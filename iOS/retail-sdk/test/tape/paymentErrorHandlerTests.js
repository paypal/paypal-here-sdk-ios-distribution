import sinon from 'sinon';
import test from 'tape';
import manticore from 'manticore';
import {
  PaymentDevice,
  FormFactor,
  deviceError,
} from 'retail-payment-device';
import { Invoice } from 'paypal-invoicing';
import PaymentErrorHandler from '../../js/flows/PaymentErrorHandler';
import TransactionContext from '../../js/transaction/TransactionContext';
import { PaymentState } from '../../js/transaction/transactionStates';
import { formattedInvoiceTotal } from '../../js/flows/messageHelper';
import { retail as retailError, transaction as transactionError } from '../../js/common/sdkErrors';
import l10n from '../../js/common/l10n';
import Merchant from '../../js/common/Merchant';
import { getAmountWithCurrencySymbol } from '../../js/common/retailSDKUtil';

function getInvoice() {
  Invoice.DefaultCurrency = 'USD';
  const invoice = new Invoice('USD');
  invoice.addItem('Test', 1, 100.0, 1);
  return invoice;
}

function getAmountTooLowInvoice() {
  Invoice.DefaultCurrency = 'USD';
  const invoice = new Invoice();
  invoice.addItem('Test', 1, 0.1, 1);
  return invoice;
}

function getAmountTooHighInvoice() {
  Invoice.DefaultCurrency = 'USD';
  const invoice = new Invoice();
  invoice.addItem('Test', 1, 10001, 1);
  return invoice;
}

function getFormattedAmount(invoice) {
  return {
    amount: getAmountWithCurrencySymbol(invoice.currency, invoice.total),
  };
}

function getPaymentDevice(config = {}) {
  const pd = new PaymentDevice(config.id || 'id-1');
  sinon.stub(pd, 'display');
  sinon.stub(pd, 'isConnected');
  sinon.stub(pd, 'waitForCardRemoval');
  pd.display.yieldsAsync();
  pd.cardInSlot = config.cardInSlot;
  pd.isConnected.returns((config.isConnected === null || config.isConnected === undefined) ? true : config.isConnected);
  return pd;
}

test('Payment error handler should prompt to contact issuer on here api error from card swipes', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ id: 'id-1' });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  errorHandler.handle(retailError.contactIssuer, FormFactor.MagneticCardSwipe, pd, (action) => {
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(pd.display.callCount, 1, 'Card reader display updated once');
    t.equal(action, PaymentErrorHandler.action.abort, 'Handle action is to abort');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.BlockedCardSwiped.Title'),
      message: l10n('Tx.Alert.BlockedCardSwiped.Msg'),
      cancel: l10n('Ok'),
    }, 'Alert options match');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.ContactIssuer, 'Card reader display message match');
    manticore.alert = null;
    t.end();
  });
});

test('Payment error handler should prompt to contact issuer on here api error from card inserts', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);
  const pdMessage = PaymentDevice.Message.ContactIssuerRemoveCard;
  const appUpdateDisplay = {
    title: l10n('Tx.Alert.BlockedCard.Title'),
    message: l10n('Tx.Alert.BlockedCard.Msg').concat(l10n('RemoveCard')),
  };
  const formattedAmount = formattedInvoiceTotal(txContext.invoice);

  // When
  errorHandler.handle(retailError.contactIssuer, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Handler action is to abort');
    t.equal(pd.display.callCount, 1, 'Update display called once');
    t.ok(pd.waitForCardRemoval.calledOnce, 'Wait for card removal');
    t.ok(pd.display.calledWith({ id: pdMessage, substitutions: formattedAmount }), 'Display called with required arguments');
    manticore.setTimeout(() => {
      t.deepEqual(manticore.alert.getCall(0).args[0], appUpdateDisplay, 'Cancelling alert is shown on the App');
      t.end();
    }, 0);
  });
});

test('Payment error handler should prompt to contact issuer on here api error from card inserts and callback called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  errorHandler.handle(retailError.contactIssuer, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler should prompt to contact issuer on here api error from card inserts and callback not called', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  errorHandler.handle(retailError.contactIssuer, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called ');
  t.end();
});

