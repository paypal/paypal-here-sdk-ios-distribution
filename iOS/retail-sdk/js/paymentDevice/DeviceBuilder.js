import log from 'manticore-log';
import MiuraDevice from 'miura-emv';
import manticore from 'manticore';
import {
  PaymentDevice,
  deviceManufacturer,
} from 'retail-payment-device';
import Merchant from '../common/Merchant';
import l10n from '../common/l10n';
import RoamSwiperDevice from './RoamSwiperDevice';

const Log = log('sdk.deviceBuilder');

function getHost(env) {
  let host;
  if (env === 'live') {
    host = 'api.paypal.com';
  } else if (env === 'sandbox') {
    host = 'api.sandbox.paypal.com';
  } else {
    host = `api.${env}.stage.paypal.com:12326`;
  }
  return host;
}

function generateSwUpdateUrl(env) {
  return `https://${getHost(env)}/v2/retail/validate-config`;
}

function generateRKIUrl(env) {
  return `https://${getHost(env)}/v2/retail/secure-terminal-configs`;
}

function getRemoteKeys(rqBody, deviceVendor, deviceModel, callback) {
  const url = generateRKIUrl(Merchant.active.environment);
  const body = rqBody || {};
  body.vendor = deviceVendor.toLowerCase();
  body.model = deviceModel.toLowerCase();
  Log.debug(() => `Firmware update - Checking for RKI info from ${url}\n${JSON.stringify(body, null, 4)}`);
  Merchant.active.request({
    url,
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    format: 'json',
  }, (err, rz) => {
    Log.debug('Received response for RKI update request');
    if (err) {
      Log.error(`Error response to firmware update request ${url}. Error: ${err}\n${JSON.stringify(rz)}`);
    } else {
      Log.debug(() => `Received firmware update response ${JSON.stringify(rz, null, 4)}`);
    }
    callback(err, rz);
  });
}

function checkForUpdates(rqBody, deviceVendor, deviceModel, callback) {
  const url = generateSwUpdateUrl(Merchant.active.environment);
  const body = rqBody || {};
  body.country_code = Merchant.active.country.toLowerCase();
  body.vendor = deviceVendor.toLowerCase();
  body.model = deviceModel.toLowerCase();
  body.environment = Merchant.active.repository;
  body.client_type = 'app';
  Log.debug(() => `Checking for firmware updates from ${url}\n${JSON.stringify(body)}`);
  Merchant.active.request({
    url,
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    format: 'json',
  }, (err, rz) => {
    Log.debug('Received response for firmware update request');
    if (err) {
      Log.error(`Error response to firmware update request ${url}. Error: ${err}\n${JSON.stringify(rz)}`);
    } else {
      Log.debug(() => `Received firmware update response ${JSON.stringify(rz)}`);
    }
    callback(err, rz);
  });
}

function displayParse(val) {
  if (!val) {
    return null;
  }
  return val.id ? l10n(val.id, val.substitutions) : l10n(val);
}

/**
 * This class is intended to be used by the Native layers to create an
 * instance of payment device as soon as one is discovered
 */
export default class DeviceBuilder {
  build(manufacturer, id, isUsb, native) {
    Log.info(`build: Building device with manufacturer: ${manufacturer}, id: ${id}, isUsb: ${isUsb}. Current devices: ${PaymentDevice.devices.length}`);
    for (const existingDevice of PaymentDevice.devices) {
      if (existingDevice.equals(id, manufacturer)) {
        Log.info(`build: Found matching device ${existingDevice}. Will re-use it`);
        existingDevice.native = native;
        return existingDevice;
      }
    }
    Log.debug(() => `Device with id ${id}, manufacturer: ${manufacturer} not found in cache... Will provision one`);
    if (manufacturer.toUpperCase() === deviceManufacturer.miura) {
      return new MiuraDevice(id, native, {
        display: this.display,
        getFirmwareUpdates: this.getFirmwareUpdates,
        getRemoteCardReaderKeys: this.getRemoteCardReaderKeys,
        getMerchant: this.getMerchant,
      }, isUsb);
    } else if (manufacturer.toUpperCase() === deviceManufacturer.roam) {
      return new RoamSwiperDevice(id, native, {
        display: this.display,
        getMerchant: this.getMerchant,
      }, isUsb);
    }

    // TODO Perhaps make PaymentDevice.discovered private and invoke it here instead of doing it on native side?
    return null;
  }

  getRemoteCardReaderKeys(rqBody, deviceVendor, deviceModel, callback) {
    Log.debug(() => `Received card reader remote keys request for '${deviceVendor}-${deviceModel}'`);
    if (Merchant.active) {
      getRemoteKeys(rqBody, deviceVendor, deviceModel, callback);
      return;
    }
    Merchant.events.once('initialized', (e) => {
      if (e) {
        Log.warn(`Will not check for RKI for ${deviceModel} as merchant initialize failed with error: ${e}`);
        callback(e);
        return;
      }
      getRemoteKeys(rqBody, deviceVendor, deviceModel, callback);
    });
  }

  getFirmwareUpdates(rqBody, deviceVendor, deviceModel, callback) {
    Log.debug(() => `Received firmware update check request for '${deviceVendor}-${deviceModel}'`);
    if (Merchant.active) {
      checkForUpdates(rqBody, deviceVendor, deviceModel, callback);
      return;
    }
    Merchant.events.once('initialized', (e) => {
      if (e) {
        Log.warn(`Will not check for SW Update for ${deviceModel} as merchant initialize failed with error: ${e}`);
        callback(e);
        return;
      }
      Log.error('Merchant initialized! Will check for updates');
      checkForUpdates(rqBody, deviceVendor, deviceModel, callback);
    });
  }

  getMerchant() {
    return Merchant.active;
  }

  display(args, callback) {
    Log.debug(() => `Card reader wants to display an alert on App: ${JSON.stringify(args)}`);
    const alertOptions = {
      title: displayParse(args.title),
      message: displayParse(args.message),
      cancel: displayParse(args.cancel),
      showActivity: args.showActivity,
      audio: args.audio,
      replace: args.replace,
      setCancellable: args.setCancellable,
    };

    if (args.buttons) {
      alertOptions.buttons = [];
      for (const button of args.buttons) {
        alertOptions.buttons.push(displayParse(button));
      }
    }

    let cb = callback;
    if (!cb) {
      cb = function () {}; // eslint-disable-line func-names
    }
    return manticore.alert(alertOptions, cb);
  }
}
