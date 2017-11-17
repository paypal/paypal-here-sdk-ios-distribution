import { TransactionType } from 'retail-payment-device';
import manticore from 'manticore';
import log from 'manticore-log';
import { Tracker, pages } from 'retail-page-tracker';
import { ReceiptViewContent } from '../../transaction/ReceiptViewContent';
import l10n from '../../common/l10n';
import FlowStep from './FlowStep';
import { getAmountWithCurrencySymbol, transactionCancelledError } from '../../common/retailSDKUtil';
import Merchant from '../../common/Merchant';
import { ReceiptDestinationType, ReceiptDestination } from '../../transaction/ReceiptDestination';

const Log = log('flow.step.receipt');

export default class ReceiptStep extends FlowStep {
  constructor(context) {
    super();
    this.context = context;
  }

  execute(flow) {
    if (flow.data.alert) {
      flow.data.alert.dismiss();
      delete flow.data.alert;
    }

    if (this.context.type === TransactionType.Auth) {
      Log.debug('Skipping receipt step for Auth');
      flow.next();
      return;
    }

    flow.data.tx = flow.data.tx || {}; // Failures prior to payment/refund may not have the transaction record
    const invoice = this.context.invoice;
    const tx = flow.data.tx;
    const error = flow.data.error;
    const amount = getAmountWithCurrencySymbol(invoice.currency, this.context.refundAmount || invoice.total);
    const viewContent = new ReceiptViewContent(amount,
        this.context.isRefund(),
        error,
        tx && tx.payer && tx.payer.maskedEmail,
        tx && tx.payer && tx.payer.maskedPhone,
        this.context.additionalReceiptOptions);

    manticore.offerReceipt({
      invoice,
      error: flow.data.error,
      viewContent,
    }, (err, option) => {
      if (option) {
        if (option.name === 'emailOrSms') {
          this._sendReceipt(flow, option.value, invoice, tx);
        } else {
          Log.info(`(${this.context.id}) Custom receipt option selected ${option.value}:${option.name}`);
          if (this.context.receiptHandler) {
            this.context.receiptHandler(option.value, option.name, flow.data.tx);
          }
          Tracker.publishPageView(null, this.context.isRefund() ?
            pages.refundReceiptCustom.withAction(option.name) : pages.paymentReceiptCustom.withAction(option.name));
        }
      } else {
        Tracker.publishPageView(null,
          this.context.isRefund() ? pages.refundReceiptNoThanks : pages.paymentReceiptNoThanks);
        Log.debug(() => `Email/SMS receipt forwarding not required. Skipping receipt step. Native response: ${option}`);
        flow.next();
      }
    });
  }

  _sendReceipt(flow, emailOrSms, invoice, tx) {
    Log.debug(() => `Forward receipt to ${emailOrSms}`);
    const alert = manticore.alert({
      showActivity: true,
      title: l10n('Rcpt.Sending'),
    }, () => {
      // TODO add cancel button support.
    });
    const txNumber = (tx && (tx.transactionHandle || tx.transactionNumber)) || flow.data.transactionNumber;
    const txType = this._transactionType(flow);
    let customerId;
    let receiptPreferenceToken;
    if (tx && tx.payer) {
      customerId = tx.payer.customerId;
      receiptPreferenceToken = tx.payer.receiptPreferenceToken;
    }
    Merchant.active.forwardReceipt(invoice, emailOrSms, txNumber, txType, customerId, receiptPreferenceToken, (err) => {
      if (err) {
        Log.error(`Send receipt failed with ${JSON.stringify(err)}`);
      } else {
        Log.info(`(${this.context.id}) Successfully forwarded receipt to ${emailOrSms} for txNumber: ${txNumber}`);
        if (!tx.receiptDestination) {
          tx.receiptDestination = new ReceiptDestination();
        }
        if ((emailOrSms.indexOf('@') > 0)) {
          tx.receiptDestination.type = ReceiptDestinationType.email;
          tx.receiptDestination.email = emailOrSms;
        } else {
          tx.receiptDestination.type = ReceiptDestinationType.text;
        }
      }
      alert.dismiss();
      flow.next();
    });
  }

  _transactionType(flow) {
    if (flow.data.error) {
      return transactionCancelledError(flow.data.error) ? 'VOID' : 'DECLINE';
    }
    if (this.context.type === TransactionType.Refund) {
      return 'REFUND';
    } else if (this.context.type === TransactionType.PartialRefund) {
      return 'PARTIAL';
    }
    return 'SALE';
  }
}
