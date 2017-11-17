/* eslint-disable global-require */
import NetworkResponse from './common/NetworkHandler/NetworkResponse';

if (!global._babelPolyfill) {
  require('core-js/es6/symbol');
  require('core-js/es6/set');
  require('core-js/fn/string/includes');
  require('core-js/fn/object/is');
  require('core-js/fn/array/of');
  require('core-js/fn/array/from');
  require('core-js/fn/array/find');
  require('core-js/fn/array/find-index');
  require('core-js/fn/symbol/iterator');
}

const Log = require('manticore-log')('root');

// TODO configure logging

const SDK = require('./sdk');
const m = require('manticore');

global.Promise = require('yaku');
global.regeneratorRuntime = require('babel-regenerator-runtime');

if (!global.setTimeout) {
  global.setTimeout = function _setTimeout(fn, time) {
    return m.setTimeout(fn, time || 0);
  };
}

try {
  Log.debug('Beginning SDK initialization.');
  m.export(require('retail-payment-device'));
  m.export(require('./paymentDevice/index'));
  m.export(require('./transaction/index'));
  m.export(NetworkResponse);
  m.export(require('paypal-invoicing'));
  m.export(require('manticore-paypalerror'));
  m.export(require('./common/RetailInvoice'));
  m.ready(SDK);
  Log.debug('SDK initialization complete.');
} catch (error) {
  Log.error(`Failed to complete initialization: ${error.message}\n${error.stack}`);
}

// // Alert dialog samples
// require('./alertDialogSamples');

/* eslint-enable global-require */

