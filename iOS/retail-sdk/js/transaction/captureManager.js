import log from 'manticore-log';
import {
  transaction as transactionError,
  sdk as sdkError,
} from '../common/sdkErrors';
import Merchant from '../common/Merchant';

const Log = log('captureManager');

export default function captureAuthorization(authorizationId, invoiceId, totalAmount,
                                             gratuityAmount, currency, callback) {
  const totalAmountInDecimal = parseFloat(totalAmount);
  const gratuityAmountInDecimal = parseFloat(gratuityAmount);
  Log.debug(() => `the authorization id is ${JSON.stringify(authorizationId)} and is of the type ${typeof authorizationId}`);
  Log.debug(() => `the invoice id is ${JSON.stringify(invoiceId)} and is of the type ${typeof invoiceId}`);
  Log.debug(() => `the totalAmount is ${JSON.stringify(totalAmountInDecimal)} and is of the type ${typeof totalAmountInDecimal}`);
  Log.debug(() => `the gratuity is ${JSON.stringify(gratuityAmountInDecimal)} and is of the type ${typeof gratuityAmountInDecimal}`);

  let validationErrorDeveloperMessage = null;
  if (!authorizationId) {
    validationErrorDeveloperMessage = 'authorization id is missing';
  } else if (!invoiceId) {
    validationErrorDeveloperMessage = 'invoice id is missing';
  } else if (!totalAmountInDecimal || totalAmountInDecimal < 0) {
    validationErrorDeveloperMessage = 'totalAmount is missing or invalid';
  } else if (gratuityAmountInDecimal &&
    (gratuityAmountInDecimal < 0 || gratuityAmountInDecimal > totalAmountInDecimal)) {
    validationErrorDeveloperMessage = 'gratuity should be greater than 0 and less than totalAmount';
  } else if (!currency) {
    validationErrorDeveloperMessage = 'currency is missing';
  }


  if (validationErrorDeveloperMessage) {
    Log.error(`Invalid input: ${validationErrorDeveloperMessage}`);
    const validationError = sdkError.validationError;
    validationError.developerMessage = validationErrorDeveloperMessage;
    callback(validationError);
    return;
  }

  // Set the total amount and currency
  const total = {
    currency,
    value: totalAmountInDecimal,
  };
  const requestBody = {
    totalAmount: total,
    finalCapture: true,
    invoiceId,
  };

  // Set the gratuity if present
  if (gratuityAmount) {
    requestBody.gratuity = {
      currency,
      value: gratuityAmountInDecimal,
    };
  }

  Log.debug(() => `the capture request is ${JSON.stringify(requestBody)}`);
  const op = `checkouts/${authorizationId}/capture`;
  Merchant.active.request({
    service: 'retail',
    op,
    format: 'json',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  }, (error, response) => {
    if (error || !response || !response.body || !response.body.id || response.body.state !== 'completed') {
      Log.error(`Capture request ${op} returned an error: ${JSON.stringify(error)}`);
      let developerMessage = null;
      if (response && response.body) {
        developerMessage = response.body.developerMessage;
      }
      callback(transactionError.captureFailed.withDevMessage(developerMessage));
    } else {
      Log.info(`Successfully captured auth id: ${authorizationId}. Response: ${JSON.stringify(response.body, null, 4)}`);
      callback(null, response.body.id);
    }
  });
}
