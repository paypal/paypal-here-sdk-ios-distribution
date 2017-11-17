/**
 * Created by aravidas on 6/11/2015.
 */
"use strict";
var mockery = require('mockery'),
    FlowState = require('./FlowState'),
    sinon = require('sinon'),
    testUtils = require('../../testUtils'),
    PaymentDevice = require('retail-payment-device').PaymentDevice,
    fs = require('fs');

import PaymentType from '../../../js/transaction/PaymentType';

let _sandbox, _merchant;
class FlowTestUtils {

    static setup(done) {
        testUtils.testUserSetup((merchant) => {
            _merchant = merchant;
            testUtils.makeMockery();
            _sandbox = sinon.sandbox.create();
            done();
        });
    }

    static cleanup() {
        testUtils.testUserCleanup();
        mockery.deregisterAll();
        testUtils.endMockery();
        _sandbox.restore();
        PaymentDevice.devices = [];
    }

    static get Sandbox() { return _sandbox; }

    /**
     *
     * @param config - Configuration for the card reader simulator and transaction object
     *           config.isSignatureRequired
     *           config.invoiceCurrency
     *           config.invoiceTotal
     *           config.alertWindowActions - List of key value pairs <alert title>:<Button to tap>
     * @param cardInSlot - Optional parameter to specify if the card is still inserted in the slot at the
     *                      time of completing payment(finalize payment) or not.
     */
    static prepareFlow(config) {
        let flowState = FlowState().Init;
        var manticore = require('manticore');

        let miuraDevice = testUtils.mockDevice('miura-terminal', null, config.cardInSlot);
        let deviceController = testUtils.mockDeviceController(miuraDevice);
        let card = testUtils.mockInstrument(config.formFactor, config.cardData, miuraDevice);

        _sandbox.stub(miuraDevice, 'startPollForBattery', () => {
            flowState.addStep('startPollForBatteryStep');
        });

        _sandbox.stub(miuraDevice, 'stopPollForBattery', () => {
            flowState.addStep('stopPollForBatteryStep');
        });

        manticore.alert = (args, cb) => {
            flowState.addStep('alert', args.title);
            let handler = testUtils.mockAlertViewButtonTap(config.alertWindowActions, args, cb);
            handler.setTitle = (args) => { flowState.addStep('alert', args); };
            handler.setMessage = () => {};
            handler.dismiss = () => { flowState.addStep('alert-dismiss'); };
            return handler;
        };

        manticore.getLocation = (cb) => {
            const location = {
                latitude: 37.123,
                longitude: -121.123,
            };
            cb(null, location);
        };

        _sandbox.stub(miuraDevice, "abortTransaction", (a, cb) => {
            if(cb) { cb(); }
        });

        _sandbox.stub(miuraDevice, "display", (opt, cb) => {
            flowState.addStep('device-display', opt.id);
            if(opt.id === PaymentDevice.Message.PaidRemoveCard) {
                process.nextTick(() => {
                    miuraDevice.emit('cardRemoved');
                });
            }

            if(cb) { cb(); }
        });

        _sandbox.stub(miuraDevice.terminal, "softReset", (cb) => {
            flowState.addStep('terminal-softReset');
            if(cb) { cb(); }
        });

        let txContext = {
            merchant: _merchant,
            card: card,
            invoice : {
                currency : config.invoiceCurrency,
                total : config.invoiceTotal,
                save : (cb) => {
                    flowState.addStep('tx-saveInvoice');
                    if(cb) {cb();}
                }
            },
            isRefund: () => {
                return (typeof config.isRefund !== 'undefined') ? config.isRefund : false;
            },
            emit: () => {},
            allowInProgressPaymentCancel: config.allowInProgressPaymentCancel,
            paymentType: config.paymentType ? config.paymentType : PaymentType.card,
            deviceController,
            _reset: () => {},
            setPaymentState: () => {},
        };

        let mockFlowStep = (path, stepName, extraLogic) => {
            let step = _sandbox.stub().returns({
                flowStep : (flow) => {
                    if (extraLogic) {
                        extraLogic(flow);
                    }
                    flowState.addStep(stepName);
                    flow.next();
                }
            });
            mockery.registerMock(path, step);
        };

        if (!config.skipMockingPaymentSteps) {
            mockFlowStep('./steps/MerchantTakePaymentStep', 'step-mtp', (flow) => {
                flow.data.tx = {transactionHandle : 'transactionHandle'};
            });
            mockFlowStep('./steps/SignatureStep', 'step-signature');
            mockFlowStep('./steps/FinalizePaymentStep', 'step-ftp');
        }

        mockFlowStep('./steps/ReceiptStep', 'step-receipt');
        mockFlowStep('./steps/UpdateInvoicePaymentStep', 'step-updateInvoice')

        return { flowState, card, txContext };
    }
}

module.exports = FlowTestUtils;
