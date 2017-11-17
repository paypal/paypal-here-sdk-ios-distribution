import log from 'manticore-log';
import {
  transaction as transactionError,
} from '../common/sdkErrors';
import Merchant from '../common/Merchant';
import AuthorizedTransaction from './AuthorizedTransaction';

const Log = log('AuthorizedTransactionsRetriever');

export default function retrieveTransactions(queryParams, callback) {
  const listOfAuths = [];
  let nextPageToken = null;

  Log.debug(() => `Retrieve list of authorizations with the queryParams: ${queryParams}`);
  const op = `checkouts?${queryParams}`;
  Merchant.active.request({
    service: 'retail',
    op,
    format: 'json',
  }, (error, response) => {
    let actualError = null;
    if (error || !response || !response.body) {
      Log.error(`Error received when trying to retrieve list of authorizations: ${JSON.stringify(error)}`);
      actualError = transactionError.retrieveAuthListFailed;
    } else if (response && response.body) {
      Log.debug(() => `this is the response object ${JSON.stringify(response.body)}`);

      // Get the list of auth
      if (response.body.items && response.body.items.length > 0) {
        response.body.items.forEach((item) => {
          const auth = new AuthorizedTransaction(item);
          listOfAuths.push(auth);
        });
      }
      Log.info(`Successfully retrieved the list of transactions containing ${listOfAuths.length} authorized transactions`);

      // Get the next page token from the array of links
      if (response.body.links) {
        response.body.links.forEach((link) => {
          if (link.rel === 'next' && link.method === 'GET') {
            nextPageToken = link.href.split('?')[1];
          }
        });
      }
    }
    callback(actualError, listOfAuths, nextPageToken);
  });
}
