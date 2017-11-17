import {
  CardDataUtil,
} from 'retail-payment-device';

import log from 'manticore-log';

const Log = log('RoamSwiper.Parser');

/**
 * Contain the details of card events on the Roam swiper such as
 * swipe, etc.
 */
export default class Parser {

  getCardInfo(rawData) {
    const cardInfo = {};
    try {
      const data = rawData.decodeData;
      const decodeData = Buffer.isBuffer(data) ? data : new Buffer(data, 'base64');
      const decodeJsonData = JSON.parse(decodeData.toString('ascii'));

      cardInfo.secureData = {};
      cardInfo.secureData.track1 = rawData.track1;
      cardInfo.secureData.serial = decodeJsonData.ksn;
      cardInfo.secureData.ksn = decodeJsonData.ksn;
      cardInfo.secureData.type = 'ROAM';
      cardInfo.secureData.firstFour = null;
      cardInfo.secureData.lastFour = null;
      if (typeof decodeJsonData.maskedPAN === 'string' || decodeJsonData.maskedPAN instanceof String) {
        const len = decodeJsonData.maskedPAN.length;
        cardInfo.secureData.firstFour = decodeJsonData.maskedPAN.substring(0, 4);
        cardInfo.secureData.lastFour = decodeJsonData.maskedPAN.substring(len - 4, len);
        cardInfo.firstFour = cardInfo.secureData.firstFour;
        cardInfo.lastFour = cardInfo.secureData.lastFour;
      }
      cardInfo.CVV = null;
      cardInfo.ExpiryDate = null;
      cardInfo.PostalCode = null;
      cardInfo.IsSignatureRequired = false;
      cardInfo.WasPinRequired = false;

      // The cardholderName has the format : lastname/firstname
      let firstName = '';
      let lastName = '';
      if (decodeJsonData.cardholderName && decodeJsonData.cardholderName.indexOf('/') > -1) {
        const name = decodeJsonData.cardholderName.split('/');
        lastName = name[0];
        firstName = name[1];
      } else {
        firstName = decodeJsonData.cardholderName;
      }
      cardInfo.CardHolderName = `${firstName} ${lastName}`;
      cardInfo.CardIssuer = CardDataUtil.getCardIssuerFromCardNumber(cardInfo.firstFour);

      Log.debug(() => `cardInfo : ${JSON.stringify(cardInfo, null, 2)}`);
    } catch (err) {
      Log.error(`Roam Swiper Parser throws ${err}`);
    }
    return cardInfo;
  }
}
