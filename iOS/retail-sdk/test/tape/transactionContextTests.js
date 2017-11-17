import test from 'tape';
import proxyquire from 'proxyquire';
import sinon from 'sinon';
import manticore from 'manticore';
import { Invoice } from 'paypal-invoicing';
import { Card, FormFactor, PaymentDevice, deviceError, TransactionType } from 'retail-payment-device';
import { transaction as transactionError } from '../../js/common/sdkErrors';
import { PaymentState, TippingState } from '../../js/transaction/transactionStates';
import TransactionBeginOptions from '../../js/transaction/TransactionBeginOptions';
import TransactionEvent from '../../js/transaction/transactionEvent';
import PaymentType from '../../js/transaction/PaymentType';
import Merchant from '../../js/common/Merchant';
import OfflineDeclineFlow from '../../js/flows/OfflineDeclineFlow';
import CreditCardFlow from '../../js/flows/CreditCardFlow';

function getTransactionContext() {
  const invoice = new Invoice('USD');
  invoice.addItem('item', 1, 1, 1, 1);
  const deviceController = sinon.stub();
  const deviceSelector = sinon.stub();
  const offlineDeclineFlowStub = sinon.createStubInstance(OfflineDeclineFlow);
  const creditCardFlowStub = sinon.createStubInstance(CreditCardFlow);
  const TransactionContext = proxyquire('../../js/transaction/TransactionContext', {
    './DeviceController': {
      default: () => (deviceController),
    },
    '../paymentDevice/DeviceSelector': {
      default: deviceSelector,
    },
    '../flows/OfflineDeclineFlow': {
      default: () => (offlineDeclineFlowStub),
    },
    './../flows/CreditCardFlow': {
      default: () => (creditCardFlowStub),
    },
  }).default;
  return {
    txContext: new TransactionContext(invoice),
    deviceController,
    deviceSelector,
    OfflineDeclineFlowStub: offlineDeclineFlowStub,
    creditCardFlowStub,
  };
}

test('Card parameter is required to discard presented card', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  txContext.card = new Card();

  // When
  txContext.discardPresentedCard(null);

  // Then
  t.ok(txContext.card, 'Invoking discardPresentedCard by not providing card object does nothing');
  t.end();
});

test('Cannot discard card presented using Chip form factor', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  const chipCard = new Card();
  chipCard.formFactor = FormFactor.Chip;
  txContext.card = chipCard;

  try {
    // When
    txContext.discardPresentedCard(chipCard);
  } catch (x) {
    // Then
    t.pass('Cannot invoke discardPresentedCard when card was presented using Chip form factor');
    t.equal(x.code, transactionError.cannotDiscardCard.code, 'Error code matches');
    t.equal(x.domain, transactionError.cannotDiscardCard.domain, 'Error code matches');
    t.end();
  }
});

test('Cannot discard card presented using Contactless form factor', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  const nfcCard = new Card();
  nfcCard.formFactor = FormFactor.EmvCertifiedContactless;
  txContext.card = nfcCard;

  try {
    // When
    txContext.discardPresentedCard(nfcCard);
  } catch (x) {
    // Then
    t.pass('Cannot invoke discardPresentedCard when card was presented using NFC form factor');
    t.equal(x.code, transactionError.cannotDiscardCard.code, 'Error code matches');
    t.equal(x.domain, transactionError.cannotDiscardCard.domain, 'Error code matches');
    t.end();
  }
});

test('Cannot discard card presented using swipe form factor when payment is in progress', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  const swipeCard = new Card();
  swipeCard.formFactor = FormFactor.MagneticCardSwipe;
  txContext.card = swipeCard;

  try {
    // When
    txContext.setPaymentState(PaymentState.inProgress);
    txContext.discardPresentedCard(swipeCard);
  } catch (x) {
    // Then
    t.pass('Cannot invoke discardPresentedCard when swipe payment is in progress');
    t.equal(x.code, transactionError.cannotDiscardCard.code, 'Error code matches');
    t.equal(x.domain, transactionError.cannotDiscardCard.domain, 'Error code matches');
    t.end();
  }
});

test('Can discard cards presented using swipe form factor when payment is not in progress', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  const swipeCard = new Card();
  swipeCard.formFactor = FormFactor.MagneticCardSwipe;
  txContext.card = swipeCard;

  // When
  txContext.setPaymentState(PaymentState.idle);
  txContext.discardPresentedCard(swipeCard);

  // Then
  t.notOk(txContext.card, 'Card is cleared from transaction context');
  t.end();
});

test('Transaction context can defer card reader activation when active reader is not set', (t) => {
  // Given
  const { txContext, deviceController, deviceSelector } = getTransactionContext();
  const paymentDevice = {
    id: 'id-1',
    isConnected: () => (true),
  };
  deviceController.activate = sinon.stub();
  deviceController.activate.returns({ device: paymentDevice });
  Merchant.active = {
    cardSettings: {
      minimum: 1.00,
      maximum: 100000,
    },
  };

  // Begin the transaction when a device is not connected
  txContext.begin();
  t.notOk(deviceController.activate.called, 'Did not invoke controller.activate as no device was selected');

  // Simulate a device selection
  deviceSelector.selectedDevice = paymentDevice;
  PaymentDevice.Events.emit(PaymentDevice.Event.selected, deviceSelector.selectedDevice);
  t.ok(deviceController.activate.called, 'Activate was called after the device came online');

  Merchant.active = null;
  t.end();
});

