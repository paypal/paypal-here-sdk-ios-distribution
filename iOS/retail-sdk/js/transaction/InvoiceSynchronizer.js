import manticore from 'manticore';
import {
  PaymentDevice,
} from 'retail-payment-device';
import log from 'manticore-log';
import { Invoice } from 'paypal-invoicing';
import { EventEmitter } from 'events';
import TransactionEvent from './transactionEvent';
import displayController from '../paymentDevice/CardReaderDisplayController';
import displayPriority from '../paymentDevice/displayPriority';
import { getAmountWithCurrencySymbol } from '../common/retailSDKUtil';

const InvoiceEvent = Invoice.event;
const Log = log('transactionContext.invoiceSynchronizer');

let syncInvoice = true; // TODO: This is just hack for now. Need to come up with a better strategy.

/**
 * InvoiceSynchronizer is responsible for synchoronizing the invoice with the transaction.
 * Whenever the invoice total changes, it will trigger the total changed event which will
 * eventually update the device display
 */
export default class InvoiceSynchronizer extends EventEmitter {
  constructor(context, deviceController) {
    super();
    this.context = context;
    this.invoice = context.invoice;
    this.deviceController = deviceController;
    this._preferredFormFactors = new Set();
  }

  /**
   * Begin syncing invoice.total with the device display
   */
  start() {
    syncInvoice = true;
    Log.debug(() => `Starting invoice sync on ${this.deviceController.selectedDevice ? this.deviceController.selectedDevice.id : '(no device selected)'} for invoice total ${this.invoice ? this.invoice.total : ''}. context.id: ${this.context.id}`);
    try {
      if (this._q) {
        if (this.invoice || this.context.isRefund()) {
          const amount = this.context.isRefund() ? this.context.refundAmount : this.invoice.total;
          this._q.push(amount);
        } else {
          Log.warn(`Attempt to start invoice sync on ${this.deviceController.selectedDevice ? this.deviceController.selectedDevice.id : '(no device selected)'} with no invoice. context.id: ${this.context.id}`);
        }
        return;
      }

      this._q = {
        tasks: [],
        invoiceSyncInProgress: false,
        kill: () => {
          this._q.tasks = [];
        },
        process: () => {
          if (!this._q || !this._q.tasks.length) {
            return;
          }
          const tasks = this._q.tasks.splice(0, this._q.tasks.length);
          const mostRecentTotal = tasks.pop();
          this._q.invoiceSyncInProgress = true;
          const pd = this.deviceController.selectedDevice;
          if (!pd) {
            this._q.invoiceSyncInProgress = false;
            return;
          }
          this.pushOnce(pd, mostRecentTotal, () => {
            this.emit('onTaskComplete');
            if (!this._q) {
              return;
            }
            this._q.invoiceSyncInProgress = false;
            if (this._q.tasks.length > 0) {
              manticore.setTimeout(() => {
                Log.debug(`manticore timeout syncInvoice: ${syncInvoice}`);
                this._q.process();
              }, 0);
            }
          });
        },
        push: (data) => {
          if (data) {
            this._q.tasks.push(data);
            if (!this._q.invoiceSyncInProgress) {
              Log.debug(`push syncInvoice: ${syncInvoice}`);
              this._q.process();
            }
          } else {
            Log.warn(`Attempt push null data on ${this.deviceController.selectedDevice ? this.deviceController.selectedDevice.id : '(no device selected)'}. context.id: ${this.context.id}`);
          }
        },
      };
      const listener = () => this._q.push(this.invoice ? this.invoice.total : null);
      const refundListener = () => this._q.push(this.context.refundAmount);
      listener.txContext = this.context;
      this.invoice.on(InvoiceEvent.totalMayHaveChanged, listener);
      this.context.on(TransactionEvent.invoiceDisplayFooterUpdated, listener);
      this.context.on(TransactionEvent.refundAmountEntered, refundListener);
      this._q.push(this.invoice ? this.invoice.total : null);
    } catch (x) {
      Log.error(`Invoice Synchronizer failed stopping with error ${x}`);
    }
  }

  pushOnce(pd, invoiceTotal, callback) {
    const deviceStatus = pd.isReadyForTransaction();
    if (!deviceStatus.isReady) {
      Log.debug(() => `Cannot push ${invoiceTotal} to ${pd.id} as card reader is not ready. Error: ${deviceStatus.error}`);
      return;
    }
    if (pd.pendingUpdate && pd.pendingUpdate.isRequired && !pd.pendingUpdate.wasInstalled) {
      pd.display({
        id: PaymentDevice.Message.SoftwareUpdateRequired,
        displaySystemIcons: true,
      }, callback);
      return;
    }
    if (!this._q || !syncInvoice) {
      Log.debug('Invoice Queue is null as stop() was called. Hence, bailing on the sync.');
      callback();
      return;
    }

    const isAmountValid = invoiceTotal.greaterThan(0.0);
    Log.debug(() => `InvoiceSync display for invoice total ${this.invoice ? this.invoice.total : ''}. context.id: ${this.context.id}`);
    displayController.display(displayPriority.medium, pd, {
      id: isAmountValid ? PaymentDevice.Message.InvoiceTotal : PaymentDevice.Message.ReadyWithId,
      substitutions: {
        amount: getAmountWithCurrencySymbol(this.invoice.currency, invoiceTotal),
        footer: this.context.totalDisplayFooter,
        id: pd.id,
      },
      displaySystemIcons: !isAmountValid,
    }, callback);
  }

  /**
   * Stops syncing the device display with the invoice total
   */
  stop() {
    syncInvoice = false;
    Log.debug(() => `Stopping invoice sync on ${this.deviceController.selectedDevice ? this.deviceController.selectedDevice.id : ', '}, this.shouldSync: ${syncInvoice} for invoice total ${this.invoice ? this.invoice.total : ''}. context.id: ${this.context.id}`);
    try {
      const invoiceEvents = [
        InvoiceEvent.totalMayHaveChanged,
      ];
      const transactionEvents = [
        TransactionEvent.invoiceDisplayFooterUpdated,
        TransactionEvent.refundAmountEntered,
      ];
      for (const e of invoiceEvents) {
        for (const l of this.invoice.listeners(e)) {
          if (Object.is(l.txContext, this.context)) {
            this.invoice.removeListener(e, l);
          } else {
            Log.debug(() => `Skip remove of listener for invoice total ${this.invoice ? this.invoice.total : ''} this.context.id: ${this.context.id}, listener.txContext: ${l.txContext.id}`);
          }
        }
      }

      for (const e of transactionEvents) {
        for (const l of this.context.listeners(e)) {
          this.context.removeListener(e, l);
        }
      }

      if (!this._q) {
        return;
      }

      this._q.kill();
      this._q = null;
    } catch (x) {
      Log.error(`Invoice Synchronizer failed stopping with error ${x}`);
    }
  }
}
