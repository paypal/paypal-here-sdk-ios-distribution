/* eslint-disable global-require */
import test from 'tape';
import sinon from 'sinon';
import {
  Card,
  ManuallyEnteredCard,
  MagneticCard,
  TransactionType,
  FormFactor,
} from 'retail-payment-device';
import MTP from '../../js/flows/steps/MerchantTakePaymentStep';
import { transaction as transactionError } from '../../js/common/sdkErrors';
import Merchant from '../../js/common/Merchant';
import PaymentType from '../../js/transaction/PaymentType';
import FlowStep from '../../js/flows/steps/FlowStep';
import mtpResponse from '../data/mtp_response.json';

const location = {
  latitude: 37.123,
  longitude: -121.123,
};

const setup = (stub, skipLocationSetup) => {
  const mtp = new MTP(stub);
  if (!skipLocationSetup) {
    const manticore = require('manticore');
    manticore.getLocation = (cb) => {
      cb(null, location);
    };
  }
  return mtp;
};

test('MTP builds as expected', (t) => {
  // Given
  const mtp = setup(sinon.stub());

  // Then
  t.ok(mtp, 'MTP builds as expected');
  t.ok(mtp instanceof FlowStep, 'MTP is a FlowStep');
  t.end();
});

test('MTP throws error for key-in payments where card is not of type ManuallyEnteredCard', (t) => {
  // Given
  const card = new Card();
  const flow = {
    abort: sinon.stub(),
  };
  const mtp = setup({ card, paymentType: PaymentType.keyIn });

  // When
  mtp.execute(flow);
  t.ok(flow.abort.calledOnce, 'Flow was aborted');
  t.ok(flow.abort.calledWith(transactionError.cardTypeMismatch), 'Flow was aborted with expected error');
  t.end();
});

test('MTP throws error for key-in payments where card is not of type ManuallyEnteredCard', (t) => {
  // Given
  const card = new Card();
  const flow = {
    abort: sinon.stub(),
  };
  const mtp = setup({ card, paymentType: PaymentType.keyIn });

  // When
  mtp.execute(flow);
  t.ok(flow.abort.calledOnce, 'Flow was aborted');
  t.ok(flow.abort.calledWith(transactionError.cardTypeMismatch), 'Flow was aborted with expected error');
  t.end();
});

test('MTP should prioritize here api errors over others', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card: {},
    invoice,
  };
  const mtp = setup(txContext);
  const mtpRz = {
    errorCode: '580031',
    message: 'Please try another card',
    developerMessage: 'This credit card cannot be processed by PayPal',
    correlationId: '5c5956eff415c',
  };

  // When
  Merchant.active.request.yieldsAsync(new Error('HTTP Error'), {
    body: mtpRz,
  });
  const flow = {
    data: {},
    nextOrAbort: (actualError) => {
      // Then
      t.equal(actualError.code, mtpRz.errorCode, 'Flow aborted with here-api error code');
      t.equal(actualError.message, mtpRz.message, 'Flow aborted with here-api error message');
      t.equal(actualError.debugId, mtpRz.correlationId, 'Flow aborted with here-api correlation Id');
      t.end();
    },
  };

  // When
  mtp.execute(flow);
});

test('MTP builds key-in request as expected', (t) => {
  // Given
  const card = new ManuallyEnteredCard();
  card.setExpiration('022017');
  card.setCardNumber('1234567890');
  card.setCVV('555');

  Merchant.active = {
    request: sinon.stub(),
  };
  const invoice = {
    paypalId: 'paypal-id',
  };
  const txContext = {
    card,
    paymentType: PaymentType.keyIn,
    invoice,
    type: TransactionType.SALE,
  };
  const mtp = setup(txContext);

  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  const actualBody = JSON.parse(actualRequest.body);
  t.equal(actualRequest.format, 'json', 'Request format matches');
  t.equal(actualRequest.method, 'POST', 'Request method matches');
  t.equal(actualBody.paymentType, PaymentType.card, 'Request paymentType matches');
  t.deepEqual(actualBody.card, {
    inputType: PaymentType.keyIn,
    accountNumber: card.getCardNumber(),
    cvv: card.getCVV(),
    expirationMonth: '02',
    expirationYear: '2017',
  }, 'Request card json matches');
  t.notOk(actualBody.paymentAction, 'Payment Action should not be set to authorization');

  Merchant.active = null;
  t.end();
});

