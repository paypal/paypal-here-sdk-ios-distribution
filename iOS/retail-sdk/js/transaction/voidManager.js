import log from 'manticore-log';
import {
  transaction as transactionError,
  sdk as sdkError,
} from '../common/sdkErrors';
import Merchant from '../common/Merchant';

const Log = log('voidManager');

export default function voidAuthorization(authorizationId, callback) {
  Log.debug(() => `the authorization id is ${JSON.stringify(authorizationId)} and is of the type ${typeof authorizationId}`);
  if (!authorizationId) {
    callback(sdkError.validationError.withDevMessage('authorization id cannot be null'));
    return;
  }

  const op = `checkouts/${authorizationId}/void`;
  const request = {
    paymentAction: 'authorization',
  };
  Merchant.active.request({
    service: 'retail',
    op,
    format: 'json',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(request),
  }, (error, response) => {
    if (error || !response || !response.body || !response.body.id || response.body.state !== 'voided') {
      Log.error(`Void request ${op} returned an error: ${JSON.stringify(error)}`);
      let developerMessage = null;
      if (response && response.body) {
        developerMessage = response.body.developerMessage;
      }
      callback(transactionError.voidFailed.withDevMessage(developerMessage));
    } else {
      Log.info(`Successfully voided auth id: ${authorizationId}.Response: ${JSON.stringify(response.body, null, 4)}`);
      callback(null);
    }
  });
}
