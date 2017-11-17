import {
  PaymentDevice,
} from 'retail-payment-device';
import manticore from 'manticore';
import sinon from 'sinon';
import MiuraDevice from 'miura-emv';
import { Invoice } from 'paypal-invoicing';
import TipFlow from '../../js/flows/ReaderTippingFlow';
import RetailTape from './RetailTape';

let sandbox;
let _alert;

function beforeEach(t) {
  sandbox = sinon.sandbox.create();
  _alert = manticore.alert;
  manticore.alert = () => {};
  t.end();
}

function afterEach(t) {
  sandbox.restore();
  manticore.alert = _alert;
  PaymentDevice.devices = [];
  t.end();
}

function getMiuraDevice(name) {
  const appInterface = {
    display: (opt, callback) => { callback(); },
    getSwUpdateUrl: (callback) => { callback('url'); },
  };
  const nativeInterface = {
    send: (data, cb) => { cb(); },
    connect: (cb) => { cb(); },
    isConnected: () => (true),
    disconnect: (cb) => { cb(); },
    removed: (cb) => { cb(); },
  };

  const device = new MiuraDevice(name, nativeInterface, appInterface);
  device.terminal.registerForKeyboardEventsAsync = () => {};
  device.terminal.displayAsync = sinon.stub();
  device.terminal.promptForTipEntry = sinon.stub();
  device.promptForTip = sinon.stub();
  device.promptForTip.returns(1.0); // $1.0 gratuity amount
  device.stopPollForBattery = () => {};
  PaymentDevice.discovered(device);
  device.connect();
  return device;
}

function getInvoice(total, currencyCode) {
  const invoice = new Invoice(currencyCode);
  invoice.addItem('item', 1, total, 'itemId', 'detailId');
  return invoice;
}

const test = new RetailTape()
  .addBeforeEach(beforeEach)
  .addAfterEach(afterEach)
  .build();

