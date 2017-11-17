import log from 'manticore-log';

import {
  PaymentDevice,
  FormFactor,
  deviceError,
  CardPresentEvent,
  deviceManufacturer,
} from 'retail-payment-device';
import { $$ } from 'paypal-invoicing';
import { EventEmitter } from 'events';
import { getPropertyName } from 'manticore-util';
import CardPresentedHandler from './CardPresentedHandler';
import DeviceSelector from '../paymentDevice/DeviceSelector';
import InvoiceSynchronizer from './InvoiceSynchronizer';
import { transaction as transactionError } from '../common/sdkErrors';
import Merchant from '../common/Merchant';
import { formattedInvoiceTotal } from '../flows/messageHelper';

const Log = log('transactionContext.deviceController');

/**
 * DeviceController is responsible for maintaining the state of devices used in a transaction.
 * It tracks the state of each device, form factors and and provides methods to
 * activate/deactivate the devices
 */
export default class DeviceController extends EventEmitter {
  constructor(context) {
    super();
    this.context = context;
    this.activeDevices = new Set();
    this._invoiceSynchronizer = new InvoiceSynchronizer(context, this);
    this._invoiceSynchronizer.start();
    this._cardPresentedHandlers = new CardPresentedHandler(this.context);
  }
  /**
   * List of all devices that are available for the transaction.
   * (Not all available devices will be approved for the transaction.
   * The filter criteria to determine an approved device is defined in
   * `DeviceManager.availabilityFilter` )
   */
  get devices() {
    return this.context.paymentDevices || PaymentDevice.devices;
  }

  /**
   * Returns a set of form factors approved for the current transaction
   * @param {[FormFactor]} preferredFormFactors List of form factors preferred for the given transaction
   * @returns {[FormFactor]} List of form factors approved for this transaction
   */
  getApprovedFormFactors(preferredFormFactors) {
    const availableDevices = this.devices.filter(pd => (pd.isReadyForTransaction().isReady));
    const sAvailableFormFactors =
      new Set([].concat.apply([], availableDevices.map(pd => pd.formFactors))); // eslint-disable-line prefer-spread

    if (sAvailableFormFactors.has(FormFactor.EmvCertifiedContactless)) {
      if (this._isNFCContactlessLimitReached()) {
        sAvailableFormFactors.delete(FormFactor.EmvCertifiedContactless);
      }
    }
    return preferredFormFactors && preferredFormFactors.length > 0 ?
      preferredFormFactors.filter(ff => sAvailableFormFactors.has(ff)) : [...sAvailableFormFactors];
  }

  _isNFCContactlessLimitReached() {
    const merchant = Merchant.active;
    if (merchant.featureMap) {
      const nfcLimit = merchant.isCertificationMode ? '*' : merchant.featureMap.CONTACTLESS_LIMIT;
      if (nfcLimit !== '*' && this.context.invoice.total.greaterThan($$(nfcLimit) || 0)) {
        Log.debug(() => `Cannot perform NFC. Invoice total ${this.context.invoice.total} is above contactless limit of ${(nfcLimit)}`); // eslint-disable-line max-len
        return true;
      }
      return false;
    }
    return false;
  }

  _isMerchantFromUK() {
    const merchantCurrency = Merchant.active.currency;
    return merchantCurrency === 'GBP';
  }

  _showInsertOrSwipeMessageOnDevice(selectedDevice, invTotal) {
    selectedDevice.display({
      id: PaymentDevice.Message.ReadyForInsertAndSwipePayment,
      substitutions: invTotal,
    }, () => {
      // Nothing to do yet
    });
  }

  /**
   * Gets the selected device
   */
  get selectedDevice() {
    return DeviceSelector.selectedDevice;
  }

  cardInsertDetected() {
    if (DeviceSelector.selectedDevice) {
      this._cardPresentedHandlers.handleCardPresent(null, CardPresentEvent.insertDetected, FormFactor.Chip, null,
        DeviceSelector.selectedDevice);
    }
  }

