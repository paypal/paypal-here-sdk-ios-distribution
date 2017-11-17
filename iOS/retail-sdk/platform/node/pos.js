var readline = require('readline'),
    Scanner = require('./lib/Scanner'),
    fs = require('fs'),
    wreck = require('wreck'),
    native = require('./lib/nodeNative'),
    argv = require('minimist')(process.argv.slice(2));

if (argv.quiet || argv.q) {
    require('manticore-log').Root.level = 'NONE';
} else if (argv.log) {
    require('manticore-log').Root.level = argv.log;
}

var rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

var token = argv.token;
if (!token || token[0] === '@') {
    token = token ? token.substring(1,token.length) : '../../testToken.txt';
    token = fs.readFileSync(token, 'utf8');
}

var deviceManager, merchant;

native.on('ready', (sdk) => {
    deviceManager = new Scanner({sdk: sdk});
    deviceManager.periodicScan(5);
    sdk.initializeMerchant(token, (error, _merchant) => {
        if (error) {
            console.log(`Failed to initialize the merchant: ${error.message}`);
            process.exit(-1);
        }
        merchant = _merchant;
        console.log(`READY for ${merchant.emailAddress}`);
        runPos();
    });
});

// This is equivalent to initializeSDK in the native SDKs
// You can use either the source or the compiled version. Source makes debugging easier.
require('../../js/debug');
require('../../js/index');
// require('../../PayPalRetailSDK')

function runPos() {
    var amt = argv.amount;
    if (!amt) {
        rl.question('Enter the amount to charge: ', (answer) => {
            makeInvoice(answer);
        });
    } else {
        makeInvoice(amt);
    }
}

function makeInvoice(amt) {
    var invoice = new native.Invoice(merchant.currency || 'GBP');
    var txContext = sdk.createTransaction(invoice);
    txContext.totalDisplayFooter = '\nNode FTW';
    invoice.addItem('Amount', '1', amt, 'Id1');
    console.log(`Created invoice for ${invoice.total.toString()}`);

    var choice;
    if (argv.card) {
        choice = '1';
    } else if (argv.cash) {
        choice = '0';
    }
    if (!choice) {
        rl.question('How do you want to get paid?\n 1 - Card Flow\n 2 - Cash\n 3 - Manual Card Entry\n[1] ==> ', (answer) => {
            chose(answer, txContext);
        });
    } else {
        chose(choice, txContext);
    }
}

function chose(choice, txContext) {
    if (!choice || choice.length === 0 || choice == 1) {
        txContext.on('cardPresented', (card) => {
            console.log('Card presented! Processing payment.');
            txContext.continueWithCard(card, (error, txOutcome) => {
                console.log(error || txOutcome);
            });
        });
        txContext.begin(true);
        console.log('Waiting for card events...');
    } else if (choice == 3) {
        native.PaymentDevice.devices[0].terminal.promptForSecureAccountNumber("00000002", () => {
            console.log('BACK!');
        });
    } else {
        console.log('Not yet implemented...');
    }
}
