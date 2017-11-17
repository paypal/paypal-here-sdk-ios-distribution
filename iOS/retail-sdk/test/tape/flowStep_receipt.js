/* eslint-disable global-require */
import manticore from 'manticore';
import log from 'manticore-log';
import test from 'tape';
import sinon from 'sinon';
import ReceiptStep from '../../js/flows/steps/ReceiptStep';
import FlowStep from '../../js/flows/steps/FlowStep';
import {
  ReceiptDestination,
  ReceiptDestinationType,
} from '../../js/transaction/ReceiptDestination';
import Merchant from '../../js/common/Merchant';

const Log = log('flow.test.receipt');

const getEmailOrSMS = (type) => {
  const option = { name: 'emailOrSms' };
  option.value = type === ReceiptDestinationType.email ?
    'blah@blah.com' : '4084084080';
  return option;
};

const setup = (stub, type) => {
  const receipt = new ReceiptStep(stub);
  manticore.offerReceipt = (params, cb) => {
    if (type) {
      cb(null, getEmailOrSMS(type));
    } else {
      cb(null);
    }
  };
  manticore.alert = () => ({
    setTitle: () => {},
    dismiss: () => {},
  });

  return receipt;
};

const getContext = () => ({
  invoice: { paypalId: 'paypalId', total: '5.01' },
  isRefund: () => false,
});

test('Receipt step builds as expected', (t) => {
  const context = getContext();
  const receipt = setup(context);

  t.ok(receipt, 'Receipt Step was builds as expected');
  t.ok(receipt instanceof FlowStep, 'Receipt Step is an instance of Flowstep');
  t.end();
});

test('Receipt was successfully sent to an email address', (t) => {
  const context = getContext();
  const receipt = setup(context, ReceiptDestinationType.email);
  Log.debug('setup the receipt flow');
  Merchant.active = { forwardReceipt: sinon.stub() };
  Merchant.active.forwardReceipt.yields(null);
  const flow = {
    data: {
      tx: {
        transactionNumber: 'transactionNumber',
        receiptDestination: new ReceiptDestination(),
      },
    },
    next: sinon.stub(),
  };
  receipt.execute(flow);
  t.ok(flow.data.tx, 'Flow data tx should be present');
  t.ok(flow.data.tx.receiptDestination, 'Receipt Destination should be present');
  t.equals(flow.data.tx.receiptDestination.type, ReceiptDestinationType.email, 'Receipt Destination type should be email.');
  t.equals(flow.data.tx.receiptDestination.email, 'blah@blah.com', 'Receipt Destination email should match.');
  t.end();
});

test('Receipt was successfully sent to a text number', (t) => {
  const context = getContext();
  const receipt = setup(context, ReceiptDestinationType.text);
  Log.debug('setup the receipt flow');
  Merchant.active = { forwardReceipt: sinon.stub() };
  Merchant.active.forwardReceipt.yields(null);
  const flow = {
    data: {
      tx: {
        transactionNumber: 'transactionNumber',
        receiptDestination: new ReceiptDestination(),
      },
    },
    next: sinon.stub(),
  };
  receipt.execute(flow);
  t.ok(flow.data.tx, 'Flow data tx should be present');
  t.ok(flow.data.tx.receiptDestination, 'Receipt Destination should be present');
  t.equals(flow.data.tx.receiptDestination.type, ReceiptDestinationType.text, 'Receipt Destination type should be text.');
  t.notok(flow.data.tx.receiptDestination.email, 'Receipt Destination email should be empty');
  t.end();
});

test('No receipt was sent', (t) => {
  const context = getContext();
  const receipt = setup(context);
  Log.debug('setup the receipt flow');
  Merchant.active = { forwardReceipt: sinon.stub() };
  Merchant.active.forwardReceipt.yields(null);
  const flow = {
    data: {
      tx: {
        transactionNumber: 'transactionNumber',
        receiptDestination: new ReceiptDestination(),
      },
    },
    next: sinon.stub(),
  };
  receipt.execute(flow);
  t.ok(flow.data.tx, 'Flow data tx should be present');
  t.equals(flow.data.tx.receiptDestination.type, ReceiptDestinationType.none, 'Receipt Destination type should be none.');
  t.end();
});
