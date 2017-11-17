import { ReceiptOptionsViewContent } from '../../../../js/transaction/ReceiptViewContent';
import TransactionContext from '../../../../js/transaction/TransactionContext';
import {
  deviceError,
  deviceErrorDomain,
  TransactionType,
} from 'retail-payment-device';
import assert from 'assert';
import Merchant from '../../../../js/common/Merchant';

let chai = require('chai'),
    fs = require('fs'),
    testUtils = require('../../../testUtils'),
    l10n = require('../../../../js/common/l10n').default,
    ReceiptStep = require('../../../../js/flows/steps/ReceiptStep').default;

describe('Receipt presentation', () => {
  let transactionNumber = 1, payerCustomerId = 2, payerReceiptPreferenceToken = 'token', payPalId = 3,
      currency = 'GBP', total = 1.0,
      receiptRequest, merchant, alertOpt, offerReceiptOpt, manticore;

  before(() => {
    chai.config.includeStack = true;
  });

  beforeEach(setup);
  afterEach(cleanup);

  it('should use different messages for each transaction type', (done) => {
    let cancelError = { code : deviceError.paymentCancelled.code , domain : deviceErrorDomain },
        otherError = {},
        paymentSuccessContent = new ReceiptOptionsViewContent(1),
        paymentFailureContent = new ReceiptOptionsViewContent(2, false, otherError),
        paymentCancelContent = new ReceiptOptionsViewContent(3, false, cancelError),
        refundSuccessContent = new ReceiptOptionsViewContent(4, true),
        refundFailureContent = new ReceiptOptionsViewContent(5, true, otherError),
        allContent = [paymentSuccessContent, paymentFailureContent, paymentCancelContent, refundSuccessContent, refundFailureContent];

    // Compare each message against each other to check duplicated content
    for (let i = 0; i < allContent.length - 1; i++) {
      for (let j = i+1; j < allContent.length; j++) {
        assert.notEqual(allContent[i].message, allContent[j].message);
      }
    }
    done();
  });

  it('should use different icons for success and failure', (done) => {
    let paymentSuccessContent = new ReceiptOptionsViewContent(1),
        paymentFailureContent = new ReceiptOptionsViewContent(1, false, {});

    assert.notEqual(paymentSuccessContent.titleIconFilename, paymentFailureContent.titleIconFilename);
    done();
  });

  it('should build content that reflects the parameters it is given', (done) => {
    let amount = 'AMOUNT',
        maskedEmail = 'maskedEmail',
        maskedPhone = 'maskedPhone',
        testContent = new ReceiptOptionsViewContent(amount, false, false, maskedEmail, maskedPhone);

    assert(testContent.title.indexOf(amount) !== -1);
    assert.equal(testContent.maskedEmail, maskedEmail);
    assert.equal(testContent.maskedPhone, maskedPhone);
    done();
  });

  it('should forward receipt to an email Id', (done) => {

    //Given
    let data = setupFlowData({receiptTarget: {name: 'emailOrSms', value: 'pphsdk2211@gmail.com'}}),
      tx = data.tx,
      receiptFlow = testUtils.mockFlow({tx}, new ReceiptStep(data.context));
    setupReceiptAlert(data.receiptTarget);

    //When
    receiptFlow.start();

    //Then
    receiptFlow.on('completed',() => {
      receiptRequest.should.deep.equal({invoiceId : payPalId,
                                        email : data.receiptTarget.value,
                                        customerId : payerCustomerId,
                                        receiptPreferenceToken : payerReceiptPreferenceToken,
                                        transactionType: 'SALE'});
      alertOpt.showActivity.should.equal(true);
      alertOpt.title.should.equal('Sending Receipt...');
      done();
    });
  });

  it('should forward receipt to phone number', (done) => {

    //Given
    let data = setupFlowData({receiptTarget: {name: 'emailOrSms', value: '+19792094603'}}),
        tx = data.tx,
        receiptFlow = testUtils.mockFlow({tx}, new ReceiptStep(data.context));
    setupReceiptAlert(data.receiptTarget);

    //When
    receiptFlow.start();

    //Then
    receiptFlow.on('completed',() => {
      receiptRequest.should.deep.equal({invoiceId: payPalId,
                                        phoneNumber: data.receiptTarget.value,
                                        customerId: payerCustomerId,
                                        receiptPreferenceToken: payerReceiptPreferenceToken,
                                        transactionType: 'SALE'});
      alertOpt.showActivity.should.equal(true);
      alertOpt.title.should.equal('Sending Receipt...');
      done();
    });
  });

  it('should not send a receipt when user declines', (done) => {

    //Given
    let data = setupFlowData({}),
        tx = data.tx,
        receiptFlow = testUtils.mockFlow({tx}, new ReceiptStep(data.context));
    setupReceiptAlert(data.receiptTarget);

    //When
    receiptFlow.start();

    //Then
    receiptFlow.on('completed',() => {
      receiptRequest.should.be.empty;
      alertOpt.should.be.empty;
      done();
    });
  });

  it('should forward refund receipt to an email Id', (done) => {

    //Given
    let data = setupFlowData({receiptTarget: {name: 'emailOrSms', value: 'pphsdk2211@gmail.com'}, isRefund: true}),
        tx = data.tx,
        receiptFlow = testUtils.mockFlow({tx}, new ReceiptStep(data.context));
    setupReceiptAlert(data.receiptTarget);

    //When
    receiptFlow.start();

    //Then
    receiptFlow.on('completed',() => {
      receiptRequest.should.deep.equal({invoiceId : payPalId,
                                        email : data.receiptTarget.value,
                                        customerId : payerCustomerId,
                                        receiptPreferenceToken : payerReceiptPreferenceToken,
                                        transactionType: 'REFUND'});
      alertOpt.showActivity.should.equal(true);
      alertOpt.title.should.equal('Sending Receipt...');
      done();
    });
  });

  it('should build content that reflects the additional receipt options', (done) => {
    let amount = 'AMOUNT',
      maskedEmail = 'maskedEmail',
      maskedPhone = 'maskedPhone',
      additionalReceiptOptions = ["Print", "Blah"],
      testContent = new ReceiptOptionsViewContent(amount, false, false, maskedEmail, maskedPhone, additionalReceiptOptions);

    assert.equal(testContent.additionalReceiptOptions.length, additionalReceiptOptions.length);
    assert.equal(testContent.additionalReceiptOptions[0], additionalReceiptOptions[0]);
    assert.equal(testContent.additionalReceiptOptions[1], additionalReceiptOptions[1]);
    done();
  });

  it('should invoke additional receipt options handler callback when an additional receipt option is selected', (done) => {
    //Given
    let data = setupFlowData({receiptTarget: {name: 'Print', value: 0}}),
      tx = data.tx;
    let context = new TransactionContext(data.invoice, data.merchant);
    context.setAdditionalReceiptOptions(['Print'], (val, name, txRecord) => {
      //Then
      assert.equal(val, 0);
      assert.equal(name, 'Print');
      receiptRequest.should.be.empty;
      alertOpt.should.be.empty;
      done();
    });

    let receiptFlow = testUtils.mockFlow({tx}, new ReceiptStep(context));
    setupReceiptAlert(data.receiptTarget);

    //When
    receiptFlow.start();
  });

  function setup() {
    receiptRequest = {};
    alertOpt = {};
    offerReceiptOpt = {};
    manticore = require('manticore');
    testUtils.seizeHttp().addLoginHandlers('GB', 'GBP');
    testUtils.addRequestHandler('retail', `checkouts/${transactionNumber}/sendReceipt`, 'POST', (options, callback) => {
      receiptRequest = JSON.parse(options.body);
      process.nextTick(() => {
        callback(null, {
          headers: {},
          statusCode: 200,
          body: { }
        })});
    });
    merchant = new Merchant();
    merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', () => {
      Merchant.active = merchant;
    });
    manticore.alert = (opt, cb) => {
      alertOpt = opt;
      return { dismiss : () => {} }
    };
  }

  function setupReceiptAlert(receiptTarget) {
    manticore.offerReceipt = (options, cb) => {
      offerReceiptOpt = options;
      process.nextTick(() => {
        cb(null, receiptTarget);
      });
    }
  }

  function setupFlowData(flowData) {
    let invoice = { payPalId, currency, total },
        maskedEmail = flowData.maskedEmail,
        maskedPhone = flowData.maskedPhone,
        tx = testUtils.mockTxRecord({ transactionNumber, payerCustomerId, payerReceiptPreferenceToken, maskedEmail, maskedPhone}),
        receiptTarget = flowData.receiptTarget,
        context = {
          isRefund: ()=> {
            return (typeof flowData.isRefund !== 'undefined') ? flowData.isRefund : false;
          },
          invoice,
          emit: ()=> {
            // A dummy emit method.
          }
        };

    tx.isRefund = () => (flowData.isRefund);

    if (flowData.isRefund) {
      context.type = TransactionType.Refund;
    }

    return {invoice, tx, receiptTarget, context};
  }

  function cleanup() {
    testUtils.releaseHttp();
  }
});
