var argv = require('minimist')(process.argv.slice(3)),
    Scanner = require('../lib/Scanner'),
    MiuraDevice = require('../../../js/paymentDevice/MiuraDevice'),
    native = require('../lib/nodeNative'),
    Log = require('manticore-log')('miuraCopy');

Log.Root.level = 'WARN';
Log.Config.level = 'INFO';

var deviceManager, fileToCopy = require('fs').readFileSync(argv._[0]);

native.on('ready', (sdk) => {
    console.log('SDK initialized, watching for devices.');
    var devFn = (device) => {
        if (device instanceof MiuraDevice) {
            device.terminal.Config.selectFile(argv._[0], true, (selError, selRz) => {
                selError = device.errorOrFailure(selError, selRz);
                if (selError) {
                    console.error('Failed to select file', selError);
                    process.exit(-1);
                }
                chunkItOut(device, fileToCopy, (e) => {
                    if (e) {
                        console.error('Failed to write file', r);
                        process.exit(-1);
                    }
                    if (argv.reset) {
                        if (argv.hard) {
                            device.terminal.hardReset(() => {
                                console.log('Initiated hard reset.');
                                process.exit(0);
                            });
                        } else {
                            device.terminal.softReset(() => {
                                console.log('Initiated soft reset.');
                                process.exit(0);
                            });
                        }
                    } else {
                        process.exit(0);
                    }
                });
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

const STREAM_CHUNK_SIZE = 0x20000;
var startTime;

function chunkItOut(device, file, callback, offset, isRetry) {
    startTime = startTime || new Date();
    offset = offset || 0;
    if (file.length - offset > STREAM_CHUNK_SIZE) {
        device.terminal.Config.streamBinary(file.slice(offset, offset + STREAM_CHUNK_SIZE), offset, 255, false, (writeError, writeRz) => {
            if (writeError || !writeRz.apdu.isSuccess) {
                if (isRetry) {
                    Log.error('Aborting file send early.');
                    if (writeRz) {
                        Log.warn(writeRz.toString());
                    }
                    return callback(writeError, writeRz);
                } else {
                    // Give it a half a second to recover and try the same segment again
                    return setTimeout(() => {
                        chunkItOut(device, file, callback, offset, true);
                    }, 500);
                }
            }
            var perc = parseInt((offset + STREAM_CHUNK_SIZE)*100/file.length);
            if (offset > 0) {
                var rate = (offset + STREAM_CHUNK_SIZE) / (new Date().getTime() - startTime);
                rate = parseInt(rate * 10) / 10;
                Log.info(`Wrote ${STREAM_CHUNK_SIZE}@${offset} (${perc}%) ${rate} kB/s `);
            } else {
                Log.info(`Wrote ${STREAM_CHUNK_SIZE}@${offset} (${perc}%)`);
            }
            chunkItOut(device, file, callback, offset + STREAM_CHUNK_SIZE);
        });
    } else {
        Log.info('Writing final chunk.');
        device.terminal.Config.streamBinary(file.slice(offset), offset, 255, true, callback);
    }
}
