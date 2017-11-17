import test from 'tape';
import Parser from '../../js/paymentDevice/RoamSwiper/Parser';

const getRawData = () => {
  const decodeData = {
    partialTrack: '07675006901$05000$^2211121',
    track1Status: '0',
    expiryDate: '2211',
    track2Status: '0',
    formatID: '29',
    cardholderName: '07675006901$05000$',
    maskedPAN: '4358XXXXXXXX5305',
    ksn: '40281212400031E00114',
    encTrack: '79199a367b470306eb1d8e13149b4d7726fff3e5263f007977d927be7bb1dddb8eb52a64867dcd4f1e30632c7fff8a05988fef8b43de33f9f158d3f3cf64971d',
  };

  const decodedData = new Buffer(JSON.stringify(decodeData)).toString('base64');

  const track1 = '$2907675006901$05000$^2211121$eRmaNntHAwbrHY4TFJtNdyb/8+UmPwB5d9knvnux3duOtSpkhn3NTx4wYyx//4oFmI/vi0PeM/nxWNPzz2SXHQ==';
  return {
    decodeData: decodedData,
    track1,
  };
};

test('roam swiper response parser', (suite) => {
  suite.test('should be initializing some values like cvv, expiryDate, PostalCode and isSignatureRequired', (t) => {
    t.plan(5);
    const rawData = getRawData();
    const parser = new Parser();
    const cardInfo = parser.getCardInfo(rawData);

    t.equal(cardInfo.CVV, null, 'CVV shall be null');
    t.equal(cardInfo.ExpiryDate, null, 'ExpiryDate shall be null');
    t.equal(cardInfo.PostalCode, null, 'PostalCode shall be null');
    t.equal(cardInfo.IsSignatureRequired, false, 'IsSignatureRequired shall be false');
    t.equal(cardInfo.WasPinRequired, false, 'WasPinRequired shall be false');
    t.end();
  });

  suite.test('should be parsing for secureData', (t) => {
    t.plan(5);
    const rawData = getRawData();
    const parser = new Parser();
    const cardInfo = parser.getCardInfo(rawData);

    const track1 = '$2907675006901$05000$^2211121$eRmaNntHAwbrHY4TFJtNdyb/8+UmPwB5d9knvnux3duOtSpkhn3NTx4wYyx//4oFmI/vi0PeM/nxWNPzz2SXHQ==';
    const ksn = '40281212400031E00114';
    t.equal(cardInfo.secureData.track1, track1, 'track1 should be from rawData');
    t.equal(cardInfo.secureData.ksn, ksn, 'ksn should be from the rawData');
    t.equal(cardInfo.secureData.type, 'ROAM', 'type should be ROAM');
    t.equal(cardInfo.secureData.firstFour, '4358', 'firstFour should be first four digit of maskedPAN of the rawData');
    t.equal(cardInfo.secureData.lastFour, '5305', 'lastFour should be last four digit of maskedPAN of the rawData');
    t.end();
  });

  suite.test('should be parsing for card holder name', (t) => {
    t.plan(1);
    const rawData = getRawData();
    const parser = new Parser();
    const cardInfo = parser.getCardInfo(rawData);

    const cardHolderName = '07675006901$05000$ ';
    t.equal(cardInfo.CardHolderName, cardHolderName, 'CardHolderName should be combined of first and last name with one space');
    t.end();
  });

  suite.test('should be parsing for card issuer', (t) => {
    t.plan(1);
    const rawData = getRawData();
    const parser = new Parser();
    const cardInfo = parser.getCardInfo(rawData);

    // 1 is for visa, 2 for masterCard, 4 for amex and so on.
    t.equal(cardInfo.CardIssuer, 1, 'Card issuer is visa for this raw data');
    t.end();
  });
});
