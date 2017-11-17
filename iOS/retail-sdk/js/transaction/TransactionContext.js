import manticore from 'manticore';
import log from 'manticore-log';
import { $$, InvoiceEnums } from 'paypal-invoicing';
import { Tracker, pages } from 'retail-page-tracker';
import {
  PaymentDevice,
  MagneticCard,
  deviceError,
  TransactionType,
  FormFactor,
  CardInsertedHandler,
  deviceCapabilityType,
  deviceModel,
} from 'retail-payment-device';
import { getPropertyName } from 'manticore-util';
import { EventEmitter } from 'events';
import async from 'async';
import l10n from '../common/l10n';
import {
  transaction as transactionError,
} from '../common/sdkErrors';
import StateManager from './TransactionStateManager';
import { PaymentState, TippingState } from './transactionStates';
import PaymentErrorHandler from '../flows/PaymentErrorHandler';
import Merchant from '../common/Merchant';
import * as messageHelper from '../flows/messageHelper';
import DeviceController from './DeviceController';
import DeviceSelector from '../paymentDevice/DeviceSelector';
import TransactionEvent from './transactionEvent';
import PaymentType from './PaymentType';
import OfflineDeclineFlow from '../flows/OfflineDeclineFlow';
import TransactionBeginOptions from './TransactionBeginOptions';
import { getRandomId } from '../common/retailSDKUtil';

const Log = log('transactionContext');
const ErrorAction = PaymentErrorHandler.action;

/**
 * The TransactionContext class is returned by RetailSDK.createTransaction and allows
 * you to control many aspects of the payment or refund flow and observe events that
 * occur during the flows. Simply creating a TransactionContext will not kick off any behaviors,
 * so that you have a chance to configure the transaction context as you wish (choose payment
 * devices, specify transaction options, etc). When you're ready to proceed with the payment flow,
 * call begin()
 * @class
 * @property {Invoice} invoice The invoice being processed for this transaction
 * @property {TransactionType} type The type of transaction being attempted
 *  (defaults to Sale if the invoice is not already paid, Refund if it is already paid)
 * @property {bool} isSignatureRequired Given the current state of the invoice and transaction,
 *  is a signature required to secure payment? @readonly
 * @property {[PaymentDevice]} paymentDevices If you set the paymentDevices property, this context
 *  will only use the devices you specify to accept
 * payment. This can be useful for cases where a single terminal is managing multiple payment
 *  devices with transactions proceeding in parallel. (This feature is still experimental for
 *  certain payment factors, as any UI will still be single-instance.)
 * @property {string} totalDisplayFooter While building your invoice, the running total
 *  will be displayed on PaymentDevices capable of displaying messages. If you set
 *  totalDisplayFooter, that will be displayed (centered) after the total
 *  amount. Note that once the payment flow starts, EMV certification requires that the display
 *  just show the total and iconography corresponding to expected payment types. Your message
 *  will not be on that screen.
 */
export default class TransactionContext extends EventEmitter {
  /**
   * Only JS constructs this
   * @private
   * @param {Invoice} invoice The invoice for this transaction
   * @param {Merchant} merchant The merchant to use for this transaction
   */
  constructor(invoice, merchant) {
    super();
    this.invoice = invoice;
    this.merchant = merchant;
    this.id = `tx-${getRandomId()}`;
    this._state = new StateManager(this);
    this.deviceController = new DeviceController(this);
    if (invoice.status === InvoiceEnums.Status.PAID ||
      invoice.status === InvoiceEnums.Status.MARKED_AS_PAID ||
      invoice.status === InvoiceEnums.Status.PARTIALLY_REFUNDED) {
      this.type = TransactionType.Refund;
    } else {
      this.type = TransactionType.Sale;
    }
    Log.debug(() => `CREATE transaction with Id ${this.id} and invoice total: ${this.invoice ? this.invoice.total : ''}`);

    this._deferredBeginHandler = () => {
      if (!DeviceSelector.selectedDevice) {
        Log.error(`${this.id} Deferred transaction begin invoked without a connected device`);
        return;
      }

      if (!this._deferredActivateOptions) {
        Log.debug(() => `${this.id} Deferred transaction begin invoked but options are missing`);
        return;
      }
      Log.info(`Deferred transaction begin was invoked for '${DeviceSelector.selectedDevice.id}'`);
      this.beginPaymentWithOptions(this._deferredActivateOptions);
    };
  }

  toString() {
    return JSON.stringify(this.toJSON());
  }

  toJSON() {
    return {
      id: this.id,
      type: this.type,
      currency: this.invoice ? this.invoice.currency : '',
      total: this.invoice ? this.invoice.total : '',
      state: this._state.toJSON(),
    };
  }

  get totalDisplayFooter() {
    return this._totalDisplayFooter;
  }

  set totalDisplayFooter(value) {
    this._totalDisplayFooter = value;
    this.emit(TransactionEvent.invoiceDisplayFooterUpdated);
  }

