var util = require('util'),
    wreck = require('wreck'),
    qs = require('querystring'),
    https = require('https'),
    AUTH = new Buffer('PPHAccreditron9k:A8VERY8SECRET8VALUE0').toString('base64');

var agent = new https.Agent({
    secureProtocol: 'TLSv1_method',
    rejectUnauthorized: false,
    secureOptions: require('constants').SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS
});

var at, rt, active_stage, retry_count = 0;

module.exports = {
    appIdAndSecret: function () {
	    return AUTH;
    },
    tokenForApp: function () {
        if (!at) {
            return null;
        }
        return {
            access_token: at,
            refresh_url: 'paypalhere://refresh',
            env: active_stage
        }
    },
    getToken: function (stage, emailOrSecondary, password, callback) {
        active_stage = stage;
        var body = qs.stringify({
            grant_type: 'password',
            email: emailOrSecondary,
            password: password,
            redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
            rememberme: true,
            scope: 'email openid phone profile address https://uri.paypal.com/services/paypalhere https://api.paypal.com/v1/payments/.* https://uri.paypal.com/services/paypalattributes/business'
        });

        var url = util.format('https://www.%s.stage.paypal.com:11888/v1/oauth2/login', stage);
        wreck.post(url, {
            headers: {
                'Authorization': 'Basic ' + AUTH,
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            payload: body,
            timeout: 15000,
    	    agent: agent
        }, function (e, rz, payload) {
            if (e) {
                if (retry_count < 2) {
                    retry_count++;
                    module.exports.getToken(stage, emailOrSecondary, password, callback);
                    return;
                } else {
                    retry_count = 0;
                }
                callback(e, rz);
            } else {
                retry_count = 0;
                try {
                    var tokenInfo = JSON.parse(payload.toString());
                    at = tokenInfo.access_token;
                    rt = tokenInfo.refresh_token;
                } catch (x) {
                    throw new Error('Invalid return payload: ' + payload.toString());
                }
                callback(null, tokenInfo);
            }
        });
    },
    refreshToken: function (callback) {
        var rqBody = {
            grant_type: 'refresh_token',
            response_type: 'token',
            refresh_token: rt
        };

        var url = 'https://www.'+active_stage+'.stage.paypal.com:12714/v1/oauth2/token';
        request.post({
            url: url,
            headers: {
                'Authorization': 'Basic ' + AUTH,
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: qs.stringify(rqBody),
            timeout: 15000,
            agentOptions: {
                secureProtocol: SSL_ALGO
            },
            rejectUnauthorized: false
        }, function (e, rz) {
            console.log(rz ? rz.body : 'none');
            if (e) {
                callback(e, rz);
            } else {
                var tokenInfo = JSON.parse(rz.body.toString());
                at = tokenInfo.access_token;
                callback(null, tokenInfo);
            }
        });
    }
};
