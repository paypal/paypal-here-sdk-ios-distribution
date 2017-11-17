import manticore from 'manticore';
import log from 'manticore-log';
import {
  CardPresentEvent,
  FormFactor,
  PaymentDevice,
  deviceError,
} from 'retail-payment-device';
import * as Util from 'manticore-util';
import { Tags } from 'tlvlib';
import TransactionEvent from './transactionEvent';
import PaymentErrorHandler from '../flows/PaymentErrorHandler';
import l10n from '../common/l10n';
import { getAmountWithCurrencySymbol } from '../common/retailSDKUtil';
import * as messageHelper from '../flows/messageHelper';
import {
  transaction as transactionError,
} from '../common/sdkErrors';

const Log = log('tx.cardPresentedHandler');

export default class CardPresentedHandler {

  constructor(tx) {
    this.context = tx;
  }

  handleCardPresent(err, subType, ff, result, device) {
    let amountAllowedError = null;
    if (subType !== CardPresentEvent.insertDetected) {
      // insertDetected is emitted just before cardDataRead
      // cardDataRead already handles this error case.
      if (this.context.isInvoiceAmountBelowAllowedMinimum()) {
        amountAllowedError = transactionError.amountTooLow;
      } else if (this.context.isInvoiceAmountAboveAllowedMaximum()) {
        amountAllowedError = transactionError.amountTooHigh;
      }
    }
    if (err || amountAllowedError) {
      this._handleError(err || amountAllowedError, ff, device);
      return;
    }
    Log.info(`Received card present event with sub type '${Util.getPropertyName(CardPresentEvent, subType)}, ff: ${Util.getPropertyName(FormFactor, ff)} for ${this.context}`);
    if (subType === CardPresentEvent.cardDataRead) {
      this._handleCardData(result);
    } else if (subType === CardPresentEvent.pinEvent) {
      this._handlePinEvent(result);
    } else if (subType === CardPresentEvent.appSelectionRequired) {
      this._handleApplicationSelect(device, ff, result);
    } else if (subType === CardPresentEvent.insertDetected) {
      this._handleCardInsertDetectedEvent(device);
    } else {
      Log.error(`Received unknown card presented event from ${device.id} event subType: ${subType},\
      formFactor: ${ff}, result: ${result}`);
    }
  }

  handleTxCancelled(device) {
    Log.warn(`Tx cancelled listener was invoked for device : ${device.id}`);
    device.display({ id: PaymentDevice.Message.TransactionCancelled, substitutions: this._formattedAmount }, () => {
      this.context.alert = manticore.alert({
        title: l10n('Tx.Alert.Cancelled.Title'),
        message: l10n('Tx.Alert.Cancelled.Msg'),
        cancel: l10n('Done'),
      }, () => {
        this.context.alert.dismiss();
        this.context.end(transactionError.genericCancel);
      });
    });
  }

  handleContactlessReaderDeactivated(device) {
    Log.debug(() => `Contactless reader was deactivated on ${device.id}`);
    this.context.deviceController.syncOnce(device);
    Log.debug(() => `Emitting contactlessReaderDeactivated event for ${this.context}`);
    this.context.emit(TransactionEvent.contactlessReaderDeactivated);
  }

  get _formattedAmount() {
    return {
      amount: getAmountWithCurrencySymbol(this.context.invoice.currency, this.context.invoice.total),
    };
  }

  _handleCardInsertDetectedEvent(device) {
    Log.debug(() => `Card insert detected on ${device.id}`);
    this.context.alert = manticore.alert({
      title: l10n('EMV.DoNotRemove'),
      message: l10n('EMV.Processing'),
      showActivity: true,
      replace: true,
    }, () => {});
    const substitutions = this.context.isRefund() ? messageHelper.formattedRefundTotal(this.context)
      : messageHelper.formattedInvoiceTotal(this.context.invoice);
    device.display({ id: PaymentDevice.Message.ProcessingContact, substitutions }, () => {});
  }

  _validateFormFactor(card, allowFallbackSwipe) {
    // Only allow fallback swipes for chip cards
    const sActiveFormFactors = this.context.getSetOfActiveFormFactors();
    if (!allowFallbackSwipe && card.chipCard && card.formFactor === FormFactor.MagneticCardSwipe) {
      if (sActiveFormFactors.has(FormFactor.Chip)) { // TODO Temporary provision that must be removed post certification
        return transactionError.cannotSwipeChipCard;
      }
      Log.info('Allow fallback swipes on chip card as chip reader was not enabled');
    }

    // Do not accept card inserts if Chip form factor was not enabled
    if (card.formFactor === FormFactor.Chip && !sActiveFormFactors.has(FormFactor.Chip)) {
      return transactionError.mustSwipeCard;
    }

    return null;
  }

