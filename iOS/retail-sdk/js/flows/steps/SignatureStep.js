import { FormFactor, PaymentDevice, TransactionType } from 'retail-payment-device';
import log from 'manticore-log';
import SignatureReceiver from '../../transaction/SignatureReceiver';
import TransactionEvent from '../../transaction/transactionEvent';
import FlowStep from './FlowStep';
import * as messageHelper from '../messageHelper';

const Log = log('flow.step.signature');
const Message = PaymentDevice.Message;

export default class SignatureStep extends FlowStep {
  constructor(context) {
    super();
    this.context = context;
    this.quickChipEnabled = context.paymentOptions && context.paymentOptions.quickChipEnabled;
  }

  execute(flow) {
    if (this.context.card.isSignatureRequired === false || this.context.type === TransactionType.Auth) {
      Log.debug('Skipping signature step. Reason: Signature not required for this transaction');
      flow.next();
      return;
    }

    this.context.emit(TransactionEvent.willPresentSignature);
    if (flow.data.error) {
      Log.debug('Skipping signature step. Reason: One/more of previous steps logged an error');
      flow.next();
      return;
    }

    const signatureReceiver = new SignatureReceiver(this.context, (err, b64Signature) => {
      flow.removeListener('aborted', this.dismissSignature);
      flow.data.signature = b64Signature;
      Log.info(`(${this.context.id}) Signature collected. err? ${!!err}`);
      flow.nextOrAbort(err);
    });

    this.dismissSignature = () => {
      signatureReceiver.dismiss();
    };
    flow.once('aborted', this.dismissSignature);
    const substitutions = messageHelper.formattedInvoiceTotal(this.context.invoice);
    const messageId = SignatureStep.getReaderDisplayMessage(this.context.card, this.quickChipEnabled);

    this.context.card.reader.display({ id: messageId, substitutions }, () => {
      if (flow.data.alert) {
        flow.data.alert.dismiss();
      }
      if (this.context._signatureCollector) {
        this.context._signatureCollector(signatureReceiver);
      } else {
        signatureReceiver.acquireSignature();
      }
    });
  }

  static getReaderDisplayMessage(card, quickChipEnabled) {
    if (card.formFactor === FormFactor.Chip) {
      return (quickChipEnabled) ? Message.SignatureForInsertQCCR : Message.SignatureForInsert;
    }

    if (card.formFactor === FormFactor.EmvCertifiedContactless && !card.isContactlessMSD) {
      return Message.SignatureForTap;
    }
    return Message.SignatureForNonEmv;
  }
}
