import log from 'manticore-log';
import moment from 'moment';
import FlowStep from './FlowStep';
import Merchant from '../../common/Merchant';
import * as retailSDKUtil from '../../common/retailSDKUtil';
import {
  transaction as transactionError,
} from '../../common/sdkErrors';

const Log = log('flow.step.checkRefundEligibility');

export default class CheckRefundEligibilityFlowStep extends FlowStep {

  constructor(context) {
    super();
    this.context = context;
  }

  execute(flow) {
    if (!this.context.card) {
      flow.next();
      return;
    }

    if (flow.data.error) {
      Log.warn('Skip Issuing refund. Reason: One/more of previous steps logged an error');
      flow.next();
      return;
    }

    const rq = this._buildRequest(flow);
    Merchant.active.request({
      service: 'retail',
      op: `checkouts/${flow.data.transactionNumber}/validateCard`,
      format: 'json',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rq),
    }, (error, refundResponse) => {
      let actualError = null;
      if (!error && refundResponse.body && refundResponse.body.status !== 'ELIGIBLE') {
        actualError = transactionError.refundCardMismatch;
      }
      flow.nextOrAbort(actualError);
    });
  }

  _buildRequest() {
    return {
      invoiceId: this.context.invoice.payPalId,
      dateTime: moment().format('YYYY-MM-DDTHH:mm:ssZZ'),
      card: retailSDKUtil.hereAPICardDataFromCard(this.context.card),
    };
  }
}
