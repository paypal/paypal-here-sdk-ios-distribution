/* eslint-disable global-require */
import test from 'tape';
import sinon from 'sinon';
import Merchant from '../../js/common/Merchant';
import voidAuthorization from '../../js/transaction/voidManager';
import {
  transaction as transacitonError,
} from '../../js/common/sdkErrors';

test('Null authorization id', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  voidAuthorization(null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'authorization id cannot be null', 'Correct error was passed to callback');
  t.end();
});

test('REST call was made with right parameters', (t) => {
  // Given
  Merchant.active = { request: sinon.spy() };
  const request = {
    paymentAction: 'authorization',
  };

  // When
  voidAuthorization('authorizationId', sinon.spy());

  // Then
  t.equal(Merchant.active.request.calledOnce, true, 'A REST call was made');
  const requestObject = Merchant.active.request.getCall(0).args[0];
  t.equal(requestObject.service, 'retail', 'Made the call to retail');
  t.equal(requestObject.op, 'checkouts/authorizationId/void', 'Call used the query parameters');
  t.equal(requestObject.format, 'json', 'Json was used for format');
  t.equal(requestObject.method, 'POST', 'POST method was invoked');
  t.equal(requestObject.body, JSON.stringify(request), 'Request body is a match');
  t.end();
});

test('Error in REST call', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  Merchant.active.request.yields(new Error('HTTP Error'), null);

  // When
  voidAuthorization('authorizationId', (error) => {
    // Then
    t.deepEqual(error, transacitonError.voidFailed, 'Error matches');
    t.end();
  });
});

test('Empty body in REST response', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  Merchant.active.request.yields(null, {});

  // When
  voidAuthorization('authorizationId', (error) => {
    // Then
    t.deepEqual(error, transacitonError.voidFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - Null id', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { };
  Merchant.active.request.yields(null, { body });

  // When
  voidAuthorization('authorizationId', (error) => {
    // Then
    t.deepEqual(error, transacitonError.voidFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - Null state', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { id: 'voidId' };
  Merchant.active.request.yields(null, { body });

  // When
  voidAuthorization('authorizationId', (error) => {
    // Then
    t.deepEqual(error, transacitonError.voidFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - Wrong state', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { id: 'voidId', state: 'authorization' };
  Merchant.active.request.yields(null, { body });

  // When
  voidAuthorization('authorizationId', (error) => {
    // Then
    t.deepEqual(error, transacitonError.voidFailed, 'Error matches');
    t.end();
  });
});

test('Successful void', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { id: 'voidId', state: 'voided' };
  Merchant.active.request.yields(null, { body });

  // When
  voidAuthorization('authorizationId', (error) => {
    // Then
    t.ok(error === null, 'Authorization was voided');
    t.end();
  });
});
