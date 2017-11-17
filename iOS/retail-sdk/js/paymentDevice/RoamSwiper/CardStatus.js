import {
  MagneticCard,
  FormFactor,
} from 'retail-payment-device';
import log from 'manticore-log';

const Log = log('RoamSwiper.cardStatus');

/**
 * Contain the details of card events on the Roam swiper such as
 * swipe, etc.
 */
export default class CardStatus {
  constructor(cardResponse) {
    this.response = cardResponse;

    try {
      const secureData = this.response.secureData;
      this.track1 = secureData.track1;
      this.track2 = secureData.track2;
      this.ksn = secureData.ksn;
      this.type = secureData.type;
      this.lastFour = secureData.lastFour;
      this.firstFour = secureData.firstFour;
    } catch (err) {
      Log.error(`Roam swiper secure data Json parse Failed: ${err}`);
    }
  }

  getPresentedCard(reader) {
    const card = new MagneticCard();
    const track = this.track1 || this.track2;
    card.formFactor = FormFactor.MagneticCardSwipe;
    card.ksn = this.ksn ? this.ksn.toString('hex') : '';
    card.reader = reader;

    if (!track || !track.length) {
      Log.error('Missing track  from roam card swipe data');
      card.failed = true;
      return card;
    }

    card.track1 = this.track1;
    card.track2 = this.track2;
    card.lastFourDigits = this.lastFour;
    card.cardIssuer = this.response.CardIssuer;
    card.isSignatureRequired = false;
    if (this.response.IsSignatureRequired === 'true') {
      card.isSignatureRequired = true;
    }
    card.cardholderName = this.response.CardHolderName;

    return card;
  }

  toString() {
    const parts = [
      this.response.toString(),
      '\nChip flags ',
      this.chipFlags.toString(16),
      ' Magstripe flags ',
      this.magstripeFlags.toString(16),
    ];
    if (this.ksn) {
      parts.push('\nKSN: ');
      parts.push(this.ksn.toString('hex'));
    }
    if (this.track1) {
      parts.push('\nTrack 1: ');
      parts.push(this.track1.toString('hex'));
    }
    if (this.track2) {
      parts.push('\nTrack 2: ');
      parts.push(this.track2.toString('hex'));
    }
    if (this.maskedTrack2) {
      parts.push('\nMasked Track 2: ');
      parts.push(this.maskedTrack2);
    }
    if (this.sredData) {
      parts.push('\nSRED: ');
      parts.push(this.sredData.toString('hex'));
    }

    return parts.join('');
  }
}
