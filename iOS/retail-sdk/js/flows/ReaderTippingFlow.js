import log from 'manticore-log';
import manticore from 'manticore';
import { PaymentDevice } from 'retail-payment-device';
import BaseFlowAsync from './BaseFlowAsync';
import l10n from '../common/l10n';

const Log = log('flow.ReaderTippingFlow');

export default class ReaderTippingFlow extends BaseFlowAsync {
  constructor(device, amountBasedTip, invoice, callback) {
    Log.debug('Initializing Tipping Flow');
    super();
    this.device = device;
    this.amountBasedTip = amountBasedTip;
    this.invoice = invoice;
    this.completionCallback = callback;
  }

  async start() {
    await super.setFlowSteps('Tipping', [
      this._stopBatteryPollStep,
      this._createFlowMessageStep,
      this._requestForTip,
      this._receiveTip,
      this._confirmTip,
    ]);
    super.addFlowEndedHandler(() => this._completeTippingFlow());
    await super.startFlow();
  }

  async _stopBatteryPollStep(flow) {
    Log.debug('Stop polling for key in TippingOnReader');
    this.device.stopPollForBattery();
    await flow.next();
  }

  async _createFlowMessageStep(flow) {
    Log.debug('_createFlowMessageStep');

    try {
      const alertOpts = {
        title: l10n('EMV.Tip.Title'),
        buttons: [l10n('EMV.Tip.Buttons.NoTip')],
      };
      this.alert = manticore.alert(alertOpts, (a, ix) => {
        if (this.alert) {
          this.alert.dismiss();
        }
        Log.debug('No Tip button pushed so aborting...');
        if (ix === 0) { // No Tip button
          // clear any persisting transactions on the reader
          this.device.abortTipping()
            .then(() => Log.debug('aborted tipping on the terminal'))
            .catch((error) => { Log.warn(`could not abort tipping on terminal with error: ${error}`); });
          this.abort();
        }
      });
    } catch (err) {
      Log.warn(`Aborting the ReaderTipping flow with error : ${err} `);
      await this.abort(err);
      return;
    }
    await flow.next();
  }

  async _requestForTip(flow) {
    Log.debug('Request Tip');

    try {
      await this.device.requestForTip(this.invoice);
    } catch (err) {
      Log.warn(`Aborting the ReaderTipping requestForTip flow with error : ${err} `);
      await this.abort(err);
      return;
    }
    await this._registerKeyPressListeners(flow);
  }

  async _receiveTip(flow) {
    Log.debug('Receiving Tip');
    let tip = 0;
    try {
      tip = await this.device.promptForTip(this.amountBasedTip);
    } catch (err) {
      Log.warn(`Aborting the tipping flow receiveTip with error : ${err} & tip : ${tip}`);
      await this.abort(err);
      return;
    }
    if (!tip) {
      Log.warn(`Aborting the tipping flow receiveTip with failed tip : ${tip}`);
      await this.abort();
      return;
    }

    Log.info(`Tip received : ${tip}`);
    if (this.amountBasedTip) {
      this.invoice.gratuityAmount = tip;
    } else { // percentage based tip
      this.invoice.gratuityAmount = ((tip * this.invoice.subTotal) / 100).toFixed(2);
    }
    await flow.next();
  }

  async _confirmTip(flow) {
    Log.debug('Confirm Tip');

    try {
      flow.confirmTip = true;
      await this.device.confirmTip(this.invoice);
    } catch (err) {
      Log.warn(`Aborting the ReaderTipping confirmTip flow with error : ${err} `);
      await this.abort(err);
      return;
    }
    await this._registerKeyPressListeners(flow);
  }

  async _registerKeyPressListeners(flow) {
    this.device.once(PaymentDevice.Event.cancelRequested, () => this._proceedWithFlow(flow, true));
    this.device.once(PaymentDevice.Event.proceed, () => this._proceedWithFlow(flow, false));
  }

  async _proceedWithFlow(flow, abort) {
    Log.debug('_proceedWithFlow');
    await this._deRegisterKeyPressListeners();
    if (abort) {
      if (flow.confirmTip) {
        flow.confirmTip = false;
        Log.debug('confirmTip cancelled so going back');
        await flow.back();
      } else {
        Log.debug('Tip Cancelled');
        await this.abort();
      }
    } else {
      await flow.next();
    }
  }

  async _deRegisterKeyPressListeners() {
    await this._removeListeners();
  }

  async _removeListeners() {
    Log.debug('_removeListeners');
    const events = [
      PaymentDevice.Event.cancelRequested,
      PaymentDevice.Event.proceed,
    ];

    for (const e of events) {
      for (const l of this.device.listeners(e)) {
        this.device.removeListener(e, l);
      }
    }
  }

  async abort(err) {
    Log.debug(() => `abort with error: ${err}`);

    if (this.alert) {
      this.alert.dismiss();
      delete this.alert;
    }
    await this._clearTip();
    await this.flow.abortFlow(err);
  }

  async _clearTip() {
    Log.debug('Tip Cleared');
    this.invoice.gratuityAmount = 0;
  }

  async _completeTippingFlow() {
    Log.debug(() => `completeTippingFlow with tipAmount: ${this.invoice.gratuityAmount}`);

    if (this.alert) {
      this.alert.dismiss();
      delete this.alert;
    }

    await this._removeListeners();
    Log.debug('Start polling for battery');
    await this.device.startPollForBattery();

    this.completionCallback();
  }
}