test('Payment error handler should prompt to contact issuer on here api error from NFC Payment', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  errorHandler.handle(retailError.contactIssuer, FormFactor.EmvCertifiedContactless, pd, (action) => {
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(pd.display.callCount, 1, 'Card reader display updated once');
    t.equal(action, PaymentErrorHandler.action.abort, 'Handle action is to abort');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.BlockedCardTapped.Title'),
      message: l10n('Tx.Alert.BlockedCardTapped.Msg'),
      cancel: l10n('Ok'),
    }, 'Alert options match');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.ContactIssuer, 'Card reader display message match');
    manticore.alert = null;
    t.end();
  });
});

test('Payment error handler should prompt amount too low on here transaction error from low amount manually entered card payment', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      minimum: 1.00,
    },
  };
  const formattedMinimum = { amount: '$1.00' };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice();

  txContext.invoice = getAmountTooLowInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  errorHandler.handle(transactionError.amountTooLow, FormFactor.ManualCardEntry, pd, (action) => {
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(pd.display.callCount, 1, 'Card reader display updated once');
    t.equal(action, PaymentErrorHandler.action.retry, 'Handle action is to retry');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.AmountTooLow.Title'),
      message: l10n('Tx.Alert.AmountTooLow.Msg', formattedMinimum),
      cancel: l10n('Ok'),
    }, 'Alert options match');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.AmountTooLow, 'Card reader display message match');
    manticore.alert = null;
    t.end();
  });
});

test('Payment error handler should prompt amount too low on here transaction error from low amount with card insert', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      minimum: 1.00,
    },
  };
  const formattedMinimum = { amount: '$1.00' };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.waitForCardRemoval.yieldsAsync(null);
  txContext.invoice = getAmountTooLowInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  errorHandler.handle(transactionError.amountTooLow, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.retry, 'Handle action is to retry');
    manticore.setTimeout(() => {
      t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
      t.equal(pd.display.callCount, 1, 'Card reader display updated once');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.AmountTooLow.Title'),
        message: l10n('Tx.Alert.AmountTooLow.Msg', formattedMinimum).concat(l10n('RemoveCard')),
      }, 'Alert options match');
      t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.AmountTooLowRemoveCard, 'Card reader display message match');
      manticore.alert = null;
      t.end();
    }, 0);
  });
});

test('Payment error handler should prompt amount too low on here transaction error from low amount with card insert and callback not called', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      minimum: 1.00,
    },
  };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getAmountTooLowInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields();
  const cb = sinon.spy();
  // When
  errorHandler.handle(transactionError.amountTooLow, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called');
  t.end();
});

test('Payment error handler should prompt amount too low on here transaction error from low amount with card insert and callback called once', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      minimum: 1.00,
    },
  };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);
  txContext.invoice = getAmountTooLowInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields();
  const cb = sinon.spy();

  // When
  errorHandler.handle(transactionError.amountTooLow, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback not called');
  t.end();
});

test('Payment error handler should prompt amount too high on here transaction error from high amount manually entered card payment', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      maximum: 10000.00,
    },
  };
  const formattedMaximum = { amount: '$10,000.00' };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice();

  txContext.invoice = getAmountTooHighInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  errorHandler.handle(transactionError.amountTooHigh, FormFactor.ManualCardEntry, pd, (action) => {
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(pd.display.callCount, 1, 'Card reader display updated once');
    t.equal(action, PaymentErrorHandler.action.retry, 'Handle action is to abort');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.AmountTooHigh.Title'),
      message: l10n('Tx.Alert.AmountTooHigh.Msg', formattedMaximum),
      cancel: l10n('Ok'),
    }, 'Alert options match');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.AmountTooHigh, 'Card reader display message match');
    manticore.alert = null;
    t.end();
  });
});

