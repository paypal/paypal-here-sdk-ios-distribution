import manticore from 'manticore';
import log from 'manticore-log';
import {
  PaymentDevice,
  deviceModel,
  deviceManufacturer,
} from 'retail-payment-device';

import l10n from '../common/l10n';
import displayController from './CardReaderDisplayController';
import displayPriority from './displayPriority';

const Log = log('DeviceSelector');

/**
 * DeviceSelector is responsible for deciding the device used in a transaction.
 * It tracks the 'deviceDiscovered' and 'deviceRemoved' events to make a decision
 * for the selected device. If more than 1 devices available, it prompts user to
 * decide it. It also provides an API 'selectDevice(id) to select the device
 * based on the id
 * Note that if any device is discovered during an active transaction, selection
 * will be postponed by the next event.
 * Note that If the selected device is removed and it has an active transaction,
 * it will postpone the selection to the next event.
 */
class DeviceSelector {
  constructor() {
    this._selectedPaymentDevice = null;
    PaymentDevice.Events.on('deviceDiscovered', pd => this.discovered(pd));
  }

  get selectedDevice() {
    return this._selectedPaymentDevice;
  }

  set selectedDevice(value) {
    throw new Error(`The readOnly selectedPaymentDevice property cannot be written. ${value} was passed.`);
  }

  _setSelectedDevice(pd) {
    Log.debug(() => `Setting selected device to '${pd && pd.id}'`);
    this._selectedPaymentDevice = pd;
    if (pd) {
      PaymentDevice.Events.emit(PaymentDevice.Event.selected, pd);
    }
  }

  discovered(pd) {
    Log.info(`a new device discovered by DeviceSelector: ${pd.id}`);
    pd.once(PaymentDevice.Event.deviceRemoved, device => this.removed(device));
    pd.on(PaymentDevice.Event.disconnected, () => this._startDeviceSelection());
    pd.on(PaymentDevice.Event.connected, () => this._startDeviceSelection());
  }

  removed(pd) {
    Log.info(`a new device removed by DeviceSelector: ${pd.id}`);
    if (pd === this._selectedPaymentDevice && pd.cardPresented) {
      // Corner case: don't bother the current transaction.
      this._setSelectedDevice(null);
      Log.debug(() => `The selected device:${pd.id} having active transaction is removed!`);
      return;
    }
    if (!this._selectedPaymentDevice || pd === this._selectedPaymentDevice || this._selectionInProgress) {
      Log.debug('a new device removed and to be select new one -->>>>');
      this._promptForDeviceSelection();
    }
  }

  isConnectedToMiura() {
    for (const device of PaymentDevice.devices) {
      if (device.manufacturer.toUpperCase() === deviceManufacturer.miura) {
        return true;
      }
    }
    return false;
  }

  promptDevicesToSelect() {
    this._promptForDeviceSelection(() => {
    });
  }

  _startDeviceSelection() {
    Log.debug(() => `_startDeviceSelection started. the current selected device: ${this._selectedPaymentDevice}`);
    if (!this._selectedPaymentDevice) { // whenever it is null, go for selection step.
      this._promptForDeviceSelection();
    } else if (!this._selectedPaymentDevice.cardPresented) {
      this._promptForDeviceSelection();
    } else {
      this._setSelectedDevice(this._selectedPaymentDevice);
      Log.info(`Will not prompt for device selection due to one of the reasons. Device already selected? '${!!this._selectedPaymentDevice}', Payment in progress? '${this._selectedPaymentDevice && this._selectedPaymentDevice.cardPresented}'`);
    }
  }

  async selectDevice(id) {
    if (!id) {
      await this._promptForDeviceSelection();
      return;
    }

    let found = false;
    for (const device of PaymentDevice.devices) {
      /*
      In case of MCR, call abort on the all other devices and update the display for each
      of them.
       */
      if (device.id === id && device.isConnected()) {
        found = true;
        this._setSelectedDevice(device);
        this._selectedPaymentDevice.emit(PaymentDevice.Event.selected, this._selectedPaymentDevice);
        Log.info(`selected device with id ==>> ${this._selectedPaymentDevice.id}`);
      } else {
        device.abortTransaction();
      }
      this._displayReadyMsg();
    }
    if (!found) {
      Log.info(`NO device is found with id ==>> ${id} or it is disconnected`);
    }
  }

