/* global describe:false, it:false, before:false, after:false, beforeEach:false, afterEach:false*/

import mockery from 'mockery';
import l10n from '../../../js/common/l10n';
import {
  PaymentDevice,
  deviceError,
  FormFactor,
} from 'retail-payment-device';
import FlowTestUtils from './FlowTestUtils';
import testUtils from '../../testUtils';
import assert from 'assert';

describe('EmvFlow', () => {
  beforeEach(FlowTestUtils.setup);
  afterEach(FlowTestUtils.cleanup);

  it('emv payment happy path with card in slot', (done) => {
    const currency = 'USD';
    const total = 10.0;
    const formattedAmount = { amount: '$10.00' };
    const setup = FlowTestUtils.prepareFlow({
      isSignatureRequired: true,
      invoiceCurrency: currency,
      invoiceTotal: total,
      formFactor: FormFactor.Chip,
      cardInSlot: true,
    });
    const EmvFlow = require('../../../js/flows/CreditCardFlow').default;
    //TODO: Add completion steps in tape
    // Act
    const emvFlow = new EmvFlow(setup.card, setup.txContext, () => {
      // Assert the sequence of flow steps
      setup.flowState.beginAssert()
        .start('alert', l10n('EMV.DoNotRemove'))
        .isFollowedImmediatelyBy('device-display', PaymentDevice.Message.ProcessingContact)
        .isFollowedBy('tx-saveInvoice')
        .isFollowedBy('step-mtp')
        .isFollowedImmediatelyBy('step-signature')
        .isFollowedBy('alert', l10n('EMV.Finalize'))
        .isFollowedBy('step-ftp')
        //.isFollowedBy('alert', l10n('EMV.Complete', formattedAmount))
        .isFollowedBy('device-display', PaymentDevice.Message.Successful)
        //.isFollowedBy('step-removecard', l10n('EMV.Remove'))
        .isFollowedBy('terminal-softReset')
        .isFollowedBy('step-receipt');
      done();
    });
    assert(emvFlow);
  });


  it('emv payment happy path without card in slot', (done) => {
    /*
     Basically this tests the case where the card is removed during the '${amount} paid, please remove card' dialog
     pop up.
      */
    const currency = 'USD';
    const total = 10.0;
    const setup = FlowTestUtils.prepareFlow({
      isSignatureRequired: true,
      invoiceCurrency: currency,
      invoiceTotal: total,
      formFactor: FormFactor.Chip,
      cardInSlot: false,
    });

    const EmvFlow = require('../../../js/flows/CreditCardFlow').default;

    // Act
    const emvFlow = new EmvFlow(setup.card, setup.txContext, () => {
      // Assert the sequence of flow steps
      setup.flowState.beginAssert()
          .start('alert', l10n('EMV.DoNotRemove'))
          .isFollowedImmediatelyBy('device-display', PaymentDevice.Message.ProcessingContact)
          .isFollowedBy('tx-saveInvoice')
          .isFollowedBy('step-mtp')
          .isFollowedImmediatelyBy('step-signature')
          .isFollowedBy('alert', l10n('EMV.Finalize'))
          .isFollowedBy('step-ftp')
          .isFollowedBy('terminal-softReset')
          .isFollowedBy('step-receipt');
      done();
    });
    assert(emvFlow);
  });


  it('emv payment should prompt for receipt if payment step is aborted', (done) => {
    const currency = 'USD';
    const total = 10.0;
    const setup = FlowTestUtils.prepareFlow({
      isSignatureRequired: true,
      invoiceCurrency: currency,
      invoiceTotal: total,
      alertWindowActions: [{
        title: l10n('Tx.Alert.GenericError.Title'),
        buttonToTap: l10n('Ok'),
      }],
      formFactor: FormFactor.Chip,
    });

    // MTP aborts
    mockery.registerMock('./steps/MerchantTakePaymentStep', FlowTestUtils.Sandbox.stub().returns({
      flowStep: (flow) => {
        setup.flowState.addStep('step-mtpAbort');
        const error = deviceError.generic;
        flow.abortFlow(error);
      },
    }));

    const EmvFlow = require('../../../js/flows/CreditCardFlow').default;

    // Act
    const emvFlow = new EmvFlow(setup.card, setup.txContext, () => {
      // Assert the sequence of flow steps
      setup.flowState.beginAssert()
        .start('alert', l10n('EMV.DoNotRemove'))
        .isFollowedImmediatelyBy('device-display', PaymentDevice.Message.ProcessingContact)
        .isFollowedBy('tx-saveInvoice')
        .isFollowedBy('step-mtpAbort')
        .isFollowedBy('terminal-softReset')
        .isFollowedBy('step-updateInvoice');

      done();
    });
    assert(emvFlow);
  });

  // Void Tests

  const handleVoidAndSetState = (setState) => {
    testUtils.seizeHttp()
      .addRequestHandler('retail', 'checkouts/transactionHandle/void', 'POST',
      (options, callback) => {
        if (setState) {
          setState();
        }
        process.nextTick(() => {
          callback(null, {
            headers: {},
            statusCode: 200,
            body: {},
          });
        });
      });
  };

  it('emv payment should be voided if we encounter an error after getting a transaction handle',
    (done) => {
      const setup = FlowTestUtils.prepareFlow({
        isSignatureRequired: true,
        invoiceCurrency: 'USD',
        invoiceTotal: 10.0,
        formFactor: FormFactor.Chip,
        alertWindowActions: [{
          title: l10n('Tx.Alert.GenericError.Title'),
          buttonToTap: l10n('Ok'),
        }],
      });

      mockery.registerMock('./steps/SignatureStep', FlowTestUtils.Sandbox.stub().returns({
        flowStep: (flow) => {
          setup.flowState.addStep('step-signatureAbort');
          flow.abortFlow(new Error());
        },
      }));

      const merchantStub = FlowTestUtils.Sandbox.stub();
      merchantStub.active = setup.txContext.merchant;
      mockery.registerMock('../common/Merchant', merchantStub);

      let calledVoid = false;
      handleVoidAndSetState(() => {
        calledVoid = true;
      });

      const Ccflow = require('../../../js/flows/CreditCardFlow').default;
      const ccflow = new Ccflow(setup.card, setup.txContext, () => {
        process.nextTick(() => {
          assert.equal(calledVoid, true);
          done();
        });
      });
      assert(ccflow);
    });


  it('emv payment should void if we encounter an error before getting a transaction handle',
    (done) => {
      const setup = FlowTestUtils.prepareFlow({
        isSignatureRequired: true,
        invoiceCurrency: 'USD',
        invoiceTotal: 10.0,
        formFactor: FormFactor.Chip,
      });

      mockery.registerMock('./steps/MerchantTakePayment', FlowTestUtils.Sandbox.stub().returns({
        flowStep: (flow) => {
          setup.flowState.addStep('step-mtpabort');
          flow.abortFlow(new Error('MTP Failed'));
        },
      }));

      let calledVoid = false;
      handleVoidAndSetState(() => {
        calledVoid = true;
      });

      const Ccflow = require('../../../js/flows/CreditCardFlow').default;
      const ccflow = new Ccflow(setup.card, setup.txContext, () => {
        process.nextTick(() => {
          assert.equal(calledVoid, false);
          done();
        });
      });
      assert(ccflow);
    });

  it('emv payment should void if we successfully complete MTP after the payment has been aborted', (done) => {
      const setup = FlowTestUtils.prepareFlow({
        isSignatureRequired: true,
        invoiceCurrency: 'USD',
        invoiceTotal: 10.0,
        alertWindowActions: [{
          title: l10n('Tx.Alert.Cancelled.Title'),
          buttonToTap: l10n('Done'),
        }],
        skipMockingPaymentSteps: true,
        formFactor: FormFactor.Chip,
        allowInProgressPaymentCancel: true
      });
      setup.card.isEmv = () => (true);
      testUtils.seizeHttp().addRequestHandler('retail', 'checkouts', 'POST', (options, callback) => {
        setup.card.reader.emit(PaymentDevice.Event.cardRemoved);
        process.nextTick(() => {
          callback(null, {
            headers: {},
            statusCode: 200,
            body: { transactionHandle: 'transactionHandle' },
          });
        });
      });

      let calledVoid = false;
      handleVoidAndSetState(() => {
        calledVoid = true;
      });

      const merchantStub = FlowTestUtils.Sandbox.stub();
      merchantStub.active = setup.txContext.merchant;
      mockery.registerMock('../../common/Merchant', merchantStub);
      mockery.registerMock('../common/Merchant', merchantStub);

      const Ccflow = require('../../../js/flows/CreditCardFlow').default;
      const ccflow = new Ccflow(setup.card, setup.txContext, () => {
        require('manticore').setTimeout(() => {
          assert.equal(calledVoid, true);
          done();
        }, 10);
      });
      assert(ccflow);
  });
});