test('Payment error handler should prompt amount too high on here transaction error from high amount with card insert', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      maximum: 10000.00,
    },
  };
  const formattedMaximum = { amount: '$10,000.00' };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.waitForCardRemoval.yields(null);
  txContext.invoice = getAmountTooHighInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();

  // When
  errorHandler.handle(transactionError.amountTooHigh, FormFactor.Chip, pd, (action) => {
    manticore.setTimeout(() => {
      t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
      t.equal(pd.display.callCount, 1, 'Card reader display updated once');
      t.equal(action, PaymentErrorHandler.action.retry, 'Handle action is to retry');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.AmountTooHigh.Title'),
        message: l10n('Tx.Alert.AmountTooHigh.Msg', formattedMaximum).concat(l10n('RemoveCard')),
      }, 'Alert options match');
      t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.AmountTooHighRemoveCard, 'Card reader display message match');
      manticore.alert = null;
      t.end();
    }, 0);
  });
});

test('Payment error handler should prompt amount too high on here transaction error from high amount with card insert and callback not called', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      maximum: 10000.00,
    },
  };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getAmountTooHighInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields();
  const cb = sinon.spy();
  // When
  errorHandler.handle(transactionError.amountTooHigh, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called');
  t.end();
});

test('Payment error handler should prompt amount too high on here transaction error from high amount with card insert and callback called once', (t) => {
  // Given
  Merchant.active = {
    cardSettings: {
      maximum: 10000.00,
    },
  };
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);
  txContext.invoice = getAmountTooHighInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields();
  const cb = sinon.spy();
  // When
  errorHandler.handle(transactionError.amountTooHigh, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback not called');
  t.end();
});

test('Payment error handler should re-activate reader for payment on receiving nfcPaymentDeclined error from here api', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  txContext.deviceController = {
    activate: sinon.stub(),
  };
  const pd = getPaymentDevice();

  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 1);

  // When
  const errorHandler = new PaymentErrorHandler(txContext);
  errorHandler.handle(retailError.nfcPaymentDeclined, FormFactor.EmvCertifiedContactless, pd, (action) => {
    // Then
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is aborted when user wants to cancel payment');
    t.equal(txContext.deviceController.activate.callCount, 1, 'Card reader activate called once');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.NfcDecline, substitutions: null }), 'Card reader display updated with expected message');
    t.ok(txContext.setPaymentState.calledWith(PaymentState.retry), 'Reset transaction context state');
    t.ok(txContext.deviceController.activate.calledWith({
      showPrompt: false,
      formFactors: [FormFactor.Chip, FormFactor.MagneticCardSwipe],
      syncInvoiceTotal: false }), 'Activate called with expected arguments');
    t.end();
  });
});

test('Payment error handler can prompt for payment on App after receiving nfcPaymentDeclined error from here api', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  txContext.promptForPaymentInstrument = sinon.stub();
  txContext.deviceController = {
    activate: sinon.stub(),
  };
  const pd = getPaymentDevice();

  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 0);

  // When
  const errorHandler = new PaymentErrorHandler(txContext);
  errorHandler.handle(retailError.nfcPaymentDeclined, FormFactor.EmvCertifiedContactless, pd, (action) => {
    // Then
    t.equal(action, PaymentErrorHandler.action.retryWithInsertOrSwipe, 'Payment is retried when user wants to');
    t.equal(txContext.deviceController.activate.callCount, 1, 'Card reader activate called once');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.NfcDecline, substitutions: null }), 'Card reader display updated with expected message');
    t.ok(txContext.setPaymentState.calledWith(PaymentState.retry), 'Reset transaction context state');
    t.ok(txContext.deviceController.activate.calledWith({
      showPrompt: false,
      formFactors: [FormFactor.Chip, FormFactor.MagneticCardSwipe],
      syncInvoiceTotal: false }), 'Activate called with expected arguments');
    t.ok(txContext.promptForPaymentInstrument.calledWith(null, new Set([FormFactor.Chip, FormFactor.MagneticCardSwipe])), 'App prompt called with expected arguments');
    t.end();
  });
});

