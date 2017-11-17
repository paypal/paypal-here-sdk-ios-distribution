import {
  FormFactor,
  MagneticCard,
  MagneticReaderDevice,
} from 'retail-payment-device';
import log from 'manticore-log';

const Log = log('paymentDevice.magtekRawUsbReaderDevice');

function getMagnetPrint(swipe, buf) {
  swipe.magneprint = {
    status: buf.slice(344, 347).toString('hex'),
    length: buf[348],
  };
  if (swipe.magneprint.length) {
    swipe.magneprint.data = buf.slice(349, 349 + swipe.magneprint.length).toString('hex');
  }
}

function getTracks(swipe, buf) {
  const track1ok = (buf[0] & 0x1) === 0;
  const track2ok = (buf[1] & 0x1) === 0;
  const track3ok = (buf[2] & 0x1) === 0;
  const track1length = buf[3];
  const track2length = buf[4];
  const track3length = buf[5];

  if (track1ok && track1length) {
    swipe.track1 = buf.slice(7, 7 + track1length).toString('hex');
  }
  if (track2ok && track2length) {
    swipe.track2 = buf.slice(119, 119 + track2length).toString('hex');
  }
  if (track3ok && track3length) {
    swipe.track3 = buf.slice(231, 231 + track3length).toString('hex');
  }
}

function magtekVersion1(swipe, buf) {
  // http://www.magtek.com/documentation/public/99875338-3.01.pdf
  swipe.counter = buf.slice(493, 500).toString('hex');
  swipe.crypto = {
    enabled: (buf[501] & 0x1) === 0x1,
    keyInjected: (buf[501] & 0x2) === 0x2,
  };
  if (buf[501] & 0x4) {
    swipe.crypto.keysExhausted = true;
    Log.error('DUKPT keys exhausted on Magtek reader.');
  }
  swipe.ksn = buf.slice(555, 565).toString('hex');
}

function magtekVersion2(swipe, buf) {
  // http://www.magtek.com/documentation/public/99875474-10.01.pdf, except it's not up
  swipe.counter = buf.slice(856, 858).toString('hex');
  swipe.crypto = {
    enabled: (buf[494] & 0x4) === 0x4,
    keyInjected: (buf[494] & 0x2) === 0x2,
  };
  if (buf[494] & 0x1) {
    swipe.crypto.keysExhausted = true;
    Log.error('DUKPT keys exhausted on Magtek reader.');
  }
  swipe.ksn = buf.slice(495, 505).toString('hex');
  swipe.counter = buf.slice(856, 858).toString('hex');

  let maskedLen = buf[505];
  if (maskedLen) {
    swipe.track1masked = buf.slice(508, 508 + maskedLen).toString('ascii');
  }
  maskedLen = buf[506];
  if (maskedLen) {
    swipe.track2masked = buf.slice(620, 620 + maskedLen).toString('ascii');
  }
  maskedLen = buf[507];
  if (maskedLen) {
    swipe.track3masked = buf.slice(732, 732 + maskedLen).toString('ascii');
  }
}

/**
 * Specialization of card reader that does its own interpretation of USB data
 */
export default class MagtekRawUsbReaderDevice extends MagneticReaderDevice {

  constructor(uniqueName, native) {
    super(uniqueName, native);
    this.manufacturer = 'Magtek';
  }

  received(event) {
    try {
      const buf = new Buffer(event, 'base64');
      if (buf.length < 565) {
        Log.error(`Invalid MagTek data length: ${buf.length}`);
        return;
      }

      const card = new MagneticCard();
      card.formFactor = FormFactor.MagneticCardSwipe;
      card.reader = this;
      getTracks(card, buf);
      getMagnetPrint(card, buf);

      if (this.productId === 0x0E || buf.length === 565) {
        magtekVersion1(card, buf);
      } else if (this.productId === 0x11 || buf.length === 887) {
        magtekVersion2(card, buf);
      }

      if (!this.serialNumber && card.ksn) {
        // Magtek serial is first 14 of ksn. For some reason this doesn't match serial
        // reported in the packet.
        this.serialNumber = card.ksn.substring(0, 14);
      }

      super.received(card);
    } catch (x) {
      Log.error(`Failed to parse Magtek card event: ${x.message}\n${x.stack}`);
    }
  }
}
