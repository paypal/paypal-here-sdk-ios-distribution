var Log = require('manticore-log')('miura.bluetooth'),
    MiuraDevice = require('../../../js/paymentDevice/MiuraDevice');

var BT_SERIAL_CHANNEL = 1;

class MiuraBluetooth {
    constructor(device) {
        this.address = device.address;
        this.uniqueId = device.name;
        this.maxSendSize = 8192;
        this._pauseVal = 75;
        this.connectCallbacks = [];
        this.closure = {
            connect: (cb) => {
                this.connect(cb);
            }, send: (data, cb) => {
                this.send(data, cb);
            }, isConnected: () => {
                return this.isConnected();
            }, disconnect: (cb) => {
                return this.disconnect(cb);
            }
        };
        this.sdkReader = new MiuraDevice(this.uniqueId, this.closure, false);
        MiuraDevice.discovered(this.sdkReader);
        this.sdkReader.connect();
    }

    createDevice() {
        this.device = new (require('bluetooth-serial-port')).BluetoothSerialPort();
        this.device.on('data', (data) => {
            this.sdkReader.received(data);
        });
        this.device.on('failure', (error) => {
           Log.debug(`Miura Bluetooth Device Error: ${error.message}\n${error.stack}`);
        });
        this.device.on('closed', () => {
            this.connected = false;
            this.sdkReader.onDisconnected(this.intendedClose ? null : new Error('Bluetooth port closed.'));
            this.intendedClose = false;
        })
    }

    connect(callback) {
        this.connectCallbacks.push(callback || function () {});
        if (this.connectCallbacks.length === 1) {
            this.createDevice();
            Log.debug(() => `Attempting Bluetooth connection to ${this.address}`);
            this._doConnect(3);
        }
    }

    _doConnect(retries) {
        this.device.connect(this.address, BT_SERIAL_CHANNEL, () => {
            // Success function
            Log.debug(() => `Bluetooth connection established (${this.address})`);
            this.connected = true;
            this.notifyCallbacks();
        }, (e) => {
            // Failure function
            Log.debug(() => `Bluetooth connection failed (${this.address}): ${e.message}`);
            if (retries) {
                return setTimeout(() => this._doConnect(--retries), 750);
            }
            this.connected = false;
            this.notifyCallbacks(e);
        });
    }

    disconnect(callback) {
        if (this.connected) {
            this.intendedClose = true;
            this.device.removeAllListeners();
            this.device.close();
            delete this.device;
            this.connected = false;
            if (callback) {
                callback();
            }
        }
    }

    isConnected() {
        return this.connected;
    }

    send(data, callback) {
        if (!this.connected) {
            if (callback) {
                callback(new Error('Device not connected.'));
            }
            return;
        }
        var binary = Buffer.isBuffer(data) ? data : new Buffer(data, 'base64');
        if (this.queued) {
            return this.queued.push([binary, callback]);
        }
        this.queued = [];
        this._send(binary, callback);
    }

    _send(binary, callback) {
        if (binary.length > this.maxSendSize) {
            // Split up the packet to avoid buffering issues and any sign issues on 16 bit values...
            // (Note that we always push it to the front of the queue to avoid reordering sends)
            // Seek the optimal time to wait between values
            this.queued.unshift([binary.slice(this.maxSendSize), callback]);
            callback = null;
            binary = binary.slice(0, this.maxSendSize);
        }
        this.device.write(binary, (err, bytesWritten) => {
            if (err) {
                binary._retryCount = binary._retryCount || 0;
                if (!binary._retryCount < 4) {
                    // If this is the second or later retry, let's up the amount we wait between sends
                    if (binary._retryCount > 0) {
                        this._pauseVal = Math.min(200, this._pauseVal * 1.25);
                        console.log('Now waiting', this._pauseVal);
                    }
                    binary._retryCount++;
                    // Wait for the send to recover
                    return setTimeout(() => {
                        this._send(binary, callback);
                    }, 100 * binary._retryCount);
                }
                if (callback) {
                    callback(err);
                }
                // TODO not sure... probably fire a disconnect message and shut 'em down
                var exQ = this.queued;
                delete this.queued;
                for (let q of exQ) {
                    if (q[1]) {
                        q[1](err);
                    }
                }
                return;
            }
            if (bytesWritten != binary.length) {
                Log.warn(`Succesfully sent ${bytesWritten} but tried to send ${data.length}`);
            }
            if (this.queued.length) {
                var next = this.queued.shift();
                setTimeout(() => this._send(next[0], next[1]), this._pauseVal);
            } else {
                delete this.queued;
            }
            if (callback) {
                callback();
            }
        });
    }

    notifyCallbacks(error) {
        var cbs = this.connectCallbacks;
        this.connectCallbacks = [];
        for (var cb of cbs) {
            try {
                cb(error);
            } catch (x) {
                Log.error(`Connect callback threw an error: ${x.message}\n${x.stack}`);
            }
        }
    }
}

module.exports = MiuraBluetooth;
