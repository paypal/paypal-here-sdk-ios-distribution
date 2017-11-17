// PLEASE NOTE! This is a bit of a funny class on the native side. It exposes top level
// events and methods (maybe properties someday too) but it is not directly exposed
// to partners. Instead, they are presented with a "singleton" type interface typically called
// PayPalRetailSDK. Then the methods/events/properties of THIS object are proxied via that singleton
// to the instance that the engine startup process makes.
// SO.... this means a few unpleasant things that were deemed ok for now:
//      1. If you change comments here, you will need to manually update PayPalRetailSDK in each platform
//      2. If you change or add events or methods here you will need to update each platform
//      3. Because of 1 and 2, ask yourself - does my event/property REALLY belong at the top level?

import log from 'manticore-log'; // eslint-disable-line no-duplicate-imports, import/no-duplicates
import RawLogs from 'manticore-log'; // eslint-disable-line no-duplicate-imports, import/no-duplicates
import { EventEmitter } from 'events';
import { PaymentDevice } from 'retail-payment-device';
import manticore from 'manticore';
import { Tracker } from 'retail-page-tracker';
import {
  merchant as merchantError,
  sdk as sdkError,
} from './common/sdkErrors';
import TransactionContext from './transaction/TransactionContext';
import Merchant from './common/Merchant';
import * as Cal from './common/cal';
import SdkFeatures from './common/Features';
import setNetworkHandler from './common/NetworkHandler/networkInterceptor';
import deviceManager from './transaction/DeviceManager';
import logLevel from './common/logLevel';
import pkg from '../package.json';
import retrieveAuthorizedTransactions from './transaction/authManager';
import voidAuthorization from './transaction/voidManager';
import captureAuthorization from './transaction/captureManager';
import cardReaderDisplay from './paymentDevice/CardReaderDisplayController';

const Log = log('sdk');

/**
 * The PayPal Here SDK object is the main entry point for all SDK operations. Because we provide
 * native-specific versions of the highest level interface, this class is essentially used
 * as a helper for binding top level events (such as a new card reader) to the native partner objects.
 * @protected
 * @class
 */
class SDK extends EventEmitter {
  constructor() {
    super();
    PaymentDevice.Events.on(SDK.Event.deviceDiscovered, d => this.emit(SDK.Event.deviceDiscovered, d));
    Tracker.events.on('pageViewed', (err, page) => this.emit(SDK.Event.pageViewed, err, page));
    SdkFeatures.loadRemoteFeatureMap();
    this.setupCalLogging();
  }

  setupCalLogging() {
    Cal.newGroup(Date.now());
    const flushLogs = () => {
      const pauseAndFlush = () => manticore.setTimeout(flushLogs, 10 * 1000);
      if (Merchant.active) {
        Cal.flush((err, count) => {
          if (count || err) {
            Log.debug(() => `Flushed ${count || 0} cal log messages. ${err ? `Error: ${err}` : ''}`);
          }
          pauseAndFlush();
        });
      } else {
        pauseAndFlush();
      }
    };

    Cal.attach(flushLogs);
  }

  buildCompositeToken(tokenObj) {
    Log.debug(() => `Received composite token ${JSON.stringify(tokenObj)}`);
    if (!tokenObj) {
      throw merchantError.tokenDataNotProvided;
    }
    if (!tokenObj.accessToken) {
      throw merchantError.accessTokenNotProvided;
    }
    if (!tokenObj.environment) {
      throw merchantError.environmentNotProvided;
    }

    tokenObj.environment = tokenObj.environment.toLowerCase();
    const appIdSecret = new Buffer(`${tokenObj.appId}:${tokenObj.appSecret}`).toString('base64');
    const tokenParts = [tokenObj.accessToken, 28880, tokenObj.refreshUrl, tokenObj.refreshToken, appIdSecret];
    return `${tokenObj.environment}:${new Buffer(JSON.stringify(tokenParts)).toString('base64')}`;
  }

  initializeMerchant(token, repository, callback) {
    new Merchant().initialize(token, repository, (e, m) => {
      if (!e && m) {
        this.emit('merchantInitialized', m);
      }
      callback(e, m);
    });
  }

  error(message) {
    return new Error(message);
  }

  setMerchant(merchantObj) {
    Log.debug(() => `Received the merchant object : ${JSON.stringify(merchantObj)}`);
    if (!merchantObj) {
      throw merchantError.merchantDataNotProvided;
    }
    merchantObj.compositeToken = this.buildCompositeToken(merchantObj.token);
    return new Merchant(merchantObj);
  }

