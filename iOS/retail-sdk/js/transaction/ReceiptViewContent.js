import l10n from '../common/l10n';
import * as retailSDKUtil from '../common/retailSDKUtil';

/**
 * The content to be presented natively in the receipt options screen.
 * @class
 * @property {string} title
 * @property {string} message
 * @property {string} titleIconFilename
 * @property {string} maskedEmail
 * @property {string} maskedPhone
 * @property {string} disclaimer
 * @property {string} emailButtonTitle
 * @property {string} smsButtonTitle
 * @property {string} noThanksButtonTitle
 * @property {[string]} additionalReceiptOptions
 */
export class ReceiptOptionsViewContent {
  constructor(amount, isRefund, error, maskedEmail, maskedPhone, additionalReceiptOptions) {
    if (isRefund) {
      this.message = error ? l10n('Tx.RefundFailed') : l10n('Tx.RefundSuccessful');
    } else {
      if (retailSDKUtil.transactionCancelledError(error)) { // eslint-disable-line no-lonely-if
        this.message = l10n('Tx.CancelledByUser');
      } else if (error) {
        this.message = l10n('Tx.TransactionFailed');
      } else {
        this.message = l10n('Tx.TransactionSuccessful');
      }
    }

    this.title = l10n('Rcpt.Title', { amount });
    this.titleIconFilename = error ? 'ic_x_declined' : 'check_icon_green';
    this.maskedEmail = maskedEmail;
    this.maskedPhone = maskedPhone;
    this.disclaimer = l10n('Rcpt.Disclaimer');
    this.emailButtonTitle = l10n('Rcpt.EmailButtonTitle');
    this.smsButtonTitle = l10n('Rcpt.SMSButtonTitle');
    this.noThanksButtonTitle = l10n('Rcpt.NoThanksButtonTitle');
    this.additionalReceiptOptions = additionalReceiptOptions;
    this.prompt = l10n('Rcpt.Prompt');
  }
}

/**
 * The content to be presented natively in the receipt email entry screen.
 * @class
 * @property {string} title
 * @property {string} placeholder
 * @property {string} disclaimer
 * @property {string} sendButtonTitle
 */
export class ReceiptEmailEntryViewContent {
  constructor() {
    this.title = l10n('Rcpt.Email.Title');
    this.placeholder = l10n('Rcpt.Email.Placeholder');
    this.disclaimer = l10n('Rcpt.Email.Disclaimer');
    this.sendButtonTitle = l10n('Rcpt.Email.SendButtonTitle');
  }
}


/**
 * The content to be presented natively in the receipt sms entry screen.
 * @class
 * @property {string} title
 * @property {string} placeholder
 * @property {string} disclaimer
 * @property {string} sendButtonTitle
 */
export class ReceiptSMSEntryViewContent {
  constructor() {
    this.title = l10n('Rcpt.SMS.Title');
    this.placeholder = l10n('Rcpt.SMS.Placeholder');
    this.disclaimer = l10n('Rcpt.SMS.Disclaimer');
    this.sendButtonTitle = l10n('Rcpt.SMS.SendButtonTitle');
  }
}

/**
 * All the content to be displayed in the native receipt flow
 * @class
 * @property {ReceiptOptionsViewContent} receiptOptionsViewContent
 * @property {ReceiptEmailEntryViewContent} receiptEmailEntryViewContent
 * @property {ReceiptSMSEntryViewContent} receiptSMSEntryViewContent
 */
export class ReceiptViewContent {
  constructor(amount, isRefund, error, maskedEmail, maskedPhone, additionalReceiptOptions) {
    this.receiptOptionsViewContent = new ReceiptOptionsViewContent(amount, isRefund, error, maskedEmail,
      maskedPhone, additionalReceiptOptions);
    this.receiptEmailEntryViewContent = new ReceiptEmailEntryViewContent();
    this.receiptSMSEntryViewContent = new ReceiptSMSEntryViewContent();
  }
}
