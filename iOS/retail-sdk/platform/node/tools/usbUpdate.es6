var os = require('os'),
    fs = require('fs'),
    exec = require('child_process').exec,
    platform = os.platform();

var miuraWinRE = /Volume Name\s*:\s*MIURA/i;
var miuraMacRE = /^MIURA\s*[0-9]*$/i;
var simpleMPIConfig = generateConfig();

if (platform === 'darwin') {

    /*****************************************************************************/
    /* Mac                                                                   */
    /*****************************************************************************/
    var dirs = fs.readdirSync('/Volumes');
    for (var d of dirs) {
        if (miuraMacRE.test(d)) {
            writeMac(d);
        }
    }

} else if (platform === 'win32') {

    /*****************************************************************************/
    /* Windoze                                                                   */
    /*****************************************************************************/
    exec('fsutil fsinfo drives', (e, stdout, stderr) => {
        if (e) {
            console.error(`Failed to get drive information ${e.message}`);
            process.exit(-1);
        }
        var drives = stdout.split(' ');
        for (var d of drives) {
            if (d[d.length-1] === '\\') {
                checkWinDrive(d);
            }
        }
    });

} else {

    console.error(`Unsupported platform (${platform})!`)

}

/*****************************************************************************/
/* Helper functions                                                          */
/*****************************************************************************/


function checkWinDrive(d) {
    exec('fsutil fsinfo drivetype ' + d, (e, stdout, stderr) => {
        if (stdout && stdout.indexOf('Removable Drive') >= 0) {
            checkWinMiura(d);
        }
    });
}

function checkWinMiura(d) {
    exec('fsutil fsinfo volumeinfo ' + d, (e, stdout, stderr) => {
        if (e) {
            console.error(`Failed to get volume information for ${d}: ${e.message}`);
            return;
        }
        if (miuraWinRE.test(stdout)) {
            fs.writeFileSync(d + 'MPI-Production.cfg', simpleMPIConfig);
            exec('fsutil volume dismount ' + d.substring(0,d.length-1), (e2, so, se) => {
                if (e2) {
                    console.error(`Failed to unmount drive ${d}: ${e2.message}\n${so}${se}`);
                    process.exit(-1);
                }
                console.log(`Updated ${d} - please remove and reconnect.`);
            });
        }
    });
}

function writeMac(d) {
    fs.writeFileSync('/Volumes/' + d + '/MPI-Production.cfg', simpleMPIConfig);
    exec('diskutil unmountDisk "/Volumes/' + d + '"', (e,so,se) => {
        if (e) {
            console.error(`Failed to unmount drive /Volumes/${d}: ${e.message}\n${so}${se}`);
            process.exit(-1);
        }
        console.log(`Updated /Volumes/${d} - please remove and reconnect.`);
    });
}

function generateConfig() {
    return `; Miura MPI production config file for PayPal devices.
[USB]
	default = serial

[bluetooth]
	name = "PayPal {serial}"
	serial_begin = 7
	serial_end = 10
	pairing_displaymode = 0

	led_config_nondisplay = false
	led_unavailable = blink:3000
	led_pairing = blink:500
	led_idle = off
	led_idle_iap = on
	led_connected = on

[iAP]
	protocol = "com.paypal.here.reader"
	bundle_seed_id = "536PU77SSW"
        use_iAP_connection_state = 1

; So we can display ‘Select PayPal 523’ in the pairing mode idle screen
[display]
	variable_expansion = 1


[MPI]
	displaysplash=0
        init_format = "bitmap"
        init_file = "/home/main-user/MPI-Boot.bmp"

        shutdown_format = "text"
	shutdown_text="\{centre}Shutting Down..."



[idle_screen_0]
	data_format = "bitmap"
	file = "/home/main-user/idle-screen-0.bmp"
[idle_screen_1]
	data_format = "text"
	text = "Turn on Bluetooth in phone/tablet settings  Select \{BT_NAME}"
[idle_screen_2]
	data_format = "bitmap"
	file = "/home/main-user/idle-screen-2.bmp"
[idle_screen_3]
	data_format = "bitmap"
	file = "/home/main-user/idle-screen-3.bmp"

# $Revision: 0.0 $

`;
}
