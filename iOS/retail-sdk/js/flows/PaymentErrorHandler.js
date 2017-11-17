import log from 'manticore-log';
import manticore from 'manticore';
import {
  PaymentDevice,
  deviceError,
  deviceErrorDomain,
  FormFactor,
} from 'retail-payment-device';
import { extend, getPropertyName } from 'manticore-util';
import l10n from '../common/l10n';
import {
  retail as retailError,
  transaction as transactionError,
  domain as sdkErrorDomain,
} from '../common/sdkErrors';
import * as messageHelper from './messageHelper';
import Merchant from '../common/Merchant';
import { PaymentState } from '../transaction/transactionStates';

const Log = log('flow.paymentErrorHandler');

/**
 * The PaymentErrorHandler class is responsible for displaying appropriate alerts on the App and terminal based on
 * the errorCode and formFactor properties on the error object.
 */
export default class PaymentErrorHandler {

  constructor(context) {
    this.context = context;
    this.formattedAmount = this.context.isRefund() && this.context.refundAmount ?
      messageHelper.formattedRefundTotal(this.context) : messageHelper.formattedInvoiceTotal(this.context.invoice);
    const action = PaymentErrorHandler.action;
    const errors = PaymentErrorHandler.errors;
    const displayMessage = PaymentErrorHandler.displayMessage;
    let nfcContactIssuer;
    let swipeContactIssuer;
    const nfcHandlersForDeviceErrors = {
      [deviceError.nfcTimeout.code]: (pd, cb) => {
        Log.debug(() => 'Received an NFC timeout. Retrying again.');
        cb(action.retry);
        // TODO : Revisit this piece post Beta.
        /* this._updateDisplay(pd, PaymentDevice.Message.NfcTimeOut, this.formattedAmount, {
          title: l10n('Tx.Alert.TimeOut.Title'),
         message: l10n('Tx.Alert.TimeOut.Msg'),
         buttons: [l10n('Tx.Retry')],
          cancel: l10n('Tx.Alert.TimeOut.Button'),
        }, (a, ix) => {
          if (ix === 0) {
            this.context.promptForPaymentInstrument();
            cb(action.retry);
          } else {
            cb(action.abort);
          }
        }); */
      },
      [deviceError.nfcNotAllowed.code]: (pd, cb) => {
        this._nfcPaymentDeclineErrorHandler(pd, (performAction) => {
          if (performAction === PaymentErrorHandler.action.retryWithInsertOrSwipe) {
            cb(performAction);
          } else {
            cb(action.offlineDecline);
          }
        });
      },
      [deviceError.tryDifferentCard.code]: (pd, cb) => {
        this._updateDisplay(pd, PaymentDevice.Message.UnableToReadNfcCard, this.formattedAmount, {
          title: l10n('Tx.Alert.TapDifferentCard.Title'),
          message: l10n('Tx.Alert.TapDifferentCard.Msg'),
          cancel: l10n('Ok'),
        }, () => {
          this.context.promptForPaymentInstrument();
          cb(action.retry);
        });
      },
      [deviceError.contactIssuer.code]: (nfcContactIssuer = (pd, cb) => {
        this._updateDisplay(pd, PaymentDevice.Message.ContactIssuer, this.formattedAmount, {
          title: l10n('Tx.Alert.BlockedCardTapped.Title'),
          message: l10n('Tx.Alert.BlockedCardTapped.Msg'),
          cancel: l10n('Ok'),
        }, () => cb(action.abort));
      }),
      [deviceError.contactlessPaymentAbortedByCardInsert.code]: PaymentErrorHandler._doNothing,
      [deviceError.contactlessPaymentAbortedByCardSwipe.code]: PaymentErrorHandler._doNothing,
    };

    const insertHandlersForDeviceErrors = {
      [deviceError.cardBlocked.code]: (pd, cb) => this._insertContactIssuer(pd, cb, true),
      [deviceError.contactIssuer.code]: (pd, cb) => this._insertContactIssuer(pd, cb, true),
      [deviceError.smartCardNotInSlot.code]: (pd, cb) => {
        this._updateDisplay(pd, PaymentDevice.Message.TransactionCancelled, this.formattedAmount, {
          title: l10n('EMV.Cancelling'),
        }, () => {
          pd.abortTransaction(this.context);
          cb(action.offlineDecline);
        });
      },
      [deviceError.invalidChip.code]: (pd, cb) => {
        Log.debug(() => `Invalid chip card (Attempt: ${this.context.retryCountInvalidChip + 1})`);
        if (this.context.retryCountInvalidChip >= PaymentDevice.constant.InvalidChipRetryCount) {
          this._updateDisplay(null, null, null, {
            title: l10n('Tx.Alert.ReadyForSwipeOnly.Title'),
            message: l10n('Tx.Alert.ReadyForSwipeOnly.Msg'),
            imageIcon: 'img_emv_swipe',
            cancel: l10n('Cancel'),
          }, () => cb(action.abort));
          this.context.allowFallBackSwipe = true;
          cb(action.retryWithSwipe);
          return;
        }

        this.context.retryCountInvalidChip += 1;
        pd.once(PaymentDevice.Event.cardRemoved, () => {
          this.context.promptForPaymentInstrument(null, new Set([FormFactor.MagneticCardSwipe, FormFactor.Chip]));
        });

        this._updateDisplay(null, null, null, {
          title: l10n('Tx.Alert.UnsuccessfulInsert.Title'),
          message: l10n('Tx.Alert.UnsuccessfulInsert.Msg'),
        });
        cb(action.retryWithInsertOrSwipe);
      },
    };

    const swipeHandlersForDeviceErrors = {
      [deviceError.contactIssuer.code]: (swipeContactIssuer = (pd, cb) => {
        this._updateDisplay(pd, PaymentDevice.Message.ContactIssuer, this.formattedAmount, {
          title: l10n('Tx.Alert.BlockedCardSwiped.Title'),
          message: l10n('Tx.Alert.BlockedCardSwiped.Msg'),
          cancel: l10n('Ok'),
        }, () => cb(action.abort));
      }),
    };

    // Handler for errors from payment device that apply to all card presentation types
    const commonHandlersForDeviceErrors = {
      [deviceError.mustSwipeCard.code]: (pd, cb) => {
        this._mustSwipeCardHandler(pd, cb);
      },
      [deviceError.generic.code]: (pd, cb) => {
        this.errorHandlerCompletion(pd, cb, action.abort, false, this.formattedAmount,
          PaymentDevice.Message.TransactionCancelled,
          PaymentDevice.Message.TransactionCancelledRemoveCard, errors.genericError, displayMessage.ok);
      },
      [deviceError.paymentCancelled.code]: (pd, cb) => {
        this.errorHandlerCompletion(pd, cb, action.abort, false, this.formattedAmount,
          PaymentDevice.Message.TransactionCancelled,
          PaymentDevice.Message.TransactionCancelledRemoveCard, errors.cancelled, displayMessage.done);
      },
      [deviceError.cancelReadCardData.code]: (pd, cb) => {
        this.errorHandlerCompletion(pd, cb, action.offlineDecline, false, this.formattedAmount,
          PaymentDevice.Message.TransactionCancelled,
          PaymentDevice.Message.TransactionCancelledRemoveCard, errors.cancelled, displayMessage.done);
      },
    };

    const nfcHandlersForApiErrors = {
      [retailError.nfcPaymentDeclined.code]: (pd, cb) => {
        this._startListeningForPayments();
        this._nfcPaymentDeclineErrorHandler(pd, cb);
      },
      [retailError.onlinePinMaxRetryExceed.code]: nfcContactIssuer,
      [retailError.contactIssuer.code]: nfcContactIssuer,
    };

    const insertHandlersForApiErrors = {
      [retailError.contactIssuer.code]: (pd, cb) => this._insertContactIssuer(pd, cb, false),
      [retailError.onlinePinMaxRetryExceed.code]: (pd, cb) => this._insertContactIssuer(pd, cb, false),
    };

    const swiperHandlersForApiErrors = {
      [retailError.contactIssuer.code]: swipeContactIssuer,
    };

    const commonHandlersForApiErrors = {
      [retailError.incorrectOnlinePin.code]: (pd, cb) => {
        this._updateDisplay(pd, PaymentDevice.Message.IncorrectPin, this.formattedAmount, {
          title: l10n('Tx.Alert.IncorrectOnlinePin.Title'),
          message: l10n('Tx.Alert.IncorrectOnlinePin.Msg'),
          cancel: l10n('Ok'),
        }, () => {
          this.context.promptForPaymentInstrument();
          cb(action.retry);
        });
      },
    };

    const swipeHandlersForTransactionErrors = {
      [transactionError.cannotSwipeChipCard.code]: (pd, cb) => {
        this._updateDisplay(null, null, null, {
          title: l10n('Tx.Alert.ChipCardSwiped.Title'),
          message: l10n('Tx.Alert.ChipCardSwiped.Msg'),
          cancel: l10n('Ok'),
        }, () => {
          this.context.promptForPaymentInstrument(null, new Set([FormFactor.Chip]));
        });
        cb(action.retryWithInsert);
      },
    };

    // Handlers that apply to all form of transactions (insert, tap & swipe)
    const commonHandlersForTransactionErrors = {
      [transactionError.mustSwipeCard.code]: (pd, cb) => {
        this._mustSwipeCardHandler(pd, cb);
      },
      [transactionError.amountTooLow.code]: (pd, cb) => {
        const allowedMin = messageHelper.formattedAmount(this.context.invoice.currency,
          Merchant.active.cardSettings.minimum);
        this.errorHandlerCompletion(pd, cb, action.retry, true, allowedMin,
          PaymentDevice.Message.AmountTooLow,
          PaymentDevice.Message.AmountTooLowRemoveCard, errors.amountTooLow, displayMessage.ok);
      },
      [transactionError.amountTooHigh.code]: (pd, cb) => {
        const allowedMax = messageHelper.formattedAmount(this.context.invoice.currency,
          Merchant.active.cardSettings.maximum);
        this.errorHandlerCompletion(pd, cb, action.retry, true, allowedMax,
          PaymentDevice.Message.AmountTooHigh,
          PaymentDevice.Message.AmountTooHighRemoveCard, errors.amountTooHigh, displayMessage.ok);
      },
      [transactionError.refundCardMismatch.code]: (pd, cb) => {
        this.errorHandlerCompletion(pd, cb, action.abort, false, this.formattedAmount,
          PaymentDevice.Message.RefundCardMismatch,
          PaymentDevice.Message.RefundCardMismatchRemoveCard, errors.refundCardMismatch, displayMessage.ok);
      },
      [transactionError.customerCancel.code]: (pd, cb) => {
        this.errorHandlerCompletion(pd, cb, action.abort, false, this.formattedAmount,
          PaymentDevice.Message.TransactionCancelled,
          PaymentDevice.Message.TransactionCancelledRemoveCard, errors.cancelled, displayMessage.ok);
      },
    };

    this.errorHandlers = {
      [deviceErrorDomain]: {
        [FormFactor.None]: commonHandlersForDeviceErrors,
        [FormFactor.EmvCertifiedContactless]: extend(nfcHandlersForDeviceErrors, commonHandlersForDeviceErrors),
        [FormFactor.Chip]: extend(insertHandlersForDeviceErrors, commonHandlersForDeviceErrors),
        [FormFactor.MagneticCardSwipe]: extend(swipeHandlersForDeviceErrors, commonHandlersForDeviceErrors),
      },
      [sdkErrorDomain.retail]: {
        [FormFactor.None]: commonHandlersForApiErrors,
        [FormFactor.EmvCertifiedContactless]: extend(nfcHandlersForApiErrors, commonHandlersForApiErrors),
        [FormFactor.Chip]: extend(insertHandlersForApiErrors, commonHandlersForApiErrors),
        [FormFactor.MagneticCardSwipe]: extend(swiperHandlersForApiErrors, commonHandlersForApiErrors),
      },
      [sdkErrorDomain.transaction]: {
        [FormFactor.None]: commonHandlersForTransactionErrors,
        [FormFactor.EmvCertifiedContactless]: commonHandlersForTransactionErrors,
        [FormFactor.Chip]: commonHandlersForTransactionErrors,
        [FormFactor.MagneticCardSwipe]: extend(swipeHandlersForTransactionErrors, commonHandlersForTransactionErrors),
        [FormFactor.ManualCardEntry]: commonHandlersForTransactionErrors,
      },
    };
  }