test('Payment error handler aborts the transaction and displays cancelling message for smartCardNotInSlot error', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice();
  sinon.stub(pd, 'abortTransaction');
  txContext.invoice = getInvoice();
  txContext.promptForPaymentInstrument = sinon.stub();
  manticore.alert = sinon.stub();

  // When
  const errorHandler = new PaymentErrorHandler(txContext);
  errorHandler.handle(deviceError.smartCardNotInSlot, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.offlineDecline, 'Payment is cancelled as an offline decline');
    t.ok(pd.abortTransaction.called, 'Transaction was aborted');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: getFormattedAmount(txContext.invoice) }), 'Card display updated with Cancelling message');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.Cancelling'),
    }, 'Cancelling alert is shown on the App');
    t.end();
  });
});

test('Payment error handler returns with abort error action when payment is cancelled and card is not in slot', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  txContext.promptForPaymentInstrument = sinon.stub();
  txContext.deviceController = {
    activate: sinon.stub(),
  };

  const pd = getPaymentDevice();
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 0);

  // When
  const errorHandler = new PaymentErrorHandler(txContext);
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as an offline decline');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: getFormattedAmount(txContext.invoice) }), 'Card display updated with Cancelling message');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.Cancelled.Title'),
      message: l10n('Tx.Alert.Cancelled.Msg'),
      cancel: l10n('Done'),
    }, 'Cancelling alert is shown on the App');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.TransactionCancelled, 'Card reader display message match');
    t.end();
  });
});

test('Payment error handler returns with abort error action when payment is cancelled for swipe', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  txContext.promptForPaymentInstrument = sinon.stub();
  txContext.deviceController = {
    activate: sinon.stub(),
  };
  const pd = getPaymentDevice();

  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 0);

  // When
  const errorHandler = new PaymentErrorHandler(txContext);
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.MagneticCardSwipe, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as an offline decline');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: getFormattedAmount(txContext.invoice) }), 'Card display updated with Cancelling message');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.Cancelled.Title'),
      message: l10n('Tx.Alert.Cancelled.Msg'),
      cancel: l10n('Done'),
    }, 'Cancelling alert is shown on the App');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.TransactionCancelled, 'Card reader display message match');
    t.end();
  });
});

test('Payment error handler returns with abort error action on cancelled payment for swipe and callback is called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  txContext.promptForPaymentInstrument = sinon.stub();
  txContext.deviceController = {
    activate: sinon.stub(),
  };
  const pd = getPaymentDevice();
  pd.display.yields(null);
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields(null, 0);
  const cb = sinon.spy();
  // When
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.MagneticCardSwipe, pd, cb);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler returns with abort error action on cancelled payment for contactless and callback is called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  txContext.promptForPaymentInstrument = sinon.stub();
  txContext.deviceController = {
    activate: sinon.stub(),
  };
  const pd = getPaymentDevice();
  pd.display.yields(null);
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields(null, 0);
  const cb = sinon.spy();
  // When
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.EmvCertifiedContactless, pd, cb);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler returns with abort error action when payment is cancelled and card is in slot', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as an offline decline');
    manticore.setTimeout(() => {
      t.equal(pd.display.callCount, 1, 'Update display called once');
      t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelledRemoveCard, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.Cancelled.Title'),
        message: l10n('Tx.Alert.Cancelled.Msg').concat(l10n('RemoveCard')),
      }, 'Cancelling alert is shown on the App');
      t.end();
    }, 0);
  });
});

test('Payment error handler returns with abort error action when payment is cancelled and card is in slot and callback called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  const cb = sinon.spy();
  // When
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler returns with abort error action when payment is cancelled and card is in slot and callback not called', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  const cb = sinon.spy();
  // When
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called ');
  t.end();
});

test('Payment error handler returns with offlineDecline error action when pin entry is cancelled from the terminal for swipe', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  const pd = getPaymentDevice({ cardInSlot: false });

  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 0);

  // When
  errorHandler.handle(deviceError.cancelReadCardData, FormFactor.MagneticCardSwipe, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.offlineDecline, 'Payment is cancelled as an offline decline');
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once for contactIssuer');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.Cancelled.Title'),
      message: l10n('Tx.Alert.Cancelled.Msg'),
      cancel: l10n('Done'),
    }, 'Cancelling alert is shown on the App');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.TransactionCancelled, 'Card reader display message match');
    t.end();
  });
});

