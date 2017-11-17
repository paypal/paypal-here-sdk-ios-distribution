"use strict";

chrome.runtime.getBackgroundPage(function (bg) {
    var SDK = bg.PayPalRetailSDK, merchant;
    var lastInvoice = null;

    $('#charge').on('click', function () {
        var invoice = new SDK.Invoice();
        invoice.addItem("Widget", "1", $('#amount').val(), "Id1");
        console.log($('#gratuity').val());
        invoice.gratuityAmount = $('#gratuity').val();
        $('#charge').prop('disabled', true);
        startSale(invoice);
    });

    $('#refund-last').on('click', function () {
        startRefund(lastInvoice);
    });

    function startSale(invoice) {
        merchant.isCertificationMode = $('#certificationMode').is(':checked');
        var tx = SDK.createTransaction(invoice);
        tx.begin(true);
        tx.on('completed', function (err, result) {
            console.log('Transaction result', err, result);
            $('#charge').prop('disabled', false);
            $('#status').text('Ready for ' + merchant.emailAddress);
            $('#refund-last').prop('disabled', false);
            lastInvoice = invoice;
        });
        tx.on('cardPresented', function (card) {
            $('#status').text('Card Presented...');
            tx.continueWithCard(card);
        });
        tx.on('willPresentSignature', function () {
            chrome.app.window.current().fullscreen();
        });
        tx.on('didCompleteSignature', function () {
            chrome.app.window.current().restore();
        });
    }

    function startRefund(invoice) {
        var tx  = SDK.createTransaction(invoice);
        tx.beginRefund(true, invoice.total);

        tx.on('completed', function (err, result) {
            console.log('Refund result', err, result);
            $('#charge').prop('disabled', false);
            $('#status').text('Ready for ' + merchant.emailAddress);
            $('#refund-last').prop('disabled', true);
            lastInvoice = null;
        });
        tx.on('cardPresented', function (card) {
            $('#status').text('Card Presented...');
            tx.continueWithCard(card);
        });

    }

    $('#charge').prop('disabled', true);
    $('#refund-last').prop('disabled', true);
    $('#status').text('Initializing SDK ');
    $('#reader-status').text('Please connect a reader.');
    SDK.initializeSDK();
    registerSDKEvents();

    $('#status').text('Initializing Merchant');
    SDK.initializeMerchant(bg.sdkTestToken, function (e, m) {
        merchant = m;
        if (e) {
            console.error(e);
            $('#status').text = 'Error: ' + e.message;
        } else {
            $('#status').text('Ready for ' + m.emailAddress);
            $('#charge').prop('disabled', false);
        }
    });

    function registerSDKEvents() {
        SDK.on('deviceDiscovered', (pd)=> {
            $('#reader-status').text('Connected with ' + pd.id);
            pd.on('updateRequired', (updateRequired)=> {
                pd.pendingUpdate.offer(()=> {

                });
            });

            pd.on('deviceRemoved', (pd)=> {
                $('#reader-status').text(pd.id + ' removed.');
            });
        });
    }
});
