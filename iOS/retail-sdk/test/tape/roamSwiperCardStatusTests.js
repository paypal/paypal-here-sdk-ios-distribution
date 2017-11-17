import test from 'tape';
import {
  MagneticCard,
  FormFactor,
} from 'retail-payment-device';

import CardStatus from '../../js/paymentDevice/RoamSwiper/CardStatus';
import RoamSwiper from '../../js/paymentDevice/RoamSwiperDevice';

const getCardResponse = () => {
  const secureData = {
    track1: '$2907675006901$05000$^2211121$eRmaNntHAwbrHY4TFJtNdyb/8+UmPwB5d9knvnux3duOtSpkhn3NTx4wYyx//4oFmI/vi0PeM/nxWNPzz2SXHQ==',
    ksn: '40281212400031E00114',
    type: 'ROAM',
    lastFour: '5305',
    firstFour: '4358',
  };

  return {
    secureData,
    CardIssuer: 1, // 1 is for visa
    IsSignatureRequired: false,
    CardHolderName: 'mus ozd',
  };
};

function getRoamDevice(name) {
  const appInterface = {
    display: (opt, callback) => { callback(); },
    getSwUpdateUrl: (callback) => { callback('url'); },
  };
  const nativeInterface = {
    send: (data, cb) => { cb(); },
    connect: (cb) => { cb(); },
    isConnected: () => (true),
    disconnect: (cb) => { cb(); },
  };

  return new RoamSwiper(name, nativeInterface, appInterface);
}

test('roam swiper response parser', (suite) => {
  suite.test('should be undefined for some values like cvv, expiryDate, PostalCode', (t) => {
    t.plan(3);
    const cardResponse = getCardResponse();
    const device = getRoamDevice('roam');
    const card = new CardStatus(cardResponse).getPresentedCard(device);

    t.equal(card.CVV, undefined, 'CVV shall be undefined');
    t.equal(card.ExpiryDate, undefined, 'ExpiryDate shall be undefined');
    t.equal(card.PostalCode, undefined, 'PostalCode shall be undefined');
    t.end();
  });

  suite.test('should be assigning right values for card', (t) => {
    t.plan(9);
    const cardResponse = getCardResponse();
    const device = getRoamDevice('roam');
    const card = new CardStatus(cardResponse).getPresentedCard(device);
    const track1 = '$2907675006901$05000$^2211121$eRmaNntHAwbrHY4TFJtNdyb/8+UmPwB5d9knvnux3duOtSpkhn3NTx4wYyx//4oFmI/vi0PeM/nxWNPzz2SXHQ==';
    const ksn = '40281212400031E00114';
    const lastFour = '5305';

    t.equal(card.formFactor, FormFactor.MagneticCardSwipe, 'formFactor shall be equal');
    t.equal(card.reader, device, 'reader shall be equal');

    t.equal(card.track1, track1, 'track1 shall be equal');
    t.equal(card.track2, undefined, 'track2 shall be undefined');
    t.equal(card.ksn, ksn, 'ksn shall be equal');
    t.equal(card.type, undefined, 'type shall be undefined');
    t.equal(card.cardholderName, 'mus ozd', 'cardholderName shall be undefined');
    t.equal(card.lastFourDigits, lastFour, 'lastFour shall be equal');
    t.equal(card.isSignatureRequired, false, 'isSignatureRequired shall be false');
    t.end();
  });

  suite.test('should be failing when no track ', (t) => {
    t.plan(1);
    const cardResponse = getCardResponse();
    cardResponse.secureData.track1 = undefined;
    const device = getRoamDevice('roam');
    const card = new CardStatus(cardResponse).getPresentedCard(device);

    t.equal(card.failed, true, 'formFactor shall be equal');
    t.end();
  });

  suite.test('should be magnetic card', (t) => {
    t.plan(1);
    const cardResponse = getCardResponse();
    cardResponse.secureData.track1 = undefined;
    const device = getRoamDevice('roam');
    const card = new CardStatus(cardResponse).getPresentedCard(device);

    t.ok(card instanceof MagneticCard, 'card shall be instance of MagneticCard');
    t.end();
  });
});
