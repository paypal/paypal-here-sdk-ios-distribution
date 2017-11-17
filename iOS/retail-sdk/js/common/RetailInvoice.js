/* eslint no-useless-constructor: "off"*/
import { Invoice, InvoicePayment } from 'paypal-invoicing';
import log from 'manticore-log';

const Log = log('retail.invoice');
/**
 * The "Retail" Implementation of Invoice that is used by PPH only. Contains receiptDetails such as store ID,
 * TerminalID, and countryCode.
 * This class is a specific version implementation of the Invoice.
 *
 * @class
 * @extends Invoice
 *
 * @property {string} name Transaction type of the Invoice
 * @property {decimal} total Total Invoice amount
 * @property {string} txnHandle The transaction handle
 * @property {string} countryCode The country object that contains the country code and country name
 * @property {string} storeId The store id where the receipt was generated
 * @property {string} terminalId The terminal ID where the actual receipt was generated
 * @property {string} sellerId The seller Id (Normally set to Primary users' full name)
 * @property {Invoice.Status} status The current status of the invoice
 * @property {[InvoicePayment]} payments an array of payment objects
 * @property {string} deviceName The device name
 * @property {string} footer The custom footer text
 * @property {string} payPalId The id assigned by PayPal for an invoice. This is basically same the
 *                    super class' payPalId. This is added to open the setter on the native side.
 * @property {bool} isCancelled Check if the transaction was cancelled by the user
 * @property {bool} isFailed Check if the payment was declined by the api
 */
export class RetailInvoice extends Invoice {
  /**
   * Creates a Retail Invoice object with the following Receipt Details.
   * @constructor
   * @param {string} currencyCode Currency code identifying the currency for amounts on the invoice.
   */
  constructor(currencyCode) {
    super(currencyCode);
  }

  toJSON() {
    const invoiceJSON = super.toJSON();
    // Check if invoiceJSON contains a field called 'additional data' and it is a valid JSON object
    this._buildAdditionalDataObject(invoiceJSON);
    // Return the invoiceJSON as is
    return invoiceJSON;
  }

  readJSON(serverJSON, hasDetails) {
    super.readJSON(serverJSON, hasDetails);
    this._parseJSONResponse(serverJSON);
  }


  _buildAdditionalDataObject(invoiceJSON) {
    let additionalData = {};
    if (invoiceJSON.additional_data) {
      try {
        additionalData = JSON.parse(invoiceJSON.additional_data);
      } catch (x) {
        // CANNOT DO MUCH HERE... LOG WARNING AND QUIT
        Log.warn('Error parsing JSON for "additional data object".. ');
        return;
      }
    }
    additionalData.dname = this.deviceName;
    additionalData.footer = additionalData.footer || {};
    additionalData.footer.customText = this.footer || additionalData.footer.customText;
    additionalData.merchant = additionalData.merchant || {};
    additionalData.merchant.sellerId = this.sellerId || additionalData.merchant.sellerId;
    additionalData.merchant.storeId = this.storeId || additionalData.merchant.storeId;
    additionalData.merchant.terminalId = this.terminalId || additionalData.merchant.terminalId;
    invoiceJSON.additional_data = JSON.stringify(additionalData);
  }

  _parseJSONResponse(serverJSON) {
    /*
     Parse the stringified additional Data and set it to the respective variables.
     */
    let jsonAdditionalData;
    if (serverJSON.additional_data) {
      try {
        jsonAdditionalData = JSON.parse(serverJSON.additional_data);
      } catch (e) {
        // Valid JSON not present .. Dont parse any values from it.
        Log.warn('Error parsing JSON for "additional data object" from server.. ');
        return;
      }
      this.deviceName = jsonAdditionalData.dname;
      if (jsonAdditionalData.footer) {
        this.footer = jsonAdditionalData.footer.customText;
      }
      if (jsonAdditionalData.merchant) {
        if (jsonAdditionalData.merchant.seller) {
          this.sellerId = jsonAdditionalData.merchant.seller.sellerId;
        }
        this.terminalId = jsonAdditionalData.merchant.terminalId;
        this.storeId = jsonAdditionalData.merchant.storeId;
      }
      // Do nothing if Additional Data is not present
    }
  }
}

/**
 * This class is only used to expose properties useful for retail invoice payments.
 *
 * @class
 *
 * @extends InvoicePayment
 * @property {string} transactionID PayPal payment transaction id. (Same name hides super class' field, Also since
 *                                  super class' field is readonly, no setters are generated)
 * @property {Invoice.PaymentMethod} method The payment method (cash, check etc.)
 */
export class RetailInvoicePayment extends InvoicePayment {

}

