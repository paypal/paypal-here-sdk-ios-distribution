import { PayPalError, PayPalErrorInfo } from 'manticore-paypalerror';

export const domain = {
  transaction: 'transaction',
  merchant: 'merchant',
  retail: 'retail',
  sdk: 'sdk',
  network: 'network',
};

export function payPalError(errDomain, code, message) {
  const errorInfo = new PayPalErrorInfo();
  errorInfo.code = code.toString();
  errorInfo.domain = errDomain;
  errorInfo.message = message;
  return PayPalError.makeError(null, errorInfo);
}

/**
 * All errors are belong to here. One assignment per domain will keep auto-complete happy.
 */
export const transaction = {
  customerCancel: payPalError(domain.transaction, 1, 'Transaction cancelled by customer'),
  genericCancel: payPalError(domain.transaction, 2, 'The transaction was cancelled'),
  cardCantContinue: payPalError(domain.transaction, 3, 'Cannot continue with specified card.'),
  noFunctionalDevices: payPalError(domain.transaction, 4, 'No functional devices.'),
  invoiceStatusMismatch: payPalError(domain.transaction, 5,
    'The invoice status is not eligible for the given transaction method'),
  amountTooLow: payPalError(domain.transaction, 6, 'The invoice amount was too low'),
  amountTooHigh: payPalError(domain.transaction, 7, 'The invoice amount was too high'),
  failedToCollectSignature: payPalError(domain.transaction, 8, 'Failed to collect signature'),
  cannotSwipeChipCard: payPalError(domain.transaction, 9, 'Cannot swipe a chip card'),
  mustSwipeCard: payPalError(domain.transaction, 10, 'Must swipe the card'),
  refundCardMismatch: payPalError(domain.transaction, 11,
    'Card presented for refund is not the one used for the original payment'),
  cardTypeMismatch: payPalError(domain.transaction, 12, 'Presented card is not of the expected type'),
  locationError: payPalError(domain.transaction, 13, 'Unable to retrieve location information'),
  missingInvoiceId: payPalError(domain.transaction, 14, 'Invoice ID is required to complete this refund.'),
  missingTransactionNumber: payPalError(domain.transaction, 15,
    'Transaction number is required to complete this refund.'),
  cannotDiscardCard: payPalError(domain.transaction, 16, 'Cannot discard the presented card'),
  captureFailed: payPalError(domain.transaction, 17, 'The capture request has failed'),
  invalidAuthorization: payPalError(domain.transaction, 18, 'Authorization is not possible on this payment mode'),
  retrieveAuthListFailed: payPalError(domain.transaction, 19, 'Unable to retrieve list of authorizations'),
  voidFailed: payPalError(domain.transaction, 20, 'Unable to void the authorization'),
};

export const merchant = {
  failedToLoad: payPalError(domain.merchant, 1, 'Failed to load the merchant information.'),
  requiredInfoNotLoaded: payPalError(domain.merchant, 2, 'Failed to load required merchant information'),
  notInitialized: payPalError(domain.merchant, 3, 'Merchant not initialized'),
  accessTokenNotProvided: payPalError(domain.merchant, 4, 'Access token is missing from provided credentials'),
  environmentNotProvided: payPalError(domain.merchant, 5, 'Environment is missing from provided credentials'),
  merchantDataNotProvided: payPalError(domain.merchant, 6, 'Data required to create the merchant object are missing.'),
  merchantUserInfoNotProvided: payPalError(domain.merchant, 7,
    'User info data required to create the merchant object are missing.'),
  merchantStatusNotProvided: payPalError(domain.merchant, 8,
    'Status data required to create the merchant object are missing.'),
  invalidToken: payPalError(domain.merchant, 9, 'The token is either invalid or missing.'),
  tokenDataNotProvided: payPalError(domain.merchant, 10, 'The token data to build the composite token' +
    ' is either invalid or missing.'),
};

// The error codes used here must match the codes returned by the retail payments endpoint
export const retail = {
  nfcPaymentDeclined: payPalError(domain.retail, 600075),
  incorrectOnlinePin: payPalError(domain.retail, 6000164),
  onlinePinMaxRetryExceed: payPalError(domain.retail, 6000165),
  contactIssuer: payPalError(domain.retail, 580031),
};

export const network = {
  requestFailed: payPalError(domain.network, 1, 'Request failed'),
  networkOffline: payPalError(domain.network, -1001),
};

export const sdk = {
  userCancelled: payPalError(domain.sdk, 1, 'Action was cancelled by user'),
  fileNotFound: payPalError(domain.sdk, 2, 'Unable to retrieve file from device storage'),
  validationError: payPalError(domain.sdk, 3, 'The arguments passed are invalid.'),
};