test('Reader Tipping Flow ', (suite) => {
  suite.test('should have happy flow', (t) => {
    t.plan(4);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');
    // happy path by emitting 'proceed' event
    device.once = (eventName, listener) => {
      device.on(eventName, listener);
      device.emit(PaymentDevice.Event.proceed);
    };

    const tippingFlow = new TipFlow(device, true, invoice, () => {
    });

    // When
    tippingFlow.start().then(() => {
      // Then
      t.equal(device.terminal.displayAsync.callCount, 2, 'there are 2 calls to displayAsync during tipping flow');
      const opt = device.terminal.displayAsync.getCall(0).args[0];
      t.equal(PaymentDevice.Message.RequestTip, opt, 'RequestTip is the first call');
      const opt2 = device.terminal.displayAsync.getCall(1).args[0];
      t.equal(PaymentDevice.Message.ConfirmTip, opt2, 'ConfirmTip is the first call');
      t.equal(invoice.total.toNumber(), 2.0, '$2.0 total with $1.0 item and $1.0 gratuity amount');
      t.end();
    }, (error) => {
      // Then
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });

  /** TODO add test case for onCompleteTip event emit
   * The event is emitted in beginTippingOnReader as a callback
   * for the tipFlow
   */

  suite.test('should call abortTipping on device after selecting \'no tip\' on the alert', (t) => {
    t.plan(2);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');

    manticore.alert = sinon.stub();
    manticore.alert.yields(null, 0);
    const tippingFlow = new TipFlow(device, true, invoice, () => {
    });
    const deviceSpy = sinon.spy(device, 'abortTipping');
    const abortSpy = sinon.stub(tippingFlow, '_abort');

    // When
    tippingFlow.start().then(() => {
      t.ok(deviceSpy.called, 'abortTipping called on device');
      t.ok(abortSpy.called, '_abort of the tippingFlow called');
      t.end();
    });
  });

  suite.test('should go to tipping even with invalid amount', (t) => {
    t.plan(4);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(0.1, 'USD');
    // should emit 'proceed' event
    device.once = (eventName, listener) => {
      device.on(eventName, listener);
      device.emit(PaymentDevice.Event.proceed);
    };
    const tippingFlow = new TipFlow(device, true, invoice, () => {
    });

    // When
    tippingFlow.start().then(() => {
      // Then
      t.equal(device.terminal.displayAsync.callCount, 2, 'there are 2 calls to displayAsync during tipping flow');
      const opt = device.terminal.displayAsync.getCall(0).args[0];
      t.equal(PaymentDevice.Message.RequestTip, opt, 'RequestTip is the first call');
      const opt2 = device.terminal.displayAsync.getCall(1).args[0];
      t.equal(PaymentDevice.Message.ConfirmTip, opt2, 'ConfirmTip is the first call');
      t.equal(invoice.total.toNumber(), 1.1, '$1.1 total with $0.1 item and $1.0 gratuity amount');
      t.end();
    }, (error) => {
      // Then
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });

  suite.test('should have failed flow', (t) => {
    t.plan(1);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');
    // NOT happy path by emitting 'proceed' event
    device.once = (eventName, listener) => {
      device.on(eventName, listener);
      device.emit(PaymentDevice.Event.cancelRequested);
    };
    const tippingFlow = new TipFlow(device, true, invoice, () => {});

    // When
    tippingFlow.start().then(() => {
      // Then
      t.equal(invoice.gratuityAmount.toNumber(), 0.0, 'with cancel requested, $0 gratuity amount is applied');
      t.end();
    }, (error) => {
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });

  suite.test('should handle when request for tip throws error', (t) => {
    t.plan(1);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');
    const expectedError = new Error('Issue with request for tip');
    device.requestForTip = sinon.stub();
    device.requestForTip.throws(expectedError);
    const tippingFlow = new TipFlow(device, true, invoice, () => {});
    const abort = sinon.stub(tippingFlow, '_abort');

    // When
    tippingFlow.start().then(() => {
      // Then
      t.ok(abort.calledWith(expectedError), 'abort called with the expected error');
      t.end();
    }, (error) => {
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });

  suite.test('should handle when prompt for tip throws error', (t) => {
    t.plan(1);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');
    const expectedError = new Error('Issue with prompt for tip');
    device.promptForTip = sinon.stub();
    device.promptForTip.throws(expectedError);
    device.once = (eventName, listener) => {
      device.on(eventName, listener);
      device.emit(PaymentDevice.Event.proceed);
    };
    const tippingFlow = new TipFlow(device, true, invoice, () => {});

    // When
    tippingFlow.start().then(() => {
      // Then
      t.equal(invoice.gratuityAmount.toNumber(), 0.0, 'with cancel requested, $0 gratuity amount is applied');
      t.end();
    }, (error) => {
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });

  suite.test('should handle when confirm for tip throws error', (t) => {
    t.plan(1);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');
    const expectedError = new Error('Issue with prompt for tip');
    device.confirmTip = sinon.stub();
    device.confirmTip.throws(expectedError);
    device.once = (eventName, listener) => {
      device.on(eventName, listener);
      device.emit(PaymentDevice.Event.proceed);
    };
    const tippingFlow = new TipFlow(device, true, invoice, () => {
    });
    const abort = sinon.stub(tippingFlow, '_abort');

    // When
    tippingFlow.start().then(() => {
      // Then
      t.ok(abort.calledWith(expectedError), 'abort called with the expected error');
      t.end();
    }, (error) => {
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });

  suite.test('should handle when percentage based tipping used', (t) => {
    t.plan(1);
    // Given
    const device = getMiuraDevice('miura');
    const invoice = getInvoice(1.0, 'USD');
    device.promptForTip = sinon.stub();
    device.promptForTip.returns(50); // 10% tip
    device.once = (eventName, listener) => {
      device.on(eventName, listener);
      device.emit(PaymentDevice.Event.proceed);
    };
    const amountBased = false; // percentage based
    const tippingFlow = new TipFlow(device, amountBased, invoice, () => {});

    // When
    tippingFlow.start().then(() => {
      // Then
      t.equal(invoice.total.toNumber(), 1.5, '$1.10 total with $1.0 item and %50 gratuity ');
      t.end();
    }, (error) => {
      t.notOk(error, 'the tipping flow should be handling all failure cases. It should not throw error');
      t.end();
    });
  });
});
