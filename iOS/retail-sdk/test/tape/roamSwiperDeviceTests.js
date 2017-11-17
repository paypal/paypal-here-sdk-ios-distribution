import proxyquire from 'proxyquire';
import test from 'tape';
import sinon from 'sinon';
import {
  PaymentDevice,
  FormFactor,
  CardPresentEvent,
  readerType,
  readerConnectionType,
} from 'retail-payment-device';

import CardStatus from '../../js/paymentDevice/RoamSwiper/CardStatus';

const setup = () => {
  const appInterface = {
    display: (opt, callback) => { callback(); },
    getSwUpdateUrl: (callback) => { callback('url'); },
  };

  const nativeInterface = {
    send: (data, cb) => { cb(); },
    connect: (cb) => { cb(); },
    isConnected: () => (true),
    disconnect: (cb) => { cb(); },
    removed: (cb) => { cb(); },
  };

  const cardStatusStub = sinon.createStubInstance(CardStatus);
  const ProxyRoamDevice = proxyquire('../../js/paymentDevice/RoamSwiperDevice', {
    './RoamSwiper/CardStatus': { default: () => (cardStatusStub) },
  }).default;

  const device = new ProxyRoamDevice('roam-1', nativeInterface, appInterface, false);
  sinon.stub(device, 'startPollForBattery');
  PaymentDevice.discovered(device);

  return {
    device,
    cardStatusStub,
    nativeInterface,
    appInterface,
  };
};

const teardown = (fixtures) => {
  fixtures.device.removed();
};

test('Roam swiper device', (suite) => {
  suite.test('should be discovered and removed correctly', (t) => {
    const fixture1 = setup();
    t.equal(PaymentDevice.devices.length, 1);
    teardown(fixture1);
    t.equal(PaymentDevice.devices.length, 0);
    t.end();
  });

  suite.test('should connect without an error', (t) => {
    const fixture = setup();

    fixture.device.connect((err) => {
      t.equal(err, undefined);
    });

    teardown(fixture);
    t.end();
  });

  suite.test('should disconnect without an error', (t) => {
    const fixture = setup();

    fixture.device.disconnect((err) => {
      t.equal(err, undefined);
    });

    teardown(fixture);
    t.end();
  });

  suite.test('should emit card presented event after received card data', (t) => {
    const { device, cardStatusStub } = setup();

    const formFactor = FormFactor.MagneticCardSwipe;
    const cardObj = { formFactor,
      data: '',
    };

    cardStatusStub.getPresentedCard.returns(cardObj);

    // Assert
    device.once(PaymentDevice.Event.cardPresented, (err, subType, ff, cardData) => {
      t.deepEqual(cardData.card, cardObj, 'Card object should match');
      t.notOk(err, 'No error as expected');
      t.equal(subType, CardPresentEvent.cardDataRead, 'Sub event type matches');
      t.equal(ff, formFactor, 'Event emitted with expected form factor');
      t.end();
    });

    device.received(cardObj);

    const fixture = {};
    fixture.device = device;
    teardown(fixture);
  });

  suite.test('should emit ERROR event after received card data', (t) => {
    const { device, cardStatusStub } = setup();

    const formFactor = FormFactor.MagneticCardSwipe;
    const expectedError = new Error('Issue with received card data');
    const cardObj = { formFactor,
      data: '',
    };

    cardStatusStub.getPresentedCard.throws(expectedError);

    // Assert
    device.once(PaymentDevice.Event.cardPresented, (err, subType, ff, cardData) => {
      t.deepEqual(err, expectedError, 'Error should match');
      t.notOk(cardData, 'Card object should be null on error events');
      t.equal(subType, CardPresentEvent.cardDataRead, 'Sub event type matches');
      t.equal(ff, formFactor, 'Event emitted with expected form factor');
      t.end();
    });

    device.received(cardObj);

    const fixture = {};
    fixture.device = device;
    teardown(fixture);
    t.end();
  });

  suite.test('should set the readerType and the readerConnectionType to the apt values', (t) => {
    t.plan(2);
    const { device } = setup();
    t.equal(device.type, readerType.Magstripe);
    t.equal(device.connectionType, readerConnectionType.AudioJack);
    t.end();
  });
});

