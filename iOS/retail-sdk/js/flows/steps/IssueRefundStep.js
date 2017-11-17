import log from 'manticore-log';
import { InvoiceEnums } from 'paypal-invoicing';
import l10n from '../../common/l10n';
import Merchant from '../../common/Merchant';
import FlowStep from './FlowStep';
import TransactionRecord from '../../transaction/TransactionRecord';
import {
  transaction as transactionError,
} from '../../common/sdkErrors';

const Log = log('flow.step.issueRefund');

export default class IssueRefundStep extends FlowStep {

  constructor(context) {
    super();
    this.context = context;
  }

  execute(flow) {
    if (flow.data.error) {
      Log.warn('Skip Issuing refund. Reason: One/more of previous steps logged an error');
      flow.next();
      return;
    }
    const merchant = Merchant.active;
    let service;
    let op;
    let rq;
    if (flow.data.paymentMethod === InvoiceEnums.PaymentMethod.CASH ||
        flow.data.paymentMethod === InvoiceEnums.PaymentMethod.CHECK) {
      if (!flow.data.invoiceId) {
        Log.error('No invoiceId found for refund. Aborting.');
        flow.abortFlow(transactionError.missingInvoiceId);
        return;
      }
      service = 'invoicing';
      op = `invoices/${flow.data.invoiceId}/record-refund`;
      rq = {};
      Log.info(`Issuing refund for check/cash with invoiceId: ${flow.data.invoiceId}, amount: ${this.context.refundAmount}`);
    } else {
      if (!flow.data.transactionNumber) {
        Log.error('No transaction transactionNumber found. Aborting.');
        flow.abortFlow(transactionError.missingTransactionNumber);
        return;
      }
      service = 'payments';
      op = `sale/${flow.data.transactionNumber}/refund`;
      rq = this._buildRequest(merchant);
      Log.info(`(${this.context.id}) Issuing refund for transaction number: ${flow.data.transactionNumber}, amount: ${this.context.refundAmount}`);
    }
    merchant.request({
      service,
      op,
      format: 'json',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rq),
    }, (error, refundRz) => {
      this._processResult(flow, error, refundRz);
    });
  }

  _buildRequest(merchant) {
    const rb = { is_non_platform_transaction: 'YES' };
    if (this.context.refundAmount) {
      rb.amount = {
        total: this.context.refundAmount,
        currency: merchant.currency,
      };
    }
    return rb;
  }

  _processResult(flow, error, refundRz) {
    flow.data.tx = {};
    if (refundRz && refundRz.body) {
      flow.data.tx = new TransactionRecord(refundRz.body);
    } else if (flow.data.paymentMethod === InvoiceEnums.PaymentMethod.CASH ||
      flow.data.paymentMethod === InvoiceEnums.PaymentMethod.CHECK) {
      // check/cash refund returns empty body
      flow.data.tx = new TransactionRecord({ invoiceId: flow.data.invoiceId });
    } else {
      Log.error('Neither card nor cash/check case! Check it out!');
    }

    if (error) {
      error.message = l10n('Tx.RefundFailed');
    } else {
      Log.info(`(${this.context.id}) Successfully refunded. txRecord: ${flow.data.tx}`);
    }
    flow.nextOrAbort(error);
  }
}

