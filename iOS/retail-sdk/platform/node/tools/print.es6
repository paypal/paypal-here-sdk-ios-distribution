var argv = require('minimist')(process.argv.slice(3)),
    Scanner = require('../lib/Scanner'),
    MiuraDevice = require('../../../js/paymentDevice/MiuraDevice'),
    native = require('../lib/nodeNative');

native.logLevel = 'WARN';

var deviceManager;

console.log(argv);

native.on('ready', (sdk) => {
    console.log('SDK initialized, watching for devices.');
    var devFn = (device) => {
        if (device instanceof MiuraDevice) {
            device.terminal.showMessage(argv._[0], () => {
                console.log('Message displayed.');
                process.exit(0);
            });
        }
    };
    sdk.on('deviceDiscovered', (d) => {
        console.error('Found device', d.id);
        deviceManager.stopScans();
        d.rawConnect = true;
        d.disableAutoConnect = true;
        console.error('Connecting to', d.id);
        d.connect((e) => {
            if (!e) {
                devFn(d);
            }
        });
    });

    deviceManager = new Scanner({sdk: sdk});
    deviceManager.periodicScan(5);
});

require('../../../js/index');
