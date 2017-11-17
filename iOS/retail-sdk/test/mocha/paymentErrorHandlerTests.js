
'use strict';

import {
  PaymentDevice,
  deviceError,
  TransactionType,
  FormFactor,
} from 'retail-payment-device';
import {
  transaction as transactionError,
  retail as retailError,
} from '../../js/common/sdkErrors';
import { Invoice } from 'paypal-invoicing';
import TransactionContext from '../../js/transaction/TransactionContext';
import Merchant from '../../js/common/Merchant';
import PaymentErrorHandler from '../../js/flows/PaymentErrorHandler';
import l10n from '../../js/common/l10n';

var sinon = require('sinon'),
    fs = require('fs'),
    Action = PaymentErrorHandler.action,
    testUtils = require('../testUtils'),
    chai = require('chai'),
    expect = chai.expect,
    should = chai.should();

describe('Payment error handler', () => {

    let amount = 100.0, merchant, pd, manticore, sandbox, txContext, invoice,
        formattedAmount = {
            amount: '£100.00',
        };

    beforeEach(setup);
    afterEach(cleanup);

    function setup(done) {
        testUtils.seizeHttp().addLoginHandlers('GB', 'GBP');
        pd = testUtils.mockDevice('error-handler-device');
        manticore = require('manticore');
        sandbox = sinon.sandbox.create();
        merchant = new Merchant();
        merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', (err, m) => {
            merchant = m;
            done();
        });
        Invoice.DefaultCurrency = 'GBP';
        invoice = new Invoice();
        invoice.addItem('Test', 1, amount, 1);
        txContext = new TransactionContext(invoice, merchant);
        sandbox.spy(pd, 'display');
        txContext.promptForPaymentInstrument = () => {};
        sandbox.spy(txContext, 'promptForPaymentInstrument');
    }

    function cleanup(done) {
        sandbox.restore();
        testUtils.releaseHttp();
        PaymentDevice.devices = [];
        done();
    }
    // TODO : Revisit these test cases later, once we have a proper callback implementation.
    /* it('should allow cancellation of timed out nfc transaction', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.nfcTimeout;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.TimeOut.Title'),
                    buttonToTap : l10n('Tx.Alert.TimeOut.Button') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledOnce;
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.NfcTimeOut, substitutions: formattedAmount });
            done();
        })
    });

    it('should allow retry of timed-out nfc transaction', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
          error = deviceError.nfcTimeout;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.TimeOut.Title'),
                buttonToTap : l10n('Tx.Retry') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.retry);
            pd.display.should.have.been.calledOnce;
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.NfcTimeOut, substitutions: formattedAmount });
            txContext.promptForPaymentInstrument.should.have.been.calledWith();
            done();
        })
    }); */

    it('should retry with contact when nfc is not allowed on the presented card', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.nfcNotAllowed;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.NfcPaymentDeclined.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.retryWithInsertOrSwipe);
            process.nextTick(() => {
                pd.display.should.have.been.called;
                [...txContext.promptForPaymentInstrument.args[0][1]].should.have.members([FormFactor.Chip, FormFactor.MagneticCardSwipe]);
                done();
            });
        })
    });

    it('should allow retry on card read fail', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.tryDifferentCard;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.TapDifferentCard.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.retry);
            pd.display.should.have.been.calledOnce;
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.UnableToReadNfcCard, substitutions: formattedAmount });
            txContext.promptForPaymentInstrument.should.have.been.calledWith();
            done();
        })
    });

    it('should allow cancellation of declined nfc transactions', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = retailError.nfcPaymentDeclined;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.NfcPaymentDeclined.Title'),
                buttonToTap : l10n('Cancel') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledTwice;
            pd.display.firstCall.should.have.been.calledWith({ id: PaymentDevice.Message.ReadyForInsertAndSwipePayment, substitutions: { amount: "£100.00" } });
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.NfcDecline, substitutions: null });
            done();
        })
    });

    it('should allow retry of declined nfc transaction', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = retailError.nfcPaymentDeclined;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.NfcPaymentDeclined.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.retryWithInsertOrSwipe);
            pd.display.should.have.been.calledTwice;
          pd.display.firstCall.should.have.been.calledWith({ id: PaymentDevice.Message.ReadyForInsertAndSwipePayment, substitutions: { amount: "£100.00" } });
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.NfcDecline, substitutions: null });
            [...txContext.promptForPaymentInstrument.args[0][1]].should.have.members([FormFactor.Chip, FormFactor.MagneticCardSwipe]);
            done();
        })
    });

    it('should abort nfc transactions that have exceeded maximum online pin retries', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = retailError.onlinePinMaxRetryExceed;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.BlockedCardTapped.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledOnce;
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.ContactIssuer, substitutions: formattedAmount });
            done();
        });
    });

    it('should retry nfc transaction when incorrect online PIN is entered', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = retailError.incorrectOnlinePin;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.IncorrectOnlinePin.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.retry);
            pd.display.should.have.been.calledOnce;
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.IncorrectPin, substitutions: formattedAmount });
            done();
        });
    });

    it('should prompt to contact issuer when blocked card was tapped', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.contactIssuer;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.BlockedCardTapped.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {
            process.nextTick(() => {

                //Then
                action.should.equal(Action.abort);
                pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.ContactIssuer, substitutions: formattedAmount });
                manticore.alert.should.have.been.calledWith({
                    title: l10n('Tx.Alert.BlockedCardTapped.Title'),
                    message: l10n('Tx.Alert.BlockedCardTapped.Msg'),
                    cancel: l10n('Ok')
                });
                done();
            });

        });
    });

    it('should retry contact transaction when incorrect online PIN is entered', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = retailError.incorrectOnlinePin;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.IncorrectOnlinePin.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };

        //When
        errorHandler.handle(error, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.retry);
            pd.display.should.have.been.calledOnce;
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.IncorrectPin, substitutions: formattedAmount });
            done();
        });
    });

    it('should fallback to swipe when emv contact is not allowed', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.mustSwipeCard;

        manticore.alert = (opt, cb) => {};
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.retryWithSwipe);
            pd.display.should.not.have.been.called;
            manticore.alert.should.have.been.calledOnce;
            manticore.alert.should.have.been.calledWith({
                title: l10n('Tx.Alert.ReadyForSwipeOnly.Title'),
                message: l10n('Tx.Alert.ReadyForSwipeOnly.Msg'),
                imageIcon: 'img_emv_swipe'
            });
            done();
        });
    });

    it('should prompt for retry of invalid chip', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.invalidChip;

        manticore.alert = () => {};
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.Chip, pd, (action) => {
            process.nextTick(() => {

                //Then
                action.should.equal(Action.retryWithInsertOrSwipe);
                pd.display.should.not.have.been.called;
                [...txContext.promptForPaymentInstrument.args[0][1]].should.have.members([FormFactor.MagneticCardSwipe, FormFactor.Chip]);
                manticore.alert.should.have.been.calledWith({
                    title: l10n('Tx.Alert.UnsuccessfulInsert.Title'),
                    message: l10n('Tx.Alert.UnsuccessfulInsert.Msg')
                });
                done();
            });
        });
        pd.emit(PaymentDevice.Event.cardRemoved);
    });

    it('should prompt for swipe when maxing out on invalid chip retries', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.invalidChip;

        txContext.retryCountInvalidChip = 3;
        manticore.alert = () => {};
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.retryWithSwipe);
            pd.display.should.not.have.been.called;
            txContext.promptForPaymentInstrument.should.not.have.been.called;
            manticore.alert.should.have.been.calledWith({
                title: l10n('Tx.Alert.ReadyForSwipeOnly.Title'),
                message: l10n('Tx.Alert.ReadyForSwipeOnly.Msg'),
                imageIcon: 'img_emv_swipe',
                cancel: l10n('Cancel')
            });
            done();
        });
    });

    it('should prompt to contact issuer when blocked card was swiped', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.contactIssuer;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.BlockedCardSwiped.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.MagneticCardSwipe, pd, (action) => {
            process.nextTick(() => {

                //Then
                action.should.equal(Action.abort);
                pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.ContactIssuer, substitutions: formattedAmount });
                manticore.alert.should.have.been.calledWith({
                    title: l10n('Tx.Alert.BlockedCardSwiped.Title'),
                    message: l10n('Tx.Alert.BlockedCardSwiped.Msg'),
                    cancel: l10n('Ok')
                });
                done();
            });

        });
    });

    it('should prompt to insert on swiping a chip card', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = transactionError.cannotSwipeChipCard;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.ChipCardSwiped.Title'),
                buttonToTap : l10n('Ok') }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.MagneticCardSwipe, pd, (action) => {
            process.nextTick(() => {

                //Then
                action.should.equal(Action.retryWithInsert);
                [...txContext.promptForPaymentInstrument.args[0][1]].should.have.members([FormFactor.Chip]);
                pd.display.should.not.have.been.called;
                manticore.alert.should.have.been.calledWith({
                    title: l10n('Tx.Alert.ChipCardSwiped.Title'),
                    message: l10n('Tx.Alert.ChipCardSwiped.Msg'),
                    cancel: l10n('Ok')
                });
                done();
            });

        });
    });

    it('should ignore contactless abort from card insert', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.contactlessPaymentAbortedByCardInsert;

        manticore.alert = () => {};
        sandbox.spy(manticore, 'alert');

        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {
            pd.display.should.not.have.been.called;
            expect(action).to.be.null;
            manticore.alert.should.not.have.been.called;
            done();
        });
    });

    it('should ignore contactless abort from card swipe', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.contactlessPaymentAbortedByCardSwipe;

        manticore.alert = () => {};
        sandbox.spy(manticore, 'alert');

        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {
            pd.display.should.not.have.been.called;
            expect(action).to.be.null;
            manticore.alert.should.not.have.been.called;
            done();
        });
    });

    it('swipe payment called error should push message to terminal', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.paymentCancelled;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.Cancelled.Title'),
                buttonToTap : l10n('Done') }], opt, cb);
        };

        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.MagneticCardSwipe, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedAmount });
            manticore.alert.should.have.been.calledWith({
              title: l10n('Tx.Alert.Cancelled.Title'),
              message: l10n('Tx.Alert.Cancelled.Msg'),
              cancel: l10n('Done')
            });
            done();
        });
    });

    it('insert payment called error should push message to terminal', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.paymentCancelled;

        manticore.alert = (opt, cb) => {
          return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.Cancelled.Title'),
            buttonToTap : l10n('Done') }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedAmount });
            manticore.alert.should.have.been.calledWith({
              title: l10n('Tx.Alert.Cancelled.Title'),
              message: l10n('Tx.Alert.Cancelled.Msg'),
              cancel: l10n('Done')
            });
             done();
        });
    });

    it('tap payment called error should push message to terminal', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
            error = deviceError.paymentCancelled;

        manticore.alert = (opt, cb) => {
          return testUtils.mockAlertViewButtonTap([{ title : l10n('Tx.Alert.Cancelled.Title'),
            buttonToTap : l10n('Done') }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.EmvCertifiedContactless, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedAmount });
            manticore.alert.should.have.been.calledWith({
              title: l10n('Tx.Alert.Cancelled.Title'),
              message: l10n('Tx.Alert.Cancelled.Msg'),
              cancel: l10n('Done')
            });
             done();
        });
    });

    it('should display generic payment failed error message for unknown errors from a payment', (done) => {

        //Given
        let errorHandler = new PaymentErrorHandler(txContext),
          unknownError = new Error();

        unknownError.domain = 'unknown';
        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{
                title: l10n('Tx.Alert.GenericError.Title'),
                buttonToTap: l10n('Ok')
            }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(unknownError, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedAmount });
            manticore.alert.should.have.been.calledWith({
                title: l10n('Tx.Alert.GenericError.Title'),
                message: l10n('Tx.Alert.GenericError.PaymentMessage'),
                cancel: l10n('Ok')
            });
            done();
        });
    });

    it('should display generic refund failed error message for unknown errors from a refund', (done) => {

        //Given
        txContext.type = TransactionType.Refund;
        let errorHandler = new PaymentErrorHandler(txContext),
          unknownError = new Error();

        unknownError.domain = 'unknown';
        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{
                title: l10n('Tx.Alert.GenericError.Title'),
                buttonToTap: l10n('Ok')
            }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(unknownError, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.TransactionCancelled, substitutions: formattedAmount });
            manticore.alert.should.have.been.calledWith({
                title: l10n('Tx.Alert.GenericError.Title'),
                message: l10n('Tx.Alert.GenericError.RefundMessage'),
                cancel: l10n('Ok')
            });
            done();
        });
    });

    it('should display card mismatch error message for error from refund on card not used for original payment', (done) =>{

        //Given
        txContext.type = TransactionType.Refund;
        let errorHandler = new PaymentErrorHandler(txContext),
            error = transactionError.refundCardMismatch;

        manticore.alert = (opt, cb) => {
            return testUtils.mockAlertViewButtonTap([{
                title : l10n('Tx.Alert.Refund.CardMismatch.Title'),
                buttonToTap: l10n('Ok')
            }], opt, cb);
        };
        sandbox.spy(manticore, 'alert');

        //When
        errorHandler.handle(error, FormFactor.Chip, pd, (action) => {

            //Then
            action.should.equal(Action.abort);
            pd.display.should.have.been.calledWith({ id: PaymentDevice.Message.RefundCardMismatch, substitutions: formattedAmount });
            manticore.alert.should.have.been.calledWith({
                title: l10n('Tx.Alert.Refund.CardMismatch.Title'),
                message: l10n('Tx.Alert.Refund.CardMismatch.Msg'),
                cancel: l10n('Ok')
            });
             done();
        });
    });
});
