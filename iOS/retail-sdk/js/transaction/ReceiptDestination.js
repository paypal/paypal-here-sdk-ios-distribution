/**
* List of possible receipt destination options, as selected by the user.
* @enum {int}
*/
export const ReceiptDestinationType = {
  /**
   * User chose the no receipt option.
   */
  none: 0,
  /**
   * User chose the email option and sent the receipt to the email provided.
   */
  email: 1,
  /**
   * User chose the text option and sent the receipt to the provided phone number.
   */
  text: 2,
};

/**
 * Contains information about the receipt status.
 * @class
 * @property {ReceiptDestinationType} type Indicates whether an email or a text
 * @property {string} email email address of the receipt is sent @readonly
 * receipt was sent or not. @readonly
 */
export class ReceiptDestination {
  constructor(type, email) {
    this.type = type || ReceiptDestinationType.none;
    this.email = email || null;
  }

}

