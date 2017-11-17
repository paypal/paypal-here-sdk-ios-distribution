var argv = require('minimist')(process.argv.slice(2)),
    Scanner = require('../lib/Scanner'),
    MiuraDevice = require('../../../js/paymentDevice/MiuraDevice'),
    native = require('../lib/nodeNative');

require('manticore-log')('miuraCopy').Root.level = 'WARN';

var deviceManager;

native.on('ready', (sdk) => {
    console.log('SDK initialized, watching for devices.');
    var devFn = (device) => {
        if (device instanceof MiuraDevice) {

            if (argv.remove) {
                console.log('Removed logs');
                device.terminal.Config.removeLogs(() => {
                    device.terminal.disconnectUsb(() => {
                        process.exit(0);
                    });
                });
            } else {
                device.terminal.Config.archiveLogs(() => {
                    device.terminal.Config.getFile('mpi.log', (err, f) => {
                        if (err) {
                            return console.error('Failed to get logs', err);
                        }
                        console.log(f.toString());
                        process.exit(0);
                    });
                });
            }
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
