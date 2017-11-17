import log from 'manticore-log';
import { PayPalREST } from 'paypalrest-manticore';
import { Invoice, InvoiceAddress } from 'paypal-invoicing';
import { Tracker, pages } from 'retail-page-tracker';
import { EventEmitter } from 'events';
import async from 'async';
import {
  merchant as merchantError,
} from './sdkErrors';
import SdkFeature from './Features';

const Log = log('merchant');
const BN = require('bignumber.js');

const $$ = a => ((a === undefined || a === null) ? null : new BN(a));

function simpleUrl(host, service, op) {
  if (service === 'retail') {
    return `https://${host}.paypal.com/v1/retail/${op}`;
  } else if (service === 'auth') {
    return `https://${host}.paypal.com/v1/identity/openidconnect/${op}`;
  } else if (service === 'payments') {
    return `https://${host}.paypal.com/v1/payments/${op}`;
  }
  return null;
}

function resolver(api, options) {
  const env = api.env;
  const service = options.service;
  const op = options.op;
  if (!env || env === 'live') {
    return simpleUrl('api', service, op);
  } else if (env.indexOf('stage2') === 0) {
    if (service === 'retail') {
      return `https://www.${env}.stage.paypal.com:12326/v1/retail/${op}`;
    } else if (service === 'auth') {
      return `https://www.${env}.stage.paypal.com/webapps/auth/protocol/openidconnect/v1/${op}`;
    } else if (service === 'payments') {
      return `https://api.${env}.stage.paypal.com:12326/v1/payments/${op}`;
    }
  } else if (env === 'sandbox') {
    return simpleUrl('api.sandbox', service, op);
  }
  return null;
}
/**
 * The merchant represents the account that all calls to the PayPal services will affect. Essentially this is
 * where all collected money will go, which account locations and checkin operations will occur under, etc.
 * @class
 * @property {string} emailAddress The email address of the merchant. @readonly
 * @property {string} businessName The name of the business operated by the merchant. @readonly
 * @property {string} currency The "home" currency of the merchant. @readonly
 * @property {InvoiceAddress} address The business address of the merchant @readonly
 * @property {string} environment The PayPal environment this merchant exists in - live or sandbox. Sandbox means the money is not real!
 * @property {decimal} signatureRequiredAbove The invoice total amount above which signature would be collected for swipe transactions.
 * @property {bool} isCertificationMode Run in certification mode.
 * @property {string} referrerCode The Partner Attribution Id code that is used for analytics
 * PLEASE NOTE: manipulating this setting (especially upwards) may cause you to be liable for chargebacks in the event we cannot retrieve
 * a signature for the transaction. MODIFY THIS SETTING AT YOUR OWN RISK!
 */
export default class Merchant extends EventEmitter {
  /**
   * Only JS will make Merchants.
   * @private
   */
  constructor(data) {
    super();
    this.api = null;
    this.userInfo = {};
    this.status = {};
    this.cbs = [];
    this.environment = 'live';

    if (data) {
      this._validateAndSetCompositeToken(data);
      this._buildObjectWithData(data);
    }
  }

  initialize(token, repository, callback) {
    this._setToken(token, repository);
    this._fetchMerchantInfo(callback);
    return true;
  }

  _validateAndSetCompositeToken(data) {
    if (data && data.compositeToken && data.compositeToken.length > 0 && data.repository) {
      this._setToken(data.compositeToken, data.repository);
      return;
    }
    throw merchantError.invalidToken;
  }

  _makeInvoiceResolver(api) {
    const env = api.env;
    return (service, opts) => {
      opts.headers = opts.headers || {};
      opts.headers['X-PAYPAL-REQUEST-SOURCE'] = 'MPA-DEVICE';
      if (this.referrerCode) {
        opts.headers['PayPal-Partner-Attribution-Id'] = this.referrerCode;
      }
      if (env === 'live') {
        return `https://api.paypal.com/v1/invoicing/${opts.op}`;
      } else if (env === 'sandbox') {
        return `https://api.sandbox.paypal.com/v1/invoicing/${opts.op}`;
      }
      return `https://api.${env}.stage.paypal.com:12326/v1/invoicing/${opts.op}`;
    };
  }


