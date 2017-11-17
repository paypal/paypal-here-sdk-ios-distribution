import { PaymentDevice } from 'retail-payment-device';
import log from 'manticore-log';
import * as messageHelper from './messageHelper';
import UpdateInvoicePaymentStep from './steps/UpdateInvoicePaymentStep';
import BaseTransactionFlow from './BaseTransactionFlow';
import CheckRefundEligibilityStep from './steps/CheckRefundEligibilityStep';
import IssueRefundStep from './steps/IssueRefundStep';
import RemoveCardStep from './steps/RemoveCardStep';
import ReceiptStep from './steps/ReceiptStep';

const Log = log('flow.refundFlow');

export default class RefundFlow extends BaseTransactionFlow {

  constructor(card, context, callback) {
    Log.debug('Initializing Refund Flow');
    super(card, context, callback);
    super.setFlowSteps('Refund', [
      function addPaymentCancelListeners(flow) {
        if (this.card) {
          this.card.reader.once(PaymentDevice.Event.cardRemoved, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.cancelRequested, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.cancelled, this.transactionCancelled);
        }
        flow.next();
      },
      this.createFlowMessageStep(messageHelper.showProcessingMessage),
      function endTransactionOnTerminal(flow) {
        if (this.card) {
          this.card.reader.abortTransaction(this.context, () => {
            flow.next();
          });
        } else {
          flow.next();
        }
      },
      new CheckRefundEligibilityStep(context).flowStep,
      this.createFlowMessageStep(messageHelper.showRefundProcessingMessage),
      function removePaymentCancelListeners(flow) {
        this._removePaymentCancelListeners();
        flow.next();
      },
      new IssueRefundStep(context).flowStep,
      new RemoveCardStep(context).flowStep,
      this.createFlowMessageStep(messageHelper.showCompleteMessage),
    ])
      .addFlowEndedHandler(() => this._removePaymentCancelListeners())
      .setCompletionSteps('Refund-Receipt', [
        new UpdateInvoicePaymentStep(context).flowStep,
        this.createFlowMessageStep(messageHelper.ifFailureShowMessage),
        new ReceiptStep(this.context).flowStep,
      ]);

    const paymentToRefund = context.invoice.payments && context.invoice.payments[0];
    this.flow.data.invoiceId = context.invoice.payPalId;
    Log.debug(`PaymentToRefund : ${JSON.stringify(paymentToRefund)} with actual refund amount : ${context.refundAmount}`);
    if (paymentToRefund) {
      this.flow.data.transactionNumber = paymentToRefund.transactionID;
      this.flow.data.paymentMethod = paymentToRefund.method;
    }

    this.startFlow();
  }

  _removePaymentCancelListeners() {
    if (this.card) {
      this.card.reader.removeListener(PaymentDevice.Event.cardRemoved, this.transactionCancelRequested);
      this.card.reader.removeListener(PaymentDevice.Event.cancelRequested, this.transactionCancelRequested);
      this.card.reader.removeListener(PaymentDevice.Event.cancelled, this.transactionCancelled);
    }
  }
}
