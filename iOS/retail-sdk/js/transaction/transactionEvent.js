/**
 * List of events that could be emitted by the Transaction context
 */
const TransactionEvent = {
  /**
   * Signature collection was completed
   */
  didCompleteSignature: 'didCompleteSignature',

  /**
   * Signature was required for this transaction and the assigned signature collector will be activated
   */
  willPresentSignature: 'willPresentSignature',

  /**
   * A footer was added to invoice total that will be display on the connected reader
   */
  invoiceDisplayFooterUpdated: 'invoiceDisplayFooterUpdated',

  /**
   * A device form factor not previously known was discovered
   */
  formFactorAdded: 'formFactorAdded',

  /**
   * Contactless reader was deactivated
   */
  contactlessReaderDeactivated: 'contactlessReaderDeactivated',

  /**
   * Tipping flow on reader was completed
   */
  readerTippingCompleted: 'readerTippingCompleted',
  /**
   * Amount to be refunded entered
   */
  refundAmountEntered: 'refundAmountEntered',
};

export default TransactionEvent;