test('Transaction context can defer card reader activation when active reader is not connected', (t) => {
  // Given
  let readerConnected = true;
  const { txContext, deviceController, deviceSelector } = getTransactionContext();
  const paymentDevice = {
    id: 'id-1',
    isConnected: () => (readerConnected),
  };
  deviceController.activate = sinon.stub();
  deviceController.activate.returns({ device: paymentDevice });
  Merchant.active = {
    cardSettings: {
      minimum: 1.00,
      maximum: 100000,
    },
  };

  // Begin the transaction when active device is set, but not connected
  deviceSelector.selectedDevice = paymentDevice;
  readerConnected = false;
  txContext.begin();
  t.notOk(deviceController.activate.called, 'Did not invoke controller.activate as no device was selected');

  // Simulate a device selection when reader is connected
  readerConnected = true;
  PaymentDevice.Events.emit(PaymentDevice.Event.selected, deviceSelector.selectedDevice);
  t.ok(deviceController.activate.called, 'Activate was called after the device came online');

  Merchant.active = null;
  t.end();
});

test('Should return payment in retry or progress', (t) => {
  const { txContext } = getTransactionContext();

  // When
  txContext.setPaymentState(PaymentState.inProgress);
  // Then
  t.equal(txContext.isPaymentInRetryOrProgress(), true);

  // When
  txContext.setPaymentState(PaymentState.retry);
  // Then
  t.equal(txContext.isPaymentInRetryOrProgress(), true);

  // When
  txContext.setPaymentState(PaymentState.complete);
  // Then
  t.equal(txContext.isPaymentInRetryOrProgress(), false);

  t.end();
});

test('Offline decline flow is started', (t) => {
  // Given
  const error = deviceError.cancelReadCardData;
  const errorAction = 'OfflineDecline';
  const ff = FormFactor.Chip;
  const { txContext, OfflineDeclineFlowStub } = getTransactionContext();
  // When
  txContext.processErrorHandlerResponse(error, errorAction, ff);
  // Then
  t.equal(OfflineDeclineFlowStub.startFlow.callCount, 1, 'Offline Decline FLow was called');
  t.end();
});

test('Emits refund amount entered event', (t) => {
  // Given
  const cardPresent = true;
  const amount = '0.10';
  const { txContext, deviceController } = getTransactionContext();
  deviceController.selectedDevice = true;
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  txContext.emit = sinon.stub();
  // When
  txContext.type = TransactionType.Refund;
  txContext.beginRefund(cardPresent, amount);
  // Then
  t.ok(txContext.emit.calledWith(TransactionEvent.refundAmountEntered), 'Emits the event');
  t.end();
});

test('Fallback swipe should not prompt for tipping if it is in complete state', (t) => {
  // Given
  const swipeCard = new Card();
  swipeCard.formFactor = FormFactor.MagneticCardSwipe;
  swipeCard.isMSRFallbackAllowed = true;
  const { txContext, deviceController } = getTransactionContext();
  deviceController.selectedDevice = true;
  txContext.deviceController.removeListeners = sinon.stub();
  txContext.card = swipeCard;
  const paymentOptions = new TransactionBeginOptions();
  paymentOptions.tippingOnReaderEnabled = true;
  txContext.paymentOptions = paymentOptions;
  txContext.setPaymentState(PaymentState.retry);
  txContext._state.setTippingState(TippingState.complete);

  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  txContext.type = TransactionType.Sale;
  txContext.continueWithCard(swipeCard);
  // Then
  t.equals(txContext.getPaymentState(), PaymentState.inProgress);
  t.end();
});

test('Transaction context updates the type to auth', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  const paymentOptions = new TransactionBeginOptions();
  paymentOptions.isAuthCapture = true;

  // When
  txContext.beginPaymentWithOptions(paymentOptions);

  // Then
  t.equal(txContext.type, TransactionType.Auth, 'Transaction context was set to authorization');
  t.end();
});

test('Transaction context sets the paymentType for auth', (t) => {
  // Given
  const { txContext, deviceController } = getTransactionContext();
  txContext.card = new Card();
  txContext.type = TransactionType.Auth;
  deviceController.removeListeners = sinon.stub();

  // When
  txContext.continueWithCard(null);

  // Then
  t.equal(txContext.paymentType, PaymentType.card, 'Payment type is same as sale');
  t.end();
});

test('Transaction context default type is sale', (t) => {
  // Given
  const { txContext } = getTransactionContext();

  // When
  txContext.beginPaymentWithOptions({});

  // Then
  t.equal(txContext.type, TransactionType.Sale, 'Transaction context was set to sale');
  t.end();
});

test('Error when authorization is processed using cash', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  txContext.end = sinon.spy();
  txContext.type = TransactionType.Auth;

  // When
  txContext.continueWithCash();

  // Then
  t.ok(txContext.end.calledOnce, 'Transaction was ended for cash');
  t.ok(txContext.end.getCall(0).args[0], transactionError.invalidAuthorization, 'The error was invalid authorization');

  t.end();
});

test('Error when authorization is processed using check', (t) => {
  // Given
  const { txContext } = getTransactionContext();
  txContext.end = sinon.spy();
  txContext.type = TransactionType.Auth;

  // When
  txContext.continueWithCheck();

  // Then
  t.ok(txContext.end.calledOnce, 'Transaction was ended for check');
  t.ok(txContext.end.getCall(0).args[0], transactionError.invalidAuthorization, 'The error was invalid authorization');

  t.end();
});
