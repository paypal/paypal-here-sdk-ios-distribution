import sinon from 'sinon';
import test from 'tape';
import { PaymentDevice } from 'retail-payment-device';
import displayController from '../../js/paymentDevice/CardReaderDisplayController';
import priority from '../../js/paymentDevice/displayPriority';

test('Display controller updates card reader display when invoked the first time irrespective of priority', (t) => {
  // Given
  displayController.resetAll();
  const cardReader = new PaymentDevice();
  const displayArgs = { id: PaymentDevice.Message.Connecting, substitutions: { id: 'PayPal-1' } };
  sinon.stub(cardReader, 'display');

  // When updating reader display for the first time
  cardReader.display.yieldsAsync(null);
  displayController.display(priority.medium, cardReader, displayArgs);
  t.ok(cardReader.display.calledWith(displayArgs), 'Card reader display updated when controller.display is invoked the first time');

  cardReader.display.reset();

  // When updating reader with message of lower priority
  cardReader.display.yieldsAsync(null);
  displayController.display(priority.low, cardReader, displayArgs);
  t.notOk(cardReader.display.called, 'Card reader display not updated when pushing message of lower priority');

  t.end();
});

test('Display controller does not update reader display for message of lower priority', (t) => {
  // Given
  displayController.resetAll();
  const cardReader = new PaymentDevice();
  const displayArgs1 = { id: PaymentDevice.Message.Connecting, substitutions: { id: 'PayPal-1' } };
  const displayArgs2 = { id: PaymentDevice.Message.ConnectionFailed, substitutions: { id: 'PayPal-1' } };
  sinon.stub(cardReader, 'display');

  // When updating reader display
  cardReader.display.yieldsAsync(null);
  displayController.display(priority.high, cardReader, displayArgs1);
  displayController.display(priority.medium, cardReader, displayArgs2);

  // Then
  t.equal(cardReader.display.callCount, 1, 'Card reader display was only invoked the first time for high priority message');
  t.ok(cardReader.display.calledWith(displayArgs1), 'Display arg matches');
  t.end();
});

test('Display controller replaces lower priority message with a higher priority one', (t) => {
  // Given
  displayController.resetAll();
  const cardReader = new PaymentDevice();
  const displayArgs1 = { id: PaymentDevice.Message.Connecting, substitutions: { id: 'PayPal-1' } };
  const displayArgs2 = { id: PaymentDevice.Message.ConnectionFailed, substitutions: { id: 'PayPal-1' } };
  sinon.stub(cardReader, 'display');

  // When updating reader display
  cardReader.display.yieldsAsync(null);
  displayController.display(priority.medium, cardReader, displayArgs1);
  displayController.display(priority.high, cardReader, displayArgs2);

  // Then
  t.equal(cardReader.display.callCount, 2, 'Display controller replaced low priority message with higher priority one');
  t.ok(cardReader.display.firstCall.calledWith(displayArgs1), 'Display arg matches for first call');
  t.ok(cardReader.display.secondCall.calledWith(displayArgs2), 'Display arg matches for second call');

  t.end();
});

test('Display controllers reset function resets the controller state', (t) => {
  // Given
  displayController.resetAll();
  const cardReader = new PaymentDevice();
  const displayArgs1 = { id: PaymentDevice.Message.Connecting, substitutions: { id: 'PayPal-1' } };
  const displayArgs2 = { id: PaymentDevice.Message.ConnectionFailed, substitutions: { id: 'PayPal-1' } };
  sinon.stub(cardReader, 'display');

  // When updating reader display
  cardReader.display.yieldsAsync(null);
  displayController.display(priority.high, cardReader, displayArgs1);
  displayController.resetAll();
  displayController.display(priority.low, cardReader, displayArgs2);

  // Then
  t.equal(cardReader.display.callCount, 2, 'Display controller replaced high priority message with low priority one as reset was invoked');
  t.ok(cardReader.display.firstCall.calledWith(displayArgs1), 'Display arg matches for first call');
  t.ok(cardReader.display.secondCall.calledWith(displayArgs2), 'Display arg matches for second call');

  t.end();
});

