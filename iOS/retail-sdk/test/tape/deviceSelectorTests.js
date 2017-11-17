/* eslint-disable no-unused-vars */

import {
  PaymentDevice,
} from 'retail-payment-device';
import manticore from 'manticore';
import sinon from 'sinon';
import MiuraDevice from 'miura-emv';
import RoamSwiper from '../../js/paymentDevice/RoamSwiperDevice';
import RetailTape from './RetailTape';
import DeviceSelector from '../../js/paymentDevice/DeviceSelector';

let sandbox;
let _alert;
let eventEmitterSpy;

function beforeEach(t) {
  PaymentDevice.devices = [];
  this.selectedPaymentDevice = null;
  sandbox = sinon.sandbox.create();
  eventEmitterSpy = sandbox.spy(PaymentDevice.Events, 'emit');
  _alert = manticore.alert;
  manticore.alert = () => {};
  t.end();
}

function afterEach(t) {
  sandbox.restore();
  eventEmitterSpy.reset();
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
  sinon.stub(device, 'startPollForBattery');
  PaymentDevice.discovered(device);
  device.connect();
  return device;
}

function getRoamDevice(name) {
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

  const device = new RoamSwiper(name, nativeInterface, appInterface);
  sinon.stub(device, 'startPollForBattery');
  PaymentDevice.discovered(device);
  device.connect();
  return device;
}

function mockAlertViewButtonTap(windowActions, args, cb) {
  const alertViewHandle = {
    setTitle: () => {},
    dismiss: () => {},
  };

  if (windowActions === undefined || !Array.isArray(windowActions)) {
    return alertViewHandle;
  }

  // Mock end user alert window interactions
  const buttonIds = args.buttonsIds ? args.buttonsIds.slice() : [];

  for (const action of windowActions) {
    if (action.title === args.title) {
      buttonIds.forEach((buttonId, i) => {
        if (action.buttonIdToTap === buttonId) {
          manticore.setTimeout(() => {
            cb(alertViewHandle, i);
          });
          return alertViewHandle;
        }
        return null;
      });
    }
  }

  return alertViewHandle;
}

const test = new RetailTape()
  .addBeforeEach(beforeEach)
  .addAfterEach(afterEach)
  .build();

test('Device Selector ', (suite) => {
  suite.test('should select the first discovered device if it is roam device', (t) => {
    const roamDevice = getRoamDevice('roam');
    t.equal(DeviceSelector.selectedDevice, roamDevice);
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, roamDevice), 'Device selected event was emitted');
    roamDevice.removed();
    t.end();
  });

  suite.test('should select the first discovered device if it is miura device', (t) => {
    const miuraDevice = getMiuraDevice('miura');
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, miuraDevice), 'Device selected event was emitted');
    t.equal(DeviceSelector.selectedDevice, miuraDevice);
    miuraDevice.removed();
    t.end();
  });

  suite.test('should select the first discovered device among many', (t) => {
    const roamDevice = getRoamDevice('roam');
    const miuraDevice = getMiuraDevice('miura');
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, roamDevice), 'roam-device was selected');
    t.notOk(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, miuraDevice), 'Device selection event for miura was not emitted');
    t.equal(DeviceSelector.selectedDevice, roamDevice);
    t.notEqual(DeviceSelector.selectedDevice, miuraDevice);

    eventEmitterSpy.reset();
    roamDevice.removed();
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, miuraDevice), 'Device selection event for miura was emitted after ROAM device is removed');

    miuraDevice.removed();
    t.end();
  });

  suite.test('should select the only device when the selected one is removed', (t) => {
    // Given
    const roamDevice = getRoamDevice('roam');
    const miuraDevice = getMiuraDevice('miura');

    // When
    eventEmitterSpy.reset();
    roamDevice.removed();

    // Then
    t.equal(DeviceSelector.selectedDevice, miuraDevice);
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, miuraDevice), 'Device selection event for miura was emitted after ROAM device is removed');

    // When
    miuraDevice.removed();

    // Then
    t.equal(DeviceSelector.selectedDevice, null);
    roamDevice.removed();
    miuraDevice.removed();
    t.end();
  });

  suite.test('should select the device', (t) => {
    // Given
    const roamDevice = getRoamDevice('roam');
    const miuraDevice = getMiuraDevice('miura');
    eventEmitterSpy.reset();

    // When
    DeviceSelector.selectDevice(roamDevice.id);

    // Then
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, roamDevice), 'roam-device was selected');
    t.equal(DeviceSelector.selectedDevice, roamDevice);
    eventEmitterSpy.reset();

    // When
    DeviceSelector.selectDevice(miuraDevice.id);

    // Then
    t.equal(DeviceSelector.selectedDevice, miuraDevice);
    t.ok(eventEmitterSpy.calledWith(PaymentDevice.Event.selected, miuraDevice), 'miura-device was selected');

    roamDevice.removed();
    miuraDevice.removed();

    t.end();
  });

  suite.test('should let user select the device when more than one device discovered ', (t) => {
    // Given
    manticore.alert = (opt, cb) => (mockAlertViewButtonTap([{
      title: 'Select a device',
      buttonIdToTap: 'miura-1',
    }], opt, cb));

    // When
    const roamDevice = getRoamDevice('roam');
    const miuraDevice1 = getMiuraDevice('miura-1');
    const miuraDevice2 = getMiuraDevice('miura-2');
    const miuraDevice3 = getMiuraDevice('miura-3');

    // Then
    manticore.setTimeout(() => {
      t.equal(DeviceSelector.selectedDevice, miuraDevice1);
      t.end();
    });
  });

  suite.test('should select the same device', (t) => {
        // Given
    const roamDevice = getRoamDevice('roam');
    const deviceSpy = sinon.spy(roamDevice, 'emit');

      // When
    DeviceSelector.selectDevice(roamDevice.id);

        // Then
    t.equal(DeviceSelector.selectedDevice, roamDevice);
    t.ok(deviceSpy.called, 'Selected device event emitted');

        // When
    DeviceSelector.selectDevice(roamDevice.id);

        // Then
    t.equal(DeviceSelector.selectedDevice, roamDevice);
    t.ok(deviceSpy.calledTwice, 'Selected device event emitted');

    roamDevice.removed();

    t.end();
  });
});

/* eslint-enable no-unused-vars */
