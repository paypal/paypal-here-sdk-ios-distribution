import log from 'manticore-log';
import { PaymentDevice } from 'retail-payment-device';
import DeviceSelector from '../paymentDevice/DeviceSelector';

const Log = log('DeviceManager');

/**
 * DeviceManager is responsible for exposing APIs regarding the devices.
 * Currently, you can use DeviceManager to prompt the List to select the device
 * or set/get the active device.
 * @class
 */
class DeviceManager {
  /**
   * Construct a new DeviceManger
   * @private
   */
  constructor() { // eslint-disable-line no-useless-constructor
  }

  /**
  * Show the Dialog UI to show the list of connected card-readers
  * if there is more than 1 devices. Select one of them to use it*
  * for transaction.
  */
  promptDevicesToSelect() {
    DeviceSelector.promptDevicesToSelect();
  }
  /**
   * Sets the active reader
   * @param {PaymentDevice} pd The device that is to be set to Active
   */
  setActiveReader(pd) {
    if (pd) {
      DeviceSelector.selectDevice(pd.id);
    } else {
      Log.warn('The payment device cannot be null');
    }
  }

  /**
   * checks if any Miura devive is connected
   * @returns {bool} Returns the bool if any miura device connected
   */
  isConnectedToMiura() {
    return DeviceSelector.isConnectedToMiura();
  }

  /**
   * Returns the selected device
   * @returns {PaymentDevice} Returns the payment device that is selected
   */
  getActiveReader() {
    if (DeviceSelector.selectedDevice === null) {
      return new PaymentDevice('null');
    }
    return DeviceSelector.selectedDevice;
  }

  /**
   * Get a list of paired/discovered devices
   * @returns {[PaymentDevice]} Devices list
   */
  getDiscoveredDevices() {
    return PaymentDevice.devices;
  }
}

// const deviceManager = new DeviceManager();
// export default deviceManager;
const deviceManager = module.exports = new DeviceManager();  // eslint-disable-line no-unused-vars

