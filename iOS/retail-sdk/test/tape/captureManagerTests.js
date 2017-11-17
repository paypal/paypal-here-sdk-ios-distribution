/* eslint-disable global-require */
import test from 'tape';
import sinon from 'sinon';
import Merchant from '../../js/common/Merchant';
import captureAuthorization from '../../js/transaction/captureManager';
import {
  transaction as transacitonError,
} from '../../js/common/sdkErrors';

test('Null authorization id', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization(null, null, null, null, null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'authorization id is missing', 'Correct error was passed to callback');
  t.end();
});

test('Null invoice id', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', null, null, null, null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'invoice id is missing', 'Correct error was passed to callback');
  t.end();
});

test('Null totalamount', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', 'invoiceid', null, null, null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'totalAmount is missing or invalid', 'Correct error was passed to callback');
  t.end();
});

test('Negative totalamount', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', 'invoiceId', '-10', null, null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'totalAmount is missing or invalid', 'Correct error was passed to callback');
  t.end();
});

test('Zero totalamount', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', 'invoiceId', '0', null, null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'totalAmount is missing or invalid', 'Correct error was passed to callback');
  t.end();
});

test('Null currency', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', 'invoiceId', '10', null, null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'currency is missing', 'Correct error was passed to callback');
  t.end();
});

test('Negative gratuity', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', 'invoiceId', '10', '-10', null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'gratuity should be greater than 0 and less than totalAmount', 'Correct error was passed to callback');
  t.end();
});

test('Gratuity greater than totalAmount', (t) => {
  // Given
  const callbackSpy = sinon.spy();

  // When
  captureAuthorization('authId', 'invoiceId', '10', '10.01', null, callbackSpy);

  // Then
  t.ok(callbackSpy.calledOnce, 'callback was called');
  t.equal(callbackSpy.args[0][0].developerMessage, 'gratuity should be greater than 0 and less than totalAmount', 'Correct error was passed to callback');
  t.end();
});

test('REST call was made with correct parameters', (t) => {
  // Given
  Merchant.active = { request: sinon.spy() };
  const callbackSpy = sinon.spy();
  const expectedRequestBody = {
    totalAmount: {
      currency: 'USD',
      value: 10,
    },
    finalCapture: true,
    invoiceId: 'invoiceId',
    gratuity: {
      currency: 'USD',
      value: 1.00,
    },
  };

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', callbackSpy);

  // Then
  t.equal(Merchant.active.request.calledOnce, true, 'A REST call was made');
  const requestObject = Merchant.active.request.getCall(0).args[0];
  t.equal(requestObject.service, 'retail', 'Made the call to retail');
  t.equal(requestObject.op, 'checkouts/authId/capture', 'Call used the correct query parameters');
  t.equal(requestObject.format, 'json', 'Json was used for format');
  t.equal(requestObject.method, 'POST', 'POST method was invoked');
  t.deepEqual(requestObject.body, JSON.stringify(expectedRequestBody), 'Request body is as expected');
  t.end();
});

test('Error in REST call', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  Merchant.active.request.yields(new Error('HTTP Error'), null);

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error) => {
    // Then
    t.deepEqual(error, transacitonError.captureFailed, 'Error matches');
    t.end();
  });
});

test('Empty body in REST response', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  Merchant.active.request.yields(null, {});

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error) => {
    // Then
    t.deepEqual(error, transacitonError.captureFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - Null id', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { };
  Merchant.active.request.yields(null, { body });

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error) => {
    // Then
    t.deepEqual(error, transacitonError.captureFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - Null state', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { id: 'captureId' };
  Merchant.active.request.yields(null, { body });

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error) => {
    // Then
    t.deepEqual(error, transacitonError.captureFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - Wrong state', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { id: 'captureId', state: 'voided' };
  Merchant.active.request.yields(null, { body });

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error) => {
    // Then
    t.deepEqual(error, transacitonError.captureFailed, 'Error matches');
    t.end();
  });
});

test('Failed response - with developer message', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = { id: 'captureId', developerMessage: 'Capture refused. Authorization was already completed.' };
  Merchant.active.request.yields(null, { body });

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error) => {
    // Then
    t.deepEqual(error, transacitonError.captureFailed.withDevMessage('Capture refused. Authorization was already completed'), 'Error matches');
    t.end();
  });
});

test('Successful capture', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const body = {
    id: '05766545UK3897340',
    totalAmount: {
      currency: 'USD',
      value: 31.00,
    },
    finalCapture: true,
    state: 'completed',
    invoice_number: 'INV2-S3UG-XGAX-WGVQ-XEU6',
  };
  Merchant.active.request.yields(null, { body });

  // When
  captureAuthorization('authId', 'invoiceId', '10', '1.00', 'USD', (error, captureId) => {
    // Then
    t.ok(error === null, 'Authorization was captured');
    t.equal(captureId, '05766545UK3897340', 'Capture id was passed to the callback');
    t.end();
  });
});