  /**
   * Get the active merchant
   * @returns {Merchant} merchant
   */
  getMerchant() {
    return Merchant.active;
  }

  /*
   * Create a transaction context for an invoice
   * @param {Invoice} invoice
   * @returns {TransactionContext} context
   */
  createTransaction(invoice) {
    if (!Merchant.active) {
      throw merchantError.notInitialized.withDevMessage('You must have an active merchant to create a transaction.' +
        'Call InitializeMerchant first, and wait for it to complete.');
    }
    return new TransactionContext(invoice, Merchant.active);
  }

  /**
   * Log a message via the Javascript logging framework (called by native to get all the side benefits of JS logging, like CAL)
   * @param {string} level
   * @param {string} component
   * @param {string} message
   * @param {object} extraData
   */
  logViaJs(level, component, message, extraData) { // eslint-disable-line no-unused-vars
    try {
      RawLogs(component)[level](message);
    } catch (x) {
      Log.debug(`Failed to log native message: ${level} ${component} ${message}`);
    }
  }

  /**
   * Information that represents the executing platform
   * @param {string} appVersion Identification information of the executing application
   * @param {string} osInfo Operating system name and version
   * @param {string} merchantId Merchant identifier like PayerId, etc.
   */
  setExecutingEnvironment(appVersion, osInfo, merchantId) {
    this.envInfo = `${osInfo}.app-${appVersion}.sdk-${pkg.version}.m-${merchantId}`.replace(/\s+/g, '');
    Cal.setRequestSourceId(this.envInfo);
    Log.info(`Setting RetailSDK executing environment to: ${this.envInfo}`);
  }

  /*
   * Register a PaymentDevice and notify listeners of the new device.
   * @param {PaymentDevice} pd
   */
  discoveredPaymentDevice(pd) {
    PaymentDevice.discovered(pd);
  }

  /**
   * Retrieve the list of authorized transactions.
   * @param {Date} startDateTime start date time for listing the authorized transactions. Cannot be greater than endDateTime or current date-time.
   * @param {Date} endDateTime end date time for listing the authorized transactions. Defaults to startDateTime + 5 days.
   * If provided it should be less than or equal to (startDateTime + 5 days)
   * @param {int} pageSize number of authorized transactions to be returned per API call. Has to be greater than 0 and less than 31.
   * @param {[AuthStatus]} status list of status that need to be retrieved. Optional, defaults to all status.
   * @param {SDK~retrieveAuthorizedTransactions} callback
   */
  retrieveAuthorizedTransactions(startDateTime, endDateTime, pageSize, status, callback) {
    if (!Merchant.active) {
      callback(merchantError.notInitialized.withDevMessage('You must have an active merchant to capture an ' +
        'authorized transaction. Call InitializeMerchant first, and wait for it to complete.'));
      return;
    }
    retrieveAuthorizedTransactions(startDateTime, endDateTime, pageSize, status, null, callback);
  }

  /**
   * Retrieve the next list of authorized transactions using the nextPageToken.
   * @param {string} nextPageToken token to retrive the next page of objects. Cannot be null.
   * @param {SDK~retrieveAuthorizedTransactions} callback
   */
  retrieveAuthorizedTransactionsUsingNextPageToken(nextPageToken, callback) {
    if (!Merchant.active) {
      callback(merchantError.notInitialized.withDevMessage('You must have an active merchant to capture an ' +
        'authorized transaction. Call InitializeMerchant first, and wait for it to complete.'), null, null);
      return;
    }
    if (!nextPageToken || nextPageToken === '') {
      callback(sdkError.validationError.withDevMessage('nextPageToken cannot be null'), null, null);
      return;
    }
    retrieveAuthorizedTransactions(null, null, null, null, nextPageToken, callback);
  }

  /**
   * Void an authorized transaction
   * @param {string} authorizationId The authorization id of the transaction. Cannot be null.
   * @param {SDK~voidAuthorization} callback
   */
  voidAuthorization(authorizationId, callback) {
    if (!Merchant.active) {
      callback(merchantError.notInitialized.withDevMessage('You must have an active merchant to void an ' +
        'authorized transaction. Call InitializeMerchant first, and wait for it to complete.'));
      return;
    }
    voidAuthorization(authorizationId, callback);
  }

