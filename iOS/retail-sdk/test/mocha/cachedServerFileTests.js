import CachedServerFile from '../../js/common/CachedServerFile';

let testUtils = require('../testUtils'),
    chai = require('chai'),
    should = chai.should(),
    expect = chai.expect;

describe('CachedServerFile module', () => {

    let remoteJsonUrl = 'https://www.paypalobjects.com/webstatic/mobile/retail-sdk/feature-map.json',
        fileId = 'cached-file-key',
        cachedFile = {
            "headers": {
                "ETag": "111-111-111",
                "Last-Modified": "Wed, 12 Aug 2015 04:25:25 GMT"
            },
            "statusCode": 200,
            "body": {
                "VERSION": "1.0",
                "US": {"CONTACTLESS_LIMIT": "10000", "MCC_CODES": {"7519": "*"}},
                "GB": {"CONTACTLESS_LIMIT": "20"},
                "AU": {"CONTACTLESS_LIMIT": "*"}
            }
        };

    beforeEach(setup);
    afterEach(cleanup);

    it('should use ETag and LastModified values from cached file for building server GET requests', (done) => {

        //Given
        require('manticore').getItem = (key, storage, cb) => cb(null, JSON.stringify(cachedFile));
        testUtils.addRequestHandler(remoteJsonUrl, (opt, cb) => {

            //Then
            opt.headers['If-None-Match'].should.equal(cachedFile.headers.ETag);
            opt.headers['If-Modified-Since'].should.equal(cachedFile.headers['Last-Modified']);
            done();
        });

        //When
        new CachedServerFile(fileId, remoteJsonUrl).get(() => {});
    });

    it('should use server backed file when cached file is not available', (done) => {

        //Given
        require('manticore').getItem = (key, storage, cb) => cb(null, null);
        let httpResponse = {
            "headers": {
                "ETag": "111-111-111",
                "Last-Modified": "Wed, 12 Aug 2015 04:25:25 GMT"
            },
            "statusCode": 200,
            "body": {
                "VERSION": "1.0",
                "UK": {"CONTACTLESS_LIMIT": "77", "MCC_CODES": {"7519": "*"}},
                "US": {"CONTACTLESS_LIMIT": "77"}
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, httpResponse);

        //When
        new CachedServerFile(fileId, remoteJsonUrl).get((err, jsonFile) => {

            //Then
            jsonFile.should.deep.equal(httpResponse.body);
            done();
        });
    });

    it('should use server backed file when cached file is not a valid JSON', (done) => {

        //Given
        require('manticore').getItem = (key, storage, cb) => cb(null, '{body: {');
        let httpResponse = {
            "headers": {
                "ETag": "111-111-111",
                "Last-Modified": "Wed, 12 Aug 2015 04:25:25 GMT"
            },
            "statusCode": 200,
            "body": {
                "VERSION": "1.0",
                "UK": {"CONTACTLESS_LIMIT": "77", "MCC_CODES": {"7519": "*"}},
                "US": {"CONTACTLESS_LIMIT": "77"}
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, httpResponse);

        //When
        new CachedServerFile(fileId, remoteJsonUrl).get((err, jsonFile) => {

            //Then
            jsonFile.should.deep.equal(httpResponse.body);
            done();
        });
    });

    it('should use cached file if the server GET errors out', (done) => {

        //Given
        require('manticore').getItem = (key, storage, cb) => cb(null, JSON.stringify(cachedFile));
        let httpResponse = {
            "headers": {
                "ETag": "111-111-111",
                "Last-Modified": "Wed, 12 Aug 2015 04:25:25 GMT"
            },
            "statusCode": 404
        };
        testUtils.addRequestHandler(remoteJsonUrl, httpResponse);

        //When
        new CachedServerFile(fileId, remoteJsonUrl).get((err, jsonFile) => {

            //Then
            jsonFile.should.deep.equal(cachedFile.body);
            done();
        });
    });

    it('should use cached file if the server could not find a newer file', (done) => {

        //Given
        require('manticore').getItem = (key, storage, cb) => cb(null, JSON.stringify(cachedFile));
        let httpResponse = {
            "headers": {
                "ETag": "111-111-111",
                "Last-Modified": "Wed, 12 Aug 2015 04:25:25 GMT"
            },
            "statusCode": 304
        };
        testUtils.addRequestHandler(remoteJsonUrl, httpResponse);

        //When
        new CachedServerFile(fileId, remoteJsonUrl).get((err, jsonFile) => {

            //Then
            jsonFile.should.deep.equal(cachedFile.body);
            done();
        });
    });

    it('should return null value when file is not accessible on both local cache store and server', (done) => {

        //Given
        require('manticore').getItem = (key, storage, cb) => cb(null, null);
        let httpResponse = {
            "headers": {
                "ETag": "111-111-111",
                "Last-Modified": "Wed, 12 Aug 2015 04:25:25 GMT"
            },
            "statusCode": 500
        };
        testUtils.addRequestHandler(remoteJsonUrl, httpResponse);

        //When
        new CachedServerFile(fileId, remoteJsonUrl).get((err, jsonFile) => {

            //Then
            expect(jsonFile).to.be.null;
            done();
        });
    });

    function setup() {
        require('manticore').getItem = (key, storage, cb) => cb();
        require('manticore').setItem = (fileId, storage, value, cb) => cb();
        testUtils.seizeHttp();
    }

    function cleanup() {
        testUtils.releaseHttp();
    }
});