  static _doNothing(pd, cb) {
    cb(null);
  }
  errorHandlerCompletion(pd, cb, action, amountError, amountSubstitution,
                      pdMessage, pdMessageRemoveCard, appMessageKey, alertButtonKey) {
    let pdDisplayMessage = pdMessage;
    const shouldPromptCardRemoval = pd && pd.isConnected() && pd.cardInSlot;
    let appUpdateDisplay = {
      title: l10n(`Tx.Alert.${appMessageKey}.Title`),
      message: amountError ? l10n(`Tx.Alert.${appMessageKey}.Msg`, amountSubstitution) : l10n(`Tx.Alert.${appMessageKey}.Msg`),
      cancel: l10n(`${alertButtonKey}`),
    };
    if (appMessageKey === PaymentErrorHandler.errors.genericError) {
      appUpdateDisplay.message = l10n(`Tx.Alert.GenericError.${this.context.isRefund() ?
        PaymentErrorHandler.displayMessage.refundMessage : PaymentErrorHandler.displayMessage.paymentMessage}`);
    }
    if (shouldPromptCardRemoval) {
      appUpdateDisplay = this._cardInSlotHelper(pd, cb, action, appUpdateDisplay);
      pdDisplayMessage = pdMessageRemoveCard;
    }
    this._updateDisplay(pd, pdDisplayMessage, amountSubstitution, appUpdateDisplay, () => {
      if (!shouldPromptCardRemoval) {
        cb(action);
      }
    });
  }

