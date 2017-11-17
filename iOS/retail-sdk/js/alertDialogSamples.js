/* eslint-disable*/
import manticore from 'manticore';
import log from 'manticore-log';
import { Invoice, InvoiceItem } from 'paypal-invoicing';
import { ReceiptViewContent } from './transaction/ReceiptViewContent';
import l10n from './common/l10n';

const Log = log('alertDialogSample');

// Alert +1500ms
manticore.setTimeout(() => {
  Log.error('TRIGERRING alert(1)');
  manticore.alert({
    title: 'Hello World',
    message: 'Cruel world.',
    showActivity: true,
    setCancellable: true,
    audio: {
      file: 'success_card_read.mp3',
    },
  }, (alert, index) => {
    Log.error(`1. Alert finished : ${!!alert}, index: ${index}, dismiss: ${alert && alert.dismiss}`);
    alert.dismiss();
  });
}, 1500);

// // Alert +2500ms
// manticore.setTimeout(() => {
//   Log.error('TRIGERRING alert(2)');
//   manticore.alert({
//     title: 'HAPPY WORLD',
//     message: 'HAPPY WORLD',
//     cancel: 'MARS',
//     setCancellable: true,
//   }, (alert, index) => {
//     Log.error(`2. Alert finished : ${!!alert}, index: ${index}, dismiss: ${alert && alert.dismiss}`);
//     alert.dismiss();
//   });
// }, 3000);

// // Signature +5000ms
// manticore.setTimeout(() => {
//   Log.error(`***TEMP*** TRIGERRING Signature with ${manticore.collectSignature}`);
//   const sigHandle = manticore.collectSignature({
//     done: l10n('Done'),
//     footer: l10n('Sig.Footer'),
//     title: l10n('Sig.Title', { amount: '$7.77' }),
//     signHere: l10n('Sig.Here'),
//     cancel: l10n('Cancel'),
//   }, (error, signature, cancel) => {
//     Log.error(`Received collectSignature response with error=${error}, cancel=${cancel}\n${signature}`);
//     if (cancel) {
//       manticore.alert({
//         title: l10n('Tx.Alert.Cancel.Title'),
//         message: l10n('Tx.Alert.Cancel.Msg'),
//         buttons: [l10n('Yes')],
//         cancel: l10n('No'),
//       }, (a, ix) => {
//         Log.error(`Received YES/NO response with index: ${ix}`);
//         a.dismiss();
//         if (ix === 0) {
//           sigHandle.dismiss();
//           Log.error('User chose to cancel signature');
//         }
//       });
//     }
//   });
// }, 8000);

// manticore.setTimeout(() => {
//   Log.error(`***TEMP*** TRIGERRING Receipt with ${manticore.offerReceipt}`);
//   const invoice = new Invoice('USD');
//   invoice.addItem(new InvoiceItem('Foo', '1.00', '1.99', '1'));
//   const viewContent = new ReceiptViewContent('$1.00', false, null);
//   manticore.offerReceipt({
//     invoice,
//     viewContent,
//   }, (err, option) => {
//     Log.error(`Received offerReceipt response with err=${err}, option=${option}`);
//     manticore.setTimeout(() => {
//       manticore.alert({
//         title: 'Sending receipt',
//         showActivity: true,
//         cancel: 'Cancel',
//       }, (alert, index) => {
//         Log.error(`3. Alert finished : ${!!alert}, index: ${index}, dismiss: ${alert && alert.dismiss}`);
//         alert.dismiss();
//       });
//     }, 0);
//   });
// }, 8000);

// // 2 - Image button alert
// const imgs2 = ['choose_device_dongle', 'choose_device_black_emv', 'choose_device_black_emv'];
// const ids2 = ['Swiper', 'M010', 'M010'];
// manticore.setTimeout(() => {
//   Log.error('TRIGERRING alert(2-image-button)');
//   manticore.alert({
//     title: l10n('MultiCard.Title'),
//     message: l10n('MultiCard.Msg'),
//     buttonsImages: imgs2,
//     buttonsIds: ids2,
//   }, (alert, index) => {
//     Log.error(`(2-image-button) Alert finished : ${!!alert}, index: ${index}, dismiss: ${alert && alert.dismiss}`);
//     alert.dismiss();
//   });
// }, 2000);
//
//
// // Multi Image button alert
// const imgs = ['choose_device_dongle', 'choose_device_black_emv'];
// const ids = ['Swiper', 'M010'];
// manticore.setTimeout(() => {
//   Log.error('TRIGERRING alert(>2-image-button)');
//   manticore.alert({
//     title: l10n('MultiCard.Title'),
//     message: l10n('MultiCard.Msg'),
//     buttonsImages: imgs,
//     buttonsIds: ids,
//   }, (alert, index) => {
//     Log.error(`(>2-image-button) Alert finished : ${!!alert}, index: ${index}, dismiss: ${alert && alert.dismiss}`);
//     alert.dismiss();
//   });
// }, 5000);

/* eslint-enable*/