  processErrorHandlerResponse(error, errAction, ff) {
    Log.info(`(${this.id}) Response from error handler for handling the error-${error.domain}:${error.code} and ff: ${getPropertyName(FormFactor, ff)} was '${getPropertyName(ErrorAction, errAction)}'`);
    if (!errAction) {
      return;
    }
    if (errAction === ErrorAction.offlineDecline) {
      const returnError = (error.code === deviceError.cancelReadCardData.code
      || error.code === deviceError.smartCardNotInSlot.code)
        ? transactionError.customerCancel : deviceError.contactIssuer;

      const offlineDeclineFlow = new OfflineDeclineFlow(returnError, this, (data) => {
        this.end(data.error, data.tx);
      });
      offlineDeclineFlow.startFlow();
      return;
    }

    if (errAction === ErrorAction.abort) {
      let returnError = error || transactionError.genericCancel;
      if (error.code === deviceError.paymentCancelled.code) {
        returnError = transactionError.customerCancel;
      }
      this.end(returnError);
      return;
    }

    // Setting the payment state to 'retry' to re-ask for tipping when on-reader tipping is enabled
    this._state.setPaymentState(PaymentState.retry);
    let deactivateFF = [];
    let activateFF = [];
    if (errAction === ErrorAction.retry) {
      activateFF = [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless];
    } else if (errAction === ErrorAction.retryWithInsertOrSwipe) {
      deactivateFF = [FormFactor.EmvCertifiedContactless];
      activateFF = [FormFactor.Chip, FormFactor.MagneticCardSwipe];
    } else if (errAction === ErrorAction.retryWithSwipe) {
      deactivateFF = [FormFactor.Chip, FormFactor.EmvCertifiedContactless];
      activateFF = [FormFactor.MagneticCardSwipe];
    } else if (errAction === ErrorAction.retryWithInsert) {
      deactivateFF = [FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless];
      activateFF = [FormFactor.Chip];
    }
    this.deviceController.selectedDevice.deactivateFormFactors(deactivateFF, () => {
      this.deviceController.activate({ showPrompt: true, formFactors: activateFF });
    });
  }

  getSetOfActiveFormFactors() {
    return this._state.getSetOfActiveFormFactors();
  }

  /**
   * Returns the current state of payment
   * @returns {PaymentState} Payment state of current transaction
   */
  getPaymentState() {
    return this._state.getPaymentState();
  }

  /**
   * Returns the current state of tipping
   * @returns {TippingState} Tipping state of current transaction
   */
  getTippingState() {
    return this._state.getTippingState();
  }

  setPaymentState(state) {
    this._state.setPaymentState(state);
  }

  /**
   * Clear the on-reader tip that was acquired for this transaction
   */
  clearOnReaderTip() {
    Log.debug(() => `Clearing tip. Will reset acquired on-reader tip amount of ${this.invoice.gratuityAmount} to 0`);
    this._state.setTippingState(TippingState.notStarted);
    this.invoice.gratuityAmount = 0;
  }

  /**
   * Begin the flow (activate payment devices, listen for relevant events from devices)
   * @param {TransactionBeginOptions} options Custom options for the transaction
   * @returns {TransactionContext} Returns this object just to make chaining easier
   */
  beginPaymentWithOptions(options) {
    Log.debug(() => `Begin payment on ${this.id} with options ${JSON.stringify(options)}`);
    Tracker.publishPageView(null, pages.transaction);
    if (this.type !== TransactionType.Sale) {
      this.end(transactionError.invoiceStatusMismatch);
      return this;
    }

    if (options.isAuthCapture) {
      this.type = TransactionType.Auth;
    }

    // If a device is not connected by the time the begin is invoked, defer the invoke to until after the device is connected
    if (!DeviceSelector.selectedDevice || !DeviceSelector.selectedDevice.isConnected()) {
      if (!DeviceSelector.selectedDevice) {
        Log.info(`${this.id} Cannot continue with tx.begin as no device is selected`);
      } else {
        Log.info(`${this.id} Cannot continue with tx.begin as ${DeviceSelector.selectedDevice.id} is not connected and ready`);
      }
      this._deferredActivateOptions = options;
      PaymentDevice.Events.removeListener(PaymentDevice.Event.selected, this._deferredBeginHandler);
      PaymentDevice.Events.once(PaymentDevice.Event.selected, this._deferredBeginHandler);
      return this;
    }

    PaymentDevice.Events.removeListener(PaymentDevice.Event.selected, this._deferredBeginHandler);
    if (!options.tippingOnReaderEnabled && this.isInvoiceAmountInvalidForCardReaderTransaction()) {
      options.showPromptInCardReader = false;
      options.showPromptInApp = false;
      options.preferredFormFactors = [FormFactor.MagneticCardSwipe, FormFactor.Chip];
    }
    this.paymentOptions = options;

    if (options.showPromptInCardReader && options.tippingOnReaderEnabled) {
      // We will be showing a prompt on the reader after the tip, so stop invoice sync
      this._stopInvoiceSync();
      this._beginTippingOnReader(options.amountBasedTipping, true, () => {
        Log.debug(() => `After tipping, validated invoices... Proceeding to activate ${PaymentDevice.devices.length} connected devices for ${this.id}`);
        if (this.isInvoiceAmountInvalidForCardReaderTransaction()) {
          options.showPromptInCardReader = false;
          options.showPromptInApp = false;
          options.preferredFormFactors = [FormFactor.MagneticCardSwipe, FormFactor.Chip];
        }
        // Set syncInvoiceTotal false if we are not showing prompt on the reader.
        this._activateReaders({
          showPromptInCardReader: options.showPromptInCardReader,
          showPromptInApp: options.showPromptInApp,
          formFactors: options.preferredFormFactors,
          syncInvoiceTotal: !options.showPromptInCardReader,
        });
      });
    } else {
      Log.debug(() => `Validated invoices... Proceeding to activate ${PaymentDevice.devices.length} connected devices for ${this.id}`);
      this._activateReaders({
        showPromptInCardReader: options.showPromptInCardReader,
        showPromptInApp: options.showPromptInApp,
        formFactors: options.preferredFormFactors,
      });
    }

    return this;
  }