  _cardInSlotHelper(pd, cb, action, appUpdateDisplay) {
    appUpdateDisplay.message = appUpdateDisplay.message.concat(l10n(PaymentErrorHandler.displayMessage.removeCard));
    delete appUpdateDisplay.cancel;
    pd.waitForCardRemoval(() => {
      if (this.alert) {
        this.alert.dismiss();
      }
      cb(action);
    });
    return appUpdateDisplay;
  }
  _startListeningForPayments() {
    Log.debug(() => `Will activate Chip & Swipe form factors for ${this.context.id}`);
    this.context.setPaymentState(PaymentState.retry);
    this.context.deviceController.activate({
      showPrompt: false,
      formFactors: [FormFactor.Chip, FormFactor.MagneticCardSwipe],
      syncInvoiceTotal: false,
    });
  }

  _mustSwipeCardHandler(pd, cb) {
    this._updateDisplay(pd, null, null, {
      title: l10n('Tx.Alert.ReadyForSwipeOnly.Title'),
      message: l10n('Tx.Alert.ReadyForSwipeOnly.Msg'),
      imageIcon: 'img_emv_swipe',
    });
    this.context.allowFallBackSwipe = true;
    cb(PaymentErrorHandler.action.retryWithSwipe);
  }

  _nfcPaymentDeclineErrorHandler(pd, cb) {
    this._updateDisplay(pd, PaymentDevice.Message.NfcDecline, null, {
      title: l10n('Tx.Alert.NfcPaymentDeclined.Title'),
      message: l10n('Tx.Alert.NfcPaymentDeclined.Msg'),
      buttons: [l10n('Ok')],
      cancel: l10n('Cancel'),
    }, (a, ix) => {
      if (ix === 0) {
        this.context.promptForPaymentInstrument(null, new Set([FormFactor.Chip, FormFactor.MagneticCardSwipe]));
        cb(PaymentErrorHandler.action.retryWithInsertOrSwipe);
      } else {
        cb(PaymentErrorHandler.action.abort);
      }
    });
  }