test('Payment error handler returns with offlineDecline error action when pin entry is cancelled from the terminal for contactless', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  const pd = getPaymentDevice({ cardInSlot: false });

  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 0);

  // When
  errorHandler.handle(deviceError.cancelReadCardData, FormFactor.EmvCertifiedContactless, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.offlineDecline, 'Payment is cancelled as an offline decline');
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once for contactIssuer');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.Cancelled.Title'),
      message: l10n('Tx.Alert.Cancelled.Msg'),
      cancel: l10n('Done'),
    }, 'Cancelling alert is shown on the App');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.TransactionCancelled, 'Card reader display message match');
    t.end();
  });
});

test('Payment error handler returns with offlineDecline error action when pin entry is cancelled from the terminal and card is in slot', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(deviceError.cancelReadCardData, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.offlineDecline, 'Payment is cancelled as an offline decline');
    manticore.setTimeout(() => {
      t.equal(pd.display.callCount, 1, 'Display called once');
      t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelledRemoveCard, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Update display called');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.Cancelled.Title'),
        message: l10n('Tx.Alert.Cancelled.Msg').concat(l10n('RemoveCard')),
      }, 'Cancelling alert is shown on the App');
      t.end();
    }, 0);
  });
});

test('Payment error handler returns with offlineDecline error action when pin entry is cancelled from the terminal with card is in slot and callback called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  // When
  errorHandler.handle(deviceError.cancelReadCardData, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler returns with offlineDecline error action when pin entry is cancelled from the terminal with card is in slot and callback is not called', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  // When
  errorHandler.handle(deviceError.cancelReadCardData, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called ');
  t.end();
});

test('Payment error handler abort contact transactions that have exceeded maximum online pin retries with card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(retailError.onlinePinMaxRetryExceed, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as abort');
    manticore.setTimeout(() => {
      t.equal(pd.display.callCount, 1, 'Display called once');
      t.ok(pd.display.calledWith({ id: PaymentDevice.Message.ContactIssuerRemoveCard, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.BlockedCard.Title'),
        message: l10n('Tx.Alert.BlockedCard.Msg').concat(l10n('RemoveCard')),
      }, 'Cancelling alert shown on the app');
      t.end();
    });
  });
});

test('Payment error handler abort contact transactions that have exceeded maximum online pin retries with card inserted and callback not called', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  // When
  errorHandler.handle(retailError.onlinePinMaxRetryExceed, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called');
  t.end();
});

test('Payment error handler abort contact transactions that have exceeded maximum online pin retries with card inserted and callback called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();

  // When
  errorHandler.handle(retailError.onlinePinMaxRetryExceed, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler abort contact transactions that have exceeded maximum online pin retries without card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: false });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync(null, 0);

  // When
  errorHandler.handle(retailError.onlinePinMaxRetryExceed, FormFactor.EmvCertifiedContactless, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as abort');
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once for contactIssuer');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.BlockedCardTapped.Title'),
      message: l10n('Tx.Alert.BlockedCardTapped.Msg'),
      cancel: l10n('Ok'),
    }, 'Cancelling alert is shown on the App');
    t.equal(pd.display.getCall(0).args[0].id, PaymentDevice.Message.ContactIssuer, 'Card reader display message match');
    t.end();
  });
});

test('Payment error handler abort contact transactions that have been cancelled by the customer with card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(transactionError.customerCancel, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as abort');
    manticore.setTimeout(() => {
      t.equal(pd.display.callCount, 1, 'Display called once');
      t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelledRemoveCard, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.Cancelled.Title'),
        message: l10n('Tx.Alert.Cancelled.Msg').concat(l10n('RemoveCard')),
      }, 'Cancelling alert shown on the app');
      t.end();
    }, 0);
  });
});

test('Payment error handler abort contact transactions that have been cancelled by the customer with card inserted and callback not called', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  // When
  errorHandler.handle(transactionError.customerCancel, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called');
  t.end();
});

