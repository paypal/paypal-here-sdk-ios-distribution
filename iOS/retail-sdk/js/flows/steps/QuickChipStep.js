import {
  FormFactor, PaymentDevice,
} from 'retail-payment-device';
import log from 'manticore-log';
import FlowStep from './FlowStep';
import * as messageHelper from '../messageHelper';

const Log = log('flow.step.qc');
const AuthCode = PaymentDevice.authCode;

/**
 * Handles Quick Chip Steps,
 * . Send 'Z3' auth code to reader
 * . Send "Remove card" message to he reader
 * . Remove cardRemoved listener
 */
export default class QuickChipStep extends FlowStep {

  constructor(context) {
    super();
    this.context = context;
    this.card = context.card;
  }

  execute(flow) {
    const cbStepComplete = (error, rz) => {
      flow.data.cardResponse = rz;

      messageHelper.showRemoveCardForQCMessage(this.context, flow.data, (alert) => {
        flow.data.alert = alert;
        flow.next();
      });
    };
    if (this.card && this.card.formFactor === FormFactor.Chip) {
      this._pushAuthCode(AuthCode.NoNetwork, this.card, cbStepComplete);
    } else {
      flow.next();
    }
  }

  _pushAuthCode(authCode, card, cb) {
    Log.debug(() => `Pushing authCode: ${authCode} to ${card.reader.id}`);
    card.reader.completeTransaction(authCode, (error, rz) => {
      card.qcAuthSend = true;
      cb(null, rz);
    });
  }
}

