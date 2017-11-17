/**
 * Created by PPH team on 3/7/17.
 */
import test from 'tape';
import sinon from 'sinon';
import { PayPalREST } from 'paypalrest-manticore';
import Merchant from '../../js/common/Merchant';

const fs = require('fs');

function buildSampleDataForMerchant() {
  let sampleData = {};
  sampleData = {
    compositeToken: fs.readFileSync('testToken.txt', 'utf-8'),
    repository: 'live',
    userInfo: {
      address: {
        country: 'US',
      },
      email: 'sample@email.com',
      name: 'Merchant-Sam',
    },
    status: {
      status: 'ready',
      currencyCode: 'US',
      businessCategoryExists: true,
      paymentTypes: 'chip',
    },
  };
  return sampleData;
}

test('Adding referrer code using es6 style', (t) => {
  let invResolver = null;
  const stubbedObj = sinon.stub(PayPalREST, 'fromToken', () => ({
    addResolver: (key, resolver) => {
      if (key === 'invoicing') {
        invResolver = resolver;
      }
    },
  }));

  const opt = {};
  const m = new Merchant(buildSampleDataForMerchant());
  m.referrerCode = 'xyz124436';
  t.ok(invResolver, 'Invoice Resolver is not Null');
  invResolver(m.api, opt);
  // expect headers to have opt. headers[PayPal-Attribution-Id]
  t.equals(opt.headers['PayPal-Partner-Attribution-Id'], m.referrerCode);
  stubbedObj.restore();
  t.end();
});


test('Setting referrer code to empty string', (t) => {
  let invResolver = null;
  const stubObj = sinon.stub(PayPalREST, 'fromToken', () => ({
    addResolver: (key, resolver) => {
      if (key === 'invoicing') {
        invResolver = resolver;
      }
    },
  }));

  const opt = {};
  const m = new Merchant(buildSampleDataForMerchant());
  t.ok(invResolver, 'Invoice Resolver is not Null');
  invResolver(m.api, opt);
  // expect headers to have opt. headers[PayPal-Attribution-Id]
  t.notOk(opt.headers['PayPal-Partner-Attribution-Id'], 'Attribution header is not set when referrer code is not provided');
  stubObj.restore();
  t.end();
});
