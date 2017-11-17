const browserify = require('browserify');
const babelify = require('babelify');
const gulp = require('gulp');
const transform = require('vinyl-transform');
const uglifyify = require('uglifyify');
const jshint = require('gulp-jshint');
const fs = require('fs-extra');
const exec = require('child_process').exec;
const path = require('path');
const rimraf = require('rimraf');
const concat = require('gulp-concat');

require('events').EventEmitter.prototype._maxListeners = 100;

function run(cmd) {
  return (cb) => {
    exec(cmd, (err, stdout, stderr) => {
      if (stdout && stdout.length) {
        console.log(stdout);
      }
      if (stderr && stderr.length) {
        console.error(stderr);
      }
      cb(err);
    });
  };
}

/**
 * Because we use node_modules for composition of manticore modules, and because those modules are ES6
 * (and we want them to stay that way until the last moment so the packager/uglifier can do better),
 * we need to be explicit about which files to transform with babelify. That means writing these crazy regexes
 **/
const filesToBabelify = require('./es6FilePatterns');

gulp.task('js-release-no-license', () => {
  return browserify({})
    .exclude('crypto')
    .exclude('util')
    .exclude('./lib/InvoicingFakeServer')
    .transform(babelify.configure({ only: filesToBabelify }), { global: true })
    .transform({
      global: true,
    }, 'uglifyify')
    .require('./js/index.js', { entry: true })
    .bundle()
    .on('error', (err) => {
      console.log(`Browserify error: ${err.message}`);
    })
    .pipe(fs.createOutputStream('./PayPalRetailSDK.js'));
});

gulp.task('js-release', ['js-release-no-license'], () => (
  gulp.src(['./license.txt', './PayPalRetailSDK.js'])
    .pipe(concat('PayPalRetailSDK.js'))
    .pipe(gulp.dest('./'))
  ));

gulp.task('js-debug-no-license', () => {
  return browserify({ fullPaths: true })
    .exclude('crypto')
    .exclude('util')
    .exclude('./lib/InvoicingFakeServer')
    .transform(babelify.configure({ only: filesToBabelify }), { global: true })
    .require('./js/debug.js', { entry: true })
    .require('./js/index.js', { entry: true })
    .bundle()
    .on('error', (err) => {
      console.log(`Browserify error: ${err.message}`);
    })
    .pipe(fs.createOutputStream('./PayPalRetailSDK.js'));
});

gulp.task('js-debug', ['js-debug-no-license'], () => (
  gulp.src(['./license.txt', './PayPalRetailSDK.js'])
    .pipe(concat('PayPalRetailSDK.js'))
    .pipe(gulp.dest('./'))
));

gulp.task('lint', () => {
  return gulp.src(['js/**/*.js'])
    .pipe(jshint({ esnext: true, node: true }))
    .pipe(jshint.reporter('default'))
    .pipe(jshint.reporter('fail')); // Exit with non-0 status if the lint failed.
});

function objcGenDir(baseName) {
  return `./platform/objc/Common/generated/${baseName}`;
}

const exposedItems = [
  'js/sdk.js',
  'node_modules/manticore-paypalerror/src/*.js',
  'node_modules/paypal-invoicing/lib/*.js',
  'js/common/Merchant.js',
  'js/common/NetworkHandler/NetworkRequest.js',
  'js/common/NetworkHandler/NetworkResponse.js',
  'js/common/logLevel.js',
  'js/common/RetailInvoice.js',
  'js/common/TokenExpirationHandler.js',
  'js/transaction/TransactionContext.js',
  'js/transaction/TransactionBeginOptions.js',
  'js/transaction/ReceiptDestination.js',
  'js/transaction/DeviceManager.js',
  'js/transaction/transactionStates.js',
  'js/transaction/AuthStatus.js',
  'js/transaction/SignatureReceiver.js',
  'js/transaction/ReceiptViewContent.js',
  'node_modules/retail-payment-device/src/Messages/Card.js',
  'node_modules/retail-payment-device/src/BatteryInfo.js',
  'node_modules/retail-payment-device/src/batteryStatus.js',
  'node_modules/retail-payment-device/src/MagneticCard.js',
  'node_modules/retail-payment-device/src/PaymentDevice.js',
  'node_modules/retail-payment-device/src/deviceCapabilityType.js',
  'node_modules/retail-payment-device/src/ManuallyEnteredCard.js',
  'node_modules/retail-payment-device/src/CardStatus.js',
  'node_modules/retail-payment-device/src/CardIssuer.js',
  'node_modules/retail-payment-device/src/FormFactor.js',
  'node_modules/retail-payment-device/src/TransactionType.js',
  'node_modules/retail-payment-device/src/DeviceUpdate.js',
  'node_modules/retail-payment-device/src/readerInformation.js',
  'node_modules/retail-payment-device/src/CardInsertedHandler.js',
  'node_modules/retail-payment-device/src/Messages/DeviceStatus.js',
  'js/transaction/Payer.js',
  'js/transaction/TransactionRecord.js',
  'js/transaction/AuthorizedTransaction.js',
  'node_modules/retail-page-tracker/src/Page.js',
].join(' ');