  _setToken(token, repository) {
    require('paypal-invoicing').InvoicingRequester.api = this.api = PayPalREST.fromToken(token); // eslint-disable-line global-require
    this.environment = this.api.env;
    this.repository = repository;
    this.api.addResolver('retail', resolver);
    this.api.addResolver('auth', resolver);
    this.api.addResolver('invoicing', this._makeInvoiceResolver(this.api));
    this.api.addResolver('payments', resolver);

    // This is a "non-server SDK" generally, so warn if they have app info
    if (this.api.app) {
      Log.warn('Using debug-only SDK token with embedded app secret. DO NOT USE IN LIVE APPS.');
    }
    Log.debug(() => `Set environment: '${this.environment}' repository: '${this.repository}' at: '${this.api.at}'`);
  }

  _fetchMerchantInfo(callback) {
    async.parallel([
      this._loadMerchantUserInfo.bind(this),
      this._loadMerchantStatus.bind(this),
    ], (err) => {
      this._merchantInitialized(err, callback);
    });
  }

  _loadMerchantUserInfo(cb) {
    Log.debug('Loading merchant user info...');
    this.api.request({
      service: 'auth',
      op: 'userinfo?schema=openid',
      format: 'json',
    }, (err, userInfo) => {
      if (err && err.code === 400 && !this._retriedUserInfo) {
        // Bug PPPLPAYPT-2414 still not fixed...
        this._retriedUserInfo = true;
        this.api.refresh((refreshError) => {
          if (refreshError) {
            cb(refreshError, this);
            return;
          }
          this._loadMerchantUserInfo(cb);
        });
        return;
      }
      // Shouldn't really be possible to come through here again, but just for correctness...
      delete this._retriedUserInfo;
      this.userInfo = userInfo ? userInfo.body : null;
      if (err) {
        cb(err, this);
        return;
      }
      if (!this.userInfo) {
        Log.error('Failed to load merchant information. Empty response.');
        cb(merchantError.failedToLoad, null);
        return;
      }

      if (!this._validateUserInfo(this.userInfo)) {
        Log.error('Failed to load required merchant information like address, country code, email or name. '
          + 'May be the scope used to generate token was not right?');
        cb(merchantError.requiredInfoNotLoaded, null);
        return;
      }

      Invoice.DefaultMerchant = {
        emailAddress: this.emailAddress,
        businessName: this.businessName,
        address: this.address,
      };

      Log.info('Successfully loaded merchant user info!');
      Log.debug(() => `Merchant Info: \n${JSON.stringify(userInfo.body, null, 4)}`);
      Log.debug(() => `DefaultMerchant : \n${JSON.stringify(Invoice.DefaultMerchant, null, 4)}`);
      cb(err, this);
    });
  }

  // TODO userInfo sometimes returns non-200 status
  // TODO Move on to Here Api status calls.
  _loadMerchantStatus(cb) {
    Log.debug('Loading merchant status...');
    this.api.request({
      service: 'retail',
      op: 'status',
      format: 'json',
    }, (err, hereApiStatus) => {
      if (err) {
        cb(err, this);
        return;
      }

      const status = hereApiStatus.body;
      if (!this._validateStatus(status)) {
        Log.error('Failed to load required merchant status information like currency code, status, payment types.');
        cb(merchantError.requiredInfoNotLoaded, null);
        return;
      }
      this.status = status;
      Invoice.DefaultCurrency = this.currency;
      Log.debug(() => `Successfully loaded merchant status ${JSON.stringify(status, null, 4)}`);
      cb(err, this);
    });
  }

  _validateUserInfo(userInfo) {
    return (userInfo
    && userInfo.address
    && userInfo.address.country
    && userInfo.email
    && userInfo.name);
  }

  _validateStatus(status) {
    return (status
    && status.status
    && status.currencyCode
    && status.businessCategoryExists
    && status.paymentTypes);
  }

