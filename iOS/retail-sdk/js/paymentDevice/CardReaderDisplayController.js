import log from 'manticore-log';
import { PaymentDevice } from 'retail-payment-device';

const Log = log('paymentDevice.displayController');

class CardReaderDisplayController {
  constructor() {
    this._lastDisplayCommand = {};
  }

  /**
   * Updates the card reader display only when the provided priority is greater than the priority of the most recent
   * display command that was pushed to the card reader
   * @param {int} priority
   * @param {PaymentDevice} cardReader
   * @param {object} displayArgs
   * @param {function} [cb]
   */
  display(priority, cardReader, displayArgs, cb) {
    let needsUpdate = false;
    const lastCommand = this._lastDisplayCommand[cardReader.id];
    if (!lastCommand) {
      Log.debug(() => `Will push ${displayArgs.id} to ${cardReader.id} as no previous commands were found`);

      // If the device disconnects at a later point, clear the prevailing state during the disconnect
      cardReader.once(PaymentDevice.Event.disconnected, () => delete this._lastDisplayCommand[cardReader.id]);
      needsUpdate = true;
    } else if (lastCommand.priority > priority) {
      Log.debug(() => `Will NOT push ${priority}:${displayArgs.id} to ${cardReader.id} as last pushed command ${lastCommand.priority}:${lastCommand.displayArgs.id} was higher in priority`);
      needsUpdate = false;
    } else {
      Log.debug(() => `Will push ${priority}:${displayArgs.id} to ${cardReader.id} as last pushed command ${lastCommand.priority}:${lastCommand.displayArgs.id} was lower in priority`);
      needsUpdate = true;
    }

    if (needsUpdate) {
      this._lastDisplayCommand[cardReader.id] = {
        priority,
        displayArgs,
      };
      cardReader.display(displayArgs, (err) => {
        if (err) {
          delete this._lastDisplayCommand[cardReader.id];
        }
        if (cb) {
          cb(err);
        }
      });
    }
  }

  resetAll() {
    this._lastDisplayCommand = {};
  }
}

const displayController = new CardReaderDisplayController();
export default displayController;
