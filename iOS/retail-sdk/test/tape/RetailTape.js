import tapeLib from 'tape';

export default class RetailTape {
  addBeforeEach(fn) {
    this.hookBeforeEach = fn;
    return this;
  }

  addAfterEach(fn) {
    this.hookAfterEach = fn;
    return this;
  }

  _assemble(_test) {
    return (testName, unitTest) => {
      _test(testName, (t) => {
        const end = t.end;

        // Override for beforeEach
        t.end = () => {
          // Override for afterEach
          t.end = () => {
            t.end = end;

            if (this.hookAfterEach) {
              this.hookAfterEach(t);
            } else {
              t.end();
            }
          };

          unitTest(t);
        };

        if (this.hookBeforeEach) {
          this.hookBeforeEach(t);
        } else {
          t.end();
        }
      });
    };
  }

  build() {
    return (suiteName, suite) => {
      tapeLib(suiteName, (_suite) => {
        const _test = _suite.test;
        _suite.test = this._assemble(_test);
        suite(_suite);
      });
    };
  }
}
