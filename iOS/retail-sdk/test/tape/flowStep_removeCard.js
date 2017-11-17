import test from 'tape';
import sinon from 'sinon';
import {
  Card,
  FormFactor,
  PaymentDevice,
} from 'retail-payment-device';
import proxyquire from 'proxyquire';
import { Invoice } from 'paypal-invoicing';
import FlowStep from '../../js/flows/steps/FlowStep';

function getInvoice() {
  Invoice.DefaultCurrency = 'USD';
  const invoice = new Invoice('USD');
  invoice.addItem('Test', 1, 100.0, 1);
  return invoice;
}

function getPaymentDevice(config = {}) {
  const pd = new PaymentDevice(config.id || 'id-1');
  sinon.stub(pd, 'display');
  sinon.stub(pd, 'isConnected');
  sinon.stub(pd, 'waitForCardRemoval');
  pd.display.yieldsAsync();
  pd.cardInSlot = config.cardInSlot;
  pd.isConnected.returns((config.isConnected === null || config.isConnected === undefined) ? true : config.isConnected);
  return pd;
}

let removeCardSub;
function getRemoveCardStep() {
  removeCardSub = sinon.stub();
  return proxyquire('../../js/flows/steps/RemoveCardStep', {
    '../messageHelper': {
      showRemoveCardMessage: removeCardSub,
    },
  }).default;
}

function getContext(config) {
  const card = new Card();
  card.formFactor = config.formFactor;
  card.reader = getPaymentDevice(config);
  return { card, invoice: getInvoice(), isRefund: () => (false) };
}

test('RemoveCard step builds as expected', (t) => {
  // Given
  const RemoveCardStep = getRemoveCardStep();
  const removeCardStep = new RemoveCardStep(sinon.stub());
  // Then
  t.ok(removeCardStep, 'RemoveCardStep builds as expected');
  t.ok(removeCardStep instanceof FlowStep, 'RemoveCardStep is a FlowStep');
  t.end();
});

test('RemoveCardStep prompts for card removal when chip card was inserted', (t) => {
  // Given
  const RemoveCardStep = getRemoveCardStep();
  const flow = { next: sinon.stub() };
  const context = getContext({
    formFactor: FormFactor.Chip,
  });
  const removeCard = new RemoveCardStep(context);

  // When
  removeCard.execute(flow);
  t.ok(removeCardSub.calledOnce, 'Prompt to remove card was shown');
  t.ok(context.card.reader.waitForCardRemoval.calledOnce, 'Waited for card removal');
  t.end();
});

test('RemoveCardStep should not prompt for card removal when card was not presented using Chip card form factor', (t) => {
  // Given
  const RemoveCardStep = getRemoveCardStep();
  const flow = { next: sinon.stub() };
  const removeCard = new RemoveCardStep(getContext({
    formFactor: FormFactor.MagneticCardSwipe,
  }));

  // When
  removeCard.execute(flow);

  // Then
  t.ok(!removeCardSub.called, 'Should not prompt for card removal when reader is not connected');
  t.ok(flow.next.calledOnce, 'Move on to next step');
  t.end();
});

test('RemoveCardStep should dismiss card removal prompt and complete the flow step when card was removed', (t) => {
  const RemoveCardStep = getRemoveCardStep();
  const alertStub = { dismiss: sinon.stub() };
  const flow = { next: () => {}, data: { alert: alertStub } };
  const context = getContext({
    formFactor: FormFactor.Chip,
  });
  const removeCard = new RemoveCardStep(context);
  context.card.reader.waitForCardRemoval.yieldsAsync();

  sinon.stub(flow, 'next', () => {
    // Then
    t.ok(alertStub.dismiss.calledOnce, 'Alert dialog was dismissed');
    t.end();
  });

  // When
  removeCard.execute(flow);
});
