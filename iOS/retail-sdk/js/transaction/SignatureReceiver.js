import manticore from 'manticore';
import {
  CardDataUtil,
  CardIssuer,
} from 'retail-payment-device';
import { Tracker, pages, action } from 'retail-page-tracker';
import { EventEmitter } from 'events';
import l10n from '../common/l10n';
import * as messageHelper from '../flows/messageHelper';
import TransactionEvent from '../transaction/transactionEvent';
import {
  transaction as transactionError,
} from '../common/sdkErrors';

/**
 * When signature is collected by external code, it will be passed a SignatureReceiver object
 * @class
 * @property {TransactionContext} context @readonly
 */
export default class SignatureReceiver extends EventEmitter {

  /**
   * @private
   */
  constructor(context, cb) {
    super();
    this.context = context;
    this.cb = cb;
  }

  /**
   * Continue processing the transaction with the supplied signature.
   * @param {string} base64SignatureJpeg The signature as a base64 encoded JPEG image. Try to keep it under 100k
   */
  continueWithSignature(base64SignatureJpeg) {
    this.context.emit(TransactionEvent.didCompleteSignature, null);
    this.cb(null, base64SignatureJpeg);
  }

  /**
   * Acquire signature using the normal PayPal Retail SDK mechanism (i.e. on screen signing)
   */
  acquireSignature() {
    const formattedValues = messageHelper.formattedInvoiceTotal(this.context.invoice);
    const titleSubstitutions = {
      amount: formattedValues.amount,
      cardIssuer: this.context.card.cardIssuer && this.context.card.cardIssuer !== CardIssuer.Unknown ?
        CardDataUtil.getCardIssuerDisplayName(this.context.card.cardIssuer) : '',
      lastFour: this.context.card.lastFourDigits,
    };

    this.sigHandle = manticore.collectSignature({
      done: l10n('Done'),
      footer: l10n('Sig.Footer'),
      title: l10n('Sig.Title', titleSubstitutions),
      signHere: l10n('Sig.Here'),
      cancel: this.context.allowInProgressPaymentCancel ? l10n('Cancel') : null,
    }, (error, signature, cancel) => {
      if (error) {
        this.cb(error);
        return;
      }

      if (cancel) {
        // TODO Use flow.data.alert
        this.alert = manticore.alert({
          title: l10n('Tx.Alert.Cancel.Title'),
          message: l10n('Tx.Alert.Cancel.Msg'),
          buttons: [l10n('Yes')],
          cancel: l10n('No'),
        }, (a, ix) => {
          a.dismiss();
          if (ix === 0) {
            this.cancel();
          }
        });
        return;
      }

      Tracker.publishPageView(null, pages.signature.withAction(action.acquire));
      this.continueWithSignature(signature);
    });
  }

  /**
   * Cancel the transaction because of a signature failure.
   */
  cancel() {
    Tracker.publishPageView(null, pages.signature.withAction(action.cancel));
    const error = transactionError.customerCancel;
    this.context.emit(TransactionEvent.didCompleteSignature, error);
    this.cb(error);
    this.dismiss();
  }

  /**
   * Dismiss any open alert windows and emit 'cancelled' in order to notify custom signature collectors to dismiss their
   * signature collection display
   * @private
   */
  dismiss() {
    this.emit(SignatureReceiver.event.cancelled);
    if (this.sigHandle) {
      this.sigHandle.dismiss();
    }
  }

  /**
   * Called when the transaction is cancelled while waiting to collect the signature
   * @event SignatureReceiver#cancelled
   */
}

SignatureReceiver.event = {
  cancelled: 'cancelled',
};