gulp.task('gen-android', run(`node ./node_modules/manticore-gen -q --config=${path.resolve('manticore-config.json')} j2v8 ./platform/android/PayPalRetailSDK/sdk/src/main/java/com/paypal/paypalretailsdk ${exposedItems}`));
gulp.task('gen-objc', run(`node ./node_modules/manticore-gen -q --config=${path.resolve('manticore-config.json')} objc ./platform/objc/Common/generated ${exposedItems}`));
gulp.task('gen-clearScript', run(`node ./node_modules/manticore-gen -q --config=${path.resolve('manticore-config.json')} csharp-clearscript ./platform/win/Common/generated/ClearScript ${exposedItems}`));

gulp.task('clean-generated', (cb) => {
  // For now, this only clears the objc generated code. Other languages have non-generated
  // code in their directory, so we can't just delete the dir.
  rimraf(objcGenDir(''), (error) => {
    if (error) {
      console.log(`failed to remove ${objcGenDir('')}: ${error}`);
    }
    cb(error);
  });
});

const platformResourceFolders = {
  objc: 'platform/objc/Common/AllPlatforms',
};

function allPlatformResourceFolders() {
  return Object.keys(platformResourceFolders).map(key => platformResourceFolders[key]);
}

const copyResources = () => {
  const destinations = allPlatformResourceFolders();
  if (destinations.length) {
    const returnVal = gulp.src([
      './PayPalRetailSDK.js',
      './resources/**/*',
    ]);

    for (const destination of destinations) {
      returnVal.pipe(gulp.dest(destination));
    }

    return returnVal;
  }
};

gulp.task('copy-resources', copyResources);

const cleanResources = (cb) => {
  const destinations = allPlatformResourceFolders();
  let asyncCounter = 0;
  function poorMansAsyncCallback(destination, error) {
    if (error) {
      console.log(`failed to remove ${destination}: ${error}`);
    }

    asyncCounter += 1;
    if (asyncCounter === destinations.length) {
      cb();
    }
  }

  destinations.forEach((d) => { rimraf(d, poorMansAsyncCallback.bind(this, d)); });
};

gulp.task('clean-resources', cleanResources);

gulp.task('watch', () => {
  let watcher = gulp.watch('js/invoicing/*.js', ['invoicegen']);
  watcher.on('change', (event) => {
    console.log(`File ${event.path} was ${event.type}, running invoicegen...`);
  });
  watcher = gulp.watch(['js/**/*.js'], ['js-debug']);
  watcher.on('change', (event) => {
    console.log(`File ${event.path} was ${event.type}, running js-debug...`);
  });
});

// Default Task
gulp.task('default', ['js-debug']);
gulp.task('gen', ['clean-generated', 'gen-android', 'gen-clearScript', 'gen-objc']);
gulp.task('resources', ['clean-resources', 'copy-resources']);
gulp.task('develop', ['js-debug', 'gen'], (cb) => {
  cleanResources(cb);
  copyResources(cb);
});

gulp.task('release', ['js-release', 'gen'], (cb) => {
  cleanResources(cb);
  copyResources(cb);
});
