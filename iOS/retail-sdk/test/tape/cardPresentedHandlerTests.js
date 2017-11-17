import {
  CardPresentEvent,
  CardReader,
  FormFactor,
  deviceError,
  PaymentDevice,
} from 'retail-payment-device';
import manticore from 'manticore';
import { EventEmitter } from 'events';
import sinon from 'sinon';
import proxyquire from 'proxyquire';
import { Invoice } from 'paypal-invoicing';
import { MiuraParser as Parser, ParserEvent } from 'miura-emv/src/Parser';
import PaymentErrorHandler from '../../js/flows/PaymentErrorHandler';
import { formattedInvoiceTotal, formattedRefundTotal } from '../../js/flows/messageHelper';
import l10n from '../../js/common/l10n';
import RetailTape from './RetailTape';
import emvBlobs from '../data/emvBlobs.json';

let sandbox;
let _alert;
function beforeEach(t) {
  sandbox = sinon.sandbox.create();
  _alert = manticore.alert;
  manticore.alert = () => {};
  t.end();
}

function afterEach(t) {
  sandbox.restore();
  manticore.alert = _alert;
  t.end();
}

function getInvoice(total, currencyCode) {
  const invoice = new Invoice(currencyCode);
  invoice.addItem('item', 1, total, 'itemId', 'detailId');
  return invoice;
}

function getProxyCardPresentedHandler() {
  const context = new EventEmitter();
  context.pinPresent = false;
  context.deviceController = {};
  context.getSetOfActiveFormFactors = () => (new Set([FormFactor.Chip, FormFactor.EmvCertifiedContactless, FormFactor.MagneticCardSwipe]));
  context.stopInvoiceSync = () => {};
  context.isInvoiceAmountBelowAllowedMinimum = () => {};
  context.isInvoiceAmountAboveAllowedMaximum = () => {};
  context.continueWithCard = () => {};
  context.setState = () => {};
  context.invoice = getInvoice(1.0, 'USD');
  context.refundAmount = 0.01;
  const PaymentErrorHandlerStub = sinon.createStubInstance(PaymentErrorHandler);
  const CardPresentedHandler = proxyquire('../../js/transaction/CardPresentedHandler', {
    '../flows/PaymentErrorHandler': { default: () => (PaymentErrorHandlerStub) },
  }).default;
  return {
    cardPresentedHandler: new CardPresentedHandler(context),
    PaymentErrorHandlerStub,
    context,
  };
}

function parseResponse(message) {
  return new Promise((accept, reject) => {
    const parser = new Parser();
    parser.once(ParserEvent.response, (rz) => {
      accept(rz);
    });
    parser.once(ParserEvent.unsolicited, (rz) => {
      accept(rz);
    });
    if (Array.isArray(message)) {
      for (const msg of message) {
        const buff = new Buffer(msg, 'hex');
        parser.received(buff);
      }
    } else {
      const buff = new Buffer(message, 'hex');
      parser.received(buff);
    }
    setTimeout(() => {
      reject(new Error('Data parsing failed'));
    }, 500); // Error out if response not received
  });
}

const test = new RetailTape()
  .addBeforeEach(beforeEach)
  .addAfterEach(afterEach)
  .build();

