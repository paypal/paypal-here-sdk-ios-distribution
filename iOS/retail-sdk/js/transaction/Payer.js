import * as util from 'manticore-util';

/**
 * Information about the payer of a transaction, including saved receipt information if
 * available
 * @class
 * @property {string} customerId An identifier for this customer that is specific to your merchant account
 * @property {string} receiptPreferenceToken A token used to send receipts and save/use previously used email address or phone number
 * @property {string} maskedEmail An email address previously used for this payment instrument, with portions masked for privacy
 * @property {string} maskedPhone A masked phone number previously used for this payment instrument
 */
export default class Payer {
  constructor(response) {
    if (response) {
      util.assignSome(this, response, ['customerId', 'receiptPreferenceToken', 'maskedEmail', 'maskedPhone']);
    }
  }
}
