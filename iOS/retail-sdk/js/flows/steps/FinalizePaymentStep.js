import log from 'manticore-log';
import {
  network as networkError,
  payPalError,
  domain,
} from '../../common/sdkErrors';
import FlowStep from './FlowStep';
import Merchant from '../../common/Merchant';

const Log = log('flow.step.mft');

export default class FinalizePaymentStep extends FlowStep {
  constructor(context) {
    super();
    this.context = context;
    this.isContaclessMSDTransaction = context.card.isContactlessMSD;
  }

  execute(flow) {
    if (flow.data.error) {
      Log.warn('Skipping Finalize payment. Reason: One/more of previous steps logged an error');
      flow.next();
      return;
    }

    if (!flow.data.signature) {
      if (!flow.data.cardResponse || this.isContaclessMSDTransaction) {
        Log.debug('Skipping Finalize payment');
        flow.next();
        return;
      }
    }
    const rq = this.buildRequest(flow);
    Log.debug(`MFT request:\n${JSON.stringify(rq, null, 4)}`);
    Merchant.active.request({
      service: 'retail',
      op: `checkouts/${flow.data.tx.transactionHandle}`,
      format: 'json',
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rq),
    }, (err, finalizeRz) => {
      let mftError = err;
      const apiErrorCode = finalizeRz && finalizeRz.body && finalizeRz.body.errorCode;
      if (apiErrorCode) {
        // Give priority to here-api errors
        mftError = payPalError(domain.retail, apiErrorCode, finalizeRz.body.message)
            .withDebugId(finalizeRz.body.correlationId);
      }
      Log.debug(`MFT response:\n${JSON.stringify(finalizeRz, null, '\t')}\n`);
      let sdkError = null;
      if (!finalizeRz || mftError) {
        Log.error(`MFT Error: ${JSON.stringify(mftError)}, Invoice Total: ${this.context.invoice.currency} ${this.context.invoice.total}\n ${JSON.stringify(finalizeRz)}`);
        sdkError = mftError || networkError.requestFailed;
        flow.abortFlow(sdkError);
        return;
      }

      if (!finalizeRz.body) {
        flow.abortFlow(networkError.requestFailed);
        return;
      }

      flow.data.tx.updateFromFinalize(finalizeRz.body);
      Log.info(`(${this.context.id}) Finalize payment response received for invoice total: ${this.context.invoice.currency} ${this.context.invoice.total}, ${flow.data.tx.toString()}`);
      flow.next();
    });
  }

  buildRequest(flow) {
    // TODO get the signature if available...
    const rq = { invoiceId: this.context.invoice.payPalId };
    // For contactless msd transactions, we should not be sending the emv data. Otherwise, the backend would throw an invoice already paid error.
    if (flow.data.cardResponse && !this.isContaclessMSDTransaction) {
      rq.emvData = flow.data.cardResponse.apdu.data.toString('hex');
      rq.responseCode = flow.data.tx.responseCode;
    }
    if (flow.data.signature) {
      rq.signature = flow.data.signature.toString('utf-8');
    }
    return rq;
  }
}
