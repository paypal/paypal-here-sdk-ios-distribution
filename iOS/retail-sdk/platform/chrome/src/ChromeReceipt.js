/* global document,window,PayPalRetailSDK */

import { subst } from 'l10n-manticore';
import l10n from '../../../js/common/l10n';
import ui from './packed-ui/receipt';

// TODO figure out how to work this conditional render into the ui packer
const rEmailHtml = `<div class="ppRcpt">
<div class="ppMsg">\${prompt}</div>
<input type="email" id="ppSDKRcptInput" required placeholder="${l10n('Rcpt.EmailPH')}"/>
<div><button class="button">&nbsp;</button></div>
</div>`;

const rTextHtml = `<div class="ppRcpt">
<div class="ppMsg">\${prompt}</div>
<input type="tel" id="ppSDKRcptInput" required placeholder="${l10n('Rcpt.TextPH')}"/>
<div><button class="button">&nbsp;</button></div>
</div>`;

let singleton;

export default class ChromeReceipt {
  static show(options, window, callback) {
    if (!singleton || singleton.window !== window) {
      if (singleton) {
        // Window has changed
        singleton.cleanup();
      }
      singleton = new ChromeReceipt(window);
    }
    singleton.setup(options, callback);
    singleton.dialog.showModal();
    return singleton;
  }

  constructor(window) {
    const self = this;
    const w = window.contentWindow;
    const id = 'ppSDKRcpt';
    this.window = w;

    self.dialog = w.document.querySelector(`#${id}`);
    let d = self;
    if (!d.dialog) {
      const css = w.document.createElement('style');
      css.type = 'text/css';
      if (css.styleSheet) {
        css.styleSheet.cssText = ui.css;
      } else {
        css.appendChild(document.createTextNode(ui.css));
      }
      w.document.head.appendChild(css);
      self.dialog = d = w.document.createElement('dialog');
      d.id = id;
      w.document.body.appendChild(d);
    }
  }

  cleanup() {
    this.dialog.innerHTML = '';
  }

  setup(options, callback) {
    const viewContent = options.byEmail ? options.viewContent.receiptEmailEntryViewContent
      : options.viewContent.receiptSMSEntryViewContent;
    const currency = PayPalRetailSDK.Currency.getCurrency(options.invoice.currency);
    const d = this.dialog;
    const args = {
      amount: currency.format(options.invoice.total),
      prompt: viewContent.title,
    };
    d.innerHTML = subst(options.byEmail ? rEmailHtml : rTextHtml, args);
    const input = d.querySelector('input');
    const btn = d.querySelector('button');
    input.placeholder = viewContent.placeholder;
    const stateUpdater = () => {
      if (input.validity.typeMismatch || input.validity.customError || input.value.length === 0) {
        btn.innerHTML = l10n('Cancel');
        btn.className = 'ppCancel';
      } else {
        btn.innerHTML = viewContent.sendButtonTitle;
        btn.className = '';
      }
    };
    btn.addEventListener('click', () => {
      d.close();
      if (btn.className === 'ppCancel') {
        callback();
      } else {
        callback(null, { name: 'emailOrSms', value: input.value });
      }
    });
    input.addEventListener('input', stateUpdater);
    stateUpdater();
  }
}
