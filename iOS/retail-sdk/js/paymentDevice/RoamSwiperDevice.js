import {
  PaymentDevice,
  deviceError,
  CardPresentEvent,
  FormFactor,
  BatteryInfo,
  batteryStatus,
  readerType,
  readerConnectionType,
  deviceModel,
  deviceManufacturer,
} from 'retail-payment-device';
import log from 'manticore-log';

import Parser from './RoamSwiper/Parser';
import CardStatus from './RoamSwiper/CardStatus';

const Log = log('roamSwiperDevice');

/**
 * Represents a payment swiper device manufactured by Roam for PayPal
 * @class
 * @protected
 */
export default class RoamSwiperDevice extends PaymentDevice {
  /**
   * Construct a new PaymentDevice given a native function capable of sending data to the device
   */
  constructor(uniqueId, nativeInterface, appInterface, isUsb) {
    super(uniqueId, nativeInterface, appInterface, isUsb);
    this.manufacturer = deviceManufacturer.roam;
    this.model = deviceModel.swiper;
    this.serialNumber = '1234567890'; // ToDo: what is the right serial number
    this.parser = new Parser();
    this.type = readerType.Magstripe;
    this.connectionType = readerConnectionType.AudioJack;
  }

  beginDeviceRemoved(callback) {
    this.native.removed(callback);
  }

  beginDeviceConnect(callback) {
    if (this.native.isConnected()) {
      Log.debug(() => `Connect called, but ${this.id} is already connected.`);
      callback();
      return;
    }

    Log.debug(() => `Connecting to Roam swiper device ${this.id}`);
    this.native.connect((error) => {
      if (error) {
        callback(error);
        return;
      }
      Log.debug(() => 'Roam swiper is bypassing normal connection sequence.');
      callback();
      return;
    });
  }

  listenForCardRemoval(callback) {
    callback();
  }

  beginDeviceDisconnect(callback) {
    if (!this.isConnected()) {
      Log.debug('Device already disconnected. Will not attempt to invoke native.disconnect');
      if (callback) {
        callback(null);
      }
      return;
    }

    this.native.disconnect(callback);
  }

  get formFactors() {
    return FormFactor.MagneticCardSwipe;
  }

  received(rawData) {
    try {
      const cardInfo = this.parser.getCardInfo(rawData);
      const card = (new CardStatus(cardInfo)).getPresentedCard(this);
      this.transactionActive = true;
      Log.debug(() => `RoamSwiper received ${card}`);
      this.emit(PaymentDevice.Event.cardPresented,
        null,
        CardPresentEvent.cardDataRead,
        FormFactor.MagneticCardSwipe, { card }
      );
    } catch (err) {
      Log.error(`RoamSwiper received throw ${err}`);
    }
  }

  send(data, cb) {
    this.native.send(data, cb);
  }

  display(opt, callback) {
    if (!this.isConnected()) {
      if (callback) {
        callback(deviceError.deviceNotConnected);
      }
      return;
    }

    if (callback) {
      callback();
    }
  }

  getFirmwareVersionInfo(callback) {
    Log.warn('there is no way to know the firmware version info of  RoamSwiper!');

    if (callback) {
      callback();
    }
  }

  activateForPayment(context) {
    Log.debug('activate roam swiper for payment');
    super.activateForPayment(context, [FormFactor.MagneticCardSwipe]);
    this.send('listenForCardEvents', (err) => {
      if (err) {
        Log.error(`Failed to register for Roam keyboard events: ${err.message}`);
      } else {
        Log.debug('Sent listenForCardEvents');
      }
    });
  }

  getBatteryInfo(callback) {
    if (callback) {
      callback(null, new BatteryInfo(100, false, new Date(), batteryStatus.unknown));
    }
  }

  deactivateFormFactors(formFactors, callback) {
    Log.debug(() => `Deactivating form factors [${formFactors}] on '${this.id}'`);
    if (!formFactors || formFactors.length === 0) {
      if (callback) {
        callback();
      }
      return;
    }
    super.deactivateFormFactors(formFactors);
    const sFormFactors = new Set(formFactors);
    if (sFormFactors.has(FormFactor.MagneticCardSwipe)) {
      this.send('stopListeningForCardEvents', (err) => {
        if (err) {
          Log.error(`Failed to stop listening for Roam swiper events: ${err.message}`);
        } else {
          Log.debug('Sent stopListeningForCardEvents');
        }

        if (callback) {
          callback(err);
        }
      });
      return;
    }
    Log.debug('Ignoring deactivate request as supported form factor not received');
    if (callback) {
      callback();
    }
  }

  abortTransaction(context, cb) {
    Log.info(() => `Deactivating ${this.id} with ${this.cardPresented ? 'an active transaction.' : 'NO active transaction.'}`);
    super.abortTransaction(context);
    if (cb) {
      cb();
    }
  }

  completeTransaction(authCode, cb) {
    this.transactionActive = false;
    Log.debug(() => 'Roam swiper completeTransaction');
    if (cb) {
      cb();
    }
  }

  postTransactionCleanup(callback) {
    Log.debug(() => 'Roam swiper postTransactionCleanup');
    if (callback) {
      callback();
    }
  }
}
