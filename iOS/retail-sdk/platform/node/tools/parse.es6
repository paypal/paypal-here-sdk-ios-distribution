var argv = require('minimist')(process.argv.slice(3)),
    MiuraTags = require('miura-emv/build/MiuraTags'),
    fs = require('fs'),
    Tlv = require('tlvlib');

var data = fs.readFileSync(argv._[0],'ascii');
var cleaner = /[^0-9A-Fa-f]/g;

var packet = new Buffer(data.replace(cleaner, ''), 'hex');

var list = new Tlv.TlvList(packet);

console.log(list.toString(true));