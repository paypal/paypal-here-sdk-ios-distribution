import log from 'manticore-log';
import { getPropertyName } from 'manticore-util';
import { PaymentDevice, FormFactor } from 'retail-payment-device';
import { PaymentState, TippingState } from './transactionStates';
import DeviceSelector from '../paymentDevice/DeviceSelector';

const Log = log('transaction.State');

export default class TransactionStateManager {
  constructor(context) {
    this._paymentState = PaymentState.idle;
    this._tippingState = TippingState.notStarted;
    this._sActiveFormFactors = new Set();
    this._context = context;
  }

  toString() {
    return JSON.stringify(this.toJSON());
  }

  toJSON() {
    return {
      paymentState: getPropertyName(PaymentState, this.getPaymentState()),
      tippingState: getPropertyName(TippingState, this.getTippingState()),
      connectedDevices: PaymentDevice.devices.length,
      selectedDevice: DeviceSelector.selectedDevice ? DeviceSelector.selectedDevice.id : '<none>',
      activeFormFactors: getPropertyName(FormFactor, [...this.getSetOfActiveFormFactors()]),
    };
  }

  getPaymentState() {
    return this._paymentState;
  }

  setPaymentState(value) {
    this._paymentState = value;
    Log.debug(() => `Setting PAYMENT state of ${this._context.id} to ${getPropertyName(PaymentState, value)}`);
  }

  getTippingState() {
    return this._tippingState;
  }

  setTippingState(value) {
    this._tippingState = value;
    Log.debug(() => `Setting TIPPING state of ${this._context.id} to ${getPropertyName(TippingState, value)}`);
  }

  getSetOfActiveFormFactors() {
    return DeviceSelector.selectedDevice ? DeviceSelector.selectedDevice.getSetOfActiveFormFactors() : new Set();
  }

  isFormFactorActive(formFactor) {
    return DeviceSelector.selectedDevice ? DeviceSelector.selectedDevice.isFormFactorActive(formFactor) : false;
  }
}

