import {
  PaymentDevice,
} from 'retail-payment-device';
import manticore from 'manticore';
import sinon from 'sinon';
import FlowAsync from '../../js/common/flowAsync';

import RetailTape from './RetailTape';

let sandbox;
let _alert;

function beforeEach(t) {
  sandbox = sinon.sandbox.create();
  _alert = manticore.alert;
  manticore.alert = () => {};
  t.end();
}

function afterEach(t) {
  sandbox.restore();
  manticore.alert = _alert;
  PaymentDevice.devices = [];
  t.end();
}

const test = new RetailTape()
  .addBeforeEach(beforeEach)
  .addAfterEach(afterEach)
  .build();

test('flow Async', (suite) => {
  suite.test('should execute a simple flow', (t) => {
    t.plan(4);
    // Given
    const self = {};
    self.foo = 'bar';
    const flowAsync = new FlowAsync(self, [(flow) => {
      t.ok(flow, 'Should have gotten a flow argument');
      setTimeout(() => {
        flow.next();
      }, 10);
    },
      (flow) => {
        t.ok(flow, 'Should have gotten a flow argument');
        process.nextTick(() => {
          flow.completeFlow();
        });
      }]).on('completed', () => {
        t.ok(true, 'flow completed');
        t.end();
      }).on('aborted', () => {
        t.notOk(true, 'it should not abort');
      });

    // When
    flowAsync.start().then(() => {
      // Then
      t.ok(true, 'flow completed');
    }, (error) => {
      t.notOk(true, `it should not abort: ${error}`);
    });
  });

  suite.test('should abort a flow', (t) => {
    t.plan(2);
    // Given
    const self = {};
    self.foo = 'bar';
    const flowAsync = new FlowAsync(self, [(flow) => {
      setTimeout(() => {
        flow.next();
      }, 10);
    },
      (flow) => {
        process.nextTick(() => {
          flow.abortFlow();
        });
      }]).on('completed', () => {
        t.notOk(true, 'flow should have aborted');
        t.end();
      }).on('aborted', () => {
        t.ok(true, 'it should abort');
        t.end();
      });

    // When
    flowAsync.start().then(() => {
      // Then
      t.ok(true, 'flow completed');
    }, (error) => {
      t.notOk(true, `it should not abort: ${error}`);
    });
  });
  suite.test('should dance back and forth', (t) => {
    t.plan(2);
    // Given
    const self = {};
    self.foo = 'bar';
    const flowAsync = new FlowAsync(self, [(flow) => {
      setTimeout(() => {
        flow.next();
      }, 0);
    }, (flow) => {
      process.nextTick(() => {
        if (flow.data.beenHere) {
          return flow.next();
        }
        flow.data.beenHere = true;
        return flow.back();
      });
    }]).on('completed', (data) => {
      t.ok(data, 'flow data is set');
      t.end();
    }).on('aborted', () => {
      t.notOk(true, 'it should not abort');
      t.end();
    });

    // When
    flowAsync.start().then(() => {
      // Then
      t.ok(true, 'flow completed');
    }, (error) => {
      t.notOk(true, `it should not abort: ${error}`);
    });
  });
  suite.test('should abort a flow when going back on 0', (t) => {
    // Given
    const self = {};
    self.foo = 'bar';
    const flowAsync = new FlowAsync(self, [(flow) => {
      flow.back();
    }]).on('aborted', () => {
      t.ok(true, 'it should abort');
      t.end();
    });

    // When
    flowAsync.start().then(() => {
      // Then
      t.ok(true, 'flow completed');
    }, (error) => {
      t.notOk(true, `it should not abort: ${error}`);
    });
  });
  suite.test('should complete a flow when going off the end', (t) => {
    // Given
    const self = {};
    self.foo = 'bar';
    const flowAsync = new FlowAsync(self, [(flow) => {
      flow.next();
    }]).on('completed', () => {
      t.ok(true, 'it should complete');
      t.end();
    });

    // When
    flowAsync.start().then(() => {
      // Then
      t.ok(true, 'flow completed');
    }, (error) => {
      t.notOk(true, `it should not abort: ${error}`);
    });
  });
});

