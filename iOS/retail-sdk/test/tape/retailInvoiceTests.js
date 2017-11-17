/**
 * Created by suvaidya on 3/9/17.
 */
import test from 'tape';
import { RetailInvoice } from '../../js/common/RetailInvoice';
import sampleInvJSON from '../data/sample_invoice.json';
import invalidSampleInvJSON from '../data/sample_invalid_invoice.json';


test('Verify to see if toJSON returns additional_data that is not null', (t) => {
  const retailInvoiceTestObj = new RetailInvoice('US');

  retailInvoiceTestObj.deviceName = 'HTC HTC 10';
  retailInvoiceTestObj.footer = 'Limiting chars to sixty chars!';
  retailInvoiceTestObj.sellerId = 'Mobile Testing SIX';

  const jsonInvoice = retailInvoiceTestObj.toJSON();

  t.notEqual(jsonInvoice.additional_data, null, 'toJSON returns an object containing additional_data that is not null');

  t.end();
});

test('Verify to see if SellerId, deviceName, footer, storeId and terminalId are added to "additionaldata" in retail invoice', (t) => {
  const retailInvoiceTestObj = new RetailInvoice('US');

  retailInvoiceTestObj.deviceName = 'Huawei Nexus 6P';
  retailInvoiceTestObj.footer = 'Limiting chars to forty chars!';
  retailInvoiceTestObj.sellerId = 'Mobile Testing Three';
  retailInvoiceTestObj.terminalId = 'zby18hs-a';
  retailInvoiceTestObj.storeId = 'flash-store-1';

  // Contains stringified additional_data object
  const jsonInvoice = retailInvoiceTestObj.toJSON();

  t.equal(sampleInvJSON.additional_data.dname, jsonInvoice.additional_data.deviceName);
  t.equal(sampleInvJSON.additional_data.footer, jsonInvoice.additional_data.footer);
  t.equal(sampleInvJSON.additional_data.sellerId, jsonInvoice.additional_data.sellerId);
  t.equal(sampleInvJSON.additional_data.terminalId, jsonInvoice.additional_data.terminalId);

  t.end();
});


test('Verify server response is parsed properly and set to corresponding fields', (t) => {
  const retailInvoiceTestObj = new RetailInvoice('US');

  retailInvoiceTestObj.readJSON(sampleInvJSON, true);

  t.equal(retailInvoiceTestObj.deviceName, 'Huawei Nexus 6P');
  t.equal(retailInvoiceTestObj.footer, 'Limiting the characters to forty chars!!');
  t.equal(retailInvoiceTestObj.sellerId, 'Mobile TestingThree');
  t.equal(retailInvoiceTestObj.terminalId, 'zby18hs-a');

  t.end();
});

test('Verify invalid JSON from server doesn\'t lead to parsing invalid values', (t) => {
  const retailInvoiceTestObj = new RetailInvoice('US');
  retailInvoiceTestObj.readJSON(invalidSampleInvJSON, true);

  t.notOk(retailInvoiceTestObj.deviceName, 'Devicename is not set');
  t.notOk(retailInvoiceTestObj.footer, 'footer is not set');
  t.notOk(retailInvoiceTestObj.sellerId, 'sellerId is not set');
  t.notOk(retailInvoiceTestObj.terminalId, 'terminalIs is not set');

  t.end();
});

test('Modifying Retail Invoice attributes and checking if changes are reflected in the readJSON and toJSON', (t) => {
  const retailInvoiceTestObj = new RetailInvoice('US');
  retailInvoiceTestObj.readJSON(sampleInvJSON, true);

  retailInvoiceTestObj.deviceName = 'HTC 10';
  retailInvoiceTestObj.terminalId = 'r2d2-asdh4';
  retailInvoiceTestObj.sellerId = 'Joes Generic Business';
  retailInvoiceTestObj.storeId = 'sadasjd132';

  const reqJSON = retailInvoiceTestObj.toJSON();

  const parsedRequsestAddtionalData = JSON.parse(reqJSON.additional_data);

  t.equal(parsedRequsestAddtionalData.merchant.terminalId, 'r2d2-asdh4');
  t.equal(parsedRequsestAddtionalData.dname, 'HTC 10');
  t.equal(parsedRequsestAddtionalData.merchant.storeId, 'sadasjd132');
  t.equal(parsedRequsestAddtionalData.merchant.sellerId, 'Joes Generic Business');

  t.end();
});
