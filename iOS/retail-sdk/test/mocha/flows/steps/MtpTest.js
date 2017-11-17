import {
  PaymentDevice,
  deviceError,
  FormFactor,
} from 'retail-payment-device';
import Merchant from '../../../../js/common/Merchant';
import MTP from '../../../../js/flows/steps/MerchantTakePaymentStep';
import PaymentType from '../../../../js/transaction/PaymentType';

let chai = require('chai'),
    should = chai.should(),
    sinon = require('sinon'),
    fs = require('fs'),
    testUtils = require('../../../testUtils'),
    l10n = require('../../../../js/common/l10n').default;

describe('Merchant take payment', () => {

    let merchant, invoice, actualCardRequest, spySandbox;
    const paymentType = PaymentType.card;

    before(() => {
        chai.config.includeStack = true;
    });

    beforeEach(setup);
    afterEach(cleanup);

    it('should build requests for emv contact tx as expected', (done) => {
        //Given
        let  pinPresent = true,
          apduData = 'miura-terminal-apdu',
          card = testUtils.mockInstrument(FormFactor.Chip, {apduData}),
          flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, pinPresent, paymentType }));

        //When
        flow.start();

        //Then
        actualCardRequest.paymentType.should.equal('card');
        actualCardRequest.card.should.deep.equal({
            "pinPresent": pinPresent,
            "reader": {
                "deviceModel" : "M010",
                "vendor": "MIURA",
                "readerSerialNumber": "readerSerialNumber"
            },
            "emvData": apduData,
            "inputType": "chip",
        });

        done();
    });

    it('should build requests for contactless chip tx as expected', (done) => {

        //Given a contact less chip
        let pinPresent = true,
            apduData = 'miura-terminal-apdu', isEmv = true,
            card = testUtils.mockInstrument(FormFactor.EmvCertifiedContactless, { isEmv, apduData }),
            flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, pinPresent, paymentType }));

        //When
        flow.start();

        //Then
        actualCardRequest.paymentType.should.equal('card');
        actualCardRequest.card.should.deep.equal({
            "pinPresent": pinPresent,
            "reader": {
                "deviceModel" : "M010",
                "vendor": "MIURA",
                "readerSerialNumber": "readerSerialNumber"
            },
            "emvData": apduData,
            "inputType": 'contactless_chip',
        });

        done();
    });

    it('should build requests for contactless msd tx as expected', (done) => {

        //Given a contact less chip
        let pinPresent = true,
            apduData = 'miura-terminal-apdu', isEmv = false,
            isContactlessMSD = true,
            card = testUtils.mockInstrument(FormFactor.EmvCertifiedContactless, {isEmv, apduData, isContactlessMSD}),
            flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, pinPresent, paymentType }));

        //When
        flow.start();

        //Then
        actualCardRequest.paymentType.should.equal('card');
        actualCardRequest.card.should.deep.equal({
            "pinPresent": pinPresent,
            "reader": {
                "deviceModel" : "M010",
                "vendor": "MIURA",
                "readerSerialNumber": "readerSerialNumber"
            },
            "emvData": apduData,
            "inputType": 'contactless_msd',
        });

        done();
    });

    it('should build requests for magnetic tx as expected', (done) => {

        //Given a contact less chip
        let card = testUtils.mockInstrument(FormFactor.MagneticCardSwipe, { track1 : 'track1', track2 : 'track2' }),
            flow = testUtils.mockFlow({}, new MTP({ merchant, invoice, card, paymentType }));

        //When
        flow.start();

        //Then
        actualCardRequest.paymentType.should.equal('card');
        actualCardRequest.card.should.deep.equal({
            "reader": {
                "deviceModel" : "M010",
                "vendor": "MIURA",
                "keySerialNumber": "keySerialNumber",
                "readerSerialNumber": "readerSerialNumber"
            },
            "track1": "track1",
            "track2": "track2",
            "inputType": "swipe",
        });

        done();
    });

    it('should abort on error response', (done) => {

        //Given an error response for MTP request
        let authCode = '8A023635', errorCode = 600075,
            card = testUtils.mockInstrument(FormFactor.Chip, {apduData:'apuData'}),
            deviceSpy = spySandbox.spy(card.reader, 'completeTransaction'),
            flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, paymentType }));
            mockMtpResponse({statusCode : 500, errorCode , authCode });

        flow.on('aborted', (data) => {

            //Then
            data.tx.authCode.should.equal(authCode);
            data.tx.errorCode.should.equal(errorCode);
            deviceSpy.should.have.been.calledWith(authCode);
            done();
        });

        //When
        flow.start();
    });

    it('should fall back to default success auth code it is not received in a success response', (done) => {

        //Given
        let card = testUtils.mockInstrument(FormFactor.Chip, {apduData: 'apduData'}),
            flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, paymentType })),
            deviceSpy = spySandbox.spy(card.reader, 'completeTransaction');

        mockMtpResponse({statusCode : 200, authCode : undefined, errorCode : undefined });

        flow.on('completed', () => {
            deviceSpy.should.have.been.calledWith('8A023030'); //Default Success Auth code was pushed to terminal
            done();
        });

        //When
        flow.start();
    });

    it('should fall back to default failure auth code it is not received in a error response', (done) => {

        //Given
        let card = testUtils.mockInstrument(FormFactor.Chip, {apduData: 'apduData'}),
            flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, paymentType })),
            deviceSpy = spySandbox.spy(card.reader, 'completeTransaction');
        mockMtpResponse({statusCode : 500, authCode : undefined, errorCode : 500 });

        flow.on('aborted', () => {
            deviceSpy.should.have.been.calledWith('8A023035'); //Default Failure Auth code was pushed to terminal
            done();
        });

        //When
        flow.start();
    });

    it('should void payment and push auth code if tx was aborted while MTP request is in flight', (done) => {

        //Given
        let card = testUtils.mockInstrument(FormFactor.Chip, {apduData:'apduData'}),
            spyVoidFunc = spySandbox.spy(),
            flow = testUtils.mockFlow({ isEmv: true }, new MTP({ merchant, invoice, card, paymentType}, spyVoidFunc)),
            deviceSpy = spySandbox.spy(card.reader, 'completeTransaction'),
            authCode = '8A023635';

        testUtils.addRequestHandler('retail', 'checkouts', 'POST', (options, callback) => {
            flow.data.error = new Error(); // Flow erred out when MTP request was in flight
            process.nextTick(() => {
                callback(null, {
                    headers: {},
                    statusCode: 200,
                    body: {
                        authCode: authCode,
                        message: {}
                    }
                })
            });

            process.nextTick(() => {
                //Then
                deviceSpy.should.have.been.calledWith(authCode);
                spyVoidFunc.should.have.been.calledWith(flow.data);
                done();
            });
        });

        //When
        flow.start();
    });

    it('should abort flow if pushing auth code returns an error', (done) => {

        //Given
        let card = testUtils.mockInstrument(FormFactor.Chip, {apduData: 'apduData'}),
          spyVoidFunc = spySandbox.spy(),
          expectedError = deviceError.contactIssuer,
          flow = testUtils.mockFlow({ isEmv: true }, new MTP({merchant, invoice, card, paymentType}, spyVoidFunc)),
          authCode = '8A023635';
        const apduResponse = {apdu: {template: 0XE5, data: {}, sw1: 0x90, sw2: 0}};

        mockMtpResponse({statusCode: 200, authCode});
        sinon.stub(card.reader, 'completeTransaction', (authCode, callback) => {
            authCode.should.equal(authCode);
            callback(expectedError, apduResponse);
        });

        flow.on('aborted', (data) => {
            data.cardResponse.should.equal(apduResponse);
            data.tx.authCode.should.equal(authCode);
            data.error.code.should.equal(expectedError.code);
            spyVoidFunc.should.not.been.called; // Listener to flow abort event will take care of voiding the tx
            done();
        });

        //When
        flow.start();
    });

    it('should build requests a cash trxn as expected', (done) => {
        //Given
        let flow = testUtils.mockFlow({ isEmv: false }, new MTP({ merchant, invoice, paymentType: PaymentType.cash }));

        //When
        flow.start();

        //Then
        actualCardRequest.paymentType.should.equal('cash');
        actualCardRequest.should.deep.equal({
            "dateTime": actualCardRequest.dateTime,
            "latitude": 37.123,
            "longitude": -121.123,
            "paymentType": 'cash'
        });

        done();
    });

    it('should build requests a check trxn as expected', (done) => {
        //Given
        let flow = testUtils.mockFlow({ isEmv: false }, new MTP({ merchant, invoice, paymentType: PaymentType.check }));

        //When
        flow.start();

        //Then
        actualCardRequest.paymentType.should.equal('check');
        actualCardRequest.should.deep.equal({
            "dateTime": actualCardRequest.dateTime,
            "latitude": 37.123,
            "longitude": -121.123,
            "paymentType": 'check'
        });

        done();
    });

    function mockMtpResponse(response) {
        testUtils.addRequestHandler('retail', 'checkouts', 'POST', (options, callback) => {
            actualCardRequest = JSON.parse(options.body);
            process.nextTick(() => {
                callback(null, {
                    headers: {},
                    statusCode: response.statusCode,
                    body: {
                        authCode: response.authCode,
                        message : response.message,
                        errorCode : response.errorCode
                    }
                })});
        });
    }

    function setup(){
        spySandbox = sinon.sandbox.create();
        testUtils.seizeHttp().addLoginHandlers('GB', 'GBP');
        mockMtpResponse({statusCode : 200, authCode : '8A023030'});

        actualCardRequest = {};
        invoice = {paypalId : '11111111'};
        merchant = new Merchant();
        merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', () => {
            Merchant.active = merchant;
        });
        const manticore = require('manticore');
        manticore.getLocation = (cb) => {
            const location = {
                latitude: 37.123,
                longitude: -121.123,
            };
            cb(null, location);
        };
    }

    function cleanup() {
        spySandbox.restore();
        testUtils.releaseHttp();
        PaymentDevice.devices = [];
    }
});
