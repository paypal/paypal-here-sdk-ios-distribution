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
import QuickChipStep from './steps/QuickChipStep';
import ReceiptStep from './steps/ReceiptStep';

const Log = log('flow.QuickChipCreditCardFlow');

/**
 * This step is to handle Quick Chip Flow
 *
 * . Once the card data is read (QuickChipStep), send 'Z3' auth code to reader
 * . Send "Remove card" message to he reader (QuickChipStep)
 * . Remove cardRemoved listener
 * . Do not send the Auth code from server to reader (#MerchantTakePaymentStep)
 * . Change the message in Signature Step
 *
 */
export default class QuickChipCreditCardFlow extends BaseTransactionFlow {
  constructor(card, context, callback) {
    Log.debug('Initializing Quick Chip Credit Flow');
    super(card, context, callback);

    this.quickChipEnabled = context.paymentOptions.quickChipEnabled;

    this.quickChipStep = new QuickChipStep(context);
    this.qcTransactionCancelRequested = () => {
      // qcAuthSend will be set by QuickChipStep after sending QC AUTH Code
      if (!this.card.qcAuthSend) {
        this.transactionCancelRequested();
      } else {
        Log.info(`qcRemoveCard was requested from device ${this.card.reader.id}`);
      }
    };

    super.setFlowSteps('QCCredit', [
      function addPaymentCancelListeners(flow) {
        if (context.allowInProgressPaymentCancel) {
          this.card.reader.once(PaymentDevice.Event.cardRemoved, this.qcTransactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.cancelRequested, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.disconnected, this.transactionCancelRequested);
          this.card.reader.once(PaymentDevice.Event.cancelled, this.transactionCancelled);
        }
        flow.next();
      },
      this.quickChipStep.flowStep,
      this.saveInvoiceStep,
      new MerchantTakePaymentStep(context, this.voidPaymentIfApplicable).flowStep,
      new SignatureStep(context).flowStep,
      this.createFlowMessageStep(messageHelper.showFinalizeMessage),
      function removePaymentCancelListeners(flow) {
        this._removePaymentCancelListeners();
        flow.next();
      },
      new FinalizePaymentStep(context).flowStep,
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
      r.removeListener(PaymentDevice.Event.cardRemoved, this.qcTransactionCancelRequested);
      r.removeListener(PaymentDevice.Event.cancelRequested, this.transactionCancelRequested);
      r.removeListener(PaymentDevice.Event.disconnected, this.transactionCancelRequested);
      r.removeListener(PaymentDevice.Event.cancelled, this.transactionCancelled);
    }
  }
}
