var sys = require('util');
var request = require('request').defaults({jar: false});
var xml2js = require("xml2js");
var querystring = require('querystring');
var spawn = require('child_process').spawn;

var curl_request = {};

// This is nasty but you, the reader, shouldn't care. This is to simulate consumer login.
// In case you do care, we do two things here: register the device and then call login with user/pass
exports.login = function (APPID, deviceId, pp_host, pp_port, id, pass, callback, retryCount) {

    retryCount = retryCount || 0;

    function callAuth(deviceToken, appNonce, devNonce) {

        var authXml = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:pt="http://svcs.paypal.com/mobile/adapter/types/pt"><soap:Header/><soap:Body>' +
            '<pt:DeviceAuthenticateUserRequest><version>2.0</version><paypalAppId>APP-2A128197VV566444R</paypalAppId><mplVersion>4.0</mplVersion><deviceReferenceToken>' + deviceToken +
            '</deviceReferenceToken><authorizeDevice>false</authorizeDevice><authorizationType>Email</authorizationType><email>' + id + '</email><password>' + pass + '</password><bypassEncryption>true</bypassEncryption>' +
            '<securityDetails><applicationNonce>' + appNonce + '</applicationNonce><deviceNonce>' + devNonce + '</deviceNonce><auxiliaryData><nvPair><name>app_guid</name><value>' + deviceId +
            '</value></nvPair><nvPair><name>library_version</name><value>1.1.1</value></nvPair></auxiliaryData></securityDetails></pt:DeviceAuthenticateUserRequest></soap:Body></soap:Envelope>';

        var post_options = {
            strictSSL: false,
            url: "https://" + pp_host + ":" + pp_port + '/GMAdapter/DeviceAuthenticateUser',
            body: authXml,
            headers: {
                'Content-Type': 'text/xml; charset=UTF-8',
                SOAPAction: "urn:DeviceInterrogation",
                "X-PAYPAL-MESSAGE-PROTOCOL": "SOAP11",
                "X-PAYPAL-REQUEST-DATA-FORMAT": "XML",
                "X-PAYPAL-RESPONSE-DATA-FORMAT": "XML"
            }
        };

        request.post(post_options, function (error, curl, response) {
            if (error) {
                callback(error, response);
                return;
            }
            var parser = new xml2js.Parser();
            parser.parseString(response, function (err, rz) {
                if (err) {
                    callback(err, null);
                }
                else {
                    try {
                        var payload = rz["soapenv:Envelope"]["soapenv:Body"][0]["ns2:DeviceAuthenticateUserResponse"][0];
                        callback(null, payload["sessionToken"][0]);
                    }
                    catch (exc) {
                        callback(exc, null);
                    }
                }
            });
        });
    };

    var diXml = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:pt="http://svcs.paypal.com/mobile/adapter/types/pt"><soap:Header/><soap:Body><pt:DeviceInterrogationRequest><Version>2.0</Version>' +
        '<paypalAppId>' + APPID + '</paypalAppId><mplVersion>4.0</mplVersion><deviceDetails><deviceId><deviceIdType>GUID</deviceIdType><deviceIdentifier>' + deviceId + '</deviceIdentifier></deviceId><deviceName>iPad Simulator</deviceName>' +
        '<deviceModel>iPad Simulator</deviceModel><systemName>iPhone OS</systemName><systemVersion>6.1</systemVersion><deviceCategory>Phone</deviceCategory><deviceSimulator>true</deviceSimulator></deviceDetails><deviceReferenceToken/>' +
        '<embeddingApplicationDetails><deviceAppId>com.paypal.herehd</deviceAppId><deviceAppName>PayPal Here HD</deviceAppName><deviceAppDisplayName>PayPal Here HD</deviceAppDisplayName><clientPlatform>Apple</clientPlatform>' +
        '<deviceAppVersion>1002</deviceAppVersion></embeddingApplicationDetails><securityDetails><applicationNonce/><deviceNonce/></securityDetails></pt:DeviceInterrogationRequest></soap:Body></soap:Envelope>';

    var drUrl = "https://" + pp_host + ":" + pp_port + "/GMAdapter/DeviceInterrogation";
    console.log("Registering device @ " + drUrl);
    request.post({
            strictSSL: false,
            url: drUrl,
            body: diXml,
            timeout: 10000,
            headers: {
                'Content-Type': 'text/xml; charset=UTF-8',
                SOAPAction: "urn:DeviceInterrogation",
                "X-PAYPAL-MESSAGE-PROTOCOL": "SOAP11",
                "X-PAYPAL-REQUEST-DATA-FORMAT": "XML",
                "X-PAYPAL-RESPONSE-DATA-FORMAT": "XML"
            }
        },
        function (e, r, b) {
            if (e || b.indexOf("<message>Internal Error</message></error>") > 0) {
                // Try again, sometimes it's flaky
                if (retryCount < 3) {
                    exports.login(APPID, deviceId, pp_host, pp_port, id, pass, callback, retryCount + 1);
                } else {
                    callback(e, null);
                }
                return;
            }
            var parser = new xml2js.Parser();
            parser.parseString(b, function (err, rz) {
                if (err) {
                    callback(err, null);
                }
                else {
                    try {
                        var payload = rz["soapenv:Envelope"]["soapenv:Body"][0];
                        var devToken = payload["ns2:DeviceInterrogationResponse"][0]["deviceReferenceToken"][0];
                        var appNonce = payload["ns2:DeviceInterrogationResponse"][0]["securityDetails"][0]["applicationNonce"][0];
                        var devNonce = payload["ns2:DeviceInterrogationResponse"][0]["securityDetails"][0]["deviceNonce"][0];
                        console.log("Device Token", devToken);
                        callAuth(devToken, appNonce, devNonce);
                    }
                    catch (exc) {
                        callback(exc, null);
                    }
                }
            });
        });
};

curl_request.post = function (o, cb) {
    // Need CURL because the stage servers SSL certs are bad and node can't handle it
    var args = [o.url, "-k", "-d", o.body];
    for (var h in o.headers) {
        args.push("-H");
        args.push(h);
        args.push(o.headers[h]);
    }
    var curl = spawn('curl', args);
    // add a 'data' event listener for the spawn instance
    var rsp = "";
    curl.stdout.on('data', function (data) {
        rsp += data;
    });
    // add an 'end' event listener to close the writeable stream
    curl.stdout.on('end', function (data) {
        cb(null, curl, rsp);
    });
    // when the spawn child process exits, check if there were and close the writeable stream
    curl.on('exit', function (code) {
        if (code < 0) {
            console.log("CURL EXIT CODE " + code);
        }
    });
}