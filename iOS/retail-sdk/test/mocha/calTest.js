/* global describe:false, it:false, before:false, after:false, beforeEach:false, afterEach:false*/

import assert from 'assert';
import testUtils from '../testUtils';
import * as retailSDKUtil from '../../js/common/retailSDKUtil';

describe('CAL logging', () => {
  let localStorage = {};
  let cal;

  beforeEach(() => {
    testUtils.makeMockery();
    const manticore = require('manticore');
    manticore.setItem = (k, t, v, cb) => {
      localStorage[t] = localStorage[t] || {};
      localStorage[t][k] = v;
      if (cb) {
        process.nextTick(cb);
      }
    };
    manticore.getItem = (k, t, cb) => {
      if (!localStorage[t]) {
        cb(null, null);
      } else {
        cb(null, localStorage[t][k]);
      }
    };
    manticore.log = () => null;
    cal = require('../../js/common/cal');
  });

  afterEach(() => {
    testUtils.endMockery();
    localStorage = {};
  });

  it('should attach to the logging infra', (done) => {
    cal.attach((e) => {
      assert(!e, `Got unexpected error on attach: ${e ? e.message : ''}`);
      done();
    });
  });

  it('should log and save to local storage', (done) => {
    cal.attach((e) => {
      assert(!e);
      require('manticore-log')('test').Config.level = 'ERROR';
      require('manticore-log')('test').error('Hello World');
      setTimeout(() => {
        assert(localStorage[retailSDKUtil.StorageType.SecureBlob],
          'Should have stored the log data.');
        assert(localStorage[retailSDKUtil.StorageType.SecureBlob].CalLogStore,
          'Should have stored the log data.');
        const blob = JSON.parse(localStorage[retailSDKUtil.StorageType.SecureBlob].CalLogStore);
        assert(1, blob.events.length, 'Should have 1 stored log message.');
        assert.equal(blob.runCounter, 1);
        assert.equal(blob.msgCounter, 1);
        done();
      }, 0);
    });
  });

  it('should not write debug message to cal', (done) => {
    cal.attach((e) => {
      assert(!e);
      require('manticore-log')('test').Config.level = 'DEBUG';
      require('manticore-log')('test').error('Hello World');
      require('manticore-log')('test').debug('Goodbye World');
      setTimeout(() => {
        const blob = JSON.parse(localStorage[retailSDKUtil.StorageType.SecureBlob].CalLogStore);
        assert.equal(1, blob.events.length, 'Should have only 1 stored log message.');
        done();
      }, 1);
    });
  });

  it('should not write info message to cal because of manticore-log level', (done) => {
    cal.attach((e) => {
      assert(!e);
      require('manticore-log').Config.level = 'WARN';
      require('manticore-log')('test').info('Goodbye World');
      setTimeout(() => {
        assert(!localStorage[retailSDKUtil.StorageType.SecureBlob],
          'Should have only 1 stored log message.');
        done();
      }, 1);
    });
  });

  it('should not log to cal after shutdown', (done) => {
    cal.attach((e) => {
      assert(!e);
      cal.detach((e2) => {
        assert(!e2);
        require('manticore-log')('test').error('Hello World');
        setTimeout(() => {
          const blob = JSON.parse(localStorage[retailSDKUtil.StorageType.SecureBlob].CalLogStore);
          assert.equal(0, blob.events.length, 'No CAL logging should have occurred.');
          done();
        }, 1);
      });
    });
  });

  it('should post the logs', (done) => {
    let callCount = 0;
    require('../../js/common/Merchant').default.active = {
      request: (opts, cb) => {
        assert.equal(opts.op, 'secure-terminal-config/cal');
        assert.equal(opts.service, 'retail');
        assert.equal(opts.headers['X-PAYPAL-REQUEST-SOURCE'], 'RetailSDK.mocha.test');
        assert.equal(opts.headers['Content-Type'], 'application/json');
        const body = JSON.parse(opts.body);
        assert.equal(body.events.length, 1);
        process.nextTick(() => {
          cb(null, { headers: {}, response: { }, statusCode: 200 });
        });
        callCount++;
      },
    };
    cal.setRequestSourceId('mocha.test');
    cal.attach((e) => {
      assert(!e);
      require('manticore-log')('test').Config.level = 'DEBUG';
      require('manticore-log')('test').error('See you on the server side.');
      require('manticore').setTimeout(() => {
        cal.flush((flushError, fl) => {
          assert(!flushError);
          assert.equal(fl, 1);
          assert.equal(callCount, 1, 'Merchant http call should have occurred.');
          cal.flush((e2, fl2) => {
            assert.equal(callCount, 1, 'Only 1 http call should have occurred.');
            assert(!e2, e2 ? e2.message : '');
            assert.equal(fl2, 0);
            done();
          });
        });
      }, 1);
    });
  });

  it('should configure CAL logging separately', (done) => {
    cal.attach((e) => {
      assert(!e);
      require('manticore-log').Root.level = 'DEBUG';
      const config = {
        eLog: {
          level: 'ERROR',
          children: {
            noSetting: {},
          },
        }, dLog: {
          level: 'DEBUG',
          children: {
            noSetting: {},
          },
        },
      };
      cal.configure(config);
      require('manticore-log')('eLog.noSetting').debug('Should NOT log to CAL');
      require('manticore-log')('eLog.noSetting').error('Should log eLog.noSetting to CAL');
      require('manticore-log')('dLog.noSetting').debug('Should log dLog.noSetting to CAL');
      require('manticore').setTimeout(() => {
        const { events } =
          JSON.parse(localStorage[retailSDKUtil.StorageType.SecureBlob].CalLogStore);
        assert.equal(events.length, 2);
        assert.equal(decodeURI(/details=([^&]*)/.exec(events[0].data)[1]),
          'Should log eLog.noSetting to CAL');
        assert.equal(decodeURI(/details=([^&]*)/.exec(events[1].data)[1]),
          'Should log dLog.noSetting to CAL');
        done();
      }, 1);
    });
  });
});
