'use strict';

var manticore = require('manticore'),
    log = require('manticore-log')('native.device'),
    HID = require('node-hid'),
    serialport = require('serialport'),
    Bluetooth = require('bluetooth-serial-port'),
    Magtek = require('./Magtek'),
    MiuraBluetooth = require('./MiuraBluetooth'),
    MiuraUsb = require('./MiuraUsb');

var Scanner = function (config) {
    this.config = config;
    this.usbDevices = {};
    this.btDevices = {};
};

Scanner.prototype.periodicScan = function (interval) {
    var self = this;
    if (this.interval) {
        clearInterval(this.interval);
    }
    this.interval = setInterval(function () {
        self.scan();
    }, interval * 1000);
};

Scanner.prototype.stopScans = function () {
    if (this.interval) {
        clearInterval(this.interval);
        delete this.interval;
    }
};

Scanner.prototype.scan = function (callback) {
    if (this.scanInProgress) {
        // One at a time people.
        return;
    }

    var exScan, self = this;
    var scanComplete = function (result) {
        if (exScan) {
            // Combine the result
            if (result && result.newDevices && result.newDevices.length) {
                exScan.newDevices = (exScan.newDevices || []).concat(result.newDevices);
            }
            self.scanInProgress = false;
            if (callback) {
                callback(exScan);
            }
        } else {
            exScan = result || {newDevices:null};
        }
    };
    this.scanInProgress = true;
    this._scanUsb(scanComplete);
    this._scanBluetooth(scanComplete);
};

Scanner.prototype._scanUsb = function (callback) {
    var devices = HID.devices(), stillThere = {}, newDevices = [];
    if (devices) {
        for (var d of devices) {
            if (this.usbDevices[d.path]) {
                // We already know about this device, but now we know it's still there.
                stillThere[d.path] = 1;
                continue;
            }
            if (d.vendorId === 2049) {
                // Magtek
                var engine = this.usbDevices[d.path] = new Magtek(d);
                newDevices.push(engine);
            }
        }
    }

    serialport.list((error, ports) => {
        if (ports) {
            for (var p of ports) {
                if (p.vendorId === '0x0525' && (p.productId === '0xa4a7' || p.productId === '0xa4a5'))
                {
                    if (this.usbDevices[p.comName]) {
                        stillThere[p.comName] = 1;
                        continue;
                    }
                    log.debug('Found ' + JSON.stringify(p,null,'\t'));
                    var engine = this.usbDevices[p.comName] = new MiuraUsb(p);
                    newDevices.push(engine);
                }
            }
        }
    });

    var scanResult = {
        newDevices: newDevices
    };
    if (callback) {
        callback(null, scanResult);
    }
};

Scanner.prototype._scanBluetooth = function (callback) {
    if (!this.btSerial) {
        this.btSerial = new Bluetooth.BluetoothSerialPort();
    }
    var self = this;
    // TODO support manual device specification
    var deviceEnum = (devs) => {
        var stillThere = {}, newDevices = [];
        if (!devs) {
            // TODO Record disappearance.
            return;
        }
        devs.forEach((dev) => {
            if (!this.btDevices[dev.address] && isMiura(dev)) {
                log.debug(() => `Found Bluetooth ${dev.address}: ${JSON.stringify(dev)}`);
                var engine = this.btDevices[dev.address] = new MiuraBluetooth(dev);
                newDevices.push(engine);
            }
        });
        newDevices.forEach(function (di) {
        });
        var scanResult = {
            newDevices: newDevices
        };
        if (callback) {
            callback(null, scanResult);
        }
    };
    if (this.bluetoothWhitelist && this.bluetoothWhitelist.length) {
        deviceEnum(this.bluetoothWhitelist);
    } else {
        this.btSerial.listPairedDevices(deviceEnum);
    }
};

function isMiura(dev) {
    return dev.name.indexOf('PayPal ') === 0;
}

module.exports = Scanner;