  async _promptForDeviceSelection() {
    Log.debug(() => `total number of devices is  ${PaymentDevice.devices.length}`);
    if (this.alert) {
      this.alert.dismiss();
    }
    const connectedDevices = [];
    for (const device of PaymentDevice.devices) {
      if (device.isConnected()) {
        Log.debug(() => `connected device:${device.id}`);
        connectedDevices.push(device);
      }
    }
    Log.debug(() => `total number of connected devices is  ${connectedDevices.length}`);
    if (connectedDevices.length <= 0) {
      this._setSelectedDevice(null);
      Log.info('No device is selected since there is no available device');
    } else if (connectedDevices.length === 1) {
      if (this._selectedPaymentDevice !== connectedDevices[0]) {
        if (this._selectedPaymentDevice) {
          this._selectedPaymentDevice.abortTransaction();
        }
        this._setSelectedDevice(connectedDevices[0]);
        Log.info(`Selected device set to ${this._selectedPaymentDevice.id}`);
        manticore.setTimeout(() => {
          if (this._selectedPaymentDevice) {
            this._selectedPaymentDevice.emit(PaymentDevice.Event.selected);
          }
        }, 0);
        this._displayReadyMsg();
      } else {
        Log.info(`SAME device selected by default ==>> ${this._selectedPaymentDevice.id}`);
        this._setSelectedDevice(this._selectedPaymentDevice);
      }
    } else if (connectedDevices.length > 1) {
      const imgs = [];
      const ids = [];
      for (const device of connectedDevices) {
        if (device.model.toUpperCase() === deviceModel.swiper) {
          imgs.push('choose_device_dongle');
          ids.push(device.id);
        } else if (device.model.toUpperCase() === deviceModel.m010) {
          imgs.push('choose_device_black_emv');
          ids.push(device.id);
        } else {
          Log.error(`wrong device model ${device.model.toUpperCase()}. Needs to be added here!!`);
        }
      }

      if (imgs.length > 1) {
        this._selectionInProgress = true;
        this.alert = manticore.alert({
          title: l10n('MultiCard.Title'),
          message: l10n('MultiCard.Msg'),
          buttonsImages: imgs,
          buttonsIds: ids,
          mcrDialog: true,
        }, (alert, index) => {
          Log.debug(() => `index selected: ${index}`);
          if (this.alert) {
            this.alert.dismiss();
          }
          if (index >= 0 && index <= (PaymentDevice.devices.length - 1)) {
            if (this._selectedPaymentDevice !== PaymentDevice.devices[index]) {
              if (this._selectedPaymentDevice) {
                this._selectedPaymentDevice.abortTransaction();
              }
              this._setSelectedDevice(connectedDevices[index]);
              Log.info(`Multi card selected device by user ==>> ${this._selectedPaymentDevice.id}`);
              this._displayReadyMsg();
            } else {
              Log.info(`SAME device selected by user ==>> ${this._selectedPaymentDevice.id}`);
            }
            this._selectedPaymentDevice.emit(PaymentDevice.Event.selected);
          } else {
            Log.error(`wrong index selected for the card reader: ${index}`);
          }
          this._selectionInProgress = false;
        });
      }
    }
  }

  _displayReadyMsg() {
    for (const device of PaymentDevice.devices) {
      if (device.model.toUpperCase() === deviceModel.m010) {
        const displayParams = {
          id: PaymentDevice.Message.NotReady,
          displaySystemIcons: true,
        };
        if (device !== this._selectedPaymentDevice) {
          device.display(displayParams);
        } else {
          displayParams.id = PaymentDevice.Message.ReadyWithId;
          displayParams.substitutions = { id: device.id };
          displayController.display(displayPriority.low, device, displayParams);
        }
      }
    }
  }

}

const deviceSelector = new DeviceSelector();
export default deviceSelector;

