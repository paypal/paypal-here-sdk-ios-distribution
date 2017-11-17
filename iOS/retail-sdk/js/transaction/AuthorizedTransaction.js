import moment from 'moment';
import { $$ } from 'paypal-invoicing';
import voidAuthorization from './voidManager';
import captureAuthorization from './captureManager';

/**
 * Information about a completed capture
 * @class
 * @property {string} authorizationId The PayPal transaction reference number for this authorization @readonly
 * @property {string} invoiceId The PayPal invoice id for this authorization @readonly
 * @property {Date} timeCreated Time at which this authorization activity was created
 * @property {decimal} authorizedAmount Amount authorized for this transaction
 * @property {string} currency Currency in which the net amount was authorized @readonly
 * @property {string} status Status of the current authorization
 */
export default class AuthorizedTransaction {
  /**
   * @private
   */
  constructor(response) {
    this.authorizationId = response.id;
    this.invoiceId = response.extension.invoice_number;
    this.timeCreated = moment(response.time_created).toDate();
    this.authorizedAmount = $$(response.gross.value);
    this.currency = response.gross.currency_code;
    this.status = response.status;
  }

  toJSON() {
    return {
      authorizationId: this.authorizationId,
      invoiceId: this.invoiceId,
      timeCreated: this.timeCreated,
      authorizedAmount: this.authorizedAmount,
      currency: this.currency,
      status: this.status,
    };
  }

  /**
   * Void this authorized transaction
   * @param {AuthorizedTransaction~voidComplete} callback
   */
  voidTransaction(callback) {
    voidAuthorization(this.authorizationId, callback);
  }

  /**
   * Capture this authorized transaction
   * @param {decimal} totalAmount the total amount that has to be captured.
   * @param {decimal} gratuityAmount (optional) the gratuity amount that is also part of the totalAmount. If present, should be less than total Amount.
   * @param {AuthorizedTransaction~captureComplete} callback
   */
  captureTransaction(totalAmount, gratuityAmount, callback) {
    captureAuthorization(this.authorizationId, this.invoiceId, totalAmount, gratuityAmount, this.currency, callback);
  }

  toString() {
    return JSON.stringify(this.toJSON());
  }
}

/**
 * @callback AuthorizedTransaction~voidComplete
 * @param {error} error Error (if any)
 */

/**
 * @callback AuthorizedTransaction~captureComplete
 * @param {error} error Error (if any)
 * @param {string} captureId Id after a successful capture
 */
