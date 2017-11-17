/* eslint-disable global-require */
import test from 'tape';
import sinon from 'sinon';
import {
  ManuallyEnteredCard,
} from 'retail-payment-device';
import MFT from '../../js/flows/steps/FinalizePaymentStep';
import FlowStep from '../../js/flows/steps/FlowStep';
import Merchant from '../../js/common/Merchant';
import PaymentType from '../../js/transaction/PaymentType';

const location = {
  latitude: 37.123,
  longitude: -121.123,
};

const setup = (stub, skipLocationSetup) => {
  const mtp = new MFT(stub);
  if (!skipLocationSetup) {
    const manticore = require('manticore');
    manticore.getLocation = (cb) => {
      cb(null, location);
    };
  }
  return mtp;
};

test('MFT builds as expected', (t) => {
  // Given
  const context = { card: {} };
  const mft = setup(context);

  // Then
  t.ok(mft, 'MTP builds as expected');
  t.ok(mft instanceof FlowStep, 'MTP is a FlowStep');
  t.end();
});

test('MFT should prioritize here api errors over others', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card: {},
    invoice,
  };
  const mft = setup(txContext);
  const mftResponse = {
    errorCode: '580031',
    message: 'Please try another card',
    developerMessage: 'This credit card cannot be processed by PayPal',
    correlationId: '5c5956eff415c',
  };

  Merchant.active.request.yieldsAsync(new Error('HTTP Error'), {
    body: mftResponse,
  });
  const flow = {
    data: {
      signature: 'signatureText',
      tx: {
        transactionHandle: 'transactionHandle',
      },
    },
    abortFlow: (actualError) => {
      // Then
      t.equal(actualError.code, mftResponse.errorCode, 'Flow aborted with here-api error code');
      t.equal(actualError.message, mftResponse.message, 'Flow aborted with here-api error message');
      t.equal(actualError.debugId, mftResponse.correlationId, 'Flow aborted with here-api correlation Id');
      t.end();
    },
  };

  // When
  mft.execute(flow);
  Merchant.active = null;
});

test('MFT builds request with handle as expected', (t) => {
  // Given
  Merchant.active = {
    request: sinon.stub(),
  };
  const card = new ManuallyEnteredCard();
  const txContext = {
    card,
    paymentType: PaymentType.keyIn,
    invoice: {
      paypalId: 'invoiceId',
    },
  };
  const flowData = {
    signature: 'SignatureBlob',
    tx: {
      transactionHandle: 'transactionHandle',
    },
  };
  const mft = setup(txContext);

  // When
  mft.execute({ data: flowData });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MFT request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  t.equal(actualRequest.format, 'json', 'Request format matches');
  t.equal(actualRequest.method, 'PUT', 'Request method matches');
  t.equal(actualRequest.op, 'checkouts/transactionHandle', 'Request URI matches');
  t.equal(actualRequest.body, '{"signature":"SignatureBlob"}', 'Request body matches');

  Merchant.active = null;
  t.end();
});