  /**
   * Capture a previously authorized transaction.
   * @param {string} authorizationId the authorizationId to be captured.
   * @param {string} invoiceId the invoice id associated with the authorization.
   * @param {decimal} totalAmount the total amount that has to be captured.
   * @param {decimal} gratuityAmount (optionl) the gratuity amount that is also part of the totalAmount. If present, should be less than total Amount.
   * @param {string} currency the currency in which authorization was placed.
   * @param {SDK~captureAuthorizedTransaction} callback
   */
  captureAuthorizedTransaction(authorizationId, invoiceId, totalAmount, gratuityAmount, currency, callback) {
    if (!Merchant.active) {
      callback(merchantError.notInitialized.withDevMessage('You must have an active merchant to capture an ' +
        'authorized transaction. Call InitializeMerchant first, and wait for it to complete.'));
      return;
    }
    captureAuthorization(authorizationId, invoiceId, totalAmount, gratuityAmount, currency, callback);
  }

  /*
   * Perform cleanup before shutting down the host application
   */
  logout() {
    try {
      Log.info(`SDK logout was invoked. Active Transaction: ${TransactionContext.active ? TransactionContext.active.id : '<none>'}. Connected devices: ${PaymentDevice.devices}`);
      cardReaderDisplay.resetAll();
      if (TransactionContext.active) {
        Log.info(`Ending ${TransactionContext.active.id} as part of user SDK logout`);
        TransactionContext.active.end(sdkError.userCancelled, null, false);
      }
      for (const pd of PaymentDevice.devices) {
        if (pd.disconnectUsb) {
          Log.debug(() => `Disconnecting USB from ${pd.id}`);
          pd.disconnectUsb(() => { });
        }
        Log.debug(() => `Removing ${pd.id}`);
        pd.removed();
      }
    } catch (x) {
      Log.error(`Error on executing log-out ${x}`);
    }
  }

  /**
   * Set the log level for SDK
   * @param {logLevel} level
   */
  setLogLevel(level) {
    let manticoreLogLevel = log.Level.DEBUG;
    if (level === logLevel.quiet) {
      manticoreLogLevel = 'QUIET';
    } else if (level === logLevel.error) {
      manticoreLogLevel = log.Level.ERROR;
    } else if (level === logLevel.warn) {
      manticoreLogLevel = log.Level.WARN;
    } else if (level === logLevel.info) {
      manticoreLogLevel = log.Level.INFO;
    } else if (level === logLevel.debug) {
      manticoreLogLevel = log.Level.DEBUG;
    }
    Log.debug(() => `Set SDK log level to ${manticoreLogLevel}`);
    require('manticore-log').Root.level = manticoreLogLevel;  // eslint-disable-line global-require
  }

  /**
   * Provide an interceptor for all HTTP calls made by the SDK
   * @param {SDK~intercept} interceptor
   */
  setNetworkInterceptor(interceptor) {
    Log.info(`Adding network interceptor ${interceptor}`);
    setNetworkHandler(interceptor);
  }

  /**
   * Returns the SDK device manager
   * @returns {DeviceManager} device manager
   */
  getDeviceManager() {
    return deviceManager;
  }
}

SDK.Event = {
  deviceDiscovered: 'deviceDiscovered',
  pageViewed: 'pageViewed',
};

/**
 * A PaymentDevice has been discovered. For further events, such as device readiness, removal or the
 * need for a software upgrade, your application should subscribe to the relevant events on the device
 * parameter. Please note that this doesn't always mean the device is present. In certain cases (e.g. Bluetooth)
 * we may know about the device independently of whether it's currently connected or available.
 * @event SDK#deviceDiscovered
 * @param {PaymentDevice} device The device that has been discovered.
 */

/**
 * A page has been viewed
 * @event SDK#pageViewed
 * @param {error} error Error reported on the page
 * @param {Page} page Page that was viewed
 */

/**
 * This callback will be invoked every time the SDK wants to do a HTTP Request, the listener could intercept this call
 * and provide
 * @callback SDK~intercept
 * @param {NetworkRequest} request HTTP Network request
 */

/**
 * The callback for retrieveAuthorizedTransactions completion
 * @callback SDK~retrieveAuthorizedTransactions
 * @param {error} error Error reported while trying to retrieve list of authorized transactions
 * @param {[AuthorizedTransaction]} listOfAuths list of authorized transactions
 * @param {string} nextPageToken token to retrieve the next page of objects. Will be null if there is no next page.
 * as a object
 */

/**
 * The callback for voidTransaction completion
 * @callback SDK~voidAuthorization
 * @param {error} error Error reported while trying to void an authorized transaction
 */

/**
 * The callback for captureAuthorizedTransaction completion
 * @callback SDK~captureAuthorizedTransaction
 * @param {error} error Error reported while trying to capture the authorized transaction
 * @param {string} captureId Id after a successful capture
 */
const sdk = module.exports = new SDK(); // eslint-disable-line no-unused-vars