test('MTP should handle empty expiration string', (t) => {
  // Given
  const card = new ManuallyEnteredCard();
  card.setCardNumber('1234567890');
  card.setCVV('555');

  Merchant.active = {
    request: sinon.stub(),
    status: {
      cardSettings: {
        authExpiryPeriodPos: '2592000',
        authHonorPeriodPos: '259200',
      },
    },
  };
  const invoice = {
    paypalId: 'paypal-id',
  };
  const txContext = {
    card,
    paymentType: PaymentType.keyIn,
    invoice,
    type: TransactionType.Auth,
  };
  const mtp = setup(txContext);
  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualBody = JSON.parse(Merchant.active.request.getCall(0).args[0].body);
  t.deepEqual(actualBody.card, {
    inputType: PaymentType.keyIn,
    accountNumber: card.getCardNumber(),
    cvv: card.getCVV(),
    expirationMonth: '',
    expirationYear: '',
  }, 'Request card json matches');
  t.equal(actualBody.paymentAction, 'authorization', 'Authorization was set in the request');
  t.equal(actualBody.auth_expiry_period, '2592000', 'auth_expiry_period was set in the request');
  t.equal(actualBody.auth_honor_period, '259200', 'auth_honor_period was set in the request');

  Merchant.active = null;
  t.end();
});

test('MTP should fetch the lat and long information', (t) => {
  // Given
  const card = new ManuallyEnteredCard();
  card.setExpiration('022017');
  card.setCardNumber('1234567890');
  card.setCVV('555');

  Merchant.active = {
    request: sinon.stub(),
  };
  const invoice = {
    paypalId: 'paypal-id',
  };
  const txContext = {
    card,
    paymentType: PaymentType.keyIn,
    invoice,
  };
  const mtp = setup(txContext);

  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  const actualBody = JSON.parse(actualRequest.body);
  t.ok(actualBody.latitude, location.latitude);
  t.ok(actualBody.longitude, location.longitude);

  Merchant.active = null;
  t.end();
});

test('MTP should set the lat and long to 0 & 0', (t) => {
  // Given
  const card = new ManuallyEnteredCard();
  card.setExpiration('022017');
  card.setCardNumber('1234567890');
  card.setCVV('555');

  Merchant.active = {
    request: sinon.stub(),
  };
  const invoice = {
    paypalId: 'paypal-id',
  };
  const txContext = {
    card,
    paymentType: PaymentType.keyIn,
    invoice,
  };
  const mtp = setup(txContext, true);

  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  const actualBody = JSON.parse(actualRequest.body);
  t.ok(actualBody.latitude, 0);
  t.ok(actualBody.longitude, 0);

  Merchant.active = null;
  t.end();
});

test('MTP should include fallback swipe in vendor field for Miura devices', (t) => {
  // Given
  const card = new MagneticCard();
  card.track1 = 'track1';
  card.track2 = 'track2';
  card.track3 = 'track3';
  card.ksn = 'key-serial-number';
  card.isMSRFallbackAllowed = true;
  card.reader = {
    manufacturer: 'miura',
  };

  Merchant.active = { request: sinon.stub() };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card,
    paymentType: PaymentType.card,
    invoice,
  };
  const mtp = setup(txContext);
  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  const actualBody = JSON.parse(actualRequest.body);
  t.equal(actualBody.card.reader.vendor, 'MIURA_FB_SWIPE', 'Vendor information matches');
  t.equal(actualBody.card.reader.keySerialNumber, card.ksn, 'KSN Matches');
  t.equal(actualBody.card.inputType, 'swipe', 'Input type matches');
  t.equal(actualBody.card.track1, card.track1, 'Track-1 information matches');
  t.equal(actualBody.card.track2, card.track2, 'Track-2 information matches');
  t.equal(actualBody.card.track3, card.track3, 'Track-3 information matches');
  t.equal(actualBody.card.signatureRequired, false, 'Signature information matches');

  Merchant.active = null;
  t.end();
});

test('MTP should include swipe information in vendor field for Miura devices', (t) => {
  // Given
  const card = new MagneticCard();
  card.track1 = 'track1';
  card.track2 = 'track2';
  card.track3 = 'track3';
  card.ksn = 'key-serial-number';
  card.isMSRFallbackAllowed = false;
  card.reader = {
    manufacturer: 'miura',
  };

  Merchant.active = { request: sinon.stub() };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card,
    paymentType: PaymentType.card,
    invoice,
  };
  const mtp = setup(txContext);
  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  const actualBody = JSON.parse(actualRequest.body);
  t.equal(actualBody.card.reader.vendor, 'MIURA', 'Vendor information matches');
  t.equal(actualBody.card.reader.keySerialNumber, card.ksn, 'KSN Matches');
  t.equal(actualBody.card.inputType, 'swipe', 'Input type matches');
  t.equal(actualBody.card.track1, card.track1, 'Track-1 information matches');
  t.equal(actualBody.card.track2, card.track2, 'Track-2 information matches');
  t.equal(actualBody.card.track3, card.track3, 'Track-3 information matches');
  t.equal(actualBody.card.signatureRequired, false, 'Signature information matches');

  Merchant.active = null;
  t.end();
});