   /**
   * Activates the devices that are available for payment. The provided callback
   * will be invoked with the activated devices. The devices that failed activation
   * would be notified.
   * @param {object} opt Configuration options with following properties
    *   showPrompt    - true to show payment prompt on card reader display (if available)
   *    formFactors   - List of payment form factors that needs to be activated.
   *                    Will be defaulted to `this.formFactors`
   *    syncInvoiceTotal - true to synchronize invoice total on card reader display
   */
  activate(opt) {
    const showPrompt = opt.showPrompt;
    const formFactors = opt.formFactors;
    const syncInvoiceTotal = (opt.syncInvoiceTotal === null || opt.syncInvoiceTotal === undefined) ? true
      : opt.syncInvoiceTotal;
    const device = DeviceSelector.selectedDevice;
    Log.debug(() => `(${this.context.id}) Begin device activation for invoice total: ${this.context.invoice.total}, sync: ${syncInvoiceTotal}`);
    if (!device) {
      Log.warn(`Exiting device activation for ${this.context.id} as selected device was not set`);
      return { error: transactionError.noFunctionalDevices };
    }

    Log.debug(() => `(${this.context.id}) Continue device activation for invoice total: ${this.context.invoice.total}, sync: ${syncInvoiceTotal} on ${device.id}`);
    if (this.updateDeviceDisplayIfError(device)) {
      return { error: transactionError.noFunctionalDevices };
    }

    if (syncInvoiceTotal) {
      this._invoiceSynchronizer.start();
    } else {
      Log.debug(() => `Will not sync invoice total of ${this.context.invoice.total} on ${device.id}`);
    }
    device.stopPollForBattery(); // Will restart battery poll on tx.end();

    if (this.listenersAddedTo === device) {
      Log.debug(() => `Skip add listeners for ${this.context.id}. Listeners already added`);
    } else {
      this.removeListenerOnDevice(device);
      Log.debug(() => `Adding listeners for ${this.context.id} to ${device.id}`);
      this.listenersAddedTo = device;
      this._addListener(device, PaymentDevice.Event.cardPresented, (err, subType, ff, result) => {
        device.cardPresented = true;
        if (!err) {
          this._invoiceSynchronizer.stop();
        }
        this._cardPresentedHandlers.handleCardPresent(err, subType, ff, result, device);
      });
      this._addListener(device, PaymentDevice.Event.cancelled,
        () => this._cardPresentedHandlers.handleTxCancelled(device));
      this._addListener(device, PaymentDevice.Event.cancelRequested, () => this.context.cancel);
      this._addListener(device, PaymentDevice.Event.contactlessReaderDeactivated,
        () => this._cardPresentedHandlers.handleContactlessReaderDeactivated(device));
    }

    if (device.manufacturer.toUpperCase() === deviceManufacturer.miura) {
      if (this._isNFCContactlessLimitReached()) {
        // UK contactless limit check and show the right image on the device
        this._showInsertOrSwipeMessageOnDevice(device, formattedInvoiceTotal(this.context.invoice));
      }
    }

    const approvedFormFactors = this.getApprovedFormFactors(formFactors);
    Log.info(`Activating ${device.id} for form factors [${getPropertyName(FormFactor, approvedFormFactors)}] & showPrompt: ${showPrompt}`);
    device.cardInsertedHandler = this.context.cardInsertedHandler;
    device.activateForPayment(this.context, approvedFormFactors, showPrompt);
    this.activeDevices.add(device);
    Log.debug(() => `Device '${device.id} activated for ${approvedFormFactors} form factors'`);
    return {
      device,
      formFactors: approvedFormFactors,
    };
  }


  updateDeviceDisplayIfError(device) {
    const deviceStatus = device.isReadyForTransaction();
    if (!deviceStatus.isReady) {
      Log.warn(`Selected device ${device.id} failed availability check due to ${deviceStatus.error}`);
      if (deviceStatus.error === deviceError.lowOnBattery) {
        device.display({ id: PaymentDevice.Message.RechargeNow }, () => {});
      } else if (deviceStatus.error === deviceError.swUpdatePending) {
        device.display({ id: PaymentDevice.Message.SoftwareUpdateRequired }, () => {});
      }
      return true;
    }
    return false;
  }

  syncOnce(device) {
    this._invoiceSynchronizer.pushOnce(device, this.context.invoice.total, () => {});
  }

  abort(cb) {
    Log.debug(() => `Aborting transaction ${this.context.id}`);
    this._invoiceSynchronizer.stop();
    this.removeListeners();
    const pd = DeviceSelector.selectedDevice;
    if (!pd) {
      if (cb) {
        cb();
      }
      return;
    }

    pd.abortTransaction(this.context, () => {
      pd.display({
        id: PaymentDevice.Message.ReadyWithId,
        substitutions: { id: pd.id },
        displaySystemIcons: true,
      }, () => {
        cb(pd);
      });
    });
  }

  deactivateFormFactors(formFactors, cb) {
    if (DeviceSelector.selectedDevice) {
      DeviceSelector.selectedDevice.deactivateFormFactors(formFactors, () => {
        if (cb) {
          cb(DeviceSelector.selectedDevice);
        }
      });
    } else {
      Log.debug('Will not deactivate tx as no device selected! Will immediately invoke callback');
      if (cb) {
        cb();
      }
    }
  }

  syncInvoice() {
    this._invoiceSynchronizer.start();
  }

  stopInvoiceSync() {
    this._invoiceSynchronizer.stop();
  }

  startPollingForBattery() {
    if (DeviceSelector.selectedDevice) {
      DeviceSelector.selectedDevice.startPollForBattery();
    }
  }

  stopPollingForBattery() {
    if (DeviceSelector.selectedDevice) {
      DeviceSelector.selectedDevice.stopPollForBattery();
    }
  }

  _addListener(pd, event, listener) {
    listener.txContextId = this.context.id;
    pd.on(event, listener);
  }

  /**
   * Removes transaction context listeners on the payment device
   * @param devices
   */
  removeListeners() {
    const devices = PaymentDevice.devices;
    for (const pd of devices) {
      this.removeListenerOnDevice(pd);
    }
    this.listenersAddedTo = null;
  }

  removeListenerOnDevice(pd) {
    const events = [
      PaymentDevice.Event.cardPresented,
      PaymentDevice.Event.cancelled,
      PaymentDevice.Event.cancelRequested,
      PaymentDevice.Event.contactlessReaderDeactivated,
    ];
    for (const e of events) {
      const listenerCount = pd.listenerCount(e);
      const listeners = [];
      for (const l of pd.listeners(e)) {
        pd.removeListener(e, l);
        listeners.push(l.id);
      }
      if (listenerCount) {
        Log.debug(() => `Removed ${listenerCount} '${e}' listener(s) from ${pd.id} for ${this.context.id}. Listeners - ${listeners}`);
      }
    }
  }
}

/**
 * Enumeration indicating possible device availability filter criterias
 * @type {{BatteryStatus: number, SoftwareUpdate: number}}
 */
DeviceController.FilterCriteria = {
  Ready: 'Ready',
  BatteryStatus: 'BatteryStatus',
  SoftwareUpdate: 'SoftwareUpdate',
};
