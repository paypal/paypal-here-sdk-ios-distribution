import test from 'tape';
import sinon from 'sinon';
import proxyquire from 'proxyquire';
import { restError } from 'paypalrest-manticore';
import TokenExpirationHandler from '../../js/common/TokenExpirationHandler';
import BaseTransactionFlow from '../../js/flows/BaseTransactionFlow';
import PaymentErrorHandler from '../../js/flows/PaymentErrorHandler';

function getTransactionContext() {
  const invoice = {};
  const TransactionContext = proxyquire('../../js/transaction/TransactionContext', {
    './DeviceController': {
      default: () => (sinon.stub()),
    },
  }).default;
  return new TransactionContext(invoice);
}

function getBaseFlow() {
  const paymentErrorHandlerStub = sinon.createStubInstance(PaymentErrorHandler);
  const paymentErrorHandlerCtor = () => (paymentErrorHandlerStub);
  paymentErrorHandlerCtor.action = PaymentErrorHandler.action;
  const BaseTransactionFlowProxied = proxyquire('../../js/flows/BaseTransactionFlow', {
    './PaymentErrorHandler': { default: paymentErrorHandlerCtor },
  }).default;
  return {
    BaseTransactionFlowProxied,
    paymentErrorHandlerStub,
  };
}

test('Transaction flow aborting a transaction invokes token expiration handler when set', (t) => {
  // Given
  const txContext = getTransactionContext();
  const baseFlow = new BaseTransactionFlow(null, txContext, (err, action) => {
    t.deepEqual(err, restError.unauthorized);
    t.notOk(action, 'null action quits the transaction');
    t.end();
  });

  // When
  txContext.setTokenExpiredHandler((tokenExpirationHandler) => {
    t.ok(tokenExpirationHandler instanceof TokenExpirationHandler);
    tokenExpirationHandler.quit();
  });
  baseFlow.abortTransaction({ error: restError.unauthorized });
});

test('Transaction flow aborting a transaction invokes payment error handler when expiration handler is not set', (t) => {
  // Given
  const txContext = getTransactionContext();
  const { BaseTransactionFlowProxied, paymentErrorHandlerStub } = getBaseFlow();

  const baseFlow = new BaseTransactionFlowProxied(null, txContext);

  // When
  txContext.setTokenExpiredHandler(null);
  baseFlow.abortTransaction({ error: restError.unauthorized });
  t.ok(paymentErrorHandlerStub.handle.calledWith(restError.unauthorized), 'Payment error handler called with expected error');
  t.end();
});

test('Alert dialog is not dismissed for transaction flow completed with retry action', (t) => {
  // Given
  const { BaseTransactionFlowProxied, paymentErrorHandlerStub } = getBaseFlow();
  const txContext = getTransactionContext();
  const alertDismiss = sinon.stub();
  paymentErrorHandlerStub.handle.yieldsAsync(PaymentErrorHandler.action.retry);

  const baseFlow = new BaseTransactionFlowProxied(null, txContext, (err, action, txRecord) => {
    // Then
    t.ok(txRecord, 'Transaction record was returned');
    t.equal(action, PaymentErrorHandler.action.retry, 'Error action matches');
    t.deepEqual(err, restError.unauthorized, 'Error matches');
    t.notOk(alertDismiss.called, 'Alert was not dismissed');
    t.end();
  });

  // When
  baseFlow.abortTransaction({
    error: restError.unauthorized,
    alert: {
      dismiss: alertDismiss,
    },
  });
});

test('Alert dialog is not dismissed for transaction flow completed with retryWithInsertOrSwipe action', (t) => {
  // Given
  const { BaseTransactionFlowProxied, paymentErrorHandlerStub } = getBaseFlow();
  const txContext = getTransactionContext();
  const alertDismiss = sinon.stub();
  paymentErrorHandlerStub.handle.yieldsAsync(PaymentErrorHandler.action.retryWithInsertOrSwipe);

  const baseFlow = new BaseTransactionFlowProxied(null, txContext, () => {
    // Then
    t.notOk(alertDismiss.called, 'Alert was not dismissed');
    t.end();
  });

  // When
  baseFlow.abortTransaction({
    error: restError.unauthorized,
    alert: {
      dismiss: alertDismiss,
    },
  });
});

test('Alert dialog is dismissed for transaction flow completed with abort action', (t) => {
  // Given
  const { BaseTransactionFlowProxied, paymentErrorHandlerStub } = getBaseFlow();
  const txContext = getTransactionContext();
  const alertDismiss = sinon.stub();
  paymentErrorHandlerStub.handle.yieldsAsync(PaymentErrorHandler.action.abort);

  const baseFlow = new BaseTransactionFlowProxied(null, txContext, (err, action, txRecord) => {
    // Then
    t.ok(txRecord, 'Transaction record was returned');
    t.equal(action, PaymentErrorHandler.action.abort, 'Error action matches');
    t.deepEqual(err, restError.unauthorized, 'Error matches');
    t.ok(alertDismiss.called, 'Alert was dismissed');
    t.end();
  });

  // When
  baseFlow.abortTransaction({
    error: restError.unauthorized,
    alert: {
      dismiss: alertDismiss,
    },
  });
});

