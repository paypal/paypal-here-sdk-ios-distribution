var HID = require('node-hid');

class Magtek {
    constructor(device) {
        this.device = device;
        var self = this;
        this.closure = {
            connect: (cb) => {
                self.connect(cb);
            }, send: (data) => {
                assert(false, 'Send not supported.');
            }, isConnected: () => {
                return !!self.interface;
            }, disconnect: (cb) => {
                return self.disconnect(cb);
            }
        };
        this.sdkReader = new sdk.MagneticReaderDevice(this.uniqueId, this.closure);
    }

    get uniqueId() {
        return `Magtek_${this.device.vendorId}_${this.device.productId}_${this.device.serialNumber}`;
    }

    connect(callback) {
        if (!this.interface) {
            var self = this;
            this.interface = new HID.HID(this.device.path);
            this.interface.on('data', function (d) {
                var info = decodeSwipe(self.device.productId, d);
                if (info) {
                    self.sdkReader.received(info);
                }
            });
            this.interface.on('error', function (e) {
                console.error('USB error %s', e);
            });
        }
        if (callback) {
            // TODO error handling
            callback();
        }
    }

    disconnect(callback) {
        /*
        if (this.interface) {
            this.interface.close();
            delete this.interface;
        }*/
        if (callback) {
            callback();
        }
    }
}

function decodeSwipe(productId, buf) {
    if (buf.length < 565) {
        console.error('Invalid MagTek swipe data length: %d', buf);
        return null;
    }
    var swipe = {
        track1: {},
        track2: {},
        track3: {}
    };

    getTracks(swipe, buf);
    getMagneprint(swipe, buf);

    swipe.serial = buf.slice(477, 492).toString('ascii');

    if (productId === 0x0E || buf.length === 565) {
        magtekVersion1(swipe, buf);
    } else if (productId === 0x11 || buf.length === 887) {
        magtekVersion2(swipe, buf);
    }

    return swipe;
}

function getMagneprint(swipe, buf) {
    swipe.magneprint = {
        status: buf.slice(344, 347).toString('hex'),
        length: buf[348]
    };
    if (swipe.magneprint.length) {
        swipe.magneprint.data = buf.slice(349, 349 + swipe.magneprint.length).toString('hex');
    }
}

function getTracks(swipe, buf) {
    swipe.track1.ok = (buf[0] & 0x1) === 0;
    swipe.track2.ok = (buf[1] & 0x1) === 0;
    swipe.track3.ok = (buf[2] & 0x1) === 0;

    swipe.track1.length = buf[3];
    swipe.track2.length = buf[4];
    swipe.track3.length = buf[5];

    swipe.format = encodingFormat(buf[6]);

    if (swipe.track1.length) {
        swipe.track1.data = buf.slice(7, 7 + swipe.track1.length).toString('hex');
    }
    if (swipe.track2.length) {
        swipe.track2.data = buf.slice(119, 119 + swipe.track2.length).toString('hex');
    }
    if (swipe.track3.length) {
        swipe.track3.data = buf.slice(231, 231 + swipe.track3.length).toString('hex');
    }
}

function magtekVersion1(swipe, buf) {
    // http://www.magtek.com/documentation/public/99875338-3.01.pdf
    swipe.counter = buf.slice(493, 500).toString('hex');
    swipe.crypto = {
        enabled: (buf[501] & 0x1) === 0x1,
        keyInjected: (buf[501] & 0x2) === 0x2
    };
    if (buf[501] & 0x4) {
        swipe.crypto.keysExhausted = true;
        console.error('DUKPT keys exhausted on Magtek reader.');
    }
    swipe.ksn = buf.slice(555, 564).toString('hex');
}

function magtekVersion2(swipe, buf) {
    // http://www.magtek.com/documentation/public/99875474-10.01.pdf, except it's not up
    swipe.counter = buf.slice(856, 858).toString('hex');
    swipe.crypto = {
        enabled: (buf[494] & 0x4) === 0x4,
        keyInjected: (buf[494] & 0x2) === 0x2
    };
    if (buf[494] & 0x1) {
        swipe.crypto.keysExhausted = true;
        console.error('DUKPT keys exhausted on Magtek reader.');
    }
    swipe.ksn = buf.slice(495, 504).toString('hex');
    swipe.counter = buf.slice(856, 858).toString('hex');

    var maskedLen = buf[505];
    if (maskedLen) {
        swipe.track1.masked = buf.slice(508, 508 + maskedLen).toString('ascii');
    }
    maskedLen = buf[506];
    if (maskedLen) {
        swipe.track2.masked = buf.slice(620, 620 + maskedLen).toString('ascii');
    }
    maskedLen = buf[507];
    if (maskedLen) {
        swipe.track3.masked = buf.slice(732, 732 + maskedLen).toString('ascii');
    }
}

Magtek.Encoding = {
    NOT_AVAILABLE: 'NotAvailable',
    ISO: 'ISO',
    AAMVA: 'AAMVA',
    BLANK: 'Blank',
    NON_STANDARD: 'NonStandard',
    UNKNOWN: 'Unknown'
};

var byteMap = [
    Magtek.Encoding.ISO,
    Magtek.Encoding.AAMVA,
    Magtek.Encoding.CADL,
    Magtek.Encoding.Blank,
    Magtek.Encoding.NonStandard,
    Magtek.Encoding.Unknown
];

function encodingFormat(byte) {
    return byteMap[byte] || Magtek.Encoding.NOT_AVAILABLE;
}

module.exports = Magtek;
