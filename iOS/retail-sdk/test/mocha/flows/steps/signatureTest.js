"use strict";

import chai from 'chai';
import sinon from 'sinon';
import assert from 'assert';
import TransactionContext from '../../../../js/transaction/TransactionContext';
import {
  PaymentDevice,
  CardDataUtil,
  CardIssuer,
  FormFactor,
} from 'retail-payment-device';
import { Invoice, Currency } from 'paypal-invoicing';
import {
  transaction as transactionError,
} from '../../../../js/common/sdkErrors';
import Merchant from '../../../../js/common/Merchant';
import SignatureStep from '../../../../js/flows/steps/SignatureStep';
import l10n from '../../../../js/common/l10n';

let expect = chai.expect,
    should = chai.should(),
    fs = require('fs'),
    mockery = require('mockery'),
    testUtils = require('../../../testUtils');

const Message = PaymentDevice.Message;

describe('Signature step', () => {
    let signatureBlob = 'SIGNATURE_BYTES',
        sinonSandbox, spyCollectSignature;

    before(() => chai.config.includeStack = true);
    beforeEach(setup);
    afterEach(cleanup);

    it('should collect signature for truthy values of card.isSignatureRequired', (done) => {

        //Given
        let flowData = {},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {
            //Then
            flowData.signature.should.deep.equal(signatureBlob);
            spyCollectSignature.should.have.been.calledWith({
                done: l10n('Done'),
                footer: l10n('Sig.Footer'),
                title: l10n('Sig.Title', {
                    amount: `£1.00`,
                    cardIssuer: CardDataUtil.getCardIssuerDisplayName(cardMetaData.cardIssuer),
                    lastFour: cardMetaData.lastFourDigits
                }),
                signHere: l10n('Sig.Here'),
                cancel: l10n('Cancel')
            });
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should not collect signature for falsy values of card.isSignatureRequired', (done) => {

        //Given
        let flowData = {},
            cardMetaData = getCardMetadata({ isSignatureRequired : false }),
            context = getContext(cardMetaData),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {
            expect(flowData.signature).to.be.undefined;
            spyCollectSignature.should.not.have.been.called;
            done();
        });

        signatureFlow.start();
    });

    it('should use custom signature collector when provided', (done) => {

        //Given
        let flowData = {},
            context = getContext(true),
            customHandler = { handler : (handler) => { handler.continueWithSignature(signatureBlob); } },
            spyCustomHandler = sinonSandbox.spy(customHandler, 'handler'),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        context.setSignatureCollector(customHandler.handler);
        signatureFlow.on('completed', () => {

            //Then
            spyCollectSignature.should.not.have.been.called; // Should NOT invoke default signature collector
            spyCustomHandler.should.have.been.calledOnce;
            flowData.signature.should.deep.equal(signatureBlob);
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should indicate paid status on reader for swipe payments', (done) => {

        //Given
        let flowData = {tx : {transactionNumber: '1'}},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData, FormFactor.MagneticCardSwipe, true),
            readerDisplaySpy = sinonSandbox.spy(context.card.reader, 'display'),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {

            //Then
            readerDisplaySpy.should.have.been.calledWith({
                id: Message.SignatureForNonEmv,
                substitutions: {
                    amount: `£1.00`
                },
            });
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should indicate paid status on reader for contactless msd payments', (done) => {

        //Given
        let flowData = {tx : {transactionNumber: '1'}},
          cardMetaData = getCardMetadata({ isSignatureRequired : true, isContactlessMSD : true }),
          context = getContext(cardMetaData, FormFactor.EmvCertifiedContactless, true),
          readerDisplaySpy = sinonSandbox.spy(context.card.reader, 'display'),
          signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {

            //Then
            readerDisplaySpy.should.have.been.calledWith({
                id: Message.SignatureForNonEmv,
                substitutions: {
                    amount: `£1.00`
                },
            });
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should prompt to not remove card for insert transaction', (done) => {

        //Given
        let flowData = {tx : {transactionNumber: '1'}},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData, FormFactor.Chip),
            readerDisplaySpy = sinonSandbox.spy(context.card.reader, 'display'),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {

            //Then
            readerDisplaySpy.should.have.been.calledWith({
                id: Message.SignatureForInsert,
                substitutions: {
                    amount: `£1.00`
                },
            });
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should not indicate paid status on reader for tap payments', (done) => {

        //Given
        let flowData = {},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData, FormFactor.EmvCertifiedContactless),
            readerDisplaySpy = sinonSandbox.spy(context.card.reader, 'display'),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {

            //Then
            readerDisplaySpy.should.have.been.calledWith({
                id: Message.SignatureForTap,
                substitutions: {
                    amount: `£1.00`
                },
            });
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should not allow paid transactions to be cancelled', (done) => {


        //Given
        let flowData = {tx : {transactionNumber: '1'}},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData, FormFactor.MagneticCardSwipe, true),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        signatureFlow.on('completed', () => {

            //Then
            spyCollectSignature.should.have.been.calledWith({
                done: l10n('Done'),
                footer: l10n('Sig.Footer'),
                title: l10n('Sig.Title', {
                    amount: `£1.00`,
                    cardIssuer: CardDataUtil.getCardIssuerDisplayName(cardMetaData.cardIssuer),
                    lastFour: cardMetaData.lastFourDigits
                }),
                signHere: l10n('Sig.Here'),
                cancel: null
            });

            done();
        });

        //When
        signatureFlow.start();
    });

    it('should abort the transaction on pressing cancel button', (done) => {

        //Given
        let flowData = {},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context)),
            expectedError = transactionError.customerCancel;

        //Simulate Cancel transaction button press from App
        require('manticore').collectSignature = (opts, cb) => { cb(null, null, true); };
        require('manticore').alert = (opt, cb) => {
            let handle = {
                dismiss: sinonSandbox.stub()
            };
            cb(handle, 0);
        };
        let spyAlert = sinonSandbox.spy(require('manticore'), 'alert');

        signatureFlow.on('aborted', (data) => {

            //Then
            assert.deepEqual(data.error, expectedError);
            spyAlert.should.have.been.calledWith({
                title: l10n('Tx.Alert.Cancel.Title'),
                message: l10n('Tx.Alert.Cancel.Msg'),
                buttons: [l10n('Yes')],
                cancel: l10n('No')
            });
            done();
        });

        //When
        signatureFlow.start();
    });

    it('should dismiss screen when a transaction is aborted', (done) => {

        //Given
        let flowData = {},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context)),
            sigHandle = { dismiss: sinonSandbox.stub() };

        //By not invoking the callback, simulate a signature collection screen that is in an open state
        require('manticore').collectSignature = (opts, cb) => { return sigHandle; };
        signatureFlow.on('aborted', () => {

            //Then
            sigHandle.dismiss.should.have.been.called;
            done();
        });

        //When
        signatureFlow.start();
        require('manticore').setTimeout(() => signatureFlow.abortFlow(new Error()), 0);
    });

    it('should prompt any custom signature collectors to dismiss on transaction abort', (done) => {

        //Given
        let flowData = {},
            cardMetaData = getCardMetadata({ isSignatureRequired : true }),
            context = getContext(cardMetaData),
            signatureFlow = testUtils.mockFlow(flowData, new SignatureStep(context));

        let customHandler = {
            handler: (sigHandler) => sigHandler.on('cancelled', done)
        };
        context.setSignatureCollector(customHandler.handler);

        //When
        signatureFlow.start();
        require('manticore').setTimeout(() => signatureFlow.abortFlow(new Error()), 0);
    });

    function getCardMetadata(config) {
        return {
            isSignatureRequired: config && config.isSignatureRequired,
            cardIssuer: CardIssuer.Visa,
            lastFourDigits: '7777',
            isContactlessMSD: config && config.isContactlessMSD
        };
    }

    function getContext(cardMetaData, formFactor = FormFactor.EmvCertifiedContactless, paymentComplete = false) {
        let invoice = new Invoice('GBP'),
            merchant = new Merchant(),
            context = new TransactionContext(invoice, merchant);

        invoice.addItem('item-1', 1, 1, '1', '1');
        context.card = testUtils.mockInstrument(formFactor, cardMetaData);
        context.flow = { paymentComplete };
        return context;
    }

    function setup(done) {
        sinonSandbox = sinon.sandbox.create();
        require('manticore').collectSignature = () => {};
        spyCollectSignature = sinonSandbox.stub(require('manticore'), 'collectSignature', (opts, cb) => {
            process.nextTick(() => cb(null, signatureBlob));
        });
        done();
    }

    function cleanup() {
        sinonSandbox.restore();
        testUtils.releaseHttp();
    }
});