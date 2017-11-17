/* eslint-disable global-require */
import test from 'tape';
import sinon from 'sinon';
import Merchant from '../../js/common/Merchant';
import retrieveTransactions from '../../js/transaction/authorizedTransactionsRetriever';
import AuthorizedTransaction from '../../js/transaction/AuthorizedTransaction';
import {
  transaction as transacitonError,
} from '../../js/common/sdkErrors';

test('REST call was made with right parameters', (t) => {
  // Given
  Merchant.active = { request: sinon.spy() };
  const querySpy = sinon.spy();

  // When
  retrieveTransactions(querySpy, null);

  // Then
  t.equal(Merchant.active.request.calledOnce, true, 'A REST call was made');
  const requestObject = Merchant.active.request.getCall(0).args[0];
  t.equal(requestObject.service, 'retail', 'Made the call to retail');
  t.equal(requestObject.op, `checkouts?${querySpy}`, 'Call used the query parameters');
  t.equal(requestObject.format, 'json', 'Json was used for format');
  t.end();
});

test('Error in REST call', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  Merchant.active.request.yields(new Error('HTTP Error'), null);

  // When
  retrieveTransactions(null, (error, listOfAuths, nextPageToken) => {
    // Then
    t.deepEqual(listOfAuths, [], 'List of auths is empty');
    t.equal(nextPageToken, null, 'Next page token is null');
    t.deepEqual(error, transacitonError.retrieveAuthListFailed, 'Error matches');
    t.end();
  });
});

test('Empty body in REST response', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  Merchant.active.request.yields(null, {});

  // When
  retrieveTransactions(null, (error, listOfAuths, nextPageToken) => {
    // Then
    t.deepEqual(listOfAuths, [], 'List of auths is empty');
    t.equal(nextPageToken, null, 'Next page token is null');
    t.deepEqual(error, transacitonError.retrieveAuthListFailed, 'Error matches');
    t.end();
  });
});

test('Build single auth with next page token', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const response = {
    body: {
      items: [{
        id: '49B35725E9678115K',
        status: 'PENDING',
        gross: {
          currency_code: 'USD',
          value: '1.50',
        },
        time_created: '2017-09-26T21:39:39.000Z',
        extension: {
          invoice_id: 'INV2-YGQ7-SMZB-N3QG-JSTT',
        },
      }],
      links: [
        {
          href: 'v1/activities/payment-activities?subtype=AUTHORIZATION&statuses=CANCELED&page_size=2&next_page_token=1506470552001',
          rel: 'next',
          method: 'GET',
        },
        {
          href: 'v1/activities/payment-activities?key=not_valid_link',
          rel: 'self',
          method: 'GET',
        },
      ],
    },
  };
  Merchant.active.request.yields(null, response);

  // When
  retrieveTransactions(null, (error, listOfAuths, nextPageToken) => {
    // Then
    t.equal(error, null, 'No error was encountered');
    t.equal(nextPageToken, 'subtype=AUTHORIZATION&statuses=CANCELED&page_size=2&next_page_token=1506470552001', 'Next page token is valid');
    const expectedListOfAuth = [];
    const auth1 = new AuthorizedTransaction({
      id: '49B35725E9678115K',
      status: 'PENDING',
      gross: {
        currency_code: 'USD',
        value: '1.50',
      },
      time_created: '2017-09-26T21:39:39.000Z',
      extension: {
        invoice_id: 'INV2-YGQ7-SMZB-N3QG-JSTT',
      },
    });
    expectedListOfAuth.push(auth1);

    t.deepEqual(listOfAuths, expectedListOfAuth, 'Response object was built as expected');
    t.end();
  });
});

test('Build the list of auth without next page token', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const response = {
    body: {
      items: [{
        id: '49B35725E9678115K',
        status: 'PENDING',
        gross: {
          currency_code: 'USD',
          value: '1.50',
        },
        time_created: '2017-09-26T21:39:39.000Z',
        extension: {
          invoice_id: 'INV2-YGQ7-SMZB-N3QG-JST1',
        },
      }, {
        id: '6HG658529S578920A',
        status: 'CANCELED',
        gross: {
          currency_code: 'USD',
          value: '1.50',
        },
        time_created: '2017-09-26T21:34:04.000Z',
        extension: {
          invoice_id: 'INV2-YGQ7-SMZB-N3QG-JST2',
        },
      }],
    },
  };
  Merchant.active.request.yields(null, response);

  // When
  retrieveTransactions(null, (error, listOfAuths, nextPageToken) => {
    // Then
    t.equal(error, null, 'No error was encountered');
    t.equal(nextPageToken, null, 'Next page token is null');
    const expectedListOfAuth = [];
    const auth1 = new AuthorizedTransaction({
      id: '49B35725E9678115K',
      status: 'PENDING',
      gross: {
        currency_code: 'USD',
        value: '1.50',
      },
      time_created: '2017-09-26T21:39:39.000Z',
      extension: {
        invoice_id: 'INV2-YGQ7-SMZB-N3QG-JST1',
      },
    });
    expectedListOfAuth.push(auth1);
    const auth2 = new AuthorizedTransaction({
      id: '6HG658529S578920A',
      status: 'CANCELED',
      gross: {
        currency_code: 'USD',
        value: '1.50',
      },
      time_created: '2017-09-26T21:34:04.000Z',
      extension: {
        invoice_id: 'INV2-YGQ7-SMZB-N3QG-JST2',
      },
    });
    expectedListOfAuth.push(auth2);

    t.deepEqual(listOfAuths, expectedListOfAuth, 'Response object was built as expected');
    t.end();
  });
});
