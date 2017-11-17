import * as util from 'manticore-util';
import Payer from './Payer';
import { ReceiptDestination } from './ReceiptDestination';

/**
 * Information about a completed transaction
 * @class
 * @property {string} transactionNumber The PayPal transaction reference number @readonly
 * @property {string} invoiceId The PayPal invoice id @readonly
 * @property {string} authCode The PayPal authCode @readonly
 * @property {string} transactionHandle An identifier available throughout the EMV transaction flow
 * (allocated before the transaction is complete, unlike transactionNumber) @readonly
 * @property {string} responseCode The acquirer response code @readonly
 * @property {Payer} payer Information about the payer, if available @readonly
 * @property {string} correlationId The correlationId used for obtaining additional support
 * from PayPal for this transaction attempt @readonly
 * @property {Card} card card that was presented by the consumer for this transaction @readonly
 * @property {ReceiptDestination} receiptDestination Indicates whether an email or a text
 * receipt was sent or not. @readonly
 */
export default class TransactionRecord {
  /**
   * @private
   */
  constructor(response) {
    // AuthCode is not an externally accessible value, but we use it internally so we copy it over.
    util.assignSome(this, response, ['correlationId', 'transactionNumber', 'invoiceId', 'transactionHandle',
      'responseCode', 'authCode', 'errorCode']);
    if (response.payerInfo) {
      this.payer = new Payer(response.payerInfo);
    }
    // In case of refunds, the transaction number is returned as an `id`
    if (response.id) {
      this.transactionNumber = response.id;
    }
    // For some reason, in a few of the MTP failures, the transaction handle is returned as `txnHandle` instead of `transactionHandle` :-(
    if (response.txnHandle && !this.transactionHandle) {
      this.transactionHandle = response.txnHandle;
    }
    if (response.invoiceId) {
      this.invoiceId = response.invoiceId;
    }

    this.receiptDestination = new ReceiptDestination();
  }

  /**
   * @private
   */
  updateFromFinalize(finalize) {
    if (!this.transactionNumber) {
      this.transactionNumber = finalize.transactionNumber;
    }

    if (finalize.correlationId && this.correlationId) {
      this.correlationId = `${this.correlationId},${finalize.correlationId}`;
    } else if (finalize.correlationId) {
      this.correlationId = finalize.correlationId;
    }
    if (finalize.payerInfo) {
      this.payer = new Payer(finalize.payerInfo);
    }
  }

  toString() {
    return `invoiceId: ${this.invoiceId}, transactionNumber: ${this.transactionNumber}, transactionHandle: ${this.transactionHandle}, ` +
      `responseCode: ${this.responseCode}, correlationId: ${this.correlationId}`;
  }
}

TransactionRecord.Error = {
  ContactlessNotAcceptable: 600075,
  IncorrectOnlinePin: 6000164,
};
