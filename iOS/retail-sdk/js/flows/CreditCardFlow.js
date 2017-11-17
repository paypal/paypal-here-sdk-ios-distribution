import log from 'manticore-log';
import {
  PaymentDevice,
} from 'retail-payment-device';
import * as messageHelper from './messageHelper';
import BaseTransactionFlow from './BaseTransactionFlow';
import MerchantTakePaymentStep from './steps/MerchantTakePaymentStep';
import SignatureStep from './steps/SignatureStep';
import FinalizePaymentStep from './steps/FinalizePaymentStep';
import UpdateInvoicePaymentStep from './steps/UpdateInvoicePaymentStep';
import RemoveCardStep from './steps/RemoveCardStep';
import ReceiptStep from './steps/ReceiptStep';

const Log = log('flow.creditCardFlow');

export default class CreditCardFlow extends BaseTransactionFlow {
  constructor(card, context, callback) {
    Log.debug('Initializing Credit Flow');
    super(card, context, callback);

    super.setFlowSteps('Credit', [
      function addPaymentCancelListeners(flow) {
        if (context.allowInProgressPaymentCancel) {
          this.card.reader.once(PaymentDevice.Event.cardRemoved, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.cancelRequested, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.disconnected, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.cancelled, this.transactionCancelled);
        }
        flow.next();
      },
      this.createFlowMessageStep(messageHelper.showProcessingMessage),
      this.saveInvoiceStep,
      new MerchantTakePaymentStep(context, this.voidPaymentIfApplicable).flowStep,
      new SignatureStep(context).flowStep,
      this.createFlowMessageStep(messageHelper.showFinalizeMessage),
      function removePaymentCancelListeners(flow) {
        this._removePaymentCancelListeners();
        flow.next();
      },
      new FinalizePaymentStep(context).flowStep,
      new RemoveCardStep(context).flowStep,
      this.createFlowMessageStep(messageHelper.showCompleteMessage),
    ])
      .addFlowEndedHandler(() => this._removePaymentCancelListeners())
      .setCompletionSteps('Credit-Receipt', [
        new UpdateInvoicePaymentStep(context).flowStep,
        this.createFlowMessageStep(messageHelper.ifFailureShowMessage),
        new ReceiptStep(this.context).flowStep,
      ])
      .startFlow();
  }

  _removePaymentCancelListeners() {
    const r = this.card.reader;
    if (this.context.allowInProgressPaymentCancel) {
      r.removeListener(PaymentDevice.Event.cardRemoved, this.transactionCancelRequested);
      r.removeListener(PaymentDevice.Event.cancelRequested, this.transactionCancelRequested);
      r.removeListener(PaymentDevice.Event.disconnected, this.transactionCancelRequested);
      r.removeListener(PaymentDevice.Event.cancelled, this.transactionCancelled);
    }
  }
}
