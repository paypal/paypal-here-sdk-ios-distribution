'use strict';

var browserify = require('browserify');
var babelify = require('babelify');
var gulp = require('gulp');
var transform = require('vinyl-transform');
var uglifyify = require('uglifyify');
var jshint = require('gulp-jshint');
var fs = require('fs-extra');
var path = require('path');
var exec = require('child_process').exec;
var rename = require('gulp-rename');

/**
 * Because we use node_modules for composition of manticore modules, and because those modules are ES6
 * (and we want them to stay that way until the last moment so the packager/uglifier can do better),
 * we need to be explicit about which files to transform with babelify. That means writing these crazy regexes
 **/

var filesToBabelify = require('../../es6FilePatterns');
filesToBabelify.push(/platform\/chrome\/src\/.*\.js/);

gulp.task('js-release-do', ['pack-all-release'], function () {
    return browserify({})
        .exclude('crypto')
        .exclude('util')
        .exclude('./lib/InvoicingFakeServer')
        .transform(babelify.configure({only: filesToBabelify}), {global: true})
        .transform({
            global: true
        }, 'uglifyify')
        .require('./src/chromeSdk.js', {entry: true})
        .bundle()
        .on("error", function (err) {
            console.log("Browserify error: " + err.message);
        })
        .pipe(fs.createOutputStream("./dist/PayPalRetailSDK.chrome.js"));
});

gulp.task('js-debug-do', ['pack-all-debug'], function () {
    return browserify({fullPaths: true, debug: true})
        .exclude('crypto')
        .exclude('util')
        .exclude('./lib/InvoicingFakeServer')
        .transform(babelify.configure({only: filesToBabelify}), {global: true})
        .on("error", function (err) {
            console.log("Babelify error: " + err.message);
        })
        .require('./src/chromeSdk.js', {entry: true})
        .require('../../js/debug.js', {entry:true})
        .bundle()
        .on("error", function (err) {
            console.log("Browserify error: " + err.message);
        })
        .pipe(fs.createOutputStream("./dist/PayPalRetailSDK.debug.chrome.js"));
});

function packTask(name, folder) {
    // TODO have this iterate over files in the directory to handle multiple templates
    gulp.task('pack-' + name + '-debug', function (cb) {
        var css = fs.readFileSync(path.join(folder, name + '.css'), 'utf8');
        var html = fs.readFileSync(path.join(folder, name + '.html'), 'utf8');
        fs.outputFileSync('./src/packed-ui/' + name + '.js', 'module.exports = ' + JSON.stringify({
                css: css,
                html: html
            }) + ';', 'utf8');
        cb();
    });
    gulp.task('pack-' + name + '-release', function (cb) {
        // TODO minify css and html for non debug builds
        var css = fs.readFileSync(path.join(folder, name + '.css'), 'utf8');
        var html = fs.readFileSync(path.join(folder, name + '.html'), 'utf8');
        fs.outputFileSync('./src/packed-ui/' + name + '.js', 'module.exports = ' + JSON.stringify({
                css: css,
                html: html
            }) + ';', 'utf8');
        cb();
    });
}

// Pack HTML/CSS into JSON to create the JS equivalent of resource bundles...
packTask('alert', './src/alert');
packTask('receipt', './src/receipt');
packTask('sig', './src/sig');

gulp.task('pack-all-debug', ['pack-alert-debug', 'pack-receipt-debug', 'pack-sig-debug']);
gulp.task('pack-all-release', ['pack-alert-release', 'pack-receipt-release', 'pack-sig-release']);

gulp.task('js-debug-copy', ['js-debug-do'], function () {
    return gulp.src(['./dist/PayPalRetailSDK.debug.chrome.js'])
        .pipe(rename('PayPalRetailSDK.chrome.js'))
        .pipe(gulp.dest('./testapp'));
});

gulp.task('js-release-copy', ['js-release-do'], function () {
    return gulp.src(['./dist/PayPalRetailSDK.chrome.js'])
        .pipe(gulp.dest('./testapp'));
});

gulp.task('lint', function () {
    return gulp.src(['src/**/*.js'])
        .pipe(jshint({esnext: true, node: true}))
        .pipe(jshint.reporter('default'));
});

gulp.task('watch', function () {
    var watcher = gulp.watch(['../../js/**/*.js', '../../submodules/**/*.js', '../../testToken.txt', 'src/**/*.js', '!src/packed-ui/*'], ['js-debug']);
    watcher.on('change', function (event) {
        console.log('File ' + event.path + ' was ' + event.type + ', running js-debug...');
    });
});

gulp.task('token', function (cb) {
    var token = fs.readFileSync('../../testToken.txt', 'utf8');
    fs.outputFileSync('./testapp/sdkTestToken.js', 'var sdkTestToken = "' + token + '";', 'utf8');
    cb();
});

gulp.task('images', function (cb) {
    const images = [];
    fs.walk('../../resources/images/drawable-xhdpi')
      .on('data', function (image) {
          if(!image.stats.isDirectory()) {
              images.push(image.path);
          }
      })
    .on('end', function() {
        gulp.src(images)
          .pipe(gulp.dest('./testapp/resources/images'))
    });
});

gulp.task('sounds', function (cb) {
    const sounds = [];
    fs.walk('../../resources/sounds')
      .on('data', function (sound) {
          if(!sound.stats.isDirectory()) {
              sounds.push(sound.path);
          }
      })
      .on('end', function() {
          gulp.src(sounds)
            .pipe(gulp.dest('./testapp/resources/sounds'))
      });
});

// Default Task
gulp.task('default', ['lint', 'token', 'js-debug']);
gulp.task('js-debug', ['token', 'images', 'sounds', 'pack-all-debug', 'js-debug-do', 'js-debug-copy']);
gulp.task('js-release', ['token', 'images', 'sounds', 'pack-all-release', 'js-release-do', 'js-release-copy']);
