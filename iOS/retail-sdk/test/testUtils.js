let Card = require('retail-payment-device').Card,
    DecisionRequired = require('retail-payment-device').DecisionRequired,
    MagneticCard = require('retail-payment-device').MagneticCard,
    Currency = require('paypal-invoicing').Currency,
    assert = require('assert'),
    mockery = require('mockery'),
    fs = require('fs');

import { MiuraParser } from 'miura-emv/build/Parser';
import { FormFactor } from 'retail-payment-device';
import MiuraDevice from 'miura-emv';
import TxRecord from '../js/transaction/TransactionRecord';
import Flow from '../js/common/flow';
import DeviceController from '../js/transaction/DeviceController'

class TestUtils {
    constructor() {
        this.handlers = {};
    }

    makeMockery() {
        mockery.enable({
            warnOnReplace: false,
            warnOnUnregistered: false,
            useCleanCache: true
        });

        if (process.env.PAYPAL_LOG_LEVEL) {
            require('manticore-log').Root.level = process.env.PAYPAL_LOG_LEVEL;
        }
    }

    endMockery() {
        mockery.disable();
    }

    seizeHttp() {
        if (!this.realHttp) {
            this.realHttp = require('manticore').http;
            require('manticore').http = (opts, cb) => this.http(opts, cb);
        }
        return this;
    }

    releaseHttp() {
        if (this.realHttp) {
            require('manticore').http = this.realHttp;
        }
        delete this.realHttp;
    }

    http(options, callback) {
        var canned = this.handlers[[options.service, options.op, options.method || 'GET'].join(' ')];
        if (!canned) {
            canned = this.handlers[options.url];
        }
        if (canned) {
            if (typeof(canned) === 'function') {
                canned(options, callback);
            } else {
                process.nextTick(() => callback(null, canned));
            }
        } else {
            console.log('Unknown HTTP request!', [options.service, options.op, options.method || 'GET'].join(' '));
            process.nextTick(() => callback(new Error('Request is not mocked. Returning error.')));
        }
    }

    addRequestHandler(service, op, method, result) {
        if (!method && !result) {
            // Short version with URL
            this.handlers[service] = op;
        } else {
            this.handlers[[service, op, method].join(' ')] = result;
        }
        return this;
    }

    addLoginHandlers(country, currency) {
        this.addRequestHandler('auth', 'userinfo?schema=openid', 'GET', this.merchantUserInfo(country))
            .addRequestHandler('retail', 'status', 'GET', this.merchantStatus(currency));
        return this;
    }

