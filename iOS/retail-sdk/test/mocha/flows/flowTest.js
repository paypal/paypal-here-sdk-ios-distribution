/*global describe:false, it:false, before:false, after:false, afterEach:false*/

var assert = require('assert');

describe('Flow', function () {

    before(() => global.native = {
        log: function (level, message) {
            // No logging in tests.
        }
    });

    it('should execute a simple flow', (done) => {
        var Flow = require('../../../js/common/flow').default;
        var self = this;
        this.foo = 'bar';
        new Flow(this,
            function (flow) {
                assert(this === self && this.foo === 'bar', 'Flow should call function with proper this pointer.');
                assert(flow, 'Should have gotten a flow argument');
                setTimeout(function () {
                    flow.next();
                }, 10);
            },
            (flow) => {
                assert(flow, 'Should have gotten a flow argument');
                process.nextTick(function () {
                    flow.completeFlow();
                });
            }
        ).on('completed', function () {
                done();
            }).on('aborted', function () {
                assert(false);
            }).start();
    });

    it('should abort a flow', (done) => {
        var Flow = require('../../../js/common/flow').default;
        new Flow(this,
            (flow) => {
                setTimeout(function () {
                    flow.next();
                }, 10);
            },
            (flow) => {
                process.nextTick(function () {
                    flow.abortFlow();
                });
            }
        ).on('completed', function () {
                assert(false);
            }).on('aborted', function () {
                done();
            }).start();
    });

    it('should dance back and forth', (done) => {
        var Flow = require('../../../js/common/flow').default;
        new Flow(this,
            (flow) => {
                process.nextTick(() => {
                    flow.next();
                });
            },
            (flow) => {
                process.nextTick(() => {
                    if (flow.data.beenHere) {
                        return flow.next();
                    }
                    flow.data.beenHere = true;
                    flow.back();
                });
            }
        ).on('completed', function (data) {
                assert(data.beenHere);
                done();
            }).on('aborted', function () {
                assert(false);
            }).start();
    });

    it('should abort a flow when going back on 0', (done) => {
        var Flow = require('../../../js/common/flow').default;
        new Flow(this, (flow) => {
            flow.back();
        }).on('aborted', () => {
                done();
            }).start();
    });

    it('should complete a flow when going off the end', (done) => {
        var Flow = require('../../../js/common/flow').default;
        new Flow(this, (flow) => {
            flow.next();
        }).on('completed', () => {
                done();
            }).start();
    });
});