  _beginTippingOnReader(amountBasedTip, deactivateNeeded = true, cb) {
    const tipState = this._state.getTippingState();
    const paymentState = this._state.getPaymentState();
    let doTipping = true;
    Log.debug(() => `${this.id} Trying to begin tipping. TippingState: ${getPropertyName(TippingState, tipState)}, PaymentState: ${getPropertyName(PaymentState, paymentState)}`);
    if (tipState === TippingState.inProgress || paymentState === PaymentState.inProgress) {
      Log.debug('Will not start tipping flow as either tipping or payment is in progress');
      doTipping = false;
    } else if (tipState === TippingState.complete) {
      // Re-acquire tip while retrying a payment
      if (paymentState === PaymentState.retry && !this.card.isMSRFallbackAllowed) {
        Log.debug('Tipping was complete, but will restart tipping as payment is being retried');
        doTipping = true;
      } else {
        Log.debug('Will not start tipping flow as tipping flow is complete');
        doTipping = false;
      }
    }

    if (!doTipping) {
      Log.debug(() => `${this.id} Bypassing tipping as it cannot be performed in current transaction state`);
      if (cb) {
        cb();
      }
      return;
    }

    const activeReader = this.deviceController.selectedDevice;
    if (!activeReader || !activeReader.doesHaveCapability(deviceCapabilityType.display)) {
      if (!activeReader) {
        Log.debug(() => `${this.id} Bypassing tipping since there is no active reader`);
      } else {
        Log.debug(() => `${this.id} Bypassing tipping since '${activeReader.id}' does not have display capability`);
      }
      if (cb) {
        cb();
      }
      return;
    }
    Log.info(`Beginning tipping on on reader. Amount based=${amountBasedTip}. ${this._state}`);
    this._state.setTippingState(TippingState.inProgress);
    const TipFlow = require('./../flows/ReaderTippingFlow').default; // eslint-disable-line global-require
    this.tippingFlow = new TipFlow(activeReader, amountBasedTip, this.invoice, () => {
      Log.debug('Tipping on Reader flow completed');
      this._state.setTippingState(TippingState.complete);
      this.emit(TransactionEvent.readerTippingCompleted, this.invoice.gratuityAmount);
      if (cb) {
        cb();
      }
    });

    const flowStart = () => {
      this.tippingFlow.start().then(() => {
        Log.debug('Tipping on Reader flow done');
      }, (error) => {
        this._state.setTippingState(TippingState.complete);
        Log.error(`Tipping flow failed ${error}`);
        if (cb) {
          cb();
        }
      });
    };
    // We don't want card swipes or inserts to be processed during tipping flow
    // That's the reason we do deactivate form factors before starting the tipping flow
    if (deactivateNeeded) {
      this.deactivateFormFactors([...this.getSetOfActiveFormFactors()], flowStart);
    } else {
      flowStart();
    }
  }

  /**
   * Begin the flow (activate payment devices, listen for relevant events from devices)
   * @returns {TransactionContext} Returns this object just to make chaining easier
   */
  begin() {
    const paymentOptions = new TransactionBeginOptions();
    paymentOptions.showPromptInCardReader = true;
    paymentOptions.showPromptInApp = true;
    paymentOptions.preferredFormFactors =
      [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless];
    return this.beginPaymentWithOptions(paymentOptions);
  }

  /**
   * Begin the authorization flow (activate payment devices, listen for relevant events from devices)
   * @returns {TransactionContext} Returns this object just to make chaining easier
   */
  beginAnAuthorization() {
    const paymentOptions = new TransactionBeginOptions();
    paymentOptions.showPromptInCardReader = true;
    paymentOptions.showPromptInApp = true;
    paymentOptions.preferredFormFactors =
      [FormFactor.Chip, FormFactor.MagneticCardSwipe, FormFactor.EmvCertifiedContactless];
    paymentOptions.isAuthCapture = true;
    return this.beginPaymentWithOptions(paymentOptions);
  }

  /**
   * Begin the flow to issue a refund on the current invoice.
   * @param {bool} cardPresent true to ask for card data to check against the payment
   * method originally used on the invoice
   * @param {decimal} amount the amount to refund
   * @returns {TransactionContext} Returns this object just to make chaining easier
   */
  beginRefund(cardPresent, amount) {
    if (this.type !== TransactionType.Refund) {
      this.end(transactionError.invoiceStatusMismatch);
      return this;
    }

    Tracker.publishPageView(null, pages.refund);
    this._reset();
    this.refundAmount = $$(amount);
    if (cardPresent) {
      if (this.deviceController.selectedDevice) {
        this.emit(TransactionEvent.refundAmountEntered);
        const alertOpts = {
          title: l10n('Tx.Alert.Refund.Title'),
          message: l10n('Tx.Alert.Refund.Msg'),
          buttons: [l10n('Tx.Alert.Refund.Buttons.WithCard'), l10n('Tx.Alert.Refund.Buttons.WithoutCard')],
          cancel: l10n('Cancel'),
        };
        this.alert = manticore.alert(alertOpts, (a, ix) => {
          if (this.alert) {
            this.alert.dismiss();
          }
          if (ix === 2) { // Cancel
            return;
          } else if (ix === 0) { // Refund with Card
            if (this.deviceController.selectedDevice) {
              this._activateReaders({ showPromptInCardReader: true, showPromptInApp: true });
            } else {
              this.continueWithCard(null);
            }
          } else if (ix === 1) { // Refund without Card
            this.continueWithCard(null);
          }
        });
      } else {
        this.continueWithCard(null);
      }
    }

    return this;
  }

