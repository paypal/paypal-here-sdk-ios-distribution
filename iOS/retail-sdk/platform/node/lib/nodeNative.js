'use strict';

var manticore = require('manticore'),
    EventEmitter = require('events').EventEmitter,
    https = require('https'),
    wreck = require('wreck'),
    stdin = process.stdin,
    localStorage = new require('node-localstorage').LocalStorage('.localstorage', 0x8FFFFFFF);

var agent = new https.Agent({
    secureProtocol: 'TLSv1_client_method',
    secureOptions: require('constants').SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS,
    rejectUnauthorized: false
});

class Native extends EventEmitter {
    constructor() {
        super();
        // Register all our overrides with manticore object
        var self = this;
        ['ready', 'alert', 'setItem', 'getItem', 'export'].forEach((m) => {
            manticore[m] = function () {
                return self[m].apply(self, arguments);
            }
        });
    }

    ready(_sdk) {
        global.sdk = _sdk;
        this.emit('ready', sdk);
    }

    export(values) {
        for (let k in values) {
            this[k] = values[k];
        }
    }

    collectSignature(options, callback) {

    }

    alert(options, callback) {
        var handle = this.handle = {
            dismiss: () => {
                if (handle === this.handle) {
                    console.log('*************** PAYPAL SDK ALERT DISMISSED ***************');
                    stdin.removeListener('data', this._getch);
                    stdin.setRawMode(false);
                } else {
                    console.error('OUT OF TURN DISMISS RECEIVED!', new Error());
                }
            },
            setTitle: (t) => {
                console.log('******* PAYPAL SDK ALERT setTitle', t);
            },
            setMessage: (t) => {
                console.log('******* PAYPAL SDK ALERT setMessage', t);
            },
            callback: callback
        };
        console.log('******************** PAYPAL SDK ALERT ********************');
        if (options.title) {
            console.log('*   Title:', options.title);
        }
        if (options.message) {
            console.log('* Message:', options.message);
        }
        if (options.cancel || (options.buttons && options.buttons.length)) {
            console.log('*');
            console.log('* Press the corresponding number:');
        }
        var bix = 1;
        if (options.buttons) {
            for (let name of options.buttons) {
                console.log('*  ', bix++, '-', name);
            }
        }
        if (options.cancel) {
            console.log('*  ', bix++, '-', options.cancel);
        }
        if (bix > 1) {
            stdin.setRawMode(true);
            stdin.on('data', this._getch);
            handle.count = bix - 1;
        }
        console.log('**********************************************************');
        return handle;
    }

    offerReceipt(options, callback) {
        console.log('****************** PAYPAL RECEIPT OFFER*******************');
        process.nextTick(callback);
    }

    setItem(name, disposition, value, cb) {
        if (value === null) {
            localStorage.removeItem(disposition + name);
        } else {
            localStorage.setItem(disposition + name, value);
        }
        if (cb) {
            cb();
        }
    }

    getItem(name, disposition, cb) {
        var it = localStorage.getItem(disposition + name);
        cb(null, it);
        return it;
    }

    _getch(v) {
        if (v[0] === 0x3) {
            process.exit(-1);
        }

        if (v[0] >= 0x31 && v[0] < (0x31 + singleton.handle.count)) {
            singleton.handle.callback(singleton.handle, v[0] - 0x31);
        }
    }
}

var singleton = module.exports = new Native();
