/* eslint-disable global-require */
import test from 'tape';
import {
  Card,
  PaymentDevice,
  FormFactor,
} from 'retail-payment-device';
import QuickChip from '../../js/flows/steps/QuickChipStep';
import PaymentType from '../../js/transaction/PaymentType';
import * as messageHelper from '../../js/flows/messageHelper';

const AuthCode = PaymentDevice.authCode;
const responseCode = 100;

const setup = (stub) => {
  const quickChipStep = new QuickChip(stub);
  return quickChipStep;
};

/**
 * Simulates the MTP Flow by sending sample response for MTP Server Call
 */
const qcFlow = (t, formFactor, expectedValue) => {
  const showRemoveCardForQCMessage = messageHelper.showRemoveCardForQCMessage;
  messageHelper.showRemoveCardForQCMessage = (context, data, callback) => {
    callback('TESTALERT');
  };

  // Given
  const card = new Card();
  card.reader = {
    manufacturer: 'miura',
  };
  card.formFactor = formFactor;

  let actualAuth = 0;
  // override completeTransaction to get the actual value
  card.reader.completeTransaction = (authcode, callback) => {
    actualAuth = authcode;
    callback(null, responseCode);
  };
  const txContext = {
    card,
    paymentType: PaymentType.card,
  };
  const quickChipStep = setup(txContext);
  const flow = {
    data: {},
    next: () => { },
  };

  // When
  quickChipStep.execute(flow);

  // Then
  t.equal(actualAuth, expectedValue.authCode, 'Auth Code');
  t.equal(flow.data.alert, expectedValue.alert, 'Alert Message');
  t.equal(flow.data.cardResponse, expectedValue.cardResponse, 'Response Code');
  t.end();

  messageHelper.showRemoveCardForQCMessage = showRemoveCardForQCMessage;
};

test('QC should send Z3 & show Remove Card Meesage if formfactor is chip', (t) => {
  const expectedValue = {
    authCode: AuthCode.NoNetwork,
    alert: 'TESTALERT',
    cardResponse: responseCode,
  };
  qcFlow(t, FormFactor.Chip, expectedValue);
});

test('QC should not send Z3 if formfactor is not chip', (t) => {
  const expectedValue = {
    authCode: 0,
  };
  qcFlow(t, FormFactor.ManualCardEntry, expectedValue);
});