  _validateInvoice(cb) {
    if (!Merchant.active.cardSettings) {
      cb();
    }

    let deviceMessageId;
    let alertOpts;
    let values;
    let error;
    if (this.isInvoiceAmountBelowAllowedMinimum()) {
      error = transactionError.amountTooLow;
      deviceMessageId = PaymentDevice.Message.AmountTooLow;
      values = messageHelper.formattedAmount(this.invoice.currency, Merchant.active.cardSettings.minimum);
      alertOpts = {
        title: l10n('Tx.Alert.AmountTooLow.Title'),
        message: l10n('Tx.Alert.AmountTooLow.Msg', values),
        cancel: l10n('Ok'),
      };
      Log.debug(() => `Amount too Low for ${this.id}`);
    } else if (this.isInvoiceAmountAboveAllowedMaximum()) {
      error = transactionError.amountTooHigh;
      deviceMessageId = PaymentDevice.Message.AmountTooHigh;
      values = messageHelper.formattedAmount(this.invoice.currency, Merchant.active.cardSettings.maximum);
      alertOpts = {
        title: l10n('Tx.Alert.AmountTooHigh.Title'),
        message: l10n('Tx.Alert.AmountTooHigh.Msg', values),
        cancel: l10n('Ok'),
      };
      Log.debug(() => `Amount too High for ${this.id}`);
    } else {
      cb();
      return;
    }
    async.each(this.deviceController.devices,
      (pd, callback) => pd.display({ id: deviceMessageId, substitutions: values }, callback),
      () => {
        this.alert = manticore.alert(alertOpts, () => {
          cb(error);
        });
      });
  }

  isInvoiceAmountBelowAllowedMinimum() {
    return (Merchant.active.cardSettings) ? (Merchant.active.cardSettings.minimum
    && this.invoice.total.lessThan(Merchant.active.cardSettings.minimum)) : false;
  }

  isInvoiceAmountAboveAllowedMaximum() {
    return (Merchant.active.cardSettings) ? (Merchant.active.cardSettings.maximum
    && this.invoice.total.greaterThan(Merchant.active.cardSettings.maximum)) : false;
  }

  isInvoiceAmountInvalidForCardReaderTransaction() {
    return this.isInvoiceAmountBelowAllowedMinimum() || this.isInvoiceAmountAboveAllowedMaximum();
  }

  _activateReaders(opt) {
    const showPromptInCardReader = opt.showPromptInCardReader;
    const showPromptInApp = opt.showPromptInApp;
    let preferredFormFactors = opt.formFactors;
    const activeReader = this.deviceController.selectedDevice;
    const deviceId = activeReader ? activeReader.id : '<no reader>';
    Log.debug(() => `Activating ${deviceId} for '${getPropertyName(FormFactor, preferredFormFactors)}'`);
    if (!preferredFormFactors || preferredFormFactors.length === 0) {
      preferredFormFactors = [FormFactor.Chip, FormFactor.EmvCertifiedContactless, FormFactor.MagneticCardSwipe];
    }

    if (this._state.getPaymentState() === PaymentState.inProgress ||
      this._state.getTippingState() === TippingState.inProgress) {
      Log.debug(() => `Will not activate reader as ${this.id} is not ready. ${this._state}`);
      return;
    }

    const sActiveFormFactors = this._state.getSetOfActiveFormFactors();
    const ffToActivate = [];
    for (const ff of preferredFormFactors) {
      if (!sActiveFormFactors.has(ff)) {
        Log.debug(() => `Activate ${deviceId}.'${getPropertyName(FormFactor, ff)}' for ${this.id}`);
        ffToActivate.push(ff);
      } else {
        Log.debug(() => `Will NOT activate '${getPropertyName(FormFactor, ff)}' on ${deviceId} for ${this.id} as it was previously activated`);
      }
    }

    if (ffToActivate.length === 0) {
      Log.info(`(${this.id}) Will not activate as all provided form factors '${getPropertyName(FormFactor, preferredFormFactors)}' are already active`);
      this.deviceController.updateDeviceDisplayIfError(activeReader);
      return;
    }

    this._reset();
    const active = this.deviceController.activate({ showPrompt: showPromptInCardReader,
      formFactors: ffToActivate,
      syncInvoiceTotal: opt.syncInvoiceTotal,
    });
    if (active.error) {
      if (active.error === transactionError.noFunctionalDevices) {
        // Do not end the transaction. Let it be open for other forms of payment like cash, check, etc.
        Log.warn(`Device activate failed as there were no functional devices for ${this.id}`);
      } else {
        this.end(active.error);
      }
      return;
    }

    const pd = active.device;
    Log.info(`(${this.id}) Activated ${pd.id} device for invoice total ${this.invoice.currency} ${this.invoice.total} for form factors: [${getPropertyName(FormFactor, active.formFactors)}]`);
    if (showPromptInApp) {
      this.promptForPaymentInstrument(pd);
    }
  }

  /**
   * Is the transaction a type of refund?
   * @returns {bool}
   */
  isRefund() {
    return this.type === TransactionType.Refund || this.type === TransactionType.PartialRefund;
  }

  /**
   * Display an alert on the app prompting for payment
   * @param {PaymentDevice} selectedDevice Payment device that was selected for this transaction
   * @param {Set(FormFactor)} sFormFactors (optional) Set of form factors to include in the payment prompt.
   *  Default value will be the form factors approved on the connected devices
   * @private
   */
  promptForPaymentInstrument(selectedDevice, sFormFactors) {
    const ff = sFormFactors || this._state.getSetOfActiveFormFactors();
    let alertId;
    let imageId;

    if (selectedDevice && selectedDevice.model && selectedDevice.model.toUpperCase() === deviceModel.swiper) { // Roam device
      if (ff.has(FormFactor.MagneticCardSwipe)) {
        alertId = 'Ready';
        imageId = 'img_reader_status_connected_160';
      }
    } else if (ff.has(FormFactor.EmvCertifiedContactless) &&
        ff.has(FormFactor.MagneticCardSwipe) &&
        ff.has(FormFactor.Chip)) { // must be MIURA device
      alertId = 'Ready';
      imageId = 'img_emv_insert_tap_swipe';
    } else if (ff.has(FormFactor.MagneticCardSwipe) && ff.has(FormFactor.Chip)) {
      alertId = 'ReadyForInsertOrSwipeOnly';
      imageId = 'img_emv_insert_swipe';
    } else if (ff.has(FormFactor.MagneticCardSwipe)) {
      alertId = 'ReadyForSwipeOnly';
      imageId = 'img_emv_swipe';
    } else if (ff.has(FormFactor.Chip)) {
      alertId = 'ReadyForInsertOnly';
      imageId = 'img_emv_insert';
    }

    if (!alertId) {
      return;
    }

    this.alert = manticore.alert({
      title: l10n(`Tx.Alert.${alertId}.Title`),
      message: l10n(`Tx.Alert.${alertId}.Msg`),
      cancel: l10n('Cancel'),
      imageIcon: imageId,
    }, () => {
      this.alert.dismiss();
      this.deactivateFormFactors([FormFactor.EmvCertifiedContactless], () => {});
    });
  }

