import {
  FormFactor,
} from 'retail-payment-device';
import FlowStep from './FlowStep';
import * as messageHelper from '../messageHelper';

/**
 * Wait for the card to be removed from the reader before continuing.
 */
export default class RemoveCardStep extends FlowStep {

  constructor(context) {
    super();
    this.context = context;
  }

  execute(flow) {
    const cardContext = this.context.card;
    if (cardContext && cardContext.formFactor === FormFactor.Chip) {
      cardContext.reader.waitForCardRemoval(() => {
        if (flow.data.alert) {
          flow.data.alert.dismiss();
          delete flow.data.alert;
        }
        flow.next();
      });
      messageHelper.showRemoveCardMessage(this.context, flow.data, (alert) => {
        flow.data.alert = alert;
      });
    } else {
      flow.next();
    }
  }
}