test('Payment error handler abort contact transactions that have been cancelled by the customer with card inserted and callback called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();

  // When
  errorHandler.handle(transactionError.customerCancel, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler abort contact transactions that have been cancelled by the customer without card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: false });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(transactionError.customerCancel, FormFactor.MagneticCardSwipe, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as abort');
    manticore.setTimeout(() => {
      t.equal(pd.display.callCount, 1, 'Display called once');
      t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.Cancelled.Title'),
        message: l10n('Tx.Alert.Cancelled.Msg'),
        cancel: l10n('Ok'),
      }, 'Cancelling alert shown on the app');
      t.end();
    }, 0);
  });
});

test('Payment error handler abort contact transactions that have been cancelled by the customer without card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: false });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yields();
  const cb = sinon.spy();

  // When
  errorHandler.handle(transactionError.customerCancel, FormFactor.MagneticCardSwipe, pd, cb);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler abort transactions for refund mismatch with card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(transactionError.refundCardMismatch, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as abort');
    manticore.setTimeout(() => {
      t.equal(pd.display.callCount, 1, 'Display called once');
      t.ok(pd.display.calledWith({ id: PaymentDevice.Message.RefundCardMismatchRemoveCard, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
      t.deepEqual(manticore.alert.getCall(0).args[0], {
        title: l10n('Tx.Alert.Refund.CardMismatch.Title'),
        message: l10n('Tx.Alert.Refund.CardMismatch.Msg').concat(l10n('RemoveCard')),
      }, 'Cancelling alert shown on the app');
      t.end();
    }, 0);
  });
});

test('Payment error handler abort transactions for refund mismatch with card inserted and callback not called', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();
  // When
  errorHandler.handle(transactionError.refundCardMismatch, FormFactor.Chip, pd, cb);
  t.equal(cb.callCount, 0, 'Callback not called');
  t.end();
});

test('Payment error handler abort transactions for refund mismatch with card inserted and callback called once', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true });
  pd.display.yields();
  pd.waitForCardRemoval.yields(null);

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  const cb = sinon.spy();

  // When
  errorHandler.handle(transactionError.refundCardMismatch, FormFactor.Chip, pd, cb);
  pd.emit(PaymentDevice.Event.cardRemoved);
  t.equal(cb.callCount, 1, 'Callback called once');
  t.end();
});

test('Payment error handler abort transactions for refund mismatch without card inserted', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: false });

  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  // When
  errorHandler.handle(transactionError.refundCardMismatch, FormFactor.EmvCertifiedContactless, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as abort');
    t.equal(pd.display.callCount, 1, 'Display called once');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.RefundCardMismatch, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.Refund.CardMismatch.Title'),
      message: l10n('Tx.Alert.Refund.CardMismatch.Msg'),
      cancel: l10n('Ok'),
    }, 'Cancelling alert shown on the app');
    t.end();
  });
});

test('Payment error handler do not prompt for card removal when device is not connected', (t) => {
  // Given
  const txContext = sinon.createStubInstance(TransactionContext);
  const pd = getPaymentDevice({ cardInSlot: true, isConnected: false });
  txContext.invoice = getInvoice();
  const errorHandler = new PaymentErrorHandler(txContext);
  manticore.alert = sinon.stub();
  manticore.alert.yieldsAsync();
  pd.waitForCardRemoval.yieldsAsync(null);

  // When
  errorHandler.handle(deviceError.paymentCancelled, FormFactor.Chip, pd, (action) => {
    t.equal(action, PaymentErrorHandler.action.abort, 'Payment is cancelled as an offline decline');
    t.equal(pd.display.callCount, 1, 'Update display called once');
    t.ok(pd.display.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedInvoiceTotal(txContext.invoice) }), 'Display called with required arguments');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('Tx.Alert.Cancelled.Title'),
      message: l10n('Tx.Alert.Cancelled.Msg'),
      cancel: l10n('Done'),
    }, 'Cancelling alert is shown on the App');
    t.end();
  });
});
