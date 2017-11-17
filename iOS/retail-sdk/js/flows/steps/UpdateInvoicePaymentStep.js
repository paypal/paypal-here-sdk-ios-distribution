import moment from 'moment';
import { TransactionType } from 'retail-payment-device';
import { InvoicePayment, InvoiceEnums } from 'paypal-invoicing';
import FlowStep from './FlowStep';
import * as retailSDKUtils from '../../common/retailSDKUtil';

export default class UpdateInvoicePaymentStep extends FlowStep {
  constructor(context) {
    super();
    this.context = context;
  }

  execute(flow) {
    const error = flow.data.error;
    if (!error) {
      const invoice = this.context.invoice;
      const stubPayment = new InvoicePayment();
      stubPayment.type = InvoiceEnums.PaymentType.EXTERNAL;
      stubPayment.transactionID = flow.data.tx.transactionNumber;
      stubPayment.transactionType = this.context.type === TransactionType.Auth ? 'AUTHORIZATION' : 'SALE';
      stubPayment.date = moment();
      stubPayment.method = retailSDKUtils.getInvoiceEnumFromPaymentType(this.context.paymentType);
      stubPayment.amount = invoice.total;
      stubPayment.currency = invoice.currency;
      if (invoice.payments) {
        invoice.payments.push(stubPayment);
      } else {
        invoice.payments = [stubPayment];
      }
      invoice.status = InvoiceEnums.Status.PAID;
      if (this.context.refundAmount) {
        stubPayment.transactionType = 'REFUND';
        invoice.status = InvoiceEnums.Status.REFUNDED;
        if (this.context.refundAmount.lessThan(invoice.total)) {
          invoice.status = InvoiceEnums.Status.PARTIALLY_REFUNDED;
        }
        invoice.refundedAmount = this.context.refundAmount;
      }
    } else if (retailSDKUtils.transactionCancelledError(error)) {
      this.context.invoice.isCancelled = true;
    } else {
      this.context.invoice.isFailed = true;
    }
    flow.next();
  }
}
