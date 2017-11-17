import proxyquire from 'proxyquire';
import sinon from 'sinon';
import test from 'tape';
import {
  merchant as merchantError,
  sdk as sdkError,
} from '../../js/common/sdkErrors';
import testUtils from '../testUtils';
import TransactionContext from '../../js/transaction/TransactionContext';

function getSdk() {
  return proxyquire('../../js/sdk', {
    './common/Features': { loadRemoteFeatureMap: () => {} },
    './common/cal': {
      attach: () => {},
      newGroup: () => {},
    },
  });
}

const validTokenParts = {
  accessToken: 'A103.sUkRBQMTxTJxL_8n6NagMGPXAdyHtSyAUy07VOgWfZ66RXZZTnIgy14zzS3_t8XX.olUb72v4nvmrxtjTib2gjRCpzue',
  refreshUrl: null,
  refreshToken: 'Js1k3u_hmyH5dpTMawrsOwNsgBe80dzkcPhwdzMdL6ShkldA1FwOayeXudJYe5evp5Y-4ovAEwaOgq15msWvixIIcGQiqYUaq2Bpuk64Rc51hZfz',
  appId: 'HereSDKPOS',
  appSecret: 'HereSDKPOS',
  environment: 'STAGE2d0044',
};

test('sdk', (suite) => {
  suite.test('environment is required for composite token building', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: 'accessToken',
      refreshUrl: 'refreshUrl',
      refreshToken: 'refreshToken',
      appId: 'appId',
      appSecret: 'appSecret',
      environment: null,
    };
    try {
      sdk.buildCompositeToken(tokenParts);
    } catch (e) {
      t.equal(e.message, merchantError.environmentNotProvided.message, 'Received expected error');
      t.end();
    }
  });

  suite.test('accessToken is required for composite token building', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: null,
      refreshUrl: 'refreshUrl',
      refreshToken: 'refreshToken',
      appId: 'appId',
      appSecret: 'appSecret',
      environment: 'environment',
    };
    try {
      sdk.buildCompositeToken(tokenParts);
    } catch (e) {
      t.equal(e.message, merchantError.accessTokenNotProvided.message, 'Received expected error');
      t.end();
    }
  });

  suite.test('appId is optional for composite token building', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: 'accessToken',
      refreshUrl: 'refreshUrl',
      refreshToken: 'refreshToken',
      appId: null,
      appSecret: 'appSecret',
      environment: 'environment',
    };
    const token = sdk.buildCompositeToken(tokenParts);
    t.ok(token, 'token returned when appId is not set');
    t.end();
  });

  suite.test('appSecret is not required for composite token building', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: 'accessToken',
      refreshUrl: 'refreshUrl',
      refreshToken: 'refreshToken',
      appId: 'appId',
      appSecret: null,
      environment: 'environment',
    };
    const token = sdk.buildCompositeToken(tokenParts);
    t.ok(token, 'token returned when appSecret is not set');
    t.end();
  });

  suite.test('refreshUrl and refreshToken is not required for composite token building', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: 'accessToken',
      refreshUrl: null,
      refreshToken: null,
      appId: 'appId',
      appSecret: 'appSecret',
      environment: 'environment',
    };
    const token = sdk.buildCompositeToken(tokenParts);
    t.ok(token, 'token returned when refreshUrl or refreshToken is not set');
    t.end();
  });

  suite.test('composite token generation works when refreshUrl is provided and refreshToken is not', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: 'accessToken',
      refreshUrl: 'refreshUrl',
      refreshToken: null,
      appId: 'appId',
      appSecret: 'appSecret',
      environment: 'environment',
    };
    const token = sdk.buildCompositeToken(tokenParts);
    t.ok(token, 'token returned when refreshUrl or refreshToken is not set');
    t.end();
  });

  suite.test('composite token generation works when refreshToken is provided and refreshUrl is not', (t) => {
    const sdk = getSdk();
    const tokenParts = {
      accessToken: 'accessToken',
      refreshUrl: null,
      refreshToken: 'refreshToken',
      appId: 'appId',
      appSecret: 'appSecret',
      environment: 'environment',
    };
    const token = sdk.buildCompositeToken(tokenParts);
    t.ok(token, 'token is generated when refreshToken is provided but not refresh URL');
    t.end();
  });

  suite.test('composite token generation works when all parameters are provided', (t) => {
    const environment = 'STAGE2d0044';
    const sdk = getSdk();
    const expectedToken = {
      accessToken: 'A103.sUkRBQMTxTJxL_8n6NagMGPXAdyHtSyAUy07VOgWfZ66RXZZTnIgy14zzS3_t8XX.olUb72v4nvmrxtjTib2gjRCpzue',
      refreshUrl: null,
      refreshToken: 'Js1k3u_hmyH5dpTMawrsOwNsgBe80dzkcPhwdzMdL6ShkldA1FwOayeXudJYe5evp5Y-4ovAEwaOgq15msWvixIIcGQiqYUaq2Bpuk64Rc51hZfz',
      appId: 'HereSDKPOS',
      appSecret: 'HereSDKPOS',
      environment,
    };
    const token = sdk.buildCompositeToken(expectedToken);
    t.ok(token, 'token is generated when refreshToken is provided but not refresh URL');
    const resultParts = token.split(':');
    const unpacked = new Buffer(resultParts[1], 'base64');
    const tokenArray = JSON.parse(unpacked.toString('utf8'));
    const appIdParts = (new Buffer(tokenArray[4], 'base64').toString('utf8')).split(':');
    t.notEqual(resultParts[0], environment, 'Stage should have been converted to lower case');
    t.equal(resultParts[0], environment.toLowerCase(), 'Stage should have been converted to lower case');
    t.equal(tokenArray[0], expectedToken.accessToken, 'Access token matches');
    t.equal(tokenArray[3], expectedToken.refreshToken, 'Refresh token matches');
    t.equal(appIdParts[0], expectedToken.appId, 'App Id matches');
    t.equal(appIdParts[1], expectedToken.appSecret, 'App Secret matches');
    t.end();
  });

  suite.test('set merchant API builds & returns the expected merchant object', (t) => {
    t.plan(2);
    const sdk = getSdk();
    const merchantData = {
      token: validTokenParts,
      repository: 'live',
      userInfo: testUtils.merchantUserInfo('US').body,
      status: testUtils.merchantStatus('USD').body,
    };
    const merchant = sdk.setMerchant(merchantData);
    t.deepEqual(merchant.userInfo, merchantData.userInfo, 'The merchant user info should match');
    t.deepEqual(merchant.status, merchantData.status, 'The merchant status should match');
    t.end();
  });

  suite.test('set merchant API throws invalid merchant data exception when no data is passed', (t) => {
    t.plan(1);
    const sdk = getSdk();
    try {
      sdk.setMerchant();
    } catch (e) {
      t.equal(e.message, merchantError.merchantDataNotProvided.message);
      t.end();
    }
  });

  suite.test('set merchant API throws invalid token exception when no data is passed', (t) => {
    t.plan(1);
    const sdk = getSdk();
    try {
      sdk.setMerchant({});
    } catch (e) {
      t.equal(e.message, merchantError.tokenDataNotProvided.message);
      t.end();
    }
  });

  suite.test('set merchant API throws invalid token exception when no token data is passed', (t) => {
    t.plan(1);
    const sdk = getSdk();
    const merchantData = {
      userInfo: testUtils.merchantUserInfo('US').body,
      status: testUtils.merchantStatus('USD').body,
    };
    try {
      sdk.setMerchant(merchantData);
    } catch (e) {
      t.equal(e.message, merchantError.tokenDataNotProvided.message);
      t.end();
    }
  });

  suite.test('set merchant API throws merchant data missing error when the merchant object is not passed in', (t) => {
    t.plan(1);
    const sdk = getSdk();
    const merchantData = {
      token: validTokenParts,
      repository: 'live',
      status: testUtils.merchantStatus('USD').body,
    };
    try {
      sdk.setMerchant(merchantData);
    } catch (e) {
      t.equal(e.message, merchantError.merchantUserInfoNotProvided.message);
      t.end();
    }
  });

  suite.test('set merchant API throws merchant status data missing error when the status info is not passed in', (t) => {
    t.plan(1);
    const sdk = getSdk();
    const merchantData = {
      token: validTokenParts,
      repository: 'live',
      userInfo: testUtils.merchantUserInfo('US').body,
    };
    try {
      sdk.setMerchant(merchantData);
    } catch (e) {
      t.equal(e.message, merchantError.merchantStatusNotProvided.message);
      t.end();
    }
  });

  suite.test('set merchant API throws error when repository information is not passed', (t) => {
    t.plan(1);
    const sdk = getSdk();
    const merchantData = {
      token: validTokenParts,
      status: testUtils.merchantStatus('USD').body,
    };
    try {
      sdk.setMerchant(merchantData);
    } catch (e) {
      t.equal(e.message, merchantError.invalidToken.message);
      t.end();
    }
  });
});

test('SDK.logout aborts active transaction', (t) => {
  // Given
  const sdk = getSdk();
  TransactionContext.active = sinon.createStubInstance(TransactionContext);

  // When
  sdk.logout();

  // Then
  t.ok(TransactionContext.active.end.calledWith(sdkError.userCancelled, null, false), 'Active transaction was cancelled');
  t.end();
});

