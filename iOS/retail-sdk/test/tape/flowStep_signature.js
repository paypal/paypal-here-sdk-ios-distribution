/* eslint-disable global-require */
import proxyquire from 'proxyquire';
import test from 'tape';
import sinon from 'sinon';
import {
  Card,
  ManuallyEnteredCard,
  TransactionType,
  FormFactor,
  PaymentDevice,
} from 'retail-payment-device';
import SignatureReceiver from '../../js/transaction/SignatureReceiver';
import PaymentType from '../../js/transaction/PaymentType';
import Signature from '../../js/flows/steps/SignatureStep';
import * as messageHelper from '../../js/flows/messageHelper';

const Message = PaymentDevice.Message;

const setup = (stub) => {
  const signature = new Signature(stub);
 // add more settings if needed
  return signature;
};

const signatureFlow = (t, qcEnabled, expectedMessageId, assertMessage) => {
  const formattedInvoiceTotal = messageHelper.formattedInvoiceTotal;
  messageHelper.formattedInvoiceTotal = () => {};

// Given
  const card = new Card();
  card.reader = {
    manufacturer: 'miura',
  };

  card.formFactor = FormFactor.Chip;
  card.isSignatureRequired = true;
  const invoice = {
    paypalId: 'paypal-id',
    currency: 'USD',
  };
  const txContext = {
    card,
    paymentType: PaymentType.card,
    invoice,
    paymentOptions: {
      quickChipEnabled: qcEnabled,
    },
    emit: () => {},
  };
  const signatureStep = setup(txContext);

  const flow = {
    data: {},
    nextOrAbort: () => {},
    once: () => {},
  };

  let actualMessageId;
  // override display to get the actual value
  card.reader.display = (message) => {
    actualMessageId = message.id;
  };
  // When
  signatureStep.execute(flow);

  // Then
  t.equal(actualMessageId, expectedMessageId, assertMessage);

  t.end();
  messageHelper.formattedInvoiceTotal = formattedInvoiceTotal;
};
test('SignatureStep should display QuickChip message if Quick Chip Is Enabled', (t) => {
  signatureFlow(t, true, Message.SignatureForInsertQCCR, 'QuickChip Displayed');
});

test('SignatureStep should display SignatureForInsert message if Quick Chip Is Disabled', (t) => {
  signatureFlow(t, false, Message.SignatureForInsert, 'SignatureForInsert displayed');
});
test('Skip signature step for auth', (t) => {
  // Given
  const card = new ManuallyEnteredCard();
  const txContext = {
    card,
    type: TransactionType.Auth,
    emit: sinon.spy(),
  };
  const flow = {
    next: sinon.spy(),
  };
  const signtureReceiverStub = sinon.createStubInstance(SignatureReceiver);
  const SignatureStep = proxyquire('../../js/flows/steps/SignatureStep', {
    '../../transaction/SignatureReceiver': { default: () => (signtureReceiverStub) },
  }).default;
  const signStep = new SignatureStep(txContext);

  // When
  signStep.execute(flow);

  // Then
  t.ok(flow.next.calledOnce, 'Next flow was callled');
  t.ok(txContext.emit.notCalled, 'Emit signature was NOT called');
  t.ok(signtureReceiverStub.acquireSignature.notCalled, 'Signature receiver was NOT called');
  t.end();
});