  /**
   * Deactivate form factors without ending the transaction. Once deactivated, you should re-begin the transaction to
   * start taking payments
   * @param {[FormFactor]} formFactors Form factors to deactivate
   * @param {TransactionContext~complete} callback
   */
  deactivateFormFactors(formFactors, callback) {
    Log.debug(() => `Deactivate form factors '${getPropertyName(FormFactor, formFactors)}' for ${this.id}`);
    if (this._deferredActivateOptions && this._deferredActivateOptions.preferredFormFactors) {
      for (const ff of formFactors) {
        const i = this._deferredActivateOptions.preferredFormFactors.indexOf(ff);
        if (i !== -1) {
          this._deferredActivateOptions.preferredFormFactors.splice(i, 1);
        }
      }
    }
    this.deviceController.deactivateFormFactors(formFactors, (pd) => {
      Log.debug(() => `Deactivated ${getPropertyName(FormFactor, formFactors)} on ${pd ? pd.id : '<no device>'}`);
      if (callback) {
        callback(null);
      }
    });
  }

  /**
   * A transaction is not complete until the end function is called. This function
   * takes care of de-registering various event listeners and clears variables that
   * track transaction state.
   * @private
   */
  end(error, txRecord, invokeHandler = true) {
    Log.debug(() => `END ${this.id}`);
    this._signatureCollector = null;
    this.tokenExpirationHandler = null;
    this.deviceController.startPollingForBattery();
    if (error) {
      Log.error(`Ending transaction due to error ${JSON.stringify(error)} ${this.id}`);
    } else {
      Log.info(`(${this.id}) Ending transaction and removing all listeners from ${this.deviceController.activeDevices.size} devices`); // eslint-disable-line max-len
    }
    if (this.alert) {
      this.alert.dismiss();
    }

    if (this.isRefund()) {
      Tracker.publishPageView(error, error ? pages.refundDecline : pages.refundComplete);
    } else {
      Tracker.publishPageView(error, error ? pages.paymentDecline : pages.paymentComplete);
    }
    this._reset();
    if (TransactionContext.active === this) {
      Log.debug(() => `${this.id} is no longer active. TransactionContext.active = null`);
      delete TransactionContext.active;
    }
    Log.debug(() => `${this.id} ENDED... Will invoke cancel`);
    this._cancel(() => {
      this._state.setPaymentState(PaymentState.complete);
      if (this.completedHandler && invokeHandler) {
        Log.debug(() => `Invoking completed handler '${this.completedHandler.id}' for ${this.id}`);
        this.completedHandler(error, txRecord);
      } else {
        Log.debug(() => `Cannot invoke completion handler as it was not set/removed from ${this.id}`);
      }
      this.dropHandlers();
      this.deviceController.removeListeners();
    });
  }

  /**
   * Determines if an in-progress payment could be cancelled
   * @private
   */
  get allowInProgressPaymentCancel() {
    return this.card && (this.card.formFactor !== FormFactor.MagneticCardSwipe && !this.card.isContactlessMSD);
  }

  _reset() {
    Log.debug(() => `Resetting state of ${this.id}`);
    this.retryCountInvalidChip = 0;
    this.pinPresent = false;
    this.pinRequired = false;
    this.allowFallBackSwipe = false;
    if (this.card) {
      this.card.isMSRFallbackAllowed = false;
    }
  }

  on(eventName, listener) {
    listener.id = `tx-listener-${getRandomId()}`;
    super.on(eventName, listener);
    Log.debug(() => `Listener: Added '${listener.id}' for '${eventName}' ${this.id}`);
  }

  emit(eventName, ...args) {
    Log.debug(() => `Listener: Emitting '${eventName}' event to ${this.listenerCount(eventName)} listener(s). '${this.id}'`);
    for (const listener of this.listeners(eventName)) {
      Log.debug(() => `   ${this.id} Emitting to '${listener.id}' listener`);
    }
    super.emit(eventName, ...args);
  }

  removeListener(eventName, listener) {
    Log.debug(() => `Listener: Removed listener '${listener.id}' for '${eventName}'. '${this.id}'`);
    super.removeListener(eventName, listener);
  }

  /**
   * Abort an idle transaction abandoning activated readers and all event listeners. The completed event
   * will NOT be fired for this TransactionContext given that you have explicitly abandoned it
   * @param {TransactionContext~complete} callback Callback to invoke after clearing the context
   * @returns {bool} True if the transaction can be cleared, false otherwise
   */
  clear(callback) {
    if (this._state.getPaymentState() === PaymentState.inProgress) {
      Log.debug(() => `Cannot CLEAR transaction ${this.id} as card was presented`);
      return false;
    }
    Log.debug(() => `CLEAR ${this.id}. Will drop all listeners`);
    this._cancel(callback);
    this.dropHandlers();
    return true;
  }

  /**
   * Check to see if payment is in 'retry' state. This check helps with
   * disconnection/connection logic when the app goes in the background.
   * @returns {bool} True if the payment is in retry, false otherwise
   */
  isPaymentInRetryOrProgress() {
    return ((this._state.getPaymentState() === PaymentState.retry) ||
            (this._state.getPaymentState() === PaymentState.inProgress));
  }

