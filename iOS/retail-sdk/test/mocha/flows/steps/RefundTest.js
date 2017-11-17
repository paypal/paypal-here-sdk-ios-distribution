//TODO: Port to tape
// import { $$, InvoiceEnums } from 'paypal-invoicing';
// import Refund from '../../../../js/flows/steps/IssueRefundStep';
// import UpdateInvoice from '../../../../js/flows/steps/UpdateInvoicePaymentStep';
// import Merchant from '../../../../js/common/Merchant';
// import Flow from '../../../../js/common/flow';
//
// let chai = require('chai'),
//     should = chai.should(),
//     fs = require('fs'),
//     testUtils = require('../../../testUtils');
//
// describe('Issue Refund',    function () {
//
//     let merchant,
//         partialRefundFlowData = {
//             refundAmount: $$(1.00),
//             transactionNumber: "2YC75749WF283792G"
//         },
//         fullRefundFlowData = {
//             transactionNumber: "2YC75749WF283792G"
//         };
//
//     before(() => {
//         chai.config.includeStack = true;
//     });
//
//     beforeEach(setup);
//     afterEach(cleanup);
//
//     it('Should issue a partial refund for a card', (done) => {
//         let tx = {
//             merchant,
//             refundAmount: $$(1.0), // partial amount to be refunded
//             card: { formFactor: 1 },
//             invoice: { total: 2.0 },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//
//         mockRefundResponse({statusCode: 200, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('transactionNumber');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.PARTIALLY_REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     it.only('Should issue a partial refund for cash', function() {
//         let tx = {
//             merchant,
//             refundAmount: $$(1.0), // partial amount to be refunded
//             card: null,
//             invoice: { total: 2.0 },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//         flow.data.paymentMethod = InvoiceEnums.PaymentMethod.CASH;
//         flow.data.invoiceId = "2YC75749WF283792G";
//
//         mockCashCheckRefundResponse({statusCode: 204, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         this.timeout(100000);
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('invoiceId');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.PARTIALLY_REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     it('Should issue a full refund for cash', (done) => {
//         let tx = {
//             merchant,
//             refundAmount: $$(2.0), // full amount to be refunded
//             card: null,
//             invoice: { total: 2.0 },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//         flow.data.paymentMethod = InvoiceEnums.PaymentMethod.CASH;
//         flow.data.invoiceId = "2YC75749WF283792G";
//
//         mockCashCheckRefundResponse({statusCode: 204, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('invoiceId');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     it('Should issue a full refund for cash with invoice method set', (done) => {
//         let tx = {
//             merchant,
//             refundAmount: $$(2.0), // full amount to be refunded
//             card: null,
//             invoice: { total: 2.0, method: InvoiceEnums.PaymentMethod.CASH },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//         flow.data.invoiceId = "2YC75749WF283792G";
//
//         mockCashCheckRefundResponse({statusCode: 204, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('invoiceId');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     it('Should issue a partial refund for check', (done) => {
//         let tx = {
//             merchant,
//             refundAmount: $$(1.0), // partial amount to be refunded
//             card: null,
//             invoice: { total: 2.0 },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//         flow.data.paymentMethod = InvoiceEnums.PaymentMethod.CHECK;
//         flow.data.invoiceId = "2YC75749WF283792G";
//
//         mockCashCheckRefundResponse({statusCode: 204, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('invoiceId');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.PARTIALLY_REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     it('Should issue a full refund for check', (done) => {
//         let tx = {
//             merchant,
//             refundAmount: $$(2.0), // full amount to be refunded
//             card: null,
//             invoice: { total: 2.0 },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//         flow.data.paymentMethod = InvoiceEnums.PaymentMethod.CHECK;
//         flow.data.invoiceId = "2YC75749WF283792G";
//
//         mockCashCheckRefundResponse({statusCode: 204, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('invoiceId');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     it('Should issue a full refund for check', (done) => {
//         let tx = {
//             merchant,
//             refundAmount: $$(2.0), // full amount to be refunded
//             card: null,
//             invoice: { total: 2.0, method: InvoiceEnums.PaymentMethod.CHECK },
//         }
//
//         let flow = mockFlow(partialRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//         flow.data.invoiceId = "2YC75749WF283792G";
//
//         mockCashCheckRefundResponse({statusCode: 204, transactionNumber: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('invoiceId');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//
//
//     it('Should issue a full refund for a card', (done) => {
//
//         //Given
//         let tx = {
//             merchant,
//             refundAmount: $$(2.0), // full amount to be refunded
//             card: {formFactor: 1},
//             invoice: { total: 2.0 },
//         }
//         let flow = mockFlow(fullRefundFlowData, [new Refund(tx).flowStep, new UpdateInvoice(tx).flowStep]);
//
//         mockRefundResponse({statusCode: 200, id: "5LP94999JW885643X", state: "completed", errorCode: undefined});
//
//         flow.on('completed', () => {
//             let response = flow.data.tx;
//             should.exist(response);
//             response.should.be.an('object');
//             response.should.have.property('transactionNumber');
//             tx.invoice.payments[0].transactionType.should.equal('REFUND');
//             tx.invoice.status.should.equal(InvoiceEnums.Status.REFUNDED);
//             done();
//         });
//
//         flow.start();
//     });
//
//     function mockFlow(flowData, steps) {
//         let flow = new Flow(this, steps);
//         flow.data = flowData;
//         return flow;
//     }
//
//     function mockRefundResponse(response) {
//         testUtils.addRequestHandler('payments',"sale/2YC75749WF283792G/refund", 'POST', (options, callback) => {
//             process.nextTick(() => {
//                 callback(null, {
//                     headers: {},
//                     statusCode: response.statusCode,
//                     body: {
//                         transactionNumber: response.transactionNumber,
//                         state: response.state,
//                         errorCode: response.errorCode
//                     }
//                 })
//             });
//         });
//     }
//
//     function mockCashCheckRefundResponse(response) {
//         testUtils.addRequestHandler('invoicing',"invoices/2YC75749WF283792G/record-refund", 'POST', (options, callback) => {
//             process.nextTick(() => {
//                 callback(null, {
//                     headers: {},
//                     statusCode: response.statusCode,
//                     body: null,
//                 })
//             });
//         });
//     }
//
//     function setup() {
//         console.log('-----------SETUP BEGIN-----------');
//         testUtils.seizeHttp().addLoginHandlers('GB', 'GBP');
//         mockRefundResponse({statusCode: 200});
//         merchant = new Merchant();
//         merchant.initialize(fs.readFileSync('testToken.txt', 'utf8'), 'live', () => {
//             Merchant.active = merchant;
//         });
//       console.log('-----------SETUP END-----------');
//     }
//
//     function cleanup() {
//         testUtils.releaseHttp();
//     }
//
// });
//
