import test from 'tape';
import sinon from 'sinon';
import manticore from 'manticore';
import { Invoice } from 'paypal-invoicing';
import { FormFactor, PaymentDevice } from 'retail-payment-device';
import { showProcessingMessage, formattedInvoiceTotal, showRemoveCardMessage, formattedRefundTotal, ifFailureShowMessage } from '../../js/flows/messageHelper';
import l10n from '../../js/common/l10n';

const sandbox = sinon.sandbox.create();

function getInvoice(total, currencyCode) {
  const invoice = new Invoice(currencyCode);
  invoice.addItem('item', 1, total, 'itemId', 'detailId');
  return invoice;
}

test('Processing message for Chip payment', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    card: {
      formFactor: FormFactor.Chip,
    },
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    pinPresent: false,
    invoice: getInvoice(1.00, 'USD'),
  };
  context.isRefund = () => false;
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);

  // When
  showProcessingMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.DoNotRemove'),
      message: l10n('EMV.Processing'),
      showActivity: true,
      replace: true,
      audio: {
        file: 'success_card_read.mp3',
      },
    }, 'Alert arg matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.ProcessingContact,
      substitutions: formattedInvoiceTotal(context.invoice),
    }, 'Pushed expected display message to card reader');

    sandbox.restore();
    t.end();
  });
});

test('Processing message for Chip payment and partial refund', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    card: {
      formFactor: FormFactor.Chip,
    },
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    pinPresent: false,
    invoice: getInvoice(1.00, 'USD'),
    refundAmount: 0.01,
  };
  context.isRefund = () => true;
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);

  // When
  showProcessingMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.DoNotRemove'),
      message: l10n('EMV.Processing'),
      showActivity: true,
      replace: true,
      audio: {
        file: 'success_card_read.mp3',
      },
    }, 'Alert arg matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.ProcessingContact,
      substitutions: formattedRefundTotal(context),
    }, 'Pushed expected display message to card reader');

    sandbox.restore();
    t.end();
  });
});

test('Processing message for Chip payment with PIN', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    card: {
      formFactor: FormFactor.Chip,
    },
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    pinPresent: true,
    invoice: getInvoice(1.00, 'USD'),
  };
  context.isRefund = () => false;
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);

  // When
  showProcessingMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.DoNotRemove'),
      message: l10n('EMV.ProcessingPinOk'),
      showActivity: true,
      replace: true,
      audio: {
        file: 'success_card_read.mp3',
      },
    }, 'Alert arg matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.ProcessingContactWithPin,
      substitutions: formattedInvoiceTotal(context.invoice),
    }, 'Pushed expected display message to card reader');

    sandbox.restore();
    t.end();
  });
});

test('Processing message for non-Chip payment', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    card: {
      formFactor: FormFactor.MagneticCardSwipe,
    },
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    pinPresent: false,
    invoice: getInvoice(1.00, 'USD'),
  };
  context.isRefund = () => false;
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);

  // When
  showProcessingMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.Processing'),
      message: null,
      showActivity: true,
      replace: true,
      audio: {
        file: 'success_card_read.mp3',
      },
    }, 'Alert arg matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.Processing,
      substitutions: formattedInvoiceTotal(context.invoice),
    }, 'Pushed expected display message to card reader');

    sandbox.restore();
    t.end();
  });
});


test('Processing message for non-Chip payment with PIN', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    card: {
      formFactor: FormFactor.MagneticCardSwipe,
    },
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    pinPresent: true,
    invoice: getInvoice(1.00, 'USD'),
  };
  context.isRefund = () => false;
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);

  // When
  showProcessingMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.Processing'),
      message: l10n('EMV.PinOk'),
      showActivity: true,
      replace: true,
      audio: {
        file: 'success_card_read.mp3',
      },
    }, 'Alert arg matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.ProcessingWithPin,
      substitutions: formattedInvoiceTotal(context.invoice),
    }, 'Pushed expected display message to card reader');

    sandbox.restore();
    t.end();
  });
});

test('Displays amount paid message on the reader and the app on payment completion', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    isRefund: () => false,
    invoice: getInvoice(1.00, 'USD'),
  };
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);
  // When
  showRemoveCardMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.Complete', formattedInvoiceTotal(context.invoice)),
      message: l10n('EMV.Remove'),
      replace: true,
      showActivity: false,
    }, 'Alert arguments matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.PaidRemoveCard,
      substitutions: formattedInvoiceTotal(context.invoice),
    }, ('Pushed expected display message to card reader'));
    sandbox.restore();
    t.end();
  });
});

test('Displays amount refunded message on the reader and the app on successful refund completion', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const context = {
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    isRefund: () => true,
    invoice: getInvoice(1.00, 'USD'),
    refundAmount: 1.00,
  };
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);
  // When
  showRemoveCardMessage(context, {}, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.RefundComplete', formattedRefundTotal(context)),
      message: l10n('EMV.Remove'),
      replace: true,
      showActivity: false,
    }, 'Alert arguments matches');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.RefundRemoveCard,
      substitutions: formattedRefundTotal(context),
    }, ('Pushed expected display message to card reader'));
    t.end();
  });
});

test('Displays please remove card message on the app on refund failure', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const flowData = {
    error: {
      code: '11',
      domain: 'transaction',
    },
  };
  const context = {
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    isRefund: () => true,
    invoice: getInvoice(1.00, 'USD'),
    refundAmount: 1.00,
  };
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);
  // When
  showRemoveCardMessage(context, flowData, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.Remove'),
      message: l10n(''),
      replace: true,
      showActivity: false,
    }, 'Alert arguments match');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: l10n(''),
      substitutions: l10n(''),
    }, ('Not pushed remove card message to card reader'));
    t.end();
  });
});

test('Displays refund failed message', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const flowData = {
    error: {
      code: '11',
      domain: 'transaction',
    },
  };
  const context = {
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    isRefund: () => true,
    invoice: getInvoice(1.00, 'USD'),
    refundAmount: 1.00,
  };
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);
  // When
  ifFailureShowMessage(context, flowData, () => {
    // Then
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: PaymentDevice.Message.RefundFailed,
      substitutions: formattedRefundTotal(context),
    }, ('Pushed message to card reader'));
    t.end();
  });
});

test('Displays please remove card message on the app on transaction cancelled by customer', (t) => {
  // Given
  const readerDisplayStub = sandbox.stub();
  const flowData = {
    error: {
      code: '1',
      domain: 'transaction',
    },
  };
  const context = {
    deviceController: {
      selectedDevice: {
        display: readerDisplayStub,
      },
    },
    isRefund: () => false,
    invoice: getInvoice(1.00, 'USD'),
  };
  manticore.alert = sandbox.stub();
  readerDisplayStub.yieldsAsync(null);
  // When
  showRemoveCardMessage(context, flowData, () => {
    // Then
    t.equal(manticore.alert.callCount, 1, 'Alert displayed once');
    t.equal(readerDisplayStub.callCount, 1, 'Reader display set once');
    t.deepEqual(manticore.alert.getCall(0).args[0], {
      title: l10n('EMV.Remove'),
      message: l10n(''),
      replace: true,
      showActivity: false,
    }, 'Alert arguments match');
    t.deepEqual(readerDisplayStub.getCall(0).args[0], {
      displaySystemIcons: undefined,
      id: l10n(''),
      substitutions: l10n(''),
    }, ('Not pushed remove card message to card reader'));
    t.end();
  });
});
