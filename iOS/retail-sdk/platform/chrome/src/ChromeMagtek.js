/* global chrome,PayPalRetailSDK,manticore */
/* eslint-disable no-console */

function toBuffer(ab) {
  const buffer = new Buffer(ab.byteLength);
  const view = new Uint8Array(ab);
  for (let i = 0; i < buffer.length; ++i) {
    buffer[i] = view[i];
  }
  return buffer;
}

export default class ChromeMagtek {
  constructor(device) {
    this.device = device;
    this.name = `Magtek USB Card Reader #${device.deviceId}`;
    const self = this;
    const closure = {
      send: function send() {
        console.error('Can\'t send to Magtek reader yet.');
      },
      connect: function connect(callback) {
        if (self.connecting) {
          self.callbackQueue.push(callback);
          return;
        }
        self.connecting = true;
        self.callbackQueue = [callback];
        chrome.hid.connect(device.deviceId, (info) => {
          console.log('Connected to Magtek');
          self.connecting = false;
          self._connected(info, () => {
            self._notifyConnect(null);
          });
        });
      },
      disconnect: function disconnect(callback) {
        console.log('Disconnect', self.name);
        if (self.connectionId) {
          const cid = self.connectionId;
          delete self.connectionId;
          chrome.hid.disconnect(cid, callback);
        } else if (callback) {
          // TODO perhaps we should give an error that we weren't connected
          callback();
        }
      },
      isConnected: function isConnected() {
        return !!self.connectionId;
      },
    };
    this._receive = () => {
      self.receiveOne();
    };
    this.reader = new PayPalRetailSDK.MagtekRawUsbReaderDevice(this.name, closure);
    PayPalRetailSDK.discoveredPaymentDevice(this.reader);
  }

  _notifyConnect(e) {
    const q = this.callbackQueue;
    delete this.callbackQueue;
    for (let i = 0; i < q.length; i++) {
      const cb = q[i];
      try {
        cb(e);
      } catch (x) {
        console.error('Connect callback exception:', x);
      }
    }
  }

  _connected(connectionInfo, callback) {
    if (chrome.runtime.lastError) {
      callback(new Error(chrome.runtime.lastError));
      return;
    }
    this.connectionId = connectionInfo.connectionId;
    this.receiveOne();
    callback(null);
  }

  receiveOne() {
    const self = this;
    if (self.connectionId) {
      console.log('Waiting for Magtek input.');
      chrome.hid.receive(this.connectionId, (reportId, data) => {
        if (data && data.byteLength) {
          self.errorCount = 0;
          console.log(`Received HID report #${reportId}: ${data.byteLength} bytes`);
          const jsData = toBuffer(data);
          self.reader.received(jsData);
        } else {
          self.errorCount += 1;
          console.log('Magtek HID device empty receive:', reportId, chrome.runtime.lastError);
        }
        if (self.errorCount < 10) {
          // Give it a little time to recover
          manticore.setTimeout(this._receive, 100);
        } else {
          // TODO consider it a disconnect?
        }
      });
    }
  }
}

/* eslint-enable no-console */