    testUserSetup(done) {
        var manticore = require('manticore'),
            debug = require('../js/debug'),
            Merchant = require('../js/common/Merchant').default;

        this.seizeHttp()
            .addLoginHandlers('GB', 'GBP')
            .addRequestHandler('retail', `merchant/v1/cardReaderDevice/miura/M010?country=GB&environment=${manticore.miuraSwRepo||'production'}&os=M000-TESTOS-7-6&mpi=M000-MPI-1-34`, 'GET', {
                body: {deviceUpdateInfoURL: 'http://paypal.com/M010Config'},
                statusCode: 200
            })
            .addRequestHandler('retail', `merchant/v1/cardReaderDevice/miura/M010?country=GB&environment=${manticore.miuraSwRepo||'production'}&os=M000-TESTOS-7-6&mpi=M000-MPI-1-34`, 'POST', {
                body: require('./data/m010_server_instruction'),
                statusCode: 200
            })
            .addRequestHandler('http://paypal.com/M010Config', {
                statusCode: 200,
                body: require('./data/m010_config')
            })
            .addRequestHandler('invoicing', 'invoices', 'POST', {
                statusCode: 200,
                body: {}
            })
            .addRequestHandler('retail', 'checkouts', 'POST', {
                statusCode: 200,
                body: {
                    authCode: '8a023030',
                    transactionHandle: "txHandle"
                }
            }).addRequestHandler('retail', 'checkouts/txHandle', 'PUT', {
                statusCode: 200,
                body: {
                    success: true,
                    transactionNumber: "txNumber"
                }
            });

        let merchant = new Merchant();
        merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', () => {
            Merchant.active = merchant;
            done(merchant);
        });
    }

    testUserCleanup() {
        this.releaseHttp();
    }

    mockInstrument(formFactor, data, reader) {

        let apduData = (data && data.apduData) ? data.apduData : require('./data/emvBlobs.json').M010.Contact.Insert.firstPacket;

        let card = new Card();
        if(formFactor === FormFactor.EmvCertifiedContactless) {
            card.isEmv = data ? !!data.isEmv : true;
            card.isContactlessMSD = data && data.isContactlessMSD;
            card.emvData = { apdu : { data : apduData } };
            card.isSignatureRequired = data ? data.isSignatureRequired : null;
        } else if (formFactor === FormFactor.Chip)  {
            card.isEmv = true;
            card.emvData = { apdu : { data : apduData } };
            card.isSignatureRequired = data ? data.isSignatureRequired : null;
        } else if(formFactor === FormFactor.MagneticCardSwipe) {
            card = new MagneticCard();
            card.isMSRFallbackAllowed = data.isFallbackSwipe;
            card.track1 = data.track1;
            card.track2 = data.track2;
            card.isSignatureRequired = data ? data.isSignatureRequired : null;
        }

        card.reader = reader || this.mockDevice('uniqueName');
        card.cardIssuer = data ? data.cardIssuer : null;
        card.lastFourDigits = data ? data.lastFourDigits : null;
        card.formFactor = formFactor;
        card.ksn = 'keySerialNumber';
        return card;
    }

    mockDeviceController(device) {
        let reader = {
          display: (opt, cb) => { cb && cb(); }
        };
        return {
          selectedDevice: reader,
          activate: () => {},
        };
    }

    mockDevice(deviceName, formFactors = [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless], cardInSlot) {
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
        let device = new MiuraDevice(deviceName, nativeInterface, appInterface);
        device.serialNumber = 'readerSerialNumber';
        device.terminal.Config._factors = formFactors;
        device.isReady = true;
        device.display = (opt, cb) => { cb && cb(); };
        device.activate = (ctx, opt) => {};
        device.abortTransaction = (context, cb) => {
            if(cb) {
                cb();
            }
        };
        device.completeTransaction = (authCode, cb) => { cb(null, { apdu: ''}); };
        device.cardInSlot = cardInSlot;
        MiuraDevice.discovered(device);
        device.connect();
        return device;
    }

    mockFlow(flowData, step) {
        let flow = new Flow(this, [step.flowStep]);
        flow.data = flowData;
        return flow;
    }

    mockTxRecord(data) {
        return new TxRecord({
            transactionNumber : data.transactionNumber,
            payerInfo : {
                customerId : data.payerCustomerId,
                receiptPreferenceToken : data.payerReceiptPreferenceToken,
                maskedEmail : data.maskedEmail,
                maskedPhone : data.maskedPhone
            }
        });
    }

    mockAlertViewButtonTap(windowActions, args, cb) {

        let alertViewHandle = {
            setTitle: () => {},
            dismiss: () => {}
        };

        if(windowActions === undefined || !Array.isArray(windowActions)) {
            return alertViewHandle;
        }

        //Mock end user alert window interactions
        let buttons = args.buttons ? args.buttons.slice() : [];
        if(args.cancel) {buttons.push(args.cancel)}

        for(let action of windowActions) {
            if(action.title !== args.title) { continue; }
            buttons.forEach((button, i) => {
                if(action.buttonToTap === button) {
                    process.nextTick(() => {
                        cb(alertViewHandle, i);
                    });
                    return alertViewHandle;
                }
            });
        }

        return alertViewHandle;
    }

    assertError(expected, actual){

        if(!expected) {
            assert(typeof actual === 'undefined', 'Expected undefined');
            return;
        }

        assert(actual instanceof Error, 'Should be an instance of Error');
        for (let key in expected) {
            if (expected.hasOwnProperty(key) && expected[key]) {
                assert.equal(actual[key], expected[key]);
            }
        }
    }

    getE0MediaData(miuraTags, imageId, messageId) {
        return {
            template: 0xe0,
            allRequired: true,
            assertOnUnmatched: true,
            tlvs: [
                {tag: miuraTags.MiuraMediaCoordinates, value: 0},
                {tag: miuraTags.MiuraImageData, value: imageId},
                {tag: miuraTags.MiuraMediaCoordinates, value: 50},
                {tag: miuraTags.MiuraTextData, value: (actual) => {
                    let expected = typeof(messageId) === 'function' ? messageId() : messageId;
                    assert.equal(expected, actual.parse());
                }}
            ]
        }
    }

    parsePaymentAppDecision(Tlv, e2RawData) {

        let buffer = new Buffer(e2RawData, 'hex'),
            response = (new MiuraParser())._readResponse(buffer),
            dr = new DecisionRequired(response),
            appId, appLabel;

        for (var i = 0; i < response.tlvs.values.length; i++) {
            var t = response.tlvs.values[i];
            if (t.tag.name === Tlv.Tags.TerminalApplicationIdentifier.name) {
                if (appId) {
                    dr.apps.push([appId, appLabel]);
                    appLabel = null;
                }
                appId = t.parse();
            } else if (t.tag.name === Tlv.Tags.ApplicationLabel.name) {
                if (appLabel && appId) {
                    dr.apps.push([appId, appLabel]);
                    appId = null;
                }
                appLabel = t.parse();
            }
        }
        if (appId) {
            dr.apps.push([appId, appLabel]);
        }
        dr.apdu = response.apdu;
        return dr;
    }

    getE0SelectApplication(Tlv, appIx, e2RawData) {
        let aid = this.parsePaymentAppDecision(Tlv, e2RawData).apps[appIx][0];
        return {
            template: 0xe0,
            allRequired: true,
            assertOnUnmatched: true,
            tlvs: [
                {
                    tag: Tlv.Tags.TerminalApplicationIdentifier, value: (actual) => {
                        assert.deepEqual(actual.parse(), aid);
                    }
                }
            ]
        }
    }

    getE0CommandData(Tlv, amount, currencyCode) {
        return {
            template: 0xe0,
            allRequired: true,
            assertOnUnmatched: true,
            tlvs: [
                {
                    tag: Tlv.Tags.TransactionSequenceCounter, value: (v) => {
                    v.bytes.length === 4;
                }
                },
                {tag: Tlv.Tags.AmountAuthorized, value: Currency.toCents(currencyCode, amount).toString()},
                {tag: Tlv.Tags.TransactionCurrencyCode, value: Currency.getCurrency(currencyCode).iso4217},
                {tag: Tlv.Tags.TransactionType, value: 0},
                {
                    tag: Tlv.Tags.TransactionDate, value: (v) => {
                    var d = v.parse(), now = new Date();
                    assert(now - d <= 60 * 60 * 24 * 1000 && now - d >= 0, `Date should be just before now (${now}) but is ${d}`);
                }
                },
                {
                    tag: Tlv.Tags.TransactionTime, value: (v) => {
                    var now = new Date(), txTime = new Date(), p = v.parse();
                    txTime.setSeconds(p.getSeconds());
                    txTime.setMinutes(p.getMinutes());
                    txTime.setHours(p.getHours());
                    assert(Math.abs(txTime - now) < 2000, `Time should be now (${now}) but is ${txTime}`);
                }
                }
            ]
        };
    }

    merchantUserInfo(country) {
        return {
            headers: {},
            statusCode: 200,
            body: {
                "family_name": "Chen",
                "verified": "true",
                "name": "Kalene Chen",
                "businessName": "Joe's Generic Business",
                "given_name": "Kalene",
                "user_id": "https://www.paypal.com/webapps/auth/identity/user/xXB95gQcM4utyLh1Kr9MLFG8BEWsU585NA5G3mE7tac",
                "address": {
                    "postal_code": "W12 4LQ",
                    "locality": "Wolverhampton",
                    "region": "West Midlands",
                    "country": country,
                    "street_address": "734 Park Avenue, 485 Ocean Avenue"
                },
                "language": "en_GB",
                "zoneinfo": "Europe/London",
                "locale": "en_GB",
                "phone_number": "06075583164",
                "email": "arun-uk-b12@paypal.com",
                "businessSubCategory": "General",
                "businessCategory": "Antiques"
            }
        };
    }

    merchantStatus(currency) {
        return {
            headers: {},
            statusCode: 200,
            body: {
                "status": "ready",
                "paymentTypes": ["tab", "key", "chip", "contactless_chip", "contactless_msd"],
                "cardSettings": {
                    "minimum": "1",
                    "maximum": "5500",
                    "signatureRequiredAbove": "50",
                    "unsupportedCardTypes": ["amex", "discover"]
                },
                "currencyCode": currency,
                "categoryCode": "5932",
                "businessCategoryExists": true
            }
        };
    };
}

module.exports = new TestUtils();
