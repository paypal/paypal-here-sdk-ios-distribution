var argv = require('minimist')(process.argv.slice(2)),
    Scanner = require('../lib/Scanner'),
    MiuraDevice = require('../../../js/paymentDevice/MiuraDevice'),
    native = require('../lib/nodeNative');

native.logLevel = 'WARN';

var deviceManager;

native.on('ready', (sdk) => {
    console.log('SDK initialized, watching for devices.');
    var devFn = (device) => {
        if (device instanceof MiuraDevice) {
            device.terminal.showMessage(process.argv, () => {
                console.log('done.');
            });
        }
    };
    sdk.on('deviceDiscovered', (d) => {
        console.error('Found device', d.id);
        deviceManager.stopScans();
    });

    deviceManager = new Scanner({sdk: sdk});
    deviceManager.periodicScan(5);
});

require('../../../js/index');
