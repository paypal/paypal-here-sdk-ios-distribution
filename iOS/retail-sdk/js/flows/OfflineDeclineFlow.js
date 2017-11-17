import log from 'manticore-log';
import Flow from '../common/flow';
import ReceiptFlowStep from './steps/ReceiptStep';
import l10n from '../common/l10n';
import { showSimpleMessage } from './messageHelper';
import * as retailSDKUtils from '../common/retailSDKUtil';

const Log = log('flow.OfflineDeclineFlow');

export default class OfflineDeclineFlow {
  constructor(err, context, callback) {
    this.err = err;
    this.context = context;
    this.callback = callback;
    Log.debug('Initializing Offline Decline Flow');
  }

  startFlow() {
    showSimpleMessage(l10n('Cancelling transaction..', ''), null, false, this);
    this.cancellationFlow = new Flow(this, [
      function saveInvoiceStep(flow) {
        this.context.invoice.isCancelled = retailSDKUtils.transactionCancelledError(this.err);
        this.context.invoice.isFailed = true;
        this.context.invoice.save((e) => {
          if (e) {
            Log.error(`Unable to save invoice. Error: ${e}\n${JSON.stringify(this.context.invoice, null, 4)}`); // eslint-disable-line max-len
            this.context.end(e, null);
            flow.abortFlow(e);
            return;
          }
          flow.next();
        });
      },
      new ReceiptFlowStep(this.context).flowStep,
    ]);

    this.cancellationFlow.data.error = this.err;
    this.cancellationFlow.on('ended', data => this.callback(data));
    this.cancellationFlow.start();
  }
}
