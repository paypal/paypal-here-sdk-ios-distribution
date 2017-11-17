import test from 'tape';
import proxyquire from 'proxyquire';
import sinon from 'sinon';
import moment from 'moment';
import retrieveAuthorizedTransactions from '../../js/transaction/authManager';
import AuthStatus from '../../js/transaction/AuthStatus';

test('Invalid input - null startDateTime', (t) => {
  // Given
  const startDateTime = null;
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, null, null, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'startDateTime is missing or is invalid', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - invalid startDateTime', (t) => {
  // Given
  const startDateTime = '2017-09-09T10:20:90';
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, null, null, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'startDateTime is missing or is invalid', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - startDateTime greater than current date time', (t) => {
  // Given
  const startDateTime = '2100-09-09T10:20:10';
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, null, null, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'startDateTime is missing or is invalid', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - invalid endDateTime', (t) => {
  // Given
  const startDateTime = '2017-09-09T10:20:40';
  const endDateTime = '2017-10-10T10:20:90';
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, null, null, null, callback);

  // then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'endDateTime is invalid', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - startDateTime is greater than endDateTime', (t) => {
  // Given
  const startDateTime = new Date();
  const endDateTime = new Date(startDateTime);
  endDateTime.setDate(startDateTime.getDate() - 1);
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, null, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'startDateTime should not greater than endDateTime', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - time window is greater than 5 days', (t) => {
  // Given
  const endDateTime = new Date();
  const startDateTime = new Date(endDateTime);
  startDateTime.setDate(endDateTime.getDate() - 5);
  startDateTime.setSeconds(startDateTime.getSeconds() - 1);
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, null, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'endDateTime - startDateTime cannot be greater than 5 days', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - pageSize is null', (t) => {
  // Given
  const startDateTime = new Date();
  const endDateTime = new Date();
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, null, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'pageSize is invalid. It should be greater than 0 and less than 31', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - pageSize is equal to 0', (t) => {
  // Given
  const startDateTime = new Date();
  const endDateTime = new Date();
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, 0, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'pageSize is invalid. It should be greater than 0 and less than 31', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - pageSize is greater than 30', (t) => {
  // Given
  const startDateTime = new Date();
  const endDateTime = new Date();
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, 31, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'pageSize is invalid. It should be greater than 0 and less than 31', 'Correct error was passed to the callback');
  t.end();
});

test('Invalid input - pageSize is less than 0', (t) => {
  // Given
  const startDateTime = new Date();
  const endDateTime = new Date();
  const callback = sinon.spy();

  // When
  retrieveAuthorizedTransactions(startDateTime, endDateTime, -10, null, null, callback);

  // Then
  t.ok(callback.calledOnce, 'callback was called');
  t.deepEqual(callback.args[0][0].developerMessage, 'pageSize is invalid. It should be greater than 0 and less than 31', 'Correct error was passed to the callback');
  t.end();
});

test('Valid input - missing end date', (t) => {
  // Given
  const endDateTime = new Date();
  const startDateTime = new Date(endDateTime);
  startDateTime.setDate(endDateTime.getDate() - 5);
  let expectedQueryParam = `start_time=${moment(startDateTime).toISOString()}`;
  expectedQueryParam = `${expectedQueryParam}&end_time=${moment(endDateTime).toISOString()}`;
  expectedQueryParam = `${expectedQueryParam}&page_size=8`;

  const callback = sinon.spy();
  const retrieveTransactionsSpy = sinon.spy();
  const pm = proxyquire('../../js/transaction/authManager', {
    './authorizedTransactionsRetriever': { default: retrieveTransactionsSpy },
  });

  // When
  pm.default(startDateTime, null, 8, null, null, callback);

  // Then
  t.ok(retrieveTransactionsSpy.calledOnce, 'retrieve transactions call was made');
  console.log(expectedQueryParam);
  t.equal(retrieveTransactionsSpy.args[0][0], expectedQueryParam, 'correct query params were generated');
  t.deepEqual(retrieveTransactionsSpy.args[0][1], callback, 'callback was passed on');
  t.end();
});

test('Valid input - with one status filter', (t) => {
  // Given
  const startDateTime = new Date();
  startDateTime.setSeconds(startDateTime.getSeconds() - 1);
  const endDateTime = new Date();
  let expectedQueryParam = `start_time=${moment(startDateTime).toISOString()}`;
  expectedQueryParam = `${expectedQueryParam}&end_time=${moment(endDateTime).toISOString()}`;
  expectedQueryParam = `${expectedQueryParam}&page_size=8&statuses=PENDING`;

  const callback = sinon.spy();
  const retrieveTransactionsSpy = sinon.spy();
  const pm = proxyquire('../../js/transaction/authManager', {
    './authorizedTransactionsRetriever': { default: retrieveTransactionsSpy },
  });

  // When
  pm.default(startDateTime, endDateTime, 8, [AuthStatus.pending], null, callback);

  // Then
  t.ok(retrieveTransactionsSpy.calledOnce, 'retrieve transactions call was made');
  t.equal(retrieveTransactionsSpy.args[0][0], expectedQueryParam, 'correct query params were generated');
  t.deepEqual(retrieveTransactionsSpy.args[0][1], callback, 'callback was passed on');
  t.end();
});

test('Valid input - with two status filter', (t) => {
  // Given
  const startDateTime = new Date();
  startDateTime.setSeconds(startDateTime.getSeconds() - 1);
  const endDateTime = new Date();
  let expectedQueryParam = `start_time=${moment(startDateTime).toISOString()}`;
  expectedQueryParam = `${expectedQueryParam}&end_time=${moment(endDateTime).toISOString()}`;
  expectedQueryParam = `${expectedQueryParam}&page_size=8&statuses=CANCELED,PENDING`;

  const callback = sinon.spy();
  const retrieveTransactionsSpy = sinon.spy();
  const pm = proxyquire('../../js/transaction/authManager', {
    './authorizedTransactionsRetriever': { default: retrieveTransactionsSpy },
  });

  // When
  pm.default(startDateTime, endDateTime, 8, [AuthStatus.canceled, AuthStatus.pending], null, callback);

  // Then
  t.ok(retrieveTransactionsSpy.calledOnce, 'retrieve transactions call was made');
  t.equal(retrieveTransactionsSpy.args[0][0], expectedQueryParam, 'correct query params were generated');
  t.deepEqual(retrieveTransactionsSpy.args[0][1], callback, 'callback was passed on');
  t.end();
});

test('Valid input - only nextPageToken', (t) => {
  const nextPageToken = 'page_size=1&&next_page_token=1504910475001';

  const callback = sinon.spy();
  const retrieveTransactionsSpy = sinon.spy();
  const pm = proxyquire('../../js/transaction/authManager', {
    './authorizedTransactionsRetriever': { default: retrieveTransactionsSpy },
  });
  const expectedQueryParam = `${nextPageToken}`;

  // When
  pm.default(null, null, null, null, nextPageToken, callback);

  // Then
  t.ok(retrieveTransactionsSpy.calledOnce, 'retrieve transactions call was made');
  t.equal(retrieveTransactionsSpy.args[0][0], expectedQueryParam, 'correct query params were generated');
  t.deepEqual(retrieveTransactionsSpy.args[0][1], callback, 'callback was passed on');
  t.end();
});
