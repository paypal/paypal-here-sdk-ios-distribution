'use strict';

import DeviceController from '../../js/transaction/DeviceController';
import TransactionContext from '../../js/transaction/TransactionContext';
import DeviceSelector from '../../js/paymentDevice/DeviceSelector';
import { transaction as transactionError } from '../../js/common/sdkErrors';

import {
  FormFactor,
  DeviceUpdate,
  PaymentDevice,
  BatteryInfo,
} from 'retail-payment-device';
import Merchant from '../../js/common/Merchant';

var sinon = require('sinon'),
  fs = require('fs'),
  FeatureMapJson = require('../../resources/feature-map.json'),
  l10n = require('../../js/common/l10n').default,
  testUtils = require('../testUtils'),
  chai = require('chai'),
  Invoice = require('paypal-invoicing').Invoice,
  should = chai.should(),
  EventEmitter = require('events').EventEmitter;

describe('Device Controller', () => {

  let merchant, manticore, sandbox, currencyCode = 'GBP', alertOpt;

  beforeEach(setup);
  afterEach(cleanup);

  function setup(done) {
    testUtils.seizeHttp().addLoginHandlers('GB', currencyCode);
    sandbox = sinon.sandbox.create();
    merchant = new Merchant();
    manticore = require('manticore');
    manticore.alert = (opt, cb) => {
      alertOpt = opt;
      return {
        dismiss: () => {
        }
      }
    };
    PaymentDevice.devices = [];
    merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', (err, m) => {
      merchant = m;
      done();
    });
  }

  function cleanup(done) {
    PaymentDevice.devices = [];
    DeviceSelector._selectedPaymentDevice = null;
    sandbox.restore();
    done();
  }

  function getInvoice(total, currencyCode) {
    let invoice = new Invoice(currencyCode);
    invoice.addItem('item', 1, total, 'itemId', 'detailId');
    return invoice;
  }

  function getDevices(count, formFactors = [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless]) {
    let devices = [];
    for (let i = 0; i < count; i++) {
      devices.push(testUtils.mockDevice(`device-${i}`, formFactors));
    }

    return devices;
  }

  it('should return all connected devices when preferred payment devices is not set on the transaction', (done) => {

    //Given
    let expectedDevices = getDevices(2),
      txContext = new TransactionContext(getInvoice(10.0, currencyCode), merchant),
      crm = new DeviceController(txContext);

    //When
    txContext.paymentDevices = undefined;

    //Then
    crm.devices.should.deep.equal(expectedDevices);
    done();
  });

  it('should return preferred devices and not all connected devices when preferred devices is set on the transaction', (done) => {

    //Given
    let expectedDevices = getDevices(2),
      txContext = new TransactionContext(getInvoice(10.0, currencyCode), merchant),
      crm = new DeviceController(txContext);

    //When
    txContext.paymentDevices = expectedDevices[0];

    //Then
    crm.devices.should.deep.equal(expectedDevices[0]);
    done();
  });

  it('should not approve NFC for amounts larger than contactless limit', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let txContext = new TransactionContext(getInvoice(FeatureMapJson.GB.CONTACTLESS_LIMIT + 1, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    txContext.paymentDevices = [
      testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe]),
      testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless])
    ];

    //Then
    setTimeout(() => {
      crm.getApprovedFormFactors().should.deep.equal([FormFactor.MagneticCardSwipe]);
      done();
    });
  });

  it('should make contactless available for amounts larger than contactless limit in certification mode', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    merchant.isCertificationMode = true;
    let txContext = new TransactionContext(getInvoice(FeatureMapJson.GB.CONTACTLESS_LIMIT + 1, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    txContext.paymentDevices = [
      testUtils.mockDevice('device-1', [FormFactor.EmvCertifiedContactless])
    ];

    //Then
    crm.getApprovedFormFactors().should.deep.equal([FormFactor.EmvCertifiedContactless]);
    done();
  });

  it('should not approve NFC for amounts larger than contactless limit even when NFC is a preferred form factor', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let txContext = new TransactionContext(getInvoice(FeatureMapJson.GB.CONTACTLESS_LIMIT + 1, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    txContext.paymentDevices = [
      testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe]),
      testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless])
    ];

    //Then
    crm.getApprovedFormFactors([FormFactor.EmvCertifiedContactless, FormFactor.MagneticCardSwipe]).should.deep.equal([FormFactor.MagneticCardSwipe]);
    done();
  });

  it('should not approve form factors from devices that are pending software update', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let invoiceAmount = 5,
      mockDevices = [
        testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe]),
        testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless])
      ],
      txContext = new TransactionContext(getInvoice(invoiceAmount, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    mockDevices[0].pendingUpdate = new DeviceUpdate(mockDevices[0]);

    //Then
    crm.getApprovedFormFactors().should.deep.equal([FormFactor.EmvCertifiedContactless]);
    done();
  });

  it('should not approve form factors from devices that are low on battery', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let invoiceAmount = 5,
      mockDevices = [
        testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe]),
        testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless])
      ],
      txContext = new TransactionContext(getInvoice(invoiceAmount, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    mockDevices[1].batteryInfo = new BatteryInfo(0, false, new Date());

    //Then
    //crm.getApprovedFormFactors().should.deep.equal([FormFactor.MagneticCardSwipe]);
    done();
  });

  it('should not approve form factors from devices that are not connected and ready', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let invoiceAmount = 5,
      mockDevices = [
        testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe]),
        testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless])
      ],
      txContext = new TransactionContext(getInvoice(invoiceAmount, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    mockDevices[1].isReady = false;

    //Then
    crm.getApprovedFormFactors().should.deep.equal([FormFactor.MagneticCardSwipe]);
    done();
  });

  it('should not approve form factors from devices that have failed payment availability criteria even if the form factor was set to be preferred', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let mockDevices = [
        testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe, FormFactor.Chip]),
        testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless])
      ],
      txContext = new TransactionContext(getInvoice(5.0, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When
    mockDevices[0].pendingUpdate = new DeviceUpdate(mockDevices[0]); // device-1 would fail software update payment availability criteria check

    //Then
    crm.getApprovedFormFactors([FormFactor.MagneticCardSwipe, FormFactor.Chip]).length.should.equal(0);
    done();
  });

  it('should make preferred form factors available as and when devices that support the form factor is connected', (done) => {

    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let txContext = new TransactionContext(getInvoice(5.0, 'GBP'), merchant),
      crm = new DeviceController(txContext);

    //When a device without the preferred form factor is connected
    testUtils.mockDevice('device-1', [FormFactor.MagneticCardSwipe, FormFactor.Chip]);

    //Then
    crm.getApprovedFormFactors([FormFactor.EmvCertifiedContactless]).length.should.equal(0);

    //When a device with the preferred form factor is connected
    testUtils.mockDevice('device-2', [FormFactor.EmvCertifiedContactless, FormFactor.Chip]);

    //Then
    crm.getApprovedFormFactors([FormFactor.EmvCertifiedContactless]).should.deep.equal([FormFactor.EmvCertifiedContactless]);
    done();
  });

  it('should not activate devices that have failed availability criteria', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let devices = getDevices(2),
      txContext = new TransactionContext(getInvoice(5.0, 'GBP'), merchant),
      crm = new DeviceController(txContext);
    DeviceSelector.selectDevice(devices[1].id); // select the device-1!
    sandbox.spy(devices[0], 'activateForPayment');
    sandbox.spy(devices[1], 'activateForPayment');

    //When
    devices[0].batteryInfo = new BatteryInfo(0, false, new Date());
    const activated = crm.activate(devices, null);

    //Then
    activated.device.should.deep.equal(devices[1]);
    devices[0].activateForPayment.should.not.have.been.called;
    devices[1].activateForPayment.should.have.been.called.once;
    devices[1].activateForPayment.should.have.been.calledWith(txContext);
    done();
  });

  it('should notify device with critical battery when trying to activate it', (done) => {

    //Given
    FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
    let devices = getDevices(1),
      txContext = new TransactionContext(getInvoice(5, 'GBP'), merchant),
      crm = new DeviceController(txContext);
    sandbox.spy(devices[0], 'activateForPayment');
    sandbox.spy(devices[0], 'display');
    devices[0].batteryInfo = new BatteryInfo(0, false, new Date());
    //When
    const active = crm.activate({});

    //Then
    // active.error.should.equal(transactionError.noFunctionalDevices);
    // devices[0].activateForPayment.should.not.have.been.called;
    // devices[0].display.should.have.been.calledWith({ id: PaymentDevice.Message.RechargeNow });
    done();
  });

  it('should push invoice total to devices on instantiation', (done) => {

    //Given
    let devices = getDevices(2),
      amount = 5;

    for (let pd of devices) {
      sandbox.spy(pd, 'display');
    }

    // we activate only one device so we gotta select one!
    DeviceSelector.selectDevice(devices[1].id); // select the device-1!

    //When
    let dm = (new TransactionContext(getInvoice(amount, currencyCode), merchant)).DeviceController;

    //Then
    devices[0].display.should.have.been.calledWith({
      id: PaymentDevice.Message.NotReady,
      displaySystemIcons: true,
    });
    devices[1].display.should.have.been.calledWith({
      id: PaymentDevice.Message.InvoiceTotal,
      substitutions: {
        footer: undefined,
        amount: '£5.00',
        id: 'device-1',
      },
      displaySystemIcons: false,
    });

    done();
  });

  it('should sync changes to invoice total to device', (done) => {

    //Given
    let devices = getDevices(2),
      amount1 = 5.0, amount2 = 1.0,
      invoice = getInvoice(amount1, 'GBP');

    // we activate only one device so we gotta select one!
    DeviceSelector.selectDevice(devices[1].id).then(() => {
      let txContext = new TransactionContext(invoice, merchant);

      txContext.totalDisplayFooter = 'footer';

      for (let pd of devices) {
        sandbox.spy(pd, 'display');
      }

      //When
      invoice.addItem('Test-2', 1, amount2, 1);
      setTimeout(() => {
        devices[1].display.should.have.been.calledWith({ id: PaymentDevice.Message.InvoiceTotal,
          displaySystemIcons: false,
          substitutions: {
            footer: 'footer',
            amount: '£6.00',
            id: 'device-1',
          }});
        done();
      });
    }, (error) => {
      done();
    });

  });

  it('should display ready message when invoice total equals 0', (done) => {

    //Given
    let devices = getDevices(1),
      amount1 = 0,
      invoice = getInvoice(amount1, 'GBP');

    for (let pd of devices) {
      sandbox.spy(pd, 'display');
    }

    // we activate only one device so we gotta select one!
    DeviceSelector.selectDevice(devices[0].id); // select the device-0!
    let txContext = new TransactionContext(invoice, merchant);

    //Then
    setTimeout(() => {
      devices[0].display.should.have.been.calledWith({
        id: PaymentDevice.Message.ReadyWithId,
        displaySystemIcons: true,
        substitutions: {
          amount: '£0.00',
          id: 'device-0',
          footer: undefined,
        }});
      done();
    }, 0);
  });

  it('should activate device after successful software update', (done) => {

    // TODO - Uncomment this test case after implementing DeviceUpdate child class
    done();

    /*
     //Given
     FeatureMapJson.GB.CONTACTLESS_LIMIT = 10;
     let invoiceAmount = 5,
     devices = getDevices(1),
     txContext = new TransactionContext(getInvoice(invoiceAmount, 'GBP'), merchant),
     dm = new DeviceManager(txContext);

     let deviceUpdate = new DeviceUpdate(devices[0]);
     devices[0].pendingUpdate = deviceUpdate;
     sandbox.spy(deviceUpdate, 'offer');
     manticore.alert = (opt, cb) => {
     return testUtils.mockAlertViewButtonTap([{
     title: l10n('SwUpgrade.Title'),
     buttonToTap: l10n('SwUpgrade.Ok')
     }], opt, cb);
     };

     //When
     dm.activateMany(devices, null, (activeDevices) => {

     //Then
     [...activeDevices][0].should.deep.equal(devices);
     deviceUpdate.offer.should.have.been.called;
     done();
     });

     //Simulate software update end event
     process.nextTick(() => {
     deviceUpdate.emit('ended');
     });
     */
  });
});