  /**
   * Request to cancel an ongoing payment. The request will only be accepted if card was presented and the presented
   * form factor accepts cancellation.
   * @returns {bool} Returns true if payment cancellation was be requested. (This does not guarantee a cancellation)
   */
  requestPaymentCancellation() {
    throw new Error('NOT IMPLEMENTED');
    // if (this._state.getPaymentState() === transactionState.idle) {
    //   Log.debug(() => `RequestPaymentCancel: Cancelling as transaction '${this.id}' is in idle state`);
    //   this.end(transactionError.customerCancel, {});
    //   return true;
    // }
    //
    // if (this._state.getPaymentState() === transactionState.paymentInProgress) {
    //   const cardFormFactor = this.card ? getPropertyName(FormFactor, this.card.formFactor) : null;
    //   if (this.card && this.card.reader && this.allowInProgressPaymentCancel()) {
    //     Log.debug(() => `RequestPaymentCancel: Emitting cancel requested event for tx '${this.id}' on reader '${this.card.reader.id}'`);
    //     this.card.reader.emit(PaymentDevice.Event.cancelRequested);
    //     return true;
    //   }
    //   Log.debug(() => `RequestPaymentCancel: Ignoring as transaction '${this.id}' cannot be cancelled. Card presented via ${cardFormFactor}`);
    // }
    // return false;
  }

  // TODO Rename once requestPaymentCancellation is implemented
  _cancel(callback) {
    const activeReader = this.deviceController.selectedDevice;
    Log.debug(() => `CANCEL ${this.id} for active device '${activeReader ? activeReader.id : '<no device>'}'. Will drop all listeners`);
    if (this._state.getTippingState() === TippingState.inProgress) {
      Log.debug('The tip flow was cancelled');
      if (this.tippingFlow) {
        this.tippingFlow.abort();
      }
    }

    this._deferredActivateOptions = null;
    PaymentDevice.Events.removeListener(PaymentDevice.Event.selected, this._deferredBeginHandler);
    this.deviceController.abort((pd) => {
      Log.debug(() => `Aborted tx on ${pd ? pd.id : '<no device>'} for ${this.id}`);
      this.deviceController.startPollingForBattery();
      const ff = [FormFactor.Chip, FormFactor.EmvCertifiedContactless, FormFactor.MagneticCardSwipe];
      this.deactivateFormFactors(ff, () => {
        Log.debug(() => `${this.id} was successfully cancelled. Active ff: '${[...this.getSetOfActiveFormFactors()]}'`);
        callback();
      });
    });
  }

  /**
   * Remove all handlers
   */
  dropHandlers() {
    Log.debug(() => `Dropping all response handlers for ${this.id}`);
    this.completedHandler = null;
    this.cardPresentedHandler = null;
    this.timeoutHandler = null;
    this.cardInsertedHandler = null;
    this.receiptHandler = null;
    for (const property in TransactionEvent) {
      if ({}.hasOwnProperty.call(TransactionEvent, property)) {
        const event = TransactionEvent[property];
        for (const l of this.listeners(event)) {
          this.removeListener(event, l);
        }
      }
    }
  }

  _setPaymentInProgress() {
    this._state.setPaymentState(PaymentState.inProgress);
    Log.debug(() => `TransactionContext.active=${this.id}`);
    TransactionContext.active = this;
  }

  /**
   * Discard the presented card for non-EMV transactions only
   * @param {Card} card The card that was presented
   */
  discardPresentedCard(card) {
    if (!card) {
      return;
    }

    if (this._state.getPaymentState() === PaymentState.inProgress) {
      const error = transactionError.cannotDiscardCard
        .withDevMessage('Cannot discard when payment is in progress');
      Log.error(`discardPresentedCard failed with error: ${error}`);
      throw error;
    }

    if (card.formFactor === FormFactor.Chip || card.formFactor === FormFactor.EmvCertifiedContactless) {
      const error = transactionError.cannotDiscardCard
        .withDevMessage('Can only discard non EMV payments after card data read');
      Log.error(`discardPresentedCard failed with error: ${error}`);
      throw error;
    }
    Log.debug(() => `Will discard presented card ${card}`);
    this.card = null;
  }

