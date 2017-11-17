import manticore from 'manticore';
import sinon from 'sinon';
import proxyquire from 'proxyquire';
import RetailTape from './RetailTape';
import setNetworkHandler from '../../js/common/NetworkHandler/networkInterceptor';
import NetworkResponse from '../../js/common/NetworkHandler/NetworkResponse';

let sandbox;
function beforeEach(t) {
  sandbox = sinon.sandbox.create();
  t.end();
}

function afterEach(t) {
  sandbox.restore();
  t.end();
}

const test = new RetailTape()
  .addBeforeEach(beforeEach)
  .addAfterEach(afterEach)
  .build();

function setup() {
  const httpStub = sandbox.stub(manticore, 'http');
  const sdk = proxyquire('../../js/sdk', {
    './common/Features': { loadRemoteFeatureMap: () => {} },
    './common/cal': {
      attach: () => {},
      newGroup: () => {},
    },
  });

  return {
    http: httpStub,
    sdk,
  };
}

test('Network interceptor', (suite) => {
  suite.test('should default to manticore http handler when not set', (t) => {
    const { http } = setup();

    // When
    manticore.http({ url: 'http://paypal.com' });

    // Then
    t.ok(http.called, 'manticore.http was called when network interceptor is not provided');

    t.end();
  });

  suite.test('can be set from SDK.js', (t) => {
    // Given
    const { http, sdk } = setup();
    const networkInterceptor = sandbox.stub();
    sdk.setNetworkInterceptor(networkInterceptor);

    // When
    manticore.http({ url: 'http://paypal.com' });

    // Then
    t.notOk(http.called, 'Default http implementation should not be implemented when network interceptor is set');
    t.ok(networkInterceptor.called, 'Network interceptor was invoked');

    t.end();
  });

  suite.test('builds NetworkRequest as expected', (t) => {
    // Given
    const customInterceptor = sandbox.stub();
    const url = 'http://paypal.com';
    const body = '{ custom body text }';
    const method = 'GET';
    const headers = {
      header1: 'header1.val',
      header2: 'header2.val',
    };

    setNetworkHandler(customInterceptor);

    // When
    manticore.http({
      url,
      body,
      method,
      headers,
    });

    // Then
    t.ok(customInterceptor.called, 'interceptor was called');
    t.equal(customInterceptor.getCall(0).args[0].url, url, 'invoked with expected request url');
    t.equal(customInterceptor.getCall(0).args[0].body, body, 'invoked with expected request body');
    t.equal(customInterceptor.getCall(0).args[0].method, method, 'invoked with expected request method');
    t.deepEqual(customInterceptor.getCall(0).args[0].headers, headers, 'invoked with expected request headers');

    t.end();
  });

  suite.test('falls back to default interceptor custom interceptor did not handle request', (t) => {
    // Given
    const manticoreHttp = sandbox.stub(manticore, 'http');
    const customInterceptor = (request) => {
      request.continueWithResponse(null, false);
    };

    setNetworkHandler(customInterceptor);

    // When
    manticore.http({ url: 'http://paypal.com' });

    // Then
    t.ok(manticoreHttp.called, 'Default interceptor was invoked as custom interceptor chose not to handle request');
    t.end();
  });

  suite.test('parses provided response body to JSON', (t) => {
    // Given
    const customInterceptor = (request) => {
      const networkResponse = new NetworkResponse();
      networkResponse.format = 'json';
      networkResponse.body = '{"status" : "HelloWorld"}';
      request.continueWithResponse(null, true, networkResponse);
    };

    setNetworkHandler(customInterceptor);

    // When
    manticore.http({ url: 'http://paypal.com' }, (err, rz) => {
      // Then
      t.equal(rz.body.status, 'HelloWorld', 'JSON response body was parsed');
      t.end();
    });
  });

  suite.test('passes error from custom interceptor', (t) => {
    // Given
    const manticoreHttp = sandbox.stub(manticore, 'http');
    const error = new Error('paypal error');
    error.code = 1234;
    error.debugId = 'paypal-debug-id';
    error.stack = 'stack trace';

    setNetworkHandler((request) => {
      const networkResponse = new NetworkResponse();
      networkResponse.format = 'json';
      networkResponse.body = '{"status" : "HelloWorld"}';
      request.continueWithResponse(error, true, networkResponse);
    });

    // When
    manticore.http({ url: 'http://paypal.com' }, (actualErr) => {
      // Then
      t.equal(actualErr.message, error.message, 'Error codes match');
      t.equal(actualErr.code, error.code, 'Error message matches');
      t.equal(actualErr.debugId, error.debugId, 'Error debugId matches');
      t.equal(actualErr.stack, error.stack, 'Error stack matches');
      t.notOk(manticoreHttp.called, 'Default handler is not invoked');
      t.end();
    });
  });

  suite.test('falls back to default handler when custom handler throws exception', (t) => {
    // Given
    const manticoreHttp = sandbox.stub(manticore, 'http');
    setNetworkHandler(() => {
      throw new Error();
    });

    // When
    manticore.http({ url: 'http://paypal.com' });

    // Then
    t.ok(manticoreHttp.called, 'Default interceptor was invoked as custom interceptor threw exception');
    t.end();
  });
});

