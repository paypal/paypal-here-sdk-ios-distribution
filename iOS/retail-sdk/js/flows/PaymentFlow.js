import log from 'manticore-log';
import * as messageHelper from './messageHelper';
import BaseTransactionFlow from './BaseTransactionFlow';
import MerchantTakePaymentStep from './steps/MerchantTakePaymentStep';
import UpdateInvoicePaymentStep from './steps/UpdateInvoicePaymentStep';
import ReceiptStep from './steps/ReceiptStep';

const Log = log('flow.paymentFlow');

export default class PaymentFlow extends BaseTransactionFlow {
  constructor(context, callback) {
    Log.debug('Initializing Payment Flow');
    super(null, context, callback);

    super.setFlowSteps('Payment', [
      this.createFlowMessageStep(messageHelper.showProcessingMessage),
      this.saveInvoiceStep,
      new MerchantTakePaymentStep(context).flowStep,
      this.createFlowMessageStep(messageHelper.showCompleteMessage),
    ]).setCompletionSteps('Payment-Receipt', [
      new UpdateInvoicePaymentStep(context).flowStep,
      new ReceiptStep(this.context).flowStep]
      )
      .startFlow();
  }
}