  _handleCardData(cardData) {
    const card = cardData.card;
    Log.debug(() => `Card presented using form factor: '${Util.getPropertyName(FormFactor, card.formFactor)}'`);
    this.context.card = card;
    const error = this._validateFormFactor(card, this.context.allowFallBackSwipe);
    if (error) {
      this._handleError(error, card.formFactor, card.reader);
      return;
    }

    if (card.chipCard && card.formFactor === FormFactor.MagneticCardSwipe) {
      Log.info('Allowing fallback swipe on the chip card');
      card.isMSRFallbackAllowed = true;
    }

    if (this._isOnlinePINVerificationRequired(card.emvData)) {
      Log.debug('Online PIN authorization required... Will set pinPresent to true');
      this.context.pinPresent = true;
    }

    if (this.context.cardPresentedHandler) {
      // Dismiss any alert before we transfer control to the app for iOS
      if (this.context.alert) {
        this.context.alert.dismiss();
      }
      this.context.cardPresentedHandler(card);
    } else {
      // Because there are no listeners, we assume you want to just proceed with the
      // transaction and be notified on completion.
      this.context.continueWithCard(card);
    }
  }

  _handlePinEvent(pinEvent) {
    Log.debug(() => `Received PinEvent ${JSON.stringify(pinEvent)}`);
    const promptForPin = () => {
      const formattedValues = this.context.isRefund() ? messageHelper.formattedRefundTotal(this.context)
        : messageHelper.formattedInvoiceTotal(this.context.invoice);
      this.context.alert = manticore.alert({
        title: l10n('Tx.Alert.EnterPin.Title', formattedValues),
        message: l10n('Tx.Alert.EnterPin.Message'),
      }, () => {});
    };
    if (pinEvent.correct) {
      this.context.pinPresent = true;
    } else if (pinEvent.digits === 0) {
      this.context.pinRequired = true;
      if (this._incorrectPin) {
        this._incorrectPin = false;
        return;
      }
      promptForPin();
    } else if (pinEvent.failureReason) {
      this._incorrectPin = true;
      this.context.alert = manticore.alert({
        title: l10n('Tx.Alert.IncorrectPin.Title'),
        message: l10n('Tx.Alert.IncorrectPin.Message'),
        cancel: l10n('OK'),
      }, promptForPin);
    }
  }

  _isOnlinePINVerificationRequired(emvData) {
    if (!this.context.pinRequired || !emvData.tlvs) {
      return false;
    }
    const cvmResult = emvData.tlvs.find(Tags.CardholderVerificationMethodResults);
    if (!cvmResult || !cvmResult.bytes[0]) {
      return false;
    }
    Log.debug(() => `Checking for online PIN Authorization... Value of bytes[0] for CVM tag is ${cvmResult.bytes[0]}`);
    // CVM codes value for left most byte of 010000 indicates 'Enciphered PIN verified online' event
    return ((cvmResult.bytes[0] & 63) === 2);
  }

  _handleApplicationSelect(device, ff, data) {
    const buttons = [];
    const availableApps = data.availableApps;
    for (const app of availableApps.apps) {
      buttons.push(app[1] || app[0]);
    }

    const onCardRemoved = () => this._handleError(deviceError.smartCardNotInSlot, FormFactor.Chip, device);
    device.once(PaymentDevice.Event.cardRemoved, onCardRemoved);
    this.context.alert = manticore.alert({
      title: l10n('EMV.Select'),
      buttons,
      replace: true,
    }, (error, ix) => {
      const applicationId = availableApps.apps[ix][0];
      const applicationName = availableApps.apps[ix][1];
      Log.info(`${this.context.id} User selected application ${applicationId}:${applicationName}`);
      this.context.alert = manticore.alert({
        title: l10n('EMV.DoNotRemove'),
        message: l10n('EMV.Processing'),
        showActivity: true,
        replace: true,
      }, () => {});
      device.removeListener(PaymentDevice.Event.cardRemoved, onCardRemoved);
      device.selectPaymentApplication(applicationId, data.card);
    });
  }

  _handleError(error, ff, pd) {
    if (error.code === deviceError.contactlessPaymentAbortedByCardInsert.code ||
      error.code === deviceError.contactlessPaymentAbortedByCardSwipe.code) {
      Log.debug('Contactless payment aborted by card insert/swipe');
    } else {
      Log.error(`Transaction failed with error '${error.domain}.${error.code}'`);
    }

    const errorHandler = new PaymentErrorHandler(this.context);
    errorHandler.handle(error, ff, pd, action => this.context.processErrorHandlerResponse(error, action, ff));
  }
}
