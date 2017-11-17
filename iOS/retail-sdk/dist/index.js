console.log('start');
var manticore = require('manticore');
console.log(global);
console.log('assign');
global.manticore = manticore;
console.log('export');
module.exports = function (ready,debug) {
    manticore.ready = manticore.ready || function _ready(sdk) {
	ready(sdk);
    };
    if (debug) {
	require('./debug');
    } else {
	require('./PayPalRetailSDK.js');
    }
};