var paypal = require('./lib/paypal');
var program = require('commander');
var request = require('request');
var async = require('async');
var fs = require('fs');

program.
	version("1.0").
	option('-c, --consumer [consumer_email]', 'Set consumer account', 'sp-us-b1@paypal.com').
	option('-cp, --consumerPass [consumer_pass]', 'Set consumer account password', '11111111').
	option('-m, --merchant [merchant_email]', 'Set merchant account', 'sp-us-b2@paypal.com').
	option('-mp, --merchantPass [merchant_pass]', 'Set merchant account password', '11111111').
    option('-l, --location [location_id]', 'Set merchant location id.').
	option('-h, --host [host]', 'Set stage hostname [stage2pph03]', 'stage2pph03').
	option('-g, --gmapi [port]', 'Set GMAPI port [10521]', '10521').
	option('-i, --image [url]', 'Set customer profile image. (optional)').
	option('-ip, --imagePort [port]', 'The port for the image server [10592]', '10592').
	option('-f, --figserv [port]', 'Set Fig Server port [10905]', '10905').
	parse(process.argv);

//var appId = 'APP-1JE4291016473214C'
var appId = "APP-2A128197VV566444R";
var host = program.host;

if (program.host.indexOf('.') > 0 && program.host[program.host.length - 1] == '.') {
	host = "www." + host + "paypal.com";
} else if (program.host.indexOf('.') < 0) {
	host = "www." + host + ".stage.paypal.com";
}

var macqUrl = 'https://' + host + ":" + program.figserv + "/MobileAcquiring/";

function rq(token, url, body, cb) {
	var rh = {
		"X-PAYPAL-REQUEST-DATA-FORMAT":"JSON",
		"X-PAYPAL-RESPONS-DATA-FORMAT":"JSON",
		"X-PAYPAL-DEVICE-AUTH-TOKEN":token,
		// These two are only for the image server, but everybody gets a free car
		"X-PAYPAL-SERVICE-VERSION": "1.0.0",
		"X-PAYPAL-REQUEST-SOURCE": "MPA-DEVICE"
	};

	// only in stage
	rh["CLIENT-AUTH"] = "No cert";
	request.post({
		url:url,
		headers:rh,
		body:JSON.stringify(body)
	}, function (e, r, b) {
		if (e) {
			console.log(e, b || "no body returned");
			process.exit(-1);
		}
		cb(JSON.parse(b));
	});
}

function runCheckin(consumerToken, payerId, locationId)
{
	rq(consumerToken, macqUrl + "CustomerCheckin",{location:{latitude:"37.377336", longitude:"-121.922761"},merchantId:payerId, locationId: locationId}, function (cb) {
		console.log("Checkin Id:", cb.checkinId||JSON.stringify(cb));
		program.confirm("Checkin Again (Y/N)? Press enter/return twice after answering...", function (ok) {
			if (ok) {
				runCheckin(consumerToken, payerId, locationId);
			} else {
				process.exit(0);
			}
		})
	});
}

console.log("Starting logins.")
async.parallel([
	function (cb) {
		paypal.login(appId, "B3A979A03C7D422BB3A4E6D8D052696B", host, program.gmapi, program.consumer, program.consumerPass, function (err, tok) {
			if (err) {
				console.log("Consumer Login Failed.", err);
			}
			cb(err, tok);
		});
	},
	function (cb) {
		paypal.login(appId, "D3A642A03C7D422BB3A4E6D8D052333B", host, program.gmapi, program.merchant, program.merchantPass, function (err, tok) {
			if (err) {
				console.log("Merchant Login Failed.", err);
			}
			cb(err, tok);
		});
	}
], function (err, rz) {
	var consumerToken = rz[0];
	var merchantToken = rz[1];
	console.log("Consumer Token:", consumerToken);
	console.log("Merchant Token:", merchantToken);

	if (err) {
		console.log(err, rz);
		process.exit(-1);
	}

	// Now call MerchantInit for the merchant payer id
	rq(merchantToken, macqUrl + 'MerchantInitialize', {swiper:{status:"SWIPER_OUT"}}, function (rz) {
		console.log("Merchant ID:", rz.userDetails.payerId);

		rq(merchantToken, macqUrl + "MerchantCheckin", {location:{latitude:"37.377336", longitude:"-121.922761"}, status:"East end of Nowhere"}, function (b) {
			var checkinId = b.merchantCheckinId;
			console.log("Merchant checkin id:", checkinId);

			if (program.image) {
				var buf = new Buffer(fs.readFileSync(program.image));
				rq(consumerToken, "https://"+host+":"+program.imagePort+"/SecureAdaptiveStorage/PutImage", {imageData: buf.toString('hex').toUpperCase(), expirationDays: 100, imageWidth: "150", imageHeight: "223" }, function (ir) {

					if (ir.error) {
						console.log(ir.error);
						process.exit(-1);
					}

					rq(consumerToken, macqUrl + "CustomerSetProfileImage", { profileImage: ir.imageId }, function (ir) {
						console.log(ir);
						runCheckin(consumerToken, rz.userDetails.payerId, program.locationId);
					});
				});
			} else {
				runCheckin(consumerToken, rz.userDetails.payerId, program.locationId);
			}

		});
	});

});
