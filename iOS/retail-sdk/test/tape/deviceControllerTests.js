import test from 'tape';
import {
  FormFactor,
  PaymentDevice,
  DeviceStatus,
  deviceError,
  deviceManufacturer,
} from 'retail-payment-device';
import sinon from 'sinon';
import { Invoice } from 'paypal-invoicing';
import DeviceSelector from '../../js/paymentDevice/DeviceSelector';
import DeviceController from '../../js/transaction/DeviceController';
import Merchant from '../../js/common/Merchant';

function getInvoice(total, currencyCode) {
  const invoice = new Invoice(currencyCode);
  invoice.addItem('item', 1, total, 'itemId', 'detailId');
  return invoice;
}

function getMiuraDevice() {
  const device = new PaymentDevice('1', { isConnected: () => (true) });
  device.isReady = true;
  device.manufacturer = deviceManufacturer.miura;
  return device;
}

function getSwiperDevice() {
  const device = new PaymentDevice('2', { isConnected: () => (true) });
  device.isReady = true;
  device.manufacturer = deviceManufacturer.roam;
  return device;
}

test('Device controller should set card inserted handler to device before activating it', (t) => {
  // Given
  const device = getMiuraDevice();

  const txContext = {
    invoice: getInvoice(1, 'USD'),
    cardInsertedHandler: () => {},
    clear: () => {},
    merchant: {
      isCertificationMode: true,
    },
  };
  const deviceController = new DeviceController(txContext);
  const merchant = txContext.merchant;
  Merchant.active = merchant;
  PaymentDevice.discovered(device);
  DeviceSelector.selectDevice('1');
  sinon.stub(device, 'activateForPayment');
  sinon.stub(device, 'isReadyForTransaction', () => ({ isReady: true }));
  sinon.stub(device, 'formFactors', { get: () => ([FormFactor.Chip]) });

  // When
  deviceController.activate({ showPrompt: false, formFactors: [FormFactor.Chip] });

  // Then
  t.ok(device.cardInsertedHandler, 'Card inserted handler is not null');
  t.equal(device.cardInsertedHandler, txContext.cardInsertedHandler, 'Card inserted listener was set on the device');
  PaymentDevice.devices = [];
  t.end();
});

test('Update Device display if device is low on battery', (t) => {
  // Given
  const device = getMiuraDevice();

  const deviceStatus = new DeviceStatus();
  deviceStatus.isReady = false;
  deviceStatus.error = deviceError.lowOnBattery;
  const txContext = {
    invoice: getInvoice(1, 'USD'),
    clear: () => {},
    merchant: {},
  };

  const deviceSpy = sinon.spy(device, 'display');

  const deviceController = new DeviceController(txContext);
  PaymentDevice.discovered(device);
  DeviceSelector.selectDevice('1');
  sinon.stub(device, 'activateForPayment');
  sinon.stub(device, 'isReadyForTransaction', () => (deviceStatus));
  sinon.stub(device, 'formFactors', { get: () => ([FormFactor.Chip]) });

  // When
  deviceController.activate({ showPrompt: false, formFactors: [FormFactor.Chip] });

  // Then
  t.ok(deviceSpy.called, 'Device display called');
  PaymentDevice.devices = [];
  t.end();
});

test('Update Device display if device needs software update', (t) => {
    // Given
  const device = getMiuraDevice();

  const deviceStatus = new DeviceStatus();
  deviceStatus.isReady = false;
  deviceStatus.error = deviceError.swUpdatePending;
  const txContext = {
    invoice: getInvoice(1, 'USD'),
    clear: () => {},
    merchant: {},
  };

  const deviceSpy = sinon.spy(device, 'display');

  const deviceController = new DeviceController(txContext);
  PaymentDevice.discovered(device);
  DeviceSelector.selectDevice('1');
  sinon.stub(device, 'activateForPayment');
  sinon.stub(device, 'isReadyForTransaction', () => (deviceStatus));
  sinon.stub(device, 'formFactors', { get: () => ([FormFactor.Chip]) });

    // When
  deviceController.activate({ showPrompt: false, formFactors: [FormFactor.Chip] });

    // Then
  t.ok(deviceSpy.called, 'Device display called');
  PaymentDevice.devices = [];
  t.end();
});

test('Should return true if merchant is from the UK', (t) => {
  const device = new PaymentDevice('1', { isConnected: () => (true) });
  device.isReady = true;
  const txContext = {
    invoice: getInvoice(1, 'GBP'),
    cardInsertedHandler: () => {},
    clear: () => {},
    merchant: {
      isCertificationMode: true,
      currency: 'GBP',
    },
  };
  const deviceController = new DeviceController(txContext);
  const merchant = txContext.merchant;
  Merchant.active = merchant;

  t.equals(deviceController._isMerchantFromUK(), true);

  t.end();
});

test('Should return false if merchant is not from the UK', (t) => {
  const device = new PaymentDevice('1', { isConnected: () => (true) });
  device.isReady = true;
  const txContext = {
    invoice: getInvoice(1, 'USD'),
    cardInsertedHandler: () => {},
    clear: () => {},
    merchant: {
      isCertificationMode: true,
      currency: 'USD',
    },
  };
  const deviceController = new DeviceController(txContext);
  const merchant = txContext.merchant;
  Merchant.active = merchant;

  t.equals(deviceController._isMerchantFromUK(), false);

  t.end();
});

test('Should return true if NFC contactless limit is reached', (t) => {
  const device = new PaymentDevice('1', { isConnected: () => (true) });
  device.isReady = true;
  const txContext = {
    invoice: getInvoice(31, 'GBP'),
    cardInsertedHandler: () => {},
    clear: () => {},
    merchant: {
      isCertificationMode: false,
      currency: 'GBP',
      featureMap: {
        CONTACTLESS_LIMIT: '30',
      },
    },
  };
  const deviceController = new DeviceController(txContext);
  const merchant = txContext.merchant;
  Merchant.active = merchant;

  t.equals(deviceController._isNFCContactlessLimitReached(), true);

  t.end();
});

test('Should return false if NFC contactless limit is not reached', (t) => {
  const device = new PaymentDevice('1', { isConnected: () => (true) });
  device.isReady = true;
  const txContext = {
    invoice: getInvoice(30, 'GBP'),
    cardInsertedHandler: () => {},
    clear: () => {},
    merchant: {
      isCertificationMode: false,
      currency: 'GBP',
      featureMap: {
        CONTACTLESS_LIMIT: '30',
      },
    },
  };
  const deviceController = new DeviceController(txContext);
  const merchant = txContext.merchant;
  Merchant.active = merchant;

  t.equals(deviceController._isNFCContactlessLimitReached(), false);

  t.end();
});

test('Should not call Contactless limit if Roam swiper is connected and active', (t) => {
  const device = getSwiperDevice();
  device.isReady = true;
  const txContext = {
    invoice: getInvoice(30, 'HK'),
    cardInsertedHandler: () => {},
    clear: () => {},
    merchant: {
      isCertificationMode: false,
      currency: 'HK',
    },
  };

  const deviceController = new DeviceController(txContext);
  const merchant = txContext.merchant;
  Merchant.active = merchant;
  const deviceNFCSpy = sinon.spy(deviceController, '_isNFCContactlessLimitReached');

  // When
  deviceController.activate({ showPrompt: false, formFactors: [FormFactor.MagneticCardSwipe] });

  // Then
  t.ok(deviceNFCSpy.notCalled, 'Device NFC limit call is not called when Roam Swiper is connected');

  t.end();
});