test('Card presented handler', (suite) => {
  suite.test('should prompt user with available applications for app select event', (t) => {
    // Given
    const device = new CardReader();
    const err = null;
    const availableApps = {
      apps: [
        ['01', 'AMEX Credit'],
        ['02', 'AMEX Debit'],
        ['03'],
      ],
    };
    const card = { formFactor: FormFactor.Chip };
    const data = {
      card,
      availableApps,
    };
    const { cardPresentedHandler } = getProxyCardPresentedHandler();
    sandbox.stub(manticore, 'alert', (args, cb) => {
      if (args.buttons) {
        t.equal(args.title, l10n('EMV.Select'), 'App select title matches');
        t.equal(args.buttons[0], availableApps.apps[0][1], 'First button matches');
        t.equal(args.buttons[1], availableApps.apps[1][1], 'Second button matches');
        t.equal(args.buttons[2], availableApps.apps[2][0], 'Third button matches');
        manticore.setTimeout(() => cb(null, 1), 0);
      } else {
        t.equal(args.title, l10n('EMV.DoNotRemove'), 'Processing title matches');
        t.equal(args.message, l10n('EMV.Processing'), 'Message matches');
        t.ok(args.showActivity, 'Show processing bar');
      }
    });

    sandbox.stub(device, 'selectPaymentApplication', (appId, actualCard) => {
      t.equal(appId, availableApps.apps[1][0], 'Invoked select payment App on device with expected application Id');
      t.deepEqual(actualCard, card, 'selectPaymentApplication was invoked with provided card object');
      t.equal(device.listenerCount(PaymentDevice.Event.cardRemoved), 0, 'Event listeners are not left behind');
      t.end();
    });

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.appSelectionRequired, FormFactor.Chip, data, device);
  });

  suite.test('should invoke payment error handler for error responses', (t) => {
    // Given
    const err = new Error();
    const ff = FormFactor.EmvCertifiedContactless;
    err.code = deviceError.badEmvData.code;
    const device = new CardReader();
    const { cardPresentedHandler, PaymentErrorHandlerStub } = getProxyCardPresentedHandler();

    // When
    cardPresentedHandler.handleCardPresent(err, null, ff, null, device);

    // Then
    t.ok(PaymentErrorHandlerStub.handle.calledWith(err, ff, device), 'Payment device error handler called with expected params');

    t.end();
  });

  suite.test('should properly compute pinPresent flag for presented card that requires online PIN verification', async (t) => {
    // Given
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const rz = await parseResponse([emvBlobs.M010.Contact.InsertAndOnlinePin.firstPacket,
      emvBlobs.M010.Contact.InsertAndOnlinePin.finalPacket]);
    const card = {
      chipCard: true,
      formFactor: FormFactor.Chip,
      emvData: rz,
    };
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();

    // When
    context.pinRequired = true;
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.cardDataRead, ff, { card }, device);

    // Then
    t.ok(context.pinPresent, 'pinPresent should be true for online PIN transactions');

    t.end();
  });

  suite.test('should prompt for PIN entry', (t) => {
    t.plan(4);

    // Given
    const pinEvent = { digits: 0 };
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();
    context.isRefund = () => false;
    sandbox.stub(manticore, 'alert', (args) => {
      // Then
      t.equal(args.title, l10n('Tx.Alert.EnterPin.Title', formattedInvoiceTotal(context.invoice)), 'Alert title matches');
      t.equal(args.message, l10n('Tx.Alert.EnterPin.Message'), 'Alert message matches');
      t.notOk(args.showActivity, 'Do not show processing bar');
      t.ok(context.pinRequired, 'Set PIN required flag on transaction context');
      t.end();
    });

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.pinEvent, ff, pinEvent, device);
  });

  suite.test('should prompt for PIN entry for partial refund', (t) => {
    t.plan(4);

    // Given
    const pinEvent = { digits: 0 };
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();
    context.isRefund = () => true;
    sandbox.stub(manticore, 'alert', (args) => {
      // Then
      t.equal(args.title, l10n('Tx.Alert.EnterPin.Title', formattedRefundTotal(context)), 'Alert title matches');
      t.equal(args.message, l10n('Tx.Alert.EnterPin.Message'), 'Alert message matches');
      t.notOk(args.showActivity, 'Do not show processing bar');
      t.ok(context.pinRequired, 'Set PIN required flag on transaction context');
      t.end();
    });

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.pinEvent, ff, pinEvent, device);
  });

  suite.test('should alert user on incorrect PIN', (t) => {
    // Given
    const pinEvent = { failureReason: 'Incorrect PIN entered' };
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const { cardPresentedHandler } = getProxyCardPresentedHandler();
    sandbox.stub(manticore, 'alert', (args) => {
      // Then
      t.equal(args.title, l10n('Tx.Alert.IncorrectPin.Title', 'Alert title matches'));
      t.equal(args.message, l10n('Tx.Alert.IncorrectPin.Message'), 'Alert message matches');
      t.notOk(args.showActivity, 'Do not show processing bar');
      t.end();
    });

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.pinEvent, ff, pinEvent, device);
  });

  suite.test('should invoke card presented handler when listeners are registered', async (t) => {
    // Given
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const rz = await parseResponse([emvBlobs.M010.Contact.Insert.firstPacket,
      emvBlobs.M010.Contact.Insert.finalPacket]);
    const card = {
      chipCard: true,
      formFactor: FormFactor.Chip,
      emvData: rz,
    };
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();
    context.cardPresentedHandler = (data) => {
      // Then
      t.deepEqual(data, card, 'Expected card object was emitted');
      t.end();
    };

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.cardDataRead, ff, { card }, device);
  });

  suite.test('should continue with presented card when no card present listeners are registered', async (t) => {
    // Given
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const rz = await parseResponse([emvBlobs.M010.Contact.Insert.firstPacket,
      emvBlobs.M010.Contact.Insert.finalPacket]);
    const card = {
      chipCard: true,
      formFactor: FormFactor.Chip,
      emvData: rz,
    };
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();

    // When
    const continueWithCard = sandbox.stub(context, 'continueWithCard');
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.cardDataRead, ff, { card }, device);

    // Then
    t.ok(continueWithCard.calledWith(card), 'context.continueWithCard called with expected args');
    t.end();
  });

  suite.test('should set MSRFallback flag for chip card swipes', async (t) => {
    // Given
    const err = null;
    const ff = FormFactor.MagneticCardSwipe;
    const device = new CardReader();
    const rz = await parseResponse(emvBlobs.M010.Contact.Swipe.chipCard);
    const card = {
      chipCard: true,
      formFactor: FormFactor.MagneticCardSwipe,
      emvData: rz,
    };
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();

    // When
    context.allowFallBackSwipe = true;
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.cardDataRead, ff, { card }, device);

    // Then
    t.ok(card.isMSRFallbackAllowed, 'isMSRFallbackAllowed was set on the card');
    t.end();
  });

  suite.test('should set pinPresent to true when entered PIN is correct', (t) => {
    // Given
    const pinEvent = { correct: true };
    const err = null;
    const ff = FormFactor.Chip;
    const device = new CardReader();
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.pinEvent, ff, pinEvent, device);

    // Then
    t.ok(context.pinPresent, 'pinPresent was true when entered PIN is correct');
    t.end();
  });

  suite.test('should display card inserted message when card inserts are detected', (t) => {
    // Given
    t.plan(4);
    const device = new CardReader();
    const err = null;
    const data = null;
    const { cardPresentedHandler, context } = getProxyCardPresentedHandler();
    const displayStub = sandbox.stub(device, 'display');
    context.isRefund = () => false;
    sandbox.stub(manticore, 'alert', (args) => {
      // Then
      t.equal(args.title, l10n('EMV.DoNotRemove'), 'Alert title matches');
      t.equal(args.message, l10n('EMV.Processing'), 'Alert message matches');
      t.ok(args.showActivity, 'Display progress bar');
    });

    // When
    cardPresentedHandler.handleCardPresent(err, CardPresentEvent.insertDetected, FormFactor.Chip, data, device);

    // Then
    t.ok(displayStub.calledWith({ id: PaymentDevice.Message.ProcessingContact, substitutions: { amount: '$1.00' } }, sinon.match.any), 'Device display updated with appropriate message');
  });
});

test('Card presented handler should invoke error handling module if card was removed before application was selected', (t) => {
  // Given
  const device = new CardReader();
  const err = null;
  const availableApps = {
    apps: [
      ['01', 'AMEX Credit'],
      ['02', 'AMEX Debit'],
      ['03'],
    ],
  };
  const card = { formFactor: FormFactor.Chip };
  const data = {
    card,
    availableApps,
  };
  const { cardPresentedHandler, PaymentErrorHandlerStub } = getProxyCardPresentedHandler();
  sinon.stub(device, 'selectPaymentApplication');
  manticore.alert = () => {};

  // When
  cardPresentedHandler.handleCardPresent(err, CardPresentEvent.appSelectionRequired, FormFactor.Chip, data, device);
  device.emit(PaymentDevice.Event.cardRemoved);

  // Then
  t.ok(!device.selectPaymentApplication.called, 'selectPaymentApplication should not be called if card is removed before user selects an app');
  t.ok(PaymentErrorHandlerStub.handle.calledWith(deviceError.smartCardNotInSlot, FormFactor.Chip, device), 'Payment device error handler called with expected params');
  t.end();
});
