#!/usr/bin/env node
var fs = require('fs-extra'),
    path = require('path'),
    program = require('commander'),
    liwp = require('node-liwp-test-tools'),
    login = require('./payPalAuth');

if (Number(process.version.match(/^v(\d+\.\d+)/)[1]) < 0.12) {
    console.error('This script requires node 0.12 or higher.');
    process.exit(-1);
}

program.
    version('1.0.0').
    command('getToken <outputFile> <stage> <emailAddress>').
    description('Write a self-contained SDK token to a file. These tokens contain the app secret as well and are for stage use only.').
    action(function (outputFile, stage, user) {
        makeFile(outputFile, stage, user);
    });

program.
    command('createApp <stage>').
    description('Create the Login With PayPal app on a stage').
    action(function (stage) {
        makeApp(stage);
    });

program.
version('1.0.0').
command('createAppGetToken <outputFile> <stage> <emailAddress>').
description('Create app and then write a self-contained SDK token to a file. These tokens contain the app secret as well and are for stage use only.').
action(function (outputFile, stage, user) {
    makeApp(stage);
    makeFile(outputFile, stage, user);
});


program.
    command('*').
    action(function () {
        program.outputHelp();
        process.exit(-1);
    });

program.parse(process.argv);

function makeApp(stage) {
    var appInfo = new Buffer(login.appIdAndSecret(), 'base64').toString().split(':');
    console.log('this is the appInfo second value: ' + appInfo[1]);
    var ppa = new liwp({
        host: stage,
        appId: appInfo[0],
        secret: appInfo[1],
        preferredRP: true,
        scopes: 'email openid https://uri.paypal.com/services/paypalhere https://api.paypal.com/v1/payments/.* https://uri.paypal.com/services/paypalattributes/business address phone profile',
        returnUrl: 'urn:ietf:wg:oauth:2.0:oob',
        privileges: 'PPEmail PPBusinessName PPBusinessCategory PPCountry PPStreet1 PPStreet2 PPState PPPostalcode PPBusinessSubCategory APIPayments PPHere PPID PPPhone PPFirstName PPLastName',
        strictSSL: false,
        appOwnerEmail: 'sp-us-b2@paypal.com'
    });

    ppa.createApp(function (err,rz) {
        if (err) {
            console.log(err.message);
            console.log(err.stack);
            process.exit(-1);
        } else {
            console.dir(rz);
        }
    });
}

if (process.argv.length <= 2) {
    program.outputHelp();
    process.exit(-1);
}

function makeFile(outputFile, stage, user) {
    console.log('Fetching new access token for', user, 'from environment', stage);
    login.getToken(stage, user, '11111111', function (error, token) {
        if (!error && token && token.error) {
	    error = new Error(token.error);
	}
        if (error) {
            console.error('FAILED to get access token:', error.message, error.stack);
            process.exit(-1);
        }
	console.log(token);
        var sdkToken = [
            token.access_token,
            token.expires_in,
            null,
            token.refresh_token,
            login.appIdAndSecret()
        ];
        sdkToken = stage + ':' + new Buffer(JSON.stringify(sdkToken)).toString('base64');
        console.log(sdkToken);
        if (outputFile !== '-') {
            fs.outputFileSync(outputFile, sdkToken);
        }
	    process.exit(0);
    });
}