  /**
   * Continue processing a transaction - the behavior of which depends on the presented card.
   * If it's a magnetic card or an NFC tap, payment will be attempted and money will move
   * (if successful). If it's an EMV card insertion, we will start the EMV flow which includes
   * a few calls to the server, potentially asking the user to enter a PIN, etc.
   * @param {Card} card The card, typically received via cardPresented, but in certain
   * regions you can simply provide a card number, address verification (AVS) fields such
   * as postal code, expiration and CVV.
   */
  continueWithCard(card) {
    Log.info(`Continue with CARD invoked for ${this}`);
    if (card) {
      Log.info(`${this.id} Card (type: ${card.constructor.name}) was presented ${card}`);
      if (!card.isContactlessMSD &&
        (card.formFactor === FormFactor.Chip || card.formFactor === FormFactor.EmvCertifiedContactless)) {
        Tracker.publishPageView(null, pages.emv);
      } else if (card.formFactor === FormFactor.MagneticCardSwipe) {
        Tracker.publishPageView(null, pages.swipe);
      } else if (card.formFactor === FormFactor.ManualCardEntry) {
        Tracker.publishPageView(null, pages.keyIn);
      }

      if (card.formFactor === FormFactor.ManualCardEntry) {
        this.card = card;
        let amountError = null;
        if (this.isInvoiceAmountBelowAllowedMinimum()) {
          amountError = transactionError.amountTooLow;
        } else if (this.isInvoiceAmountAboveAllowedMaximum()) {
          amountError = transactionError.amountTooHigh;
        }
        if (amountError) {
          const errorHandler = new PaymentErrorHandler(this);
          errorHandler.handle(amountError, card.formFactor, this.deviceController.selectedDevice,
              () => this.processErrorHandlerResponse(amountError, null, card.formFactor));
        } else {
          this._continuePayment(PaymentType.keyIn);
        }
        return;
      }
    } else {
      Log.debug(() => `No card presented ${this.id}`);
    }

    const initializationForFlow = () => {
      this._setPaymentInProgress();
      this.deviceController.removeListeners();
    };
    // From this point onwards, the events will be handled by the flow controllers
    const cbFlowComplete = (err, errAction, txRecord) => {
      Log[err ? 'error' : 'info'](
        `Transaction flow complete handler was invoked with action: '${errAction}' and error ${err} ${this.id}`);
      if (errAction && errAction !== ErrorAction.abort) {
        this.processErrorHandlerResponse(err, errAction, card.formFactor);
      } else {
        this.end(err, txRecord);
      }
    };
    if (this.type === TransactionType.Sale) {
      this.card = card;
      if (card instanceof MagneticCard) {
        card.isSignatureRequired = this._isMSRFallbackSignatureRequired(card) ||
          this.invoice.total.greaterThanOrEqualTo(Merchant.active.signatureRequiredAbove);
      }
      this.paymentType = PaymentType.card;
      const CCFlow = (this.paymentOptions.quickChipEnabled) ?
        require('./../flows/QuickChipCreditCardFlow').default : // eslint-disable-line global-require
        require('./../flows/CreditCardFlow').default; // eslint-disable-line global-require

      // After reading card data, the tipping amount can be added to the tender only for card swipes
      if (this.paymentOptions.tippingOnReaderEnabled
        && card && card.formFactor === FormFactor.MagneticCardSwipe
        && (this._state.getPaymentState() === PaymentState.retry
        || (this._state.getTippingState() === TippingState.notStarted))) {
        this._beginTippingOnReader(this.paymentOptions.amountBasedTipping, false, () => {
          Log.debug(() => `After tipping, started the credit card flow for ${this.id}`);
          initializationForFlow();
          this.flow = new CCFlow(card, this, cbFlowComplete);
        });
      } else {
        Log.debug(() => `${this.id} Will not start tipping flow tippingOnReaderEnabled=${this.paymentOptions.tippingOnReaderEnabled}, state=${this._state}`);
        initializationForFlow();
        this.flow = new CCFlow(card, this, cbFlowComplete);
      }
    } else if (this.type === TransactionType.Auth) {
      Log.debug(() => `${this.id} is an AUTH transaction`);
      this.paymentType = PaymentType.card;
      const CCFlow = require('./../flows/CreditCardFlow').default; // eslint-disable-line global-require
      initializationForFlow();
      this.flow = new CCFlow(card, this, cbFlowComplete);
    } else {
      initializationForFlow();
      this.card = card;
      const RefundFlow = require('./../flows/refundFlow').default; // eslint-disable-line global-require
      this.flow = new RefundFlow(card, this, cbFlowComplete);
    }
  }

  /**
   * Sync the Invoice total to the reader. Use this function to sync
   * invoice amount on the app to the reader
   */
  startInvoiceSync() {
    this.deviceController.syncInvoice();
  }

  _stopInvoiceSync() {
    this.deviceController.stopInvoiceSync();
  }

  /**
   * Continue processing a cash transaction.
   */
  continueWithCash() {
    Log.debug(() => `Continue with CASH invoked for ${this.id}`);
    if (this.type === TransactionType.Auth) {
      this.end(transactionError.invalidAuthorization);
      return;
    }
    this._continuePayment(PaymentType.cash);
  }

  /**
   * Continue processing a check transaction.
   */
  continueWithCheck() {
    Log.debug(() => `Continue with CHECK invoked for ${this.id}`);
    if (this.type === TransactionType.Auth) {
      this.end(transactionError.invalidAuthorization);
      return;
    }
    this._continuePayment(PaymentType.check);
  }

  _continuePayment(paymentType) {
    this._setPaymentInProgress();
    this.deactivateFormFactors([FormFactor.EmvCertifiedContactless], () => {
      this.deviceController.removeListeners();
      this.paymentType = paymentType;
      this._stopInvoiceSync();
      const PaymentFlow = require('./../flows/PaymentFlow').default; // eslint-disable-line global-require
      this.flow = new PaymentFlow(this, (err, action, record) => this.end(err, record));
    });
  }

  _isMSRFallbackSignatureRequired(card) {
    // Always ask for signature in case of a fallback swipe.
    return card.isMSRFallbackAllowed && this._state.isFormFactorActive(FormFactor.Chip);
  }

  /**
   * If you acquire signatures yourself, for example from a Topaz Pen Pad or with an external
   * camera, set this property to a handler that will be invoked when signature should be
   * collected. Once you've collected the signature, call the supplied signatureReceiver
   * with a base64 encoded JPG of the signature. Try to keep it under 100k.
   * @param {TransactionContext~signatureCollector} collector The function that will be
   *  called when a signature should be acquired
   */
  setSignatureCollector(collector) {
    this._signatureCollector = collector;
  }

  /**
   * Provide a token expiration handler if you want to handle token expirations during a transaction
   * @param {TransactionContext~tokenExpirationHandler} expirationHandler
   */
  setTokenExpiredHandler(expirationHandler) {
    if (!expirationHandler) {
      this.timeoutHandler = null;
      return;
    }
    const handler = (handle) => {
      Log.debug(() => `Invoking token expiration handler ${handler.id} for ${this.id}`);
      expirationHandler(handle);
    };
    handler.id = `timeout-${getRandomId()}`;
    this.timeoutHandler = handler;
    Log.debug(() => `Set token expiration handler to ${handler.id} for ${this.id}`);
  }