test('MTP should include fallback swipe in inputType field for non-Miura devices', (t) => {
  // Given
  const card = new MagneticCard();
  card.track1 = 'track1';
  card.track2 = 'track2';
  card.track3 = 'track3';
  card.ksn = 'key-serial-number';
  card.isMSRFallbackAllowed = true;
  card.reader = {
    manufacturer: 'ingenico',
  };

  Merchant.active = { request: sinon.stub() };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card,
    paymentType: PaymentType.card,
    invoice,
  };
  const mtp = setup(txContext);
  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualRequest = Merchant.active.request.getCall(0).args[0];
  const actualBody = JSON.parse(actualRequest.body);
  t.equal(actualBody.card.reader.vendor, 'INGENICO', 'Vendor information matches');
  t.equal(actualBody.card.reader.keySerialNumber, card.ksn, 'KSN Matches');
  t.equal(actualBody.card.inputType, 'fallback_swipe', 'Input type matches');
  t.equal(actualBody.card.track1, card.track1, 'Track-1 information matches');
  t.equal(actualBody.card.track2, card.track2, 'Track-2 information matches');
  t.equal(actualBody.card.track3, card.track3, 'Track-3 information matches');
  t.equal(actualBody.card.signatureRequired, false, 'Signature information matches');

  Merchant.active = null;
  t.end();
});

test('MTP should prioritize here api warning errors over others', (t) => {
  // Given
  Merchant.active = { request: sinon.stub() };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card: {},
    invoice,
  };
  const mtp = setup(txContext);
  const mtpRz = {
    warnings: [{
      errorCode: '580031',
      message: 'Please try another card',
      developerMessage: 'This credit card cannot be processed by PayPal',
    }],
    errorCode: '580032',
    correlationId: '5c5956eff415c',
  };

  // When
  Merchant.active.request.yieldsAsync(new Error('HTTP Error'), {
    body: mtpRz,
  });
  const flow = {
    data: {},
    nextOrAbort: (actualError) => {
      // Then
      t.equal(actualError.code, mtpRz.warnings[0].errorCode, 'Flow aborted with here-api error code');
      t.equal(actualError.message, mtpRz.warnings[0].message, 'Flow aborted with here-api error message');
      t.equal(actualError.debugId, mtpRz.correlationId, 'Flow aborted with here-api correlation Id');
      t.end();
    },
  };

  // When
  mtp.execute(flow);
});

test('MTP should set payment action field for auth', (t) => {
  // Given
  Merchant.active = {
    request: sinon.stub(),
    status: {
      cardSettings: {
        authExpiryPeriodPos: '2592000',
        authHonorPeriodPos: '259200',
      },
    },
  };
  const invoice = {
    paypalId: 'paypal-id',
  };
  const txContext = {
    type: TransactionType.Auth,
    invoice,
  };
  const mtp = setup(txContext);
  const data = {};

  // When
  mtp.execute({ data });

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  const actualBody = JSON.parse(Merchant.active.request.getCall(0).args[0].body);
  t.equal(actualBody.paymentAction, 'authorization', 'Authorization was set in the request');
  t.equal(actualBody.auth_expiry_period, '2592000', 'auth_expiry_period was set in the request');
  t.equal(actualBody.auth_honor_period, '259200', 'auth_honor_period was set in the request');

  Merchant.active = null;
  t.end();
});

/**
 * Simulates the MTP Flow by sending sample response for MTP Server Call
 */
const mtpFlow = (t, qcEnabled, mtpAuthCode, expectedAuthCode, assertMessage) => {
  // Given
  const card = new Card();
  card.reader = {
    manufacturer: 'miura',
  };
  card.formFactor = FormFactor.Chip;
  card.emvData = {
    apdu: {
      data: 'Test EMV Data',
    },
  };

  let actualAuth = 0;
  // override completeTransaction to get the actual value
  card.reader.completeTransaction = (authcode, callback) => {
    actualAuth = authcode;
    callback(null, 100);
  };
  mtpResponse.body.authCode = mtpAuthCode;
  Merchant.active = { request: (requestData, callback) => {
    Merchant.active.request.calledOnce = !Merchant.active.request.calledOnce;
    callback(undefined, mtpResponse);
  },
  };
  const invoice = { paypalId: 'paypal-id' };
  const txContext = {
    card,
    paymentType: PaymentType.card,
    invoice,
    paymentOptions: {
      quickChipEnabled: qcEnabled,
    },
  };
  const mtp = setup(txContext);
  const flow = {
    data: {},
    nextOrAbort: () => {},
  };

  // When
  mtp.execute(flow);

  // Then
  t.ok(Merchant.active.request.calledOnce, 'MTP request was made');
  t.equal(actualAuth, expectedAuthCode, assertMessage);

  Merchant.active = null;
  t.end();
};

test('MTP should not send Auth Code to Reader if Quick Chip Is Enabled', (t) => {
  mtpFlow(t, true, 'AUTH1234', 0, 'Auth Code Not Sent To Terminal');
});

test('MTP should send Auth Code to Reader if Quick Chip Is Disabled', (t) => {
  mtpFlow(t, false, 'AUTH1234', 'AUTH1234', 'Auth Code Sent To Terminal');
});
