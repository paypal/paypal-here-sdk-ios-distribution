#!/usr/bin/env node
/**
 * Run node index.js <commandName> args
 */

require("babel-register")({
    ignore: /PayPalRetailSDK/
});

if (process.argv.length < 3) {
    console.error('Usage: node index.js <toolName>');
    process.exit(-1);
}

require("./"+process.argv[2].replace(/\.es6$/,''));
