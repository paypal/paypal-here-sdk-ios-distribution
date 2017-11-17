var SerialPort = require('serialport').SerialPort,
    MiuraDevice = require('../../../js/paymentDevice/MiuraDevice'),
    Log = require('manticore-log')('miura.usb');

class MiuraUsb {
    constructor(port) {
        this.connectCallbacks = [];
        this.port = port;
        this.maxSendSize = 8000;
        this.closure = {
            connect: (cb) => {
                this.connect(cb);
            }, send: (data, callback) => {
                this.send(data, callback);
            }, isConnected: () => {
                return this.isConnected();
            }, disconnect: (cb) => {
                return this.disconnect(cb);
            }
        };
        this.sdkReader = new MiuraDevice(this.uniqueId, this.closure, true);
        MiuraDevice.discovered(this.sdkReader);
        this.sdkReader.connect();
    }

    createDevice() {
        this.device = new SerialPort(this.port.comName, {baudRate: 115200}, false);
        this.device.on('error', (error) => {
            Log.debug(`Miura USB Device Error: ${error.message}\n${error.stack}`);
        });
        this.device.on('data', (buf) => {
            this.sdkReader.received(buf);
        });
        this.device.on('close', (err) => {
            this.connected = false;
            Log.debug('Miura serial port closed on ' + this.port.comName);
            this.sdkReader.onDisconnected(err || new Error('Serial port closed.'));
        });
    }

    get uniqueId() {
        return `PayPal Here USB Reader (${this.port.comName})`;
    }

    connect(callback) {
        this.connectCallbacks.push(callback || function () { });
        if (this.connectCallbacks.length === 1) {
            this.createDevice();
            this.device.open((error) => {
                if (!error) {
                    this.connected = true;
                }
                var cbs = this.connectCallbacks;
                this.connectCallbacks = [];
                for (var cb of cbs) {
                    try {
                        cb(error);
                    } catch (x) {
                        Log.error(`Connect callback threw an error: ${x.message}\n${x.stack}`);
                    }
                }
            });
        }
    }

    send(dataSpec, callback) {
        var binary;
        if (dataSpec.data) {
            binary = new Buffer(dataSpec.data, 'base64').slice(dataSpec.offset, dataSpec.offset + dataSpec.len);
        } else {
            binary = Buffer.isBuffer(dataSpec) ? dataSpec : new Buffer(dataSpec, 'base64');
        }
        if (this.queued) {
            return this.queued.push([binary, callback]);
        }
        this.queued = [];
        this._send(binary, callback);
    }

    _send(binary, callback) {
        // TODO move this into the core JS so that other platforms can take advantage (if it turns out they need it)
        if (binary.length > this.maxSendSize) {
            // Split up the packet to avoid buffering issues and any sign issues on 16 bit values...
            // (Note that we always push it to the front of the queue to avoid reordering sends)
            this.queued.unshift([binary.slice(this.maxSendSize), callback]);
            callback = null;
            binary = binary.slice(0, this.maxSendSize);
        }
        this.device.write(binary, (e) => {
            // Sometimes serialport calls our write callback twice, sometimes not at all, so don't do anything real here
            if (e) {
                Log.debug(`Failed to send MiuraUsb data: ${e.message}`);
            }
        });
        this.device.drain((e) => {
            if (e) {
                Log.error(`Drain failed ${e}`);
                // TODO not sure... probably fire a disconnect message and shut 'em down
            }
            if (this.queued.length) {
                var next = this.queued.shift();
                this._send(next[0], next[1]);
            } else {
                delete this.queued;
            }
            if (callback) {
                callback(e);
            }
        });
    }

    isConnected() {
        return this.connected;
    }

    disconnect(callback) {
        var d = this.device;
        delete this.device;
        if (this.connected) {
            this.connected = false;
            d.close((e) => {
                if (callback) {
                    callback(e);
                }
            });
        } else {
            if (callback) {
                callback(null);
            }
        }
    }
}

module.exports = MiuraUsb;
