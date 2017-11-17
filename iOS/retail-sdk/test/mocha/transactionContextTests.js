"use strict";

import fs from 'fs';
import { EventEmitter } from 'events';
import {
  PaymentDevice,
  MagneticCard,
  deviceError,
  FormFactor,
  CardPresentEvent,
} from 'retail-payment-device';
import { Invoice } from 'paypal-invoicing';
import Merchant from '../../js/common/Merchant';
import * as messageHelper from '../../js/flows/messageHelper';
import DeviceSelector from '../../js/paymentDevice/DeviceSelector';
import TransactionBeginOptions from '../../js/transaction/TransactionBeginOptions';

let mockery = require('mockery'),
    sinon = require('sinon'),
    assert = require('assert'),
    l10n = require('../../js/common/l10n').default,
    testUtils = require('../testUtils'),
    FeatureMapJson = require('../../resources/feature-map.json');

//ToDo - Offering software update
describe('Transaction context', () => {

    let sdk, TransactionContext, manticore, merchant, sinonSandbox, alertStub,
        events = [
            PaymentDevice.Event.cancelled,
            PaymentDevice.Event.cardPresented,
            PaymentDevice.Event.cancelRequested
        ];

    beforeEach(setup);
    afterEach(cleanup);

    it('should activate all contactless readers on beginning a tx', (done) => {

        // Given
        let devices = getDevices({count : 2}),
            deviceSpies = registerSpies(devices),
            invoice = buildInvoice('GBP', 10.0);

        // we activate only one device so we gotta select one!
        DeviceSelector.selectDevice(devices[0].id); // select the device-0!
        let txContext = new TransactionContext(invoice, merchant),
            expectedFormFactors = [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless];

        // When
        txContext.begin(true);

        // Then
        setTimeout(() => {
            assert.ok(deviceSpies[0].activateForPayment.calledWith(txContext, expectedFormFactors));
            assert.equal(deviceSpies[0].abortTransaction.callCount, 0);
            done();
        });
    });

    it('should listen to events on all connected devices on beginning a tx', (done) => {

        // Given
        let devices = getDevices({count : 2}),
            deviceSpies = registerSpies(devices),
            invoice = buildInvoice('GBP', 10.0);

        // we activate only one device so we gotta select one!
        DeviceSelector.selectDevice(devices[0].id); // select the device-1!
        let txContext = new TransactionContext(invoice, merchant);

        // When
        txContext.begin(true);

        // Then
        setTimeout( () => {
            for (let e of events) {
                assert.ok(deviceSpies[0].eventRegisterListener.calledWith(e));
            }
            done();
        })
    });

    it('should prompt the user for payment on beginning a transaction', (done) => {

        // Given
        let invoice = buildInvoice('GBP', 10.0),
            device = testUtils.mockDevice('device-0'),
            txContext = new TransactionContext(invoice, merchant),
            expectedTransactionPromptAlert = {'title': l10n('Tx.Alert.Ready.Title'),
                'message': l10n('Tx.Alert.Ready.Msg'),
                'imageIcon': 'img_emv_insert_tap_swipe',
                'cancel': l10n('Cancel')
            };

        // When
        txContext.begin(true);

        // Then
        setTimeout(() => {
            assert.ok(alertStub.calledWith(expectedTransactionPromptAlert));
            device.removed();
            done();
        });
    });

    // TODO : Revisit these test cases later, once we have a proper callback implementation.
    /* it('should end transaction when user cancels tx after a contactless timeout event', (done) => {

        // Given
        let device = testUtils.mockDevice('device-0'),
            invoice = buildInvoice('GBP', 10.0),
            txContext = new TransactionContext(invoice, merchant),
            deviceSpy = registerSpy(device),
            error = deviceError.nfcTimeout,
            expectedTimeOutAlert = {
                title: l10n('Tx.Alert.TimeOut.Title'),
                message: l10n('Tx.Alert.TimeOut.Msg'),
                buttons: [l10n('Tx.Retry')],
                cancel: l10n('Tx.Alert.TimeOut.Button')
            };

        alertStub.withArgs(expectedTimeOutAlert).onCall(0).yields(null, 1);

        // When
        txContext.begin(true);
        emitEvent(device, PaymentDevice.Event.cardPresented, [error, null, FormFactor.EmvCertifiedContactless], () => {
            // Then
            assert.equal(deviceSpy.abortTransaction.callCount, 0);
            for(let e of events) {
                assert.equal(EventEmitter.listenerCount(device, e), 0, 'Context should have stopped listening for payment events');
            }
            done();
        }, error, device);
    });

    it('should restart a tx if user wants to retry payment after a contactless timeout event', (done) => {

        // Given
        let device = testUtils.mockDevice('device-0'),
            invoice = buildInvoice('GBP', 10.0),
            txContext = new TransactionContext(invoice, merchant),
            deviceSpy = registerSpy(device),
            error = deviceError.nfcTimeout,
            expectedTimeOutAlert = {
                title: l10n('Tx.Alert.TimeOut.Title'),
                message: l10n('Tx.Alert.TimeOut.Msg'),
                buttons: [l10n('Tx.Retry')],
                cancel: l10n('Tx.Alert.TimeOut.Button')
            },
            expectedTransactionPromptAlert = {'title': l10n('Tx.Alert.Ready.Title'),
                'message': l10n('Tx.Alert.Ready.Msg'),
                'imageIcon': 'img_emv_insert_tap_swipe',
                'cancel': l10n('Cancel')
            };

        alertStub.withArgs(expectedTimeOutAlert).onCall(0).yields(null, 0);

        // When
        txContext.begin(true);
        setTimeout(() => {
            emitEvent(device, PaymentDevice.Event.cardPresented, [error, null, FormFactor.EmvCertifiedContactless], () => {
                // Then
                assert.equal(deviceSpy.abortTransaction.callCount, 0, 'Should not deactivate on retry');
                assert.equal(alertStub.withArgs(expectedTransactionPromptAlert).callCount, 2, 'Should prompt for payment twice');
                done();
            }, error, device);
        });
    }); */

    it('should prompt user to fallback to contact tx when card read failed', (done) => {
        // Given
        let devices = getDevices({count : 2}),
            invoice = buildInvoice('GBP', 10.0),
            txContext = new TransactionContext(invoice, merchant),
            error = deviceError.nfcNotAllowed,
            expectedPaymentDeclinedError = {
                'title': l10n('Tx.Alert.NfcPaymentDeclined.Title'),
                'message': l10n('Tx.Alert.NfcPaymentDeclined.Msg'),
                'cancel': l10n('Cancel'),
                'buttons': [l10n('Ok')]
            };

        // When
        DeviceSelector.selectDevice(devices[0].id);
        txContext.begin(true);

        setTimeout(() => {
            emitEvent(devices[0], PaymentDevice.Event.cardPresented, [error, null, FormFactor.EmvCertifiedContactless], () => {
                // Then
                assert.ok(alertStub.calledWith(expectedPaymentDeclinedError));
                done();
            }, error, devices[0]);
        });
    });

    it('should end tx when user chooses to cancel tx after an error', (done) => {
        // Given
        let devices = getDevices({count : 2}),
            deviceSpies = registerSpies(devices),
            invoice = buildInvoice('GBP', 10.0),
            txContext = new TransactionContext(invoice, merchant),
            txCardEventSpy = sinonSandbox.spy(),
            error = deviceError.nfcTimeout,
            expectedTimeOutAlert = {
                title: l10n('Tx.Alert.TimeOut.Title'),
                message: l10n('Tx.Alert.TimeOut.Msg'),
                buttons: [l10n('Tx.Retry')],
                cancel: l10n('Tx.Alert.TimeOut.Button')
            };

        txContext.on(PaymentDevice.Event.cardPresented, txCardEventSpy);

        alertStub.withArgs(expectedTimeOutAlert).onCall(0).yields(null, 0);

        // When
        txContext.begin(true);
        emitEvent(devices[0], PaymentDevice.Event.cardPresented, [error, null, FormFactor.EmvCertifiedContactless], () => {
            // Then
            assert.equal(txCardEventSpy.callCount, 0);
            for(let spy of deviceSpies) {
                assert.equal(spy.abortTransaction.callCount, 0);
            }
            done();
        }, error, devices[0]);
    });

    it('should remove all registered device listeners when context is ended', (done) => {

        // Given
        let devices = getDevices({count : 2}), invoice = buildInvoice('GBP', 10.0),
            txContext = new TransactionContext(invoice, merchant);
        txContext.begin(true);

        // When
        txContext.end();

        // Then
        for(let device of devices) {
            for(let e of events) {
                assert.equal(EventEmitter.listenerCount(device, e), 0, 'Context should have stopped listening for payment events');
            }
            assert.equal(EventEmitter.listenerCount(sdk, 'deviceDiscovered'), 0, 'Context should have stopped listening for new devices');
        }

        done();
    });

    it('should not accept card insert payments if Chip is not a preferred form factor', (done) => {

        // Given
        let device = testUtils.mockDevice('device-0'), deviceSpy = registerSpy(device),
            invoice = buildInvoice('GBP', 10.0),
            txContext = new TransactionContext(invoice, merchant),
            expectedFormFactors = [ FormFactor.MagneticCardSwipe ],
            card = { formFactor: FormFactor.Chip },
            expectedSwipeOnlyAlert = {
                title: l10n('Tx.Alert.ReadyForSwipeOnly.Title'),
                message: l10n('Tx.Alert.ReadyForSwipeOnly.Msg'),
                imageIcon: 'img_emv_swipe'
            };
        const txOptions = new TransactionBeginOptions();
        txOptions.preferredFormFactors = expectedFormFactors;

        // When
        txContext.beginPaymentWithOptions(txOptions);

        // Then
        setImmediate(() => {
            // Only swipe form factor should be enabled
            assert.ok(deviceSpy.activateForPayment.calledWith(txContext, expectedFormFactors, undefined));

            // On inserting the card
            emitEvent(device, PaymentDevice.Event.cardPresented, [null, CardPresentEvent.cardDataRead, FormFactor.Chip, { card }], () => {
                // Most recent window should be the prompt to swipe the card
                assert.ok(alertStub.calledWith(expectedSwipeOnlyAlert));
                device.removed();
                done();
            }, card);
        });
    });

    it('should properly handle device event registration and de-registration when multiple tx contexts are active', (done) => {

        // Given
        let invoice1 = buildInvoice('GBP', 77.0), txContext1 = new TransactionContext(invoice1, merchant),
            invoice2 = buildInvoice('GBP', 777.0), txContext2 = new TransactionContext(invoice2, merchant),
            devices = getDevices({count : 3});

        // When
        DeviceSelector.selectDevice(devices[0].id); // select the device-1!
        txContext1.begin(true);
        txContext2.begin(true);

        // Then
        setTimeout(() => {
            // by default, the fist device is selected so only consider the First one.
            for(let e of events) {
                assert.equal(EventEmitter.listenerCount(devices[0], e), 1);
            }
        });

        // When
        setTimeout(() => {
            txContext1.end(true);
        });

        // Then
        setImmediate(() => {
            for(let device of devices) {
                for(let event of [PaymentDevice.Event.cardPresented, PaymentDevice.Event.error, PaymentDevice.Event.cancelled]) {
                    device.listeners(event).forEach((handler) => {
                        assert.equal(handler.txContextId, txContext2.id);
                    });
                }
            }
        });

        // When
        setTimeout(() => {
            txContext2.end(true);
        });

        // Then
        setTimeout(() => {
            for(let device of devices) {
                for(let e of events) {
                    assert.equal(device.listenerCount(e), 0, `Assert failed for event '${e}' on ${device.id}`);
                }
            }
            done();
        });
    });

    it('should not activate contactless reader when invoice amount is greater than contactless limit for the region', (done) => {

        // Given
        FeatureMapJson.GB.CONTACTLESS_LIMIT = 100;
        let invoice = buildInvoice('GBP', 101.0), txContext = new TransactionContext(invoice, merchant),
            device = testUtils.mockDevice('device-0'), deviceSpy = registerSpy(device),
            expectedFormFactors = [FormFactor.Chip, FormFactor.MagneticCardSwipe],
            expectedReadyForInsertAndSwipeOnlyAlert = {'title': l10n('Tx.Alert.ReadyForInsertOrSwipeOnly.Title'),
                'message': l10n('Tx.Alert.ReadyForInsertOrSwipeOnly.Msg'),
                'imageIcon': 'img_emv_insert_swipe',
                'cancel': l10n('Cancel')};

        // When
        txContext.begin(true);

        // Then
        setImmediate(() => {
            assert.ok(deviceSpy.activateForPayment.calledWith(txContext, expectedFormFactors));
            assert.ok(alertStub.calledWith(expectedReadyForInsertAndSwipeOnlyAlert));
            device.removed();
            done();
        });
    });

    it('should activate contactless reader when invoice amount exactly matches contactless limit for the region', (done) => {

        // Given
        FeatureMapJson.GB.CONTACTLESS_LIMIT = 100;
        let invoice = buildInvoice('GBP', 100.0), txContext = new TransactionContext(invoice, merchant),
            device = testUtils.mockDevice('device-0'), deviceSpy = registerSpy(device),
            expectedFormFactors = [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless],
            expectedPrompt = {
                'title': l10n('Tx.Alert.Ready.Title'),
                'message': l10n('Tx.Alert.Ready.Msg'),
                'imageIcon': 'img_emv_insert_tap_swipe',
                'cancel': l10n('Cancel')
            };

        // When
        txContext.begin(true);

        // Then
        assert.ok(device.activateForPayment.calledWith(txContext, expectedFormFactors));
        assert.ok(alertStub.calledWith(expectedPrompt));
        device.removed();
        done();
    });

    it('should never deactivate contactless reader when wild card character is used for contactless limit in feature map', (done) => {

        // Given
        FeatureMapJson.GB.CONTACTLESS_LIMIT = '*';
        let invoice = buildInvoice('GBP', Merchant.active.cardSettings.maximum), txContext = new TransactionContext(invoice, merchant),
            device = testUtils.mockDevice('device-0'), deviceSpy = registerSpy(device),
            expectedFormFactors = [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless],
            expectedPrompt = {
                'title': l10n('Tx.Alert.Ready.Title'),
                'message': l10n('Tx.Alert.Ready.Msg'),
                'imageIcon': 'img_emv_insert_tap_swipe',
                'cancel': l10n('Cancel')
            };

        // When
        txContext.begin(true);

        // Then
        setImmediate(() => {
            assert.ok(deviceSpy.activateForPayment.calledWith(txContext, expectedFormFactors));
            assert.ok(alertStub.calledWith(expectedPrompt));
            device.removed()
            done();
        });
    });

    it('should prompt for signature when invoice total is greater than or equal to signatureRequiredAbove value from merchant status', (done) => {

        // Given
        let invoice = buildInvoice('GBP', 150.0),
            txContext = new TransactionContext(invoice, merchant),
            swipedCard = new MagneticCard();

        swipedCard.reader = testUtils.mockDevice('device-0');
        merchant.cardSettings.signatureRequiredAbove = 150;
        txContext.paymentOptions = { tippingOnReaderEnabled: false };

        // When
        txContext.continueWithCard(swipedCard);

        // Then
        assert.ok(swipedCard.isSignatureRequired);
        swipedCard.reader.removed()
        done();
    });

    it('should not prompt for signature if Merchant.signatureRequiredAbove was used to increase the threshold', (done) => {

        // Given
        merchant.cardSettings.signatureRequiredAbove = 50;
        let invoice = buildInvoice('GBP', 51.0),
            txContext = new TransactionContext(invoice, merchant),
            swipedCard = new MagneticCard();

        swipedCard.reader = testUtils.mockDevice('device-0');
        txContext.paymentOptions = { tippingOnReaderEnabled: false };

        // When
        merchant.signatureRequiredAbove = 999;
        txContext.continueWithCard(swipedCard);

        // Then
        assert.ok(!swipedCard.isSignatureRequired);
        swipedCard.reader.removed();
        done();
    });

    it('should prompt for signature if Merchant.signatureRequiredAbove was used to always prompt for signature', (done) => {

        // Given
        merchant.cardSettings.signatureRequiredAbove = 50;
        let invoice = buildInvoice('GBP', 1.0),
            txContext = new TransactionContext(invoice, merchant),
            swipedCard = new MagneticCard();

        swipedCard.reader = testUtils.mockDevice('device-0');
        txContext.paymentOptions = { tippingOnReaderEnabled: false };

        // When
        merchant.signatureRequiredAbove = 0;
        txContext.continueWithCard(swipedCard);

        // Then
        assert.ok(swipedCard.isSignatureRequired);
        swipedCard.reader.removed()
        done();
    });

    it('should cancel transaction if amount is too low', (done) => {

        // Given
        merchant.cardSettings.minimum = 1.0;
        const invoice = buildInvoice('GBP', merchant.cardSettings.minimum - 0.01);
        const formattedAmount = messageHelper.formattedAmount(invoice.currency, merchant.cardSettings.minimum);
        let device = testUtils.mockDevice('device-0'),
          deviceSpy = registerSpy(device),
          txContext = new TransactionContext(invoice, merchant),
          expectedAlertArgs = {
              title: l10n('Tx.Alert.AmountTooLow.Title'),
              message: l10n('Tx.Alert.AmountTooLow.Msg', formattedAmount),
              cancel: l10n('Ok')
          };
        alertStub.withArgs(expectedAlertArgs).yieldsAsync(null, 0).returns({dismiss: () => {}});

        // When
        txContext.begin();
        emitEvent(device, PaymentDevice.Event.cardPresented, [null, null, FormFactor.MagneticCardSwipe], () => {
            // Then
            assert.ok(alertStub.calledWith(expectedAlertArgs));
            assert.ok(deviceSpy.display.calledWith({ id: PaymentDevice.Message.AmountTooLow, substitutions: formattedAmount }));
            device.removed();
            done();
        });
    });

    it('should cancel transaction if amount is too high', (done) => {

        // Given
        merchant.cardSettings.maximum = 10000.0;
        const invoice = buildInvoice('GBP', merchant.cardSettings.maximum + 0.01);
        const formattedAmount = messageHelper.formattedAmount(invoice.currency, merchant.cardSettings.maximum);
        let device = testUtils.mockDevice('device-1'),
          deviceSpy = registerSpy(device),
          txContext = new TransactionContext(invoice, merchant),
          expectedAlertArgs = {
              title: l10n('Tx.Alert.AmountTooHigh.Title'),
              message: l10n('Tx.Alert.AmountTooHigh.Msg', formattedAmount),
              cancel: l10n('Ok')
          };

        alertStub.withArgs(expectedAlertArgs).yieldsAsync(null, 0).returns({dismiss: () => {}});

        // When
        txContext.begin();

        emitEvent(device, PaymentDevice.Event.cardPresented, [null, null, FormFactor.MagneticCardSwipe], () => {
            // Then
            assert.ok(alertStub.calledWith(expectedAlertArgs));
            assert.ok(deviceSpy.display.calledWith({ id: PaymentDevice.Message.AmountTooHigh, substitutions: formattedAmount }));
            device.removed();
            done();
        });
    });

    it('should not allow cancellations for swipe payments', () => {
        // Given
        let device = testUtils.mockDevice('device-0'),
          invoice = buildInvoice('GBP', 10),
          txContext = new TransactionContext(invoice, merchant);

        // When
        txContext.card = { formFactor: FormFactor.MagneticCardSwipe, reader : device };

        // Then
        assert.equal(txContext.allowInProgressPaymentCancel, false, 'Magnetic card swipes cannot be cancelled');
    });

    it('should not allow cancellations for contactless msd payments', () => {
        // Given
        let device = testUtils.mockDevice('device-0'),
          invoice = buildInvoice('GBP', 10),
          txContext = new TransactionContext(invoice, merchant);

        // When
        txContext.card = { isContactlessMSD : true, formFactor: FormFactor.MagneticCardSwipe, reader : device };

        // Then
        assert.equal(txContext.allowInProgressPaymentCancel, false, 'MSD Contactless payments cannot be cancelled');
        device.removed();
    });

    function setup(done) {
        mockery.enable({
            warnOnReplace: false,
            warnOnUnregistered: false,
            useCleanCache: false
        });

        sdk = new EventEmitter();
        mockery.registerMock('../sdk', sdk);
        mockery.registerMock('./CreditCardFlow', () => {});
        TransactionContext = require('../../js/transaction/TransactionContext').default;
        testUtils.seizeHttp().addLoginHandlers('GB', 'GBP');
        merchant = new Merchant();
        merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', (err, m) => {
            Merchant.active = m;
            done();
        });
        sinonSandbox = sinon.sandbox.create();
        alertStub = sinonSandbox.stub();
        alertStub.returns({
            dismiss: () => {}
        });
        require('manticore').alert = alertStub;
    }

    function emitEvent(ee, event, args, cb) {
        process.nextTick(() => {
            ee.emit(event, ...args);
            process.nextTick(cb);
        });
    }

    function cleanup() {
        sinonSandbox.restore();
        testUtils.releaseHttp();
        PaymentDevice.devices = [];
        DeviceSelector._selectedPaymentDevice = null;
        testUtils.endMockery();
    }

    function registerSpy(device) {
        let newEventSpy = sinonSandbox.spy();
        device.on('newListener', newEventSpy);
        return {
            activateForPayment : sinonSandbox.spy(device, 'activateForPayment'),
            abortTransaction : sinonSandbox.spy(device, 'abortTransaction'),
            eventRegisterListener : newEventSpy,
            display : sinonSandbox.spy(device, 'display')
        };
    }

    function registerSpies(devices) {
        let spies = [];
        for(let device of devices) {
            spies.push(registerSpy(device));
        }

        return spies;
    }

    function getDevices(data) {
        let devices = [];
        for(let i=0; i < data.count; i++) {
            devices.push(testUtils.mockDevice(`device-${i}`));
        }

        return devices;
    }

    function buildInvoice(currencyCode, total) {
        let invoice = new Invoice(currencyCode);
        invoice.addItem('item', 1, total);
        return invoice;
    }
});