  _insertContactIssuer(pd, cb, isOffline) {
    const action = isOffline ? PaymentErrorHandler.action.offlineDecline : PaymentErrorHandler.action.abort;
    this.errorHandlerCompletion(pd, cb, action, false, this.formattedAmount,
      PaymentDevice.Message.ContactIssuer, PaymentDevice.Message.ContactIssuerRemoveCard,
      PaymentErrorHandler.errors.blockedCard, PaymentErrorHandler.displayMessage.ok);
  }

  /**
   * Display alerts on the payment device and app
   */
  _updateDisplay(pd, deviceMessageId, deviceMessageSubstitutions, alertOptions, cb) {
    const onDeviceDisplay = () => {
      if (!alertOptions) {
        if (cb) {
          cb();
        }
        return;
      }
      this.alert = manticore.alert(alertOptions, (a, ix) => {
        if (this.alert) {
          this.alert.dismiss();
        }
        if (cb) {
          cb(a, ix);
        }
      });

      if (!alertOptions.cancel && !alertOptions.buttons && cb) {
        cb(this.alert);
      }
    };

    if (pd && deviceMessageId) {
      pd.display({ id: deviceMessageId, substitutions: deviceMessageSubstitutions }, onDeviceDisplay);
    } else {
      onDeviceDisplay();
    }
  }

