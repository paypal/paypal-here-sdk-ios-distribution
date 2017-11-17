var sinonChai = require('sinon-chai'),
  chai = require('chai');

chai.should();
chai.use(sinonChai);

require('babel-polyfill');
require('babel-register')({
    only: require('../es6FilePatterns')
});

process.env.PAYPAL_LOG_LEVEL = process.env.PAYPAL_LOG_LEVEL || 'QUIET';
require('manticore-log').Root.level = process.env.PAYPAL_LOG_LEVEL;

if (!process.env.DISABLE_NOCYCLE) {
    require('nocycle').detect(require('nocycle').printer(function (log) {
        if (!log.match(/babel-types(\/||\\)lib(\/||\\)index.js/) &&
          !log.match(/babel-traverse(\/||\\)lib(\/||\\)index.js/) &&
          !log.match(/paypal-invoicing(\/||\\)build(\/||\\)index.js/)) {
            console.error(log);
            throw new Error(log);
        }
    }));
}
