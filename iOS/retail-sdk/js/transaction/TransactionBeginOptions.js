/**
 * TransactionOptions provides the list of customizations for a given transaction
 * @class
 * @property {bool} showPromptInCardReader Show a payment prompt on the card reader's screen (if available) to
 * indicate that the customer/cashier should insert, swipe or tap a card
 * @property {bool} showPromptInApp Show a payment prompt in-app to indicate that the customer/cahsier should
 * insert, swipe or tap a card
 * @property {[FormFactor]} preferredFormFactors Use this property to set the preferred list of form factors for the
 * transaction. The actual list of form factors that will be used for a transaction will be an intersection of
 * available form factors and preferred list
 * @property {bool} tippingOnReaderEnabled Set the flag if the tipping on the reader is enabled
 * @property {bool} amountBasedTipping Set the flag if the amount based tipping type used, otherwise, percentage based used
 * @property {bool} isAuthCapture Setting this to true will only authorize the transaction and a payment will NOT be taken.
 * The money will be moved only when a capture call is made on an authorized transaction.
 * @property {bool} quickChipEnabled Set the flag if Quick Chip feature is Enabled
 */
export default class TransactionBeginOptions {
  toJSON() {
    return {
      showPromptInCardReader: this.showPromptInCardReader,
      showPromptInApp: this.showPromptInApp,
      preferredFormFactors: this.preferredFormFactors,
      tippingOnReaderEnabled: this.tippingOnReaderEnabled,
      amountBasedTipping: this.amountBasedTipping,
      isAuthCapture: this.isAuthCapture,
      quickChipEnabled: this.quickChipEnabled,
    };
  }

  toString() {
    return JSON.stringify(this);
  }
}