  /**
   * Handles payment errors by displaying appropriate alerts on the terminal and app side.
   * @param {PayPalError} error
   * @param formFactor
   * @param paymentDevice
   * @param cb Callback to invoke after the error was handled. A single parameter with value action.abort or
   *                  action.retry will be passed to the callback function.
   */
  handle(error, formFactor, paymentDevice, cb) {
    Log.debug(() => `Handling error with code: ${error.code}, domain: ${error.domain}, formFactor: ${getPropertyName(FormFactor, formFactor)}, device: ${paymentDevice ? paymentDevice.id : '<no device>'}`);
    if (error.domain && formFactor && this.errorHandlers[error.domain] && this.errorHandlers[error.domain][formFactor]
      && this.errorHandlers[error.domain][formFactor][error.code]) {
      const handler = this.errorHandlers[error.domain][formFactor][error.code];
      try {
        handler(paymentDevice, cb);
        return;
      } catch (x) {
        Log.error(`Error (${error.domain}:${error.code}) executing handler ${handler}\n${x}`);
        throw x;
      }
    }

    Log.warn(`No handlers were defined for domain: '${error.domain}' form factor : '${getPropertyName(FormFactor, formFactor)}' and Error code ${error.code}`);
    this.errorHandlerCompletion(paymentDevice, cb, PaymentErrorHandler.action.abort, false, this.formattedAmount,
      PaymentDevice.Message.TransactionCancelled,
      PaymentDevice.Message.TransactionCancelledRemoveCard,
      PaymentErrorHandler.errors.genericError, PaymentErrorHandler.displayMessage.ok);
  }
}

/**
 * Contains the list of actions PaymentErrorHandler class could request the caller of Handle function to perform
 * @type {{Abort: string, Retry: string}}
 * @private
 */
PaymentErrorHandler.action = {
  offlineDecline: 'OfflineDecline',
  abort: 'abort',
  retry: 'retry',
  retryWithInsertOrSwipe: 'retryWithInsertOrSwipe',
  retryWithInsert: 'retryWithInsert',
  retryWithSwipe: 'retryWithSwipe',
};
PaymentErrorHandler.errors = {
  genericError: 'GenericError',
  cancelled: 'Cancelled',
  amountTooLow: 'AmountTooLow',
  amountTooHigh: 'AmountTooHigh',
  refundCardMismatch: 'Refund.CardMismatch',
  blockedCard: 'BlockedCard',
};
PaymentErrorHandler.displayMessage = {
  ok: 'Ok',
  done: 'Done',
  cancel: 'Cancel',
  removeCard: 'RemoveCard',
  refundMessage: 'RefundMessage',
  paymentMessage: 'PaymentMessage',
};
