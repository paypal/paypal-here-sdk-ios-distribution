/* global describe:false, it:false, before:false, after:false, beforeEach:false, afterEach:false*/

import {
  PaymentDevice,
  FormFactor,
} from 'retail-payment-device';
import mockery from 'mockery';
import FlowTestUtils from './FlowTestUtils';
import l10n from '../../../js/common/l10n';
import assert from 'assert';
import {
  retail as retailError,
} from '../../../js/common/sdkErrors';

describe('NFCFlow', () => {
  beforeEach(FlowTestUtils.setup);
  afterEach(FlowTestUtils.cleanup);

  it('nfc payment happy path', (done) => {
    const setup = FlowTestUtils.prepareFlow({
      isSignatureRequired: true,
      invoiceCurrency: 'USD',
      invoiceTotal: 10.0,
      formFactor: FormFactor.EmvCertifiedContactless,
    });
    const NfcFlow = require('../../../js/flows/CreditCardFlow').default;

    // Act
    const flow = new NfcFlow(setup.card, setup.txContext, () => {
      setup.flowState.addStep('complete');
    });
    assert(flow);

    // Assert the sequence of steps
    setup.flowState.beginAssert()
      .start('alert', l10n('EMV.Processing'))
      .isFollowedImmediatelyBy('device-display', PaymentDevice.Message.Processing)
      .isFollowedBy('tx-saveInvoice')
      .isFollowedBy('step-mtp')
      .isFollowedBy('step-signature')
      .isFollowedBy('alert', l10n('EMV.Finalize'))
      .isFollowedBy('step-ftp')
      .isFollowedBy('device-display', PaymentDevice.Message.Paid)
      .isFollowedBy('step-receipt')
      .isFollowedImmediatelyBy('complete');

    done();
  });

  it('nfc payment should prompt for receipt if payment step is aborted', (done) => {
    const setup = FlowTestUtils.prepareFlow({
      isSignatureRequired: true,
      invoiceCurrency: 'USD',
      invoiceTotal: 10.0,
      formFactor: FormFactor.EmvCertifiedContactless,
      alertWindowActions: [{
        title: l10n('Tx.Alert.GenericError.Title'),
        buttonToTap: l10n('Ok'),
      }],
    });
    const expectedError = new Error('Payment Declined');

    // MTP aborts
    mockery.registerMock('./steps/MerchantTakePaymentStep', FlowTestUtils.Sandbox.stub().returns({
      flowStep: (flow) => {
        setup.flowState.addStep('step-mtpAbort');
        flow.abortFlow(expectedError);
      },
    }));

    const NfcFlow = require('../../../js/flows/CreditCardFlow').default;

    // Act
    assert(new NfcFlow(setup.card, setup.txContext, (e) => {
      // Assert the sequence of steps
      setup.flowState.beginAssert()
        .start('alert', l10n('EMV.Processing'))
        .isFollowedImmediatelyBy('device-display', PaymentDevice.Message.Processing)
        .isFollowedBy('tx-saveInvoice')
        .isFollowedBy('step-mtpAbort')
        .isFollowedBy('device-display', PaymentDevice.Message.TransactionCancelled)
        .isFollowedBy('alert', l10n('Tx.Alert.GenericError.Title'))
        .isFollowedBy('step-updateInvoice');
      done();
    }));
  });

  it('acquirer wants user to fallback to insert/swipe', (done) => {
    const setup = FlowTestUtils.prepareFlow({
      isSignatureRequired: true,
      invoiceCurrency: 'USD',
      invoiceTotal: 10.0,
      formFactor: FormFactor.EmvCertifiedContactless,
    });
    const error =  retailError.nfcPaymentDeclined;

    // MTP aborts
    mockery.registerMock('./steps/MerchantTakePaymentStep', FlowTestUtils.Sandbox.stub().returns({
      flowStep: (flow) => {
        setup.flowState.addStep('step-mtpContactlessNotPossible');
        flow.data.tx = { errorCode: 600075 }; // Contactless tx not acceptable
        flow.abortFlow(error);
      },
    }));

    const NfcFlow = require('../../../js/flows/CreditCardFlow').default;

    // Act
    assert(new NfcFlow(setup.card, setup.txContext, (e) => {
      setup.flowState.addStep('complete', e);
    }));

    // Assert the sequence of steps
    setup.flowState.beginAssert()
      .start('alert', l10n('EMV.Processing'))
      .isFollowedImmediatelyBy('device-display', PaymentDevice.Message.Processing)
      .isFollowedBy('tx-saveInvoice')
      .isFollowedBy('step-mtpContactlessNotPossible')
      .isFollowedBy('alert', l10n('Tx.Alert.NfcPaymentDeclined.Title'));
    done();
  });
});
