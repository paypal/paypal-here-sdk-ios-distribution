/* global document */
import SignaturePad from './signature_pad';
import ui from './packed-ui/sig';

let singleton;

export default class ChromeSignature {
  // TODO sort out the whole "I'm a singleton or I'm not" stuff here with events and callbacks
  static create(options, window, callback) {
    if (singleton) {
      singleton.cleanup();
    } else {
      singleton = new ChromeSignature(window);
    }
    singleton.setup(options, callback);
    singleton.show();
    return singleton;
  }

  constructor(window) {
    const self = this;
    const w = window.contentWindow;
    const id = 'ppRetailSig';
    this.window = w;

    this.resizer = function resize() {
      if (self.canvas) {
        self.canvas.height = w.innerHeight - 55;
        self.canvas.width = w.innerWidth - 35;
      }
    };
    w.addEventListener('resize', this.resizer);

    let d = self.dialog = w.document.querySelector(`#${id}`);
    if (!d) {
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
      d.innerHTML = ui.html;
      d.querySelector('button.clear').addEventListener('click', () => {
        self.pad.clear();
      });
      d.querySelector('button.save').addEventListener('click', () => {
        const sig = self.pad.toDataURL('image/jpeg', 0.90);
        d.close();
        const cb = self.callback;
        self.cleanup();
        if (cb) {
          cb(null, new Buffer(sig.substring(sig.indexOf('base64') + 7)));
        }
      });
    }
  }

  cleanup() {
    if (this.canvas && typeof this.canvas !== 'undefined') {
      this.canvas.parentNode.innerHTML = '';
    }
    delete this.canvas;
    delete this.callback;
  }

  setup(options, callback) {
    this.callback = callback;

    this.canvas = this.window.document.createElement('canvas');
    this.resizer();
    this.dialog.querySelector('div.ppRBody').appendChild(this.canvas);
    this.pad = new SignaturePad(this.window, this.canvas, {
      backgroundColor: 'white',
    });

    if (options.title) {
      this.dialog.querySelector('div.title').innerHTML = options.title;
    }

    if (options.signHere) {
      this.dialog.querySelector('div.watermark').innerHTML = options.signHere;
    }

    if (options.done) {
      this.dialog.querySelector('button.save').innerHTML = options.done;
    }

    if (options.footer) {
      this.dialog.querySelector('div.footer').innerHTML = options.footer;
    }
  }

  show() {
    if (!this.dialog.open) {
      this.dialog.showModal();
    }
  }

  /**
   * Does not call the callback
   */
  dismiss() {
    this.dialog.close();
    this.cleanup();
  }

}