  /**
   * Provide a handler to get notified after chip card insert is detected but before EMV data is read.
   * cardInsertedHandler.continueWithCardDataRead must be invoked to continue with transaction
   * @param {TransactionContext~cardInsertedHandler} cardInsertedHandler
   */
  setCardInsertedHandler(cardInsertedHandler) {
    if (!cardInsertedHandler) {
      this.cardInsertedHandler = null;
      return;
    }
    const handler = (handle) => {
      Log.debug(() => `Invoking card inserted handler ${handler.id} for ${this.id}`);
      cardInsertedHandler(new CardInsertedHandler(() => {
        Log.debug('Card Inserted Handler : about to read card data.');
        this.deviceController.cardInsertDetected();
        this.deviceController.stopPollingForBattery();
        this._stopInvoiceSync();
        handle.continueWithCardDataRead();
      }));
    };
    handler.id = `cardInserted-${getRandomId()}`;
    this.cardInsertedHandler = handler;
    Log.debug(() => `Set card inserted handler to ${handler.id} for ${this.id}`);
  }

  /**
   * Provide a handler to get notified when card was presented.
   * @param {TransactionContext~cardPresented} cardPresentedHandler
   */
  setCardPresentedHandler(cardPresentedHandler) {
    if (!cardPresentedHandler) {
      this.cardPresentedHandler = null;
      return;
    }
    const handler = (card) => {
      Log.debug(() => `Invoking card PRESENTED handler ${handler.id} for ${this.id}`);
      cardPresentedHandler(card);
    };
    handler.id = `cardPresented-${getRandomId()}`;
    this.cardPresentedHandler = handler;
    Log.debug(() => `Set card presented handler to ${handler.id} for ${this.id}`);
  }

  /**
   * Provide a handler to get notified once transaction is complete
   * @param {TransactionContext~transactionCompleted} completedHandler
   */
  setCompletedHandler(completedHandler) {
    if (!completedHandler) {
      this.completedHandler = null;
      return;
    }
    const handler = (err, txRecord) => {
      Log.debug(() => `Invoking COMPLETION handler ${handler.id} for ${this.id}`);
      completedHandler(err, txRecord);
    };
    handler.id = `completed-${getRandomId()}`;
    this.completedHandler = handler;
    Log.debug(() => `Set completed handler to ${handler.id} for ${this.id}`);
  }

  /**
   * If you would like to display additional receipt options such as print, etc., you can provide them here. These
   * options would be presented on the receipt screen below the Email and Text options.
   * @param {[string]} additionalReceiptOptions Additional options to display on the receipt page
   * @param {TransactionContext~receiptOptionHandler} receiptHandler Provide a handler to get notified when an additional receipt option is selected
   */
  setAdditionalReceiptOptions(additionalReceiptOptions, receiptHandler) {
    if (!receiptHandler) {
      this.receiptHandler = null;
      return;
    }
    const handler = (index, name, txRecord) => {
      Log.debug(() => `Invoking additional receipt options handler ${handler.id} for ${this.id} with index: ${index}, name: ${name}`);
      receiptHandler(index, name, txRecord);
    };
    handler.id = `receiptOptions-${getRandomId()}`;
    this.receiptHandler = handler;
    this.additionalReceiptOptions = additionalReceiptOptions;
    Log.debug(() => `Set additional receipt options handler to ${handler.id} for ${this.id}`);
  }
}

/**
 * Called when either payment completes or fails.
 * Note that other events may be fired in the meantime.
 * @callback TransactionContext~transactionCompleted
 * @param {error} error The error that caused the transaction to fail, if any
 * @param {TransactionRecord} record The transaction record for successful transactions
 *  and failed transactions that reached PayPal.
 */

/**
 * Depending on your region and the buyer payment type, this can mean a magnetic
 * card was swiped, an EMV card was inserted, or an NFC card/device was tapped.
 * @callback TransactionContext~cardPresented
 * @param {Card} card Information about the card.
 */

/**
 * Contactless reader was de-activated and the transaction still remains active.
 * @event TransactionContext#contactlessReaderDeactivated
 */

/**
 * Called when PIN entry is in progress or complete
 * @protected
 * @event TransactionContext#pinEntry
 * @param {bool} complete The PIN entry is complete
 * @param {bool} correct The PIN entry is correct
 * @param {int} pinDigits The number of digits entered
 * @param {bool} lastAttempt Whether this is the last attempt before pin lockout
 */

/**
 * Called when the signature input interface will be displayed
 * @event TransactionContext#willPresentSignature
 */

/**
 * Called when the tipping on reader flow has been completed
 * @event TransactionContext#readerTippingCompleted
 * @param {decimal} tipAmount The tip amount set in the invoice after tipping on reader flow completes
 */

/**
 * Called when the signature entry is completed
 * @event TransactionContext#didCompleteSignature
 * @param {error} error The error which caused the signature not to be acquired or saved,
 *  or null if it worked
 */

/**
 * @callback TransactionContext~signatureCollector
 * @param {SignatureReceiver} signatureReceiver Call continueWithSignature or
 *  cancel on this object once signature acquisition is complete.
 */

/**
 * @callback TransactionContext~tokenExpirationHandler
 * @param {TokenExpirationHandler} tokenExpirationHandler Call quit to abort the transaction or call continueWithNewToken
 * by providing a valid composite token
 */

/**
 * @callback TransactionContext~cardInsertedHandler
 * @param {CardInsertedHandler} cardInsertedHandler Call continue to read EMV data from inserted chip card
 */

/**
 * Called when one of the additional receipt option is selected.
 * @callback TransactionContext~receiptOptionHandler
 * @param {int} index The index of the selected receipt option.
 * @param {string} name The name of the selected receipt option.
 * @param {TransactionRecord} record The transaction record for successful transactions
 *  and failed transactions that reached PayPal. @readonly
 */

/**
 * @callback TransactionContext~complete
 * @param {error} error Error (if any)
 */
