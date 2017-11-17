/* global PayPalRetailSDK,XMLHttpRequest,window,chrome */
/* eslint-disable func-names */

import m from 'manticore';
import ChromeAlert from './ChromeAlert';
import DM from './ChromeDeviceManager';
import ChromeReceipt from './ChromeReceipt';
import ChromeSignature from './ChromeSignature';

m.devices = new DM();
m.export = function (items) {
  if (items) {
    for (const k in items) { // eslint-disable-line guard-for-in
      PayPalRetailSDK[k] = items[k];
    }
  }
};

m.ready = function (_sdk) {
  PayPalRetailSDK.ready(_sdk);
  m.devices.start();
};

m.alert = function (options, callback) {
  if (!m.mainWindow) {
    throw new Error('mainWindow is not set on the PayPal Retail SDK.');
  }
  return ChromeAlert.create(options, m.mainWindow, callback);
};

m.collectSignature = function (options, callback) {
  if (!m.mainWindow) {
    throw new Error('mainWindow is not set on the PayPal Retail SDK.');
  }
  return ChromeSignature.create(options, m.mainWindow, callback);
};

m.offerReceipt = function (options, callback) {
  const viewContent = options.viewContent.receiptOptionsViewContent;
  m.alert({
    title: viewContent.message,
    message: `${viewContent.title}<br/>${viewContent.prompt}`,
    titleIcon: viewContent.titleIcon,
    buttons: [
      viewContent.emailButtonTitle,
      viewContent.smsButtonTitle,
      { type: 'cancel', title: viewContent.noThanksButtonTitle },
    ],
  }, (alertView, btnIndex) => {
    alertView.dismiss();
    if (btnIndex === 0) {
      options.byEmail = true;
      ChromeReceipt.show(options, m.mainWindow, callback);
    } else if (btnIndex === 1) {
      ChromeReceipt.show(options, m.mainWindow, callback);
    } else {
      callback();
    }
  });
};

/* eslint-enable func-names */

