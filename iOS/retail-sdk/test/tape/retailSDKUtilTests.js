import test from 'tape';
import { getAmountWithCurrencySymbol,
  isDatesWithinOffset } from '../../js/common/retailSDKUtil';

test('Formatted amount util function', (suite) => {
  suite.test('Symbol defaults to \'$\' when currency code is not provided', (t) => {
    t.equal(getAmountWithCurrencySymbol(null, 3), '$3.00');
    t.end();
  });

  suite.test('Symbol defaults to \'$\' when currency code is incorrect', (t) => {
    t.equal(getAmountWithCurrencySymbol('XYZ', 4), '$4.00');
    t.end();
  });

  suite.test('Uses \'$\' for AUD', (t) => {
    t.equal(getAmountWithCurrencySymbol('AUD', '4.01'), '$4.01');
    t.end();
  });

  suite.test('Uses \'$\' for USD', (t) => {
    t.equal(getAmountWithCurrencySymbol('USD', '4.01'), '$4.01');
    t.end();
  });

  suite.test('Uses \'$\' for HKD', (t) => {
    t.equal(getAmountWithCurrencySymbol('HKD', '4.01'), '$4.01');
    t.end();
  });

  suite.test('Uses \'$\' for CAD', (t) => {
    t.equal(getAmountWithCurrencySymbol('CAD', '4.01'), '$4.01');
    t.end();
  });

  suite.test('Uses \'£\' for GBP', (t) => {
    t.equal(getAmountWithCurrencySymbol('GBP', '4.01'), '£4.01');
    t.end();
  });

  suite.test('Uses \'€\' for EUR', (t) => {
    t.equal(getAmountWithCurrencySymbol('EUR', '4.01'), '€4.01');
    t.end();
  });
  suite.test('Date is within offset', (t) => {
    // Given
    const startDate = new Date();
    let endDate = new Date(startDate);

    endDate.setDate(startDate.getDate());
    t.equal(isDatesWithinOffset(startDate, endDate, 5), true, 'Date is within offset (5 days): endDate = startDate');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 4);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), true, 'Date is within offset (5 days): endDate = startDate + 4 days');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 3);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), true, 'Date is within offset (5 days): endDate = startDate + 3 days');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 2);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), true, 'Date is within offset (5 days): endDate = startDate + 2 days');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 1);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), true, 'Date is within offset (5 days): endDate = startDate + 1 day');
    t.end();
  });

  suite.test('Date is NOT within offset', (t) => {
    // Given
    const startDate = new Date();
    let endDate = new Date(startDate);

    endDate.setDate(startDate.getDate() + 6);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), false, 'Date is NOT within offset (5 days): endDate = startDate + 6 days');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() - 1);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), false, 'Date is NOT within offset (5 days): endDate = startDate - 1 day');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() - 100);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), false, 'Date is NOT within offset (5 days): endDate = startDate - 100 days');
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 100);
    t.equal(isDatesWithinOffset(startDate, endDate, 5), false, 'Date is NOT within offset (5 days): endDate = startDate + 100 days');
    t.end();
  });
});
