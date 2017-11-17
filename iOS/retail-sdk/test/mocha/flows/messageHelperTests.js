import sinon from 'sinon';
import assert from 'assert';
import proxyquire from 'proxyquire';
import l10n from '../../../js/common/l10n';
import { Invoice } from 'paypal-invoicing';
import {
  PaymentDevice,
  FormFactor,
} from 'retail-payment-device';

const Message = PaymentDevice.Message;
const manticoreStub = {};
const messageHelper = proxyquire('../../../js/flows/messageHelper', { 'manticore': manticoreStub });

describe('Message helper', function() {

  function resetSpyies(spies) {
    for(let spy of spies) {
      spy.reset();
    }
  }

  const deviceController = {
    'selectedDevice': {
      'reader': {
        'display': sinon.stub()
      }
    }
  };

  it('should push cancellation message to both reader and App', (done) => {

    //Given
    let flowData = {};
    let context = {
      deviceController,
      'card': {
        'formFactor': FormFactor.EmvCertifiedContactless,
        'reader': {
          'display': sinon.stub()
        }
      }
    };
    manticoreStub.alert = sinon.stub();

    //When
    messageHelper.showCancellationMessage(context, flowData, ()=> {});

    //Then
    assert.ok(manticoreStub.alert.getCall(0).calledWith({
      title: l10n('EMV.Cancelling'),
      message: null,
      showActivity: true,
      replace: true,
    }));
    assert.ok(context.card.reader.display.getCall(0).calledWith({
      id: Message.TransactionCancelling,
      substitutions: null,
      displaySystemIcons: undefined
    }));
    done();
  });

  it('should indicate processing with PIN message for PIN transactions', (done) => {
    //Given
    let flowData = {};
    let context = {
      deviceController,
      'card': {
        'reader': {
          'display': sinon.stub()
        }
      }
    };

    context.card.reader.display.callsArgAsync(1);

    //When
    messageHelper.showProcessingWithPinMessage(context, flowData, ()=> {

      //Then
      assert.ok(context.card.reader.display.getCall(0).calledWith({
        id: Message.ProcessingWithPin,
        substitutions: null,
        displaySystemIcons: undefined
      }));
      done();
    });
  });

  it('should indicate expected processing status for contactless payments', (done) => {
    //Given
    let invoice = new Invoice('USD');
    let flowData = {};
    let context = {
      deviceController,
      'invoice': invoice,
      'card': {
        'formFactor': FormFactor.EmvCertifiedContactless,
        'reader': {
          'display': sinon.stub()
        }
      }
    };
    context.isRefund = () => false;
    invoice.addItem('name', 1, 1, null, null);
    manticoreStub.alert = sinon.stub();

    //Contactless
    messageHelper.showProcessingMessage(context, flowData, ()=> {
    });

    assert.ok(manticoreStub.alert.getCall(0).calledWith({
      title: l10n('EMV.Processing'),
      showActivity: true,
      message: null,
      replace: true,
      audio: { file: 'success_card_read.mp3' }
    }));
    assert.ok(context.card.reader.display.getCall(0).calledWith({
      id: Message.Processing,
      substitutions: { 'amount' : '$1.00'},
      displaySystemIcons: undefined
    }));
    resetSpyies([manticoreStub.alert, context.card.reader.display]);

    //Contact
    context.card.formFactor = FormFactor.Chip;
    messageHelper.showProcessingMessage(context, flowData, ()=> {
    });

    assert.ok(manticoreStub.alert.getCall(0).calledWith({
      title: l10n('EMV.DoNotRemove'),
      message: l10n('EMV.Processing'),
      showActivity: true,
      replace: true,
      audio: { file: 'success_card_read.mp3' }
    }));
    assert.ok(context.card.reader.display.getCall(0).calledWith({
      id: Message.ProcessingContact,
      substitutions: { 'amount' : '$1.00'},
      displaySystemIcons: undefined
    }));
    resetSpyies([manticoreStub.alert, context.card.reader.display]);

    //Swipe
    context.card.formFactor = FormFactor.MagneticCardSwipe;
    messageHelper.showProcessingMessage(context, flowData, ()=> {
    });

    assert.ok(manticoreStub.alert.getCall(0).calledWith({
      title: l10n('EMV.Processing'),
      message: null,
      showActivity: true,
      replace: true,
      audio: { file: 'success_card_read.mp3' }
    }));
    assert.ok(context.card.reader.display.getCall(0).calledWith({
      id: Message.Processing,
      substitutions: { 'amount' : '$1.00' },
      displaySystemIcons: undefined
    }));
    resetSpyies([manticoreStub.alert, context.card.reader.display]);

    done();
  });
});