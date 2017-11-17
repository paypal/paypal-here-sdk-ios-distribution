import {
  PaymentDevice,
  FormFactor,
} from 'retail-payment-device';
import manticore from 'manticore';
import l10n from '../common/l10n';
import { getAmountWithCurrencySymbol } from '../common/retailSDKUtil';

export function formattedAmount(currency, total) {
  return {
    amount: getAmountWithCurrencySymbol(currency, total),
  };
}

export function formattedInvoiceTotal(invoice) {
  return formattedAmount(invoice.currency, invoice.total);
}

export function formattedRefundTotal(context) {
  return formattedAmount(context.invoice.currency, context.refundAmount);
}

function displayOrReuseAlert(flowData, options) {
  flowData.alert = manticore.alert(options, () => {});
  return flowData.alert;
}

export function readerDisplay(context, messageId, substitutions, cb, displaySystemIcons) {
  let reader = context.deviceController.selectedDevice;
  if (context.card && context.card.reader) {
    reader = context.card.reader;
  }
  if (reader) {
    reader.display({ id: messageId, substitutions, displaySystemIcons }, cb);
  } else if (cb) {
    cb();
  }
}

export function showSimpleMessage(title, message, showActivity, flowData) {
  return displayOrReuseAlert(flowData, {
    title,
    message,
    showActivity,
    replace: true,
  });
}

export function showProcessingMessage(context, flowData, cb) {
  const chip = context.card && (context.card.formFactor === FormFactor.Chip);
  const alertOptions = {
    title: chip ? l10n('EMV.DoNotRemove') : l10n('EMV.Processing'),
    message: chip ? l10n('EMV.Processing') : null,
    showActivity: true,
    replace: true,
    audio: {
      file: 'success_card_read.mp3',
    },
  };

  if (context.pinPresent) {
    alertOptions.message = chip ? l10n('EMV.ProcessingPinOk') : l10n('EMV.PinOk');
  }

  const alert = manticore.alert(alertOptions, () => {});
  flowData.alert = alert;

  let messageId = chip ? PaymentDevice.Message.ProcessingContact : PaymentDevice.Message.Processing;
  if (context.pinPresent) {
    messageId = chip ? PaymentDevice.Message.ProcessingContactWithPin : PaymentDevice.Message.ProcessingWithPin;
  }
  const amount = context.isRefund() ? formattedRefundTotal(context)
    : formattedInvoiceTotal(context.invoice);
  readerDisplay(context, messageId, amount, () => cb(alert));
}

export function showRemoveCardForQCMessage(context, flowData, cb) {
  const alert = showSimpleMessage(l10n('EMV.QuickChip'), null, true, flowData);

  readerDisplay(context, PaymentDevice.Message.QuickChip, null, () => cb(alert));
}

export function showProcessingWithPinMessage(context, flowData, cb) {
  readerDisplay(context, PaymentDevice.Message.ProcessingWithPin, null, cb);
}

export function showCancellationMessage(context, flowData, cb) {
  const alert = showSimpleMessage(l10n('EMV.Cancelling'), null, true, flowData);
  readerDisplay(context, PaymentDevice.Message.TransactionCancelling, null, () => cb(alert));
}

export function showFinalizeMessage(context, flowData, cb) {
  // Showing "Completing payment" dialog irrespective of payment type
  const alert = showSimpleMessage(l10n('EMV.Finalize'), null, true, flowData);
  const amt = formattedInvoiceTotal(context.invoice);
  readerDisplay(context, PaymentDevice.Message.CompletingPayment, amt, () => cb(alert));
}

export function showRefundProcessingMessage(context, flowData, cb) {
  return cb(showSimpleMessage(l10n('EMV.ProcessingRefund'), null, true, flowData));
}

export function showRemoveCardMessage(context, flowData, cb) {
  let amt = formattedInvoiceTotal(context.invoice);
  let appTitle = 'EMV.Complete';
  let appMessage = 'EMV.Remove';
  let messageId = PaymentDevice.Message.PaidRemoveCard;
  if (context.isRefund()) {
    amt = formattedRefundTotal(context);
    appTitle = 'EMV.RefundComplete';
    messageId = PaymentDevice.Message.RefundRemoveCard;
  }
  if (flowData.error) {
    appTitle = 'EMV.Remove';
    appMessage = '';
    messageId = '';
    amt = '';
  }
  const alert = showSimpleMessage(l10n(appTitle, amt), l10n(appMessage), false, flowData);

  // TODO Remove the cb parameter in this and showAuthMessage, showFinalizeMessage functions after device EMV device display method
  // is updated to not require a cb
  readerDisplay(context, messageId, amt, () => cb(alert));
}

export function showCompleteMessage(context, flowData, cb) {
  const amt = context.isRefund() ? formattedRefundTotal(context) : formattedInvoiceTotal(context.invoice);
  const msgId = context.isRefund() ? PaymentDevice.Message.Refund : PaymentDevice.Message.Paid;
  readerDisplay(context, msgId, amt, () => cb(flowData));
}

export function ifFailureShowMessage(context, flowData, cb) {
  if (context.isRefund() && flowData.error) {
    const amt = formattedRefundTotal(context);
    const msgId = PaymentDevice.Message.RefundFailed;
    readerDisplay(context, msgId, amt, () => cb(flowData));
  } else {
    cb(flowData);
  }
}

export function showSelectApplicationPrompt(context, flowData, applicationPairs, cb) {
  const buttons = [];
  for (const app of applicationPairs) {
    buttons.push(app[1] || app[0]);
  }

  flowData.alert = manticore.alert({
    title: l10n('EMV.Select'),
    buttons,
  }, (error, ix) => {
    if (cb) {
      const applicationId = applicationPairs[ix][0];
      const applicationName = applicationPairs[ix][1];
      cb(applicationId, applicationName);
    }
  });

  return flowData.alert;
}
