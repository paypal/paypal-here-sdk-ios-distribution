/* global chrome,window,manticore */

// Do this absolutely-first. It sets up the global manticore object before
// any other module goes looking for it.
require('manticore-browser'); // eslint-disable global-require
require('./chromeNative.js'); // eslint-disable global-require

class PayPalRetailSDK {

  static initializeSDK() {
    const wins = chrome.app.window.getAll();
    if (wins && wins.length > 0) {
      // Set the window for alerts and dialogs. Otherwise the SDK
      // user needs to set them themselves.
      manticore.mainWindow = wins[0];
    }

    require('../../../js/index'); // eslint-disable-line global-require
  }

  static ready(_sdk) {
    // We're basically hijacking the raw SDK object into our static.
    // There's probably a better way than these __proto__ shenanigans.
    /* jshint proto: true */
    window.PayPalRetailSDK.__proto__ = _sdk.__proto__; // eslint-disable-line no-proto
    for (const k in _sdk) {
      if ({}.hasOwnProperty.call(_sdk, k)) {
        window.PayPalRetailSDK[k] = _sdk[k];
      }
    }
    // Need to copy any local methods over since we transplanted the
    // prototype and properties of the true SDK
    _sdk.initializeSDK = mySdk.initializeSDK; // eslint-disable-line no-use-before-define
    _sdk.setMainWindow = mySdk.setMainWindow; // eslint-disable-line no-use-before-define
    chrome.runtime.getPlatformInfo((info) => {
      const manifest = chrome.runtime.getManifest();
      _sdk.setExecutingEnvironment('chrome', `${info.os}.${info.arch}`, `${manifest.name}.${manifest.version}`);
    });
  }

  /**
   * Set the window used for all PayPal Retail SDK overlays and dialogs.
   * If you don't set this, we'll just pick the first window in
   * chrome.app.window.getAll()
   *
   * @param window The main window used for launching all SDK UI
   */
  static setMainWindow(window) {
    manticore.mainWindow = window;
  }

}

var mySdk = PayPalRetailSDK; // eslint-disable-line no-var, vars-on-top
window.PayPalRetailSDK = PayPalRetailSDK;