  _buildObjectWithData(merchantData) {
    Log.debug('Building the merchant object');
    if (!merchantData) {
      throw merchantError.merchantDataNotProvided;
    }
    if (!this._validateUserInfo(merchantData.userInfo)) {
      throw merchantError.merchantUserInfoNotProvided;
    }
    if (!this._validateStatus(merchantData.status)) {
      throw merchantError.merchantStatusNotProvided;
    }

    this.userInfo = merchantData.userInfo;
    this.status = merchantData.status;

    Invoice.DefaultMerchant = {
      emailAddress: this.emailAddress,
      businessName: this.businessName,
      address: this.address,
    };
    Invoice.DefaultCurrency = this.currency;
    Log.debug(() => `Successfully created Default merchant : \n${JSON.stringify(Invoice.DefaultMerchant, null, 4)}`);

    this._merchantInitialized();
  }

  _merchantInitialized(err, callback) {
    if (err) {
      Log.error(`Merchant initialize failed: ${err}`);
    } else {
      Merchant.active = this;
    }
    Merchant.events.emit('initialized', err);
    if (callback) {
      callback(err, this);
    }
  }

  request(options, callback) {
    return this.api.request(options, callback);
  }

  get signatureRequiredAbove() {
    return $$(this._signatureRequiredAbove) || $$(this.cardSettings.signatureRequiredAbove) || $$(0);
  }

  set signatureRequiredAbove(value) {
    this._signatureRequiredAbove = value;
  }

  get featureMap() {
    return SdkFeature.map[this.country];
  }

  get emailAddress() {
    return this.userInfo ? this.userInfo.email : null;
  }

  get businessName() {
    return this.userInfo ? (this.userInfo.businessName || this.userInfo.name) : null;
  }

  get currency() {
    return this.status.currencyCode;
  }

  get country() {
    return this.address.country;
  }

  get cardSettings() {
    const cardSettings = this.status.cardSettings;
    if (typeof cardSettings === 'string' || cardSettings instanceof String) {
      const cardSettingsJson = JSON.parse(cardSettings);
      return cardSettingsJson;
    }
    return cardSettings;
  }

  get address() {
    if (this._address) {
      return this._address;
    }
    let u = this.userInfo;
    const a = this._address = new InvoiceAddress();
    if (u && u.address) {
      u = u.address;
      a.country = u.country;
      a.postalCode = u.postal_code;
      a.city = u.locality;
      a.line1 = u.street_address;
      a.state = u.region;
    }
    return a;
  }

  /**
   * Forward a receipt for an invoice.
   * @param {Invoice} invoice The invoice object for which the receipt is supposed
   * @param {string} emailOrSms Either send a receipt as an email or as an sms to a phone number
   * @param {string} txNumber The transactionNumber or the handle
   * @param {string} customerId The customer identification number if any
   * @param {string} receiptPreferenceToken The receipt preference token if any
   * @param {string} txType The status of the invoice
   * @param {Merchant~receiptForwarded} callback Error callback if any or null
   */
  forwardReceipt(invoice, emailOrSms, txNumber, txType, customerId, receiptPreferenceToken, callback) {
    Log.debug(() => 'Inside Forward Receipt');
    const rq = {
      invoiceId: invoice.payPalId,
      transactionType: txType,
    };
    if (emailOrSms.indexOf('@') > 0) {
      rq.email = emailOrSms;
      Tracker.publishPageView(null, pages.paymentReceiptEmail);
    } else {
      rq.phoneNumber = emailOrSms;
      Tracker.publishPageView(null, pages.paymentReceiptSms);
    }
    rq.customerId = customerId;
    rq.receiptPreferenceToken = receiptPreferenceToken;

    let op;
    if (txNumber) {
      op = `checkouts/${txNumber}/sendReceipt`;
    } else {
      op = 'checkouts/sendReceipt';
    }
    Log.debug(() => `SendReceipt op: ${op}\n${JSON.stringify(rq)}`);
    Merchant.active.request({
      service: 'retail',
      op,
      format: 'json',
      method: 'POST',
      debug: true,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rq),
    }, callback);
  }
}

/**
 * After an attempt has been made to send your receipt to the PayPal servers,
 * the completion handler will be called with the error (if any, or null if not)
 * @callback Merchant~receiptForwarded
 * @param {PayPalError} error The error that occurred, if any
 */
Merchant.events = new EventEmitter();
