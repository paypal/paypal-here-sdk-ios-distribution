/* global chrome,PayPalRetailSDK,manticore */
/* eslint-disable no-console */

import manticore from 'manticore';
import { Tags } from 'tlvlib';
import { Buffer } from 'buffer';
import { MiuraParser as Parser } from 'miura-emv/build/Parser';
import CMiura from './ChromeMiura';
import CMagtek from './ChromeMagtek';

const macRE = /\/dev\/tty\.usbmodem(.*)/;
const winRE = /^(COM\d+)$/;
const macBTRE = /^\/dev\/tty.PayPal(\d+)-SerialPort$/;

function log(level, message) {
  manticore.log(level, 'chromeDeviceManager', message);
}

function toBuffer(ab) {
  const buffer = new Buffer(ab.byteLength);
  const view = new Uint8Array(ab);
  for (let i = 0; i < buffer.length; ++i) {
    buffer[i] = view[i];
  }
  return buffer;
}

class MiuraDetector {
  constructor(manager, path) {
    this.manager = manager;
    this.parser = new Parser();
    this.parser.on('response', (rz) => {
      if (this.responseCount) {
        console.error('Shouldn\'t be around for this');
      }
      this.responseCount = 1;
      const ifd = rz.tlvs.find(Tags.InterfaceDeviceSerialNumber);
      // This means we got a good device
      if (!ifd) {
        console.log('NotMiura', rz);
        this.notMiura();
        return;
      }
      this.completed = true;
      const serial = ifd.parse();
      let miuraReader;
      if (this.manager.miuraBySerialNumber[serial]) {
        log('DEBUG', `Reusing existing reader for ${serial}`);
        miuraReader = this.manager.miuraBySerialNumber[serial];
        // TODO maybe trigger disconnect?
        delete this.manager.knownDevices[miuraReader.path];
        miuraReader.reappearedAtPath(path, this.connectionId);
      } else {
        log('DEBUG', `New reader for serial ${serial}`);
        if (this.existing.data.length) {
          this.existing.data = Buffer.concat(this.existing.data);
        } else {
          delete this.existing.data;
        }
        miuraReader = new CMiura(this.manager, path, `PayPal Reader ${serial}`, this.existing);
        this.manager.miuraBySerialNumber[serial] = miuraReader;
      }
      this.manager.knownDevices[path] = miuraReader;
    });
    this.parser.on('unsolicited', (rz) => {
      console.log('Unsolicited packet during Miura detection.', rz.raw.toString('hex'));
      this.existing.data.push(rz.raw);
    });
    this.path = path;
    this.tryConnect();
    this.reader = {
      received: (data) => {
        // TODO better detection logic.
        if (this.gotGoodPacket || (data.length > 4 && data[0] === 1 && data.length >= data[2] + 4)) {
          this.gotGoodPacket = true;
          this.parser.received(new Buffer(data));
        } else {
          log('DEBUG', 'Received improper data format.');
          this.notMiura();
        }
      },
    };
  }

  notMiura() {
    chrome.serial.disconnect(this.connectionId, () => {
      // Not miura, but let's hold on to it so nobody else tries.
      log('DEBUG', `${this.path} is not a Miura device.`);
    });
  }

  tryConnect() {
    chrome.serial.connect(this.path, {}, (connectionInfo) => {
      this.connecting = false;
      if (chrome.runtime.lastError) {
        // TODO maybe retry this periodically? Remove ourselves from known devices?
        // Right now this means if the device isn't present but the port is, you'll never recover from that.
        delete this.manager.knownDevices[this.path];
        return;
      }
      this.connectionId = connectionInfo.connectionId;
      this.existing = {
        id: this.connectionId,
        data: [],
      };
      this.manager.serialConnectionIds[connectionInfo.connectionId] = this;
      // Send a soft reset
      const binary = new Buffer('010004D0000000D5', 'hex');
      chrome.serial.send(this.connectionId, binary.buffer, () => {
        if (chrome.runtime.lastError) {
          console.error('Failed to send Miura data', chrome.runtime.lastError);
          // TODO not sure... Much like when the connection fails though
          delete this.manager.knownDevices[this.path];
          return;
        }
        // Wait for a response
        setTimeout(() => {
          if (!this.completed) {
            console.log('Timeout attempting to validate Miura device', this);
            this.notMiura();
          }
        }, 5000);
        // TODO timeouts
      });
    });
  }
}

export default class DeviceManager {
  constructor() {
    this.knownDevices = {};
    this.miuraBySerialNumber = {};
    this.ignoredPorts = {};
    this.serialConnectionIds = {};
    this.hasCandidateUsb = false;
  }

