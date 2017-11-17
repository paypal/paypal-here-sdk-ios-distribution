var argv = require('minimist')(process.argv.slice(2)),
    fs = require('fs'),
    Scanner = require('../lib/Scanner'),
    native = require('../lib/nodeNative');

// native.logLevel = 'INFO';

var deviceManager, updater, merchant;

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
        merchant = _merchant;
        console.log(`READY for ${merchant.emailAddress}`);
        getDevices();
    });
});

function getDevices() {
    console.log('SDK initialized, watching for devices.');
    sdk.on('deviceDiscovered', (device) => {
        if (argv.mpi) {
            device.forceMpiUpdate = true;
        }
        if (argv.os) {
            device.forceOsUpdate = true;
        }
        if (argv.config) {
            device.forceConfigUpdate = true;
        }
        if (argv.rki) {
            device.forceRki = true;
        }
        console.log('Found payment device.');
        deviceManager.stopScans();
        device.on('updateRequired', (update) => {
            device.terminal.Config.removeLogs(() => {
                update.offer((error, completion) => {
                    if (completion) {
                        console.log('Software Update Completed!');
                        batteryCheck(device);
                    } else {
                        console.log('Software Update Failed.', error);
                    }
                });
                setInterval(() => {
                    // This just keeps us alive while the updater is waiting for restarts and such.
                }, 10000);
            });
        });
    });

    deviceManager = new Scanner({sdk: sdk});
    deviceManager.scan(() => { });
    deviceManager.periodicScan(5);
}

function batteryCheck(device) {
    var fail = true;
    device.terminal.getBatteryLevel((e,rz) => {
        fail = false;
        console.log(e || rz);
        setTimeout(() => batteryCheck(device), 2500);
    });
    setTimeout(() => {
        if (fail) {
            batteryCheck(device);
        }
    }, 7500);
}

require('../../../js/debug');
require('../../../js/index');
