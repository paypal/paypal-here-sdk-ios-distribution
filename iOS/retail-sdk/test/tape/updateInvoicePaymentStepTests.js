/* eslint-disable global-require */
import test from 'tape';
import sinon from 'sinon';
import {
  TransactionType,
} from 'retail-payment-device';
import UpdateInvoicePaymentStep from '../../js/flows/steps/UpdateInvoicePaymentStep';

test('Update invoice type to authorization', (t) => {
  // Given
  const txContext = {
    type: TransactionType.Auth,
    invoice: {
      paypalId: 'paypal-id',
    },
  };
  const flow = {
    data: {
      tx: {
        transactionHandle: 'transactionHandle',
      },
    },
    next: sinon.spy(),
  };
  const invoiceStep = new UpdateInvoicePaymentStep(txContext);

  // When
  invoiceStep.execute(flow);

  // Then
  const stubPayment = txContext.invoice.payments[0];
  t.equal(stubPayment.transactionType, 'AUTHORIZATION', 'Invoice transaction type was updated as authorization');
  t.end();
});

test('Update invoice type to sale', (t) => {
  // Given
  const txContext = {
    type: TransactionType.Sale,
    invoice: {
      paypalId: 'paypal-id',
    },
  };
  const flow = {
    data: {
      tx: {
        transactionHandle: 'transactionHandle',
      },
    },
    next: sinon.spy(),
  };
  const invoiceStep = new UpdateInvoicePaymentStep(txContext);

  // When
  invoiceStep.execute(flow);

  // Then
  const stubPayment = txContext.invoice.payments[0];
  t.equal(stubPayment.transactionType, 'SALE', 'Invoice transaction type was updated as sale');
  t.end();
});