  start() {
    log('DEBUG', 'Starting device manager');
    chrome.usb.getDevices({}, d => this._foundUsb(d));
    chrome.usb.onDeviceAdded.addListener(d => this._foundUsb([d]));
    chrome.usb.onDeviceRemoved.addListener(d => console.trace(d));
    // Scan for bluetooth Miura readers
    chrome.serial.getDevices(p => this._foundSerial(p, true));
    // Scan for HID swipers
    chrome.hid.getDevices({}, p => this._foundHIDDevices(p));
    chrome.hid.onDeviceAdded.addListener(d => this._foundHID(d));
    chrome.hid.onDeviceRemoved.addListener(d => this._lostHID(d));
    if (!this.serialReceiveListener) {
      this.serialReceiveListener = info => this._received(info);
      chrome.serial.onReceive.addListener(this.serialReceiveListener);
      this.serialErrorListener = info => this._serialError(info);
      chrome.serial.onReceiveError.addListener(this.serialErrorListener);
    }
  }

  stop() {
    if (this.serialReceiveListener) {
      chrome.serial.onReceive.removeListener(this.serialReceiveListener);
      delete this.serialReceiveListener;
      chrome.serial.onReceiveError.removeListener(this.serialErrorListener);
    }
  }

  _foundHIDDevices(devices) {
    if (devices) {
      for (let i = 0; i < devices.length; i++) {
        this._foundHID(devices[i]);
      }
    }
  }

  _foundHID(device) {
    log('DEBUG', `Found HID device ${device.deviceId}`);
    const hidDevice = `HID${device.deviceId}`;
    if (!this.knownDevices[hidDevice] && device.vendorId === 2049) {
      this.knownDevices[hidDevice] = new CMagtek(device);
    }
  }

  _lostHID(deviceId) {
    const nativeReader = this.knownDevices[`HID${deviceId}`];
    if (nativeReader) {
      nativeReader.reader.removed();
    }
  }

  _foundUsb(devices) {
    if (this.hasCandidateUsb) {
      // We already know there's a candidate. Do a new scan.
      chrome.serial.getDevices(p => this._foundSerial(p));
      return;
    }
    log('DEBUG', `Found USB Devices : ${devices.length}`);
    let foundCandidate = false;
    if (devices) {
      for (let i = 0; i < devices.length; i++) {
        if (devices[i].vendorId === 1317) {
          foundCandidate = true;
        }
      }
      if (foundCandidate) {
        this.hasCandidateUsb = true;
        log('DEBUG', 'Discovered candidate USB device, enumerating serial ports.');
        chrome.serial.getDevices(p => this._foundSerial(p));
      }
    } else {
      console.trace('USB scanner permission denied. The PayPal SDK will not be able to connect to USB reader devices.');
    }
  }

  _foundSerial(ports, btOnly) {
    for (let i = 0; i < ports.length; i++) {
      const path = ports[i].path;
      const p = ports[i];
      if (!this.ignoredPorts[path] && !this.knownDevices[path]) {
        if ((p.productId === 0xA4A7 || p.productId === 0xA4A5) && p.vendorId === 1317) {
          // We know this is us
          this.knownDevices[path] = new CMiura(this, path, `PayPal Reader ${path}`);
        } else if (!btOnly && ((path.match(macRE)) || (path.match(winRE)))) {
          this.knownDevices[path] = new MiuraDetector(this, path);
        } else if ((path.match(macBTRE))) {
          this.knownDevices[path] = new MiuraDetector(this, path);
        } else if ((path.match(winRE))) {
          this.knownDevices[path] = new MiuraDetector(this, path);
        }
      }
    }
  }

  _received(info) {
    // console.log('Received serial data', info);
    const data = toBuffer(info.data);
    const device = this.serialConnectionIds[info.connectionId];
    if (device) {
      if (device.reader) {
        device.reader.received(data);
      } else {
        log('WARN', 'Received serial data for device that wasn\'t ready');
      }
    } else {
      log('WARN', 'Received serial data with no matching device.');
    }
  }

  _serialError(info) {
    log('ERROR', `Received serial error! ${JSON.stringify(info)}`);
    const device = this.serialConnectionIds[info.connectionId];
    if (info.error === 'device_lost') {
      log('INFO', `${info.connectionId} device lost`);
      if (device && device.reader) {
        device.reader.disconnect();
        device.reader.onDisconnected(new Error('Device disconnected'));
      }
      delete this.serialConnectionIds[info.connectionId];
      delete this.knownDevices[device.path];
    } else if (device && device.reader.native) {
      device.reader.native.connect(() => {
        log('WARN', 'Triggering serial reconnect');
      });
    }
  }
}

/* eslint-enable no-console */
