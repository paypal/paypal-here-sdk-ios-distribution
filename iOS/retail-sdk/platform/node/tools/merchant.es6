var argv = require('minimist')(process.argv.slice(2)),
    fs = require('fs'),
    native = require('../lib/nodeNative');

native.logLevel = 'WARN';

var token = argv.token;
if (!token || token[0] === '@') {
    token = token ? token.substring(1, token.length) : '../../../testToken.txt';
    token = fs.readFileSync(token, 'utf8');
}

native.on('ready', (sdk) => {
    sdk.initializeMerchant(token, (error, _merchant) => {
        if (error) {
            return console.log(`Failed to initialize the merchant: ${error.message}`);
        }
        console.log(`READY for ${_merchant.emailAddress}`);
    });
});

require('../../../js/index');
