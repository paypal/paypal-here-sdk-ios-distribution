/* global chrome,PayPalRetailSDK */
/* eslint-disable no-console */

import log from 'manticore-log';

const Log = log('native.chromeMiura');

export default class ChromeMiura {

  constructor(manager, path, name, existingInfo) {
    this.path = path;
    this.manager = manager;
    const closure = {
      send: (d, callback) => {
        this._send(d, callback);
      },
      connect: (callback) => {
        if (this.connectionId) {
          delete this.importedConnection;
          if (this.pendedBytes) {
            this.reader.received(this.pendedBytes);
          }
          delete this.pendedBytes;
          callback(null);
          return;
        }
        if (this.connecting) {
          this.callbackQueue.push(callback);
          return;
        }
        this.connecting = true;
        this.callbackQueue = [callback];
        console.log(`connect ${name}`);
        chrome.serial.connect(this.path, {}, (info) => {
          this.connecting = false;
          this._connected(info, (err) => {
            this._notifyConnect(err);
          });
        });
      },
      disconnect: (callback) => {
        console.log(`Disconnect ${name}`);
        if (this.connectionId) {
          const cid = this.connectionId;
          delete this.connectionId;
          chrome.serial.disconnect(cid, (result) => {
            if (callback) {
              callback(result ? null : new Error('Disconnect failed'));
            }
          });
        } else if (callback) {
          // TODO perhaps we should give an error that we weren't connected
          callback();
        }
      },
      isConnected: () => {
        if (this.importedConnection) {
          // Fake 'em out
          return false;
        }
        return !!this.connectionId;
      },
    };
    if (existingInfo) {
      this.connectionId = existingInfo.id;
      this.manager.serialConnectionIds[existingInfo.id] = this;
      this.importedConnection = true;
      this.pendedBytes = existingInfo.data;
    }
    // Last arg to the JS constructor disables autoconnect if we have imported this connection. Connect will happen above us.
    const retailDeviceBuilder = new PayPalRetailSDK.DeviceBuilder();
    this.reader = retailDeviceBuilder.build('MIURA', 'M010', name, true, closure);
    chrome.runtime.getPlatformInfo((platformInfo) => {
      Log.info(`Platform info: ${JSON.stringify(platformInfo)}`);
      if (platformInfo.os === 'mac') {
        // Chrome is very sensitive to this, I'm not sure why.
        this.reader.throttleInfo = {
          size: 1024,
          pause: 50,
        };
      }
    });

    PayPalRetailSDK.discoveredPaymentDevice(this.reader);
    if (existingInfo && existingInfo.responders) {
      this.reader.terminal.injectResponders(existingInfo.responders);
      setTimeout(() => this.reader.connect(), 0);
    } else {
      this.reader.connect();
    }
  }

  _send(dataSpec, callback) {
    if (this.connectionId) {
      let binary;
      if (dataSpec.data) {
        const buff = Buffer.from(dataSpec.data, 'base64');
        binary = new Buffer(dataSpec.len);
        buff.copy(binary, 0, dataSpec.offset, dataSpec.offset + dataSpec.len);
      } else {
        binary = Buffer.isBuffer(dataSpec) ? dataSpec : Buffer.from(dataSpec, 'base64');
      }
      const self = this;
      if (!binary.length) {
        console.error('Sending 0 bytes');
        if (callback) {
          callback();
        }
        return;
      }
      chrome.serial.send(this.connectionId, binary.buffer, (sendInfo) => {
        if (chrome.runtime.lastError) {
          console.error('Failed to send Miura data', chrome.runtime.lastError);
        } else if (sendInfo.bytesSent !== binary.length && sendInfo.bytesSent) {
          console.warn('Attempted to send', binary.length, 'but sent', sendInfo.bytesSent);
          if (sendInfo.bytesSent < binary.length) {
            self._send(binary.slice(sendInfo.bytesSent), callback);
            return;
          }
        }
        if (callback) {
          setTimeout(() => callback(chrome.runtime.lastError, 0));
        }
      });
    }
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
      console.error(`Device connection error: ${JSON.stringify(chrome.runtime.lastError)}`);
      callback(new Error(chrome.runtime.lastError));
      return;
    }

    if (!connectionInfo) {
      console.error('Connection was successful, but could not retrieve connection information');
      callback(new Error('Could not retrieve connection info from serial port'));
      return;
    }

    this.connectionId = connectionInfo.connectionId;
    this.manager.serialConnectionIds[connectionInfo.connectionId] = this;
    callback(null);
  }

  reappearedAtPath(path, connectionId) {
    this.path = path;
    this.connectionId = connectionId;
    // TODO not so happy this is in the native layer.
    if (!this.reader.isUpdating) {
      setTimeout(() => this.reader.connect(), 0);
    }
  }
}

/* eslint-enable no-console */
