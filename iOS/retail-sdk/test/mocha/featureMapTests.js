'use strict';

let testUtils = require('../testUtils'),
    chai = require('chai'),
    should = chai.should(),
    expect = chai.expect,
    mockery = require('mockery');

describe('Local feature map', () => {

    let remoteJsonUrl = 'https://www.paypalobjects.com/webstatic/mobile/retail-sdk/feature-map.json',
        localFeatureMapMock = {
            "VERSION": "1.0",
            "US": {
                "MCC_CODES": {
                    "4121": "*"
                },
                "CONTACTLESS_LIMIT": "10000"
            },
            "AU": {
                "CONTACTLESS_LIMIT": "*"
            }
        };

    beforeEach(setup);
    afterEach(cleanup);

    it('should be loaded on referencing feature module', (done) => {

        //When
        const SdkFeature = require('../../js/common/Features');

        //Then
        SdkFeature.map.should.deep.equal(localFeatureMapMock);
        done();
    });

    it('should be replaced by remote map with higher version', (done) => {

        //Given
        let remoteFeatureMap = {
            "VERSION": "1.1",
            "US": {
                "MCC_CODES": {
                    "4121": "*",
                    "5812": "*"
                },
                "CONTACTLESS_LIMIT": "35"
            },
            "AU": {
                "CONTACTLESS_LIMIT": "10000"
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, { statusCode : 200, body : remoteFeatureMap });

        //When
        const SdkFeature = require('../../js/common/Features');
        SdkFeature.loadRemoteFeatureMap();

        //Then
        process.nextTick(() => {
            SdkFeature.map.should.deep.equal(remoteFeatureMap);
            done();
        });
    });

    it('should not be replaced with remote map with lower version', (done) => {

        //Given
        let remoteFeatureMap = {
            "VERSION": "0.9",
            "US": {
                "MCC_CODES": {
                    "4121": "*",
                    "5812": "*"
                },
                "CONTACTLESS_LIMIT": "35"
            },
            "AU": {
                "CONTACTLESS_LIMIT": "10000"
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, { statusCode : 200, body : remoteFeatureMap });

        //When
        const SdkFeature = require('../../js/common/Features');
        SdkFeature.loadRemoteFeatureMap();

        //Then
        process.nextTick(() => {
            SdkFeature.map.should.deep.equal(localFeatureMapMock);
            done();
        });
    });

    it('should be replaced and not merged by remote map with higher version', (done) => {

        //Given
        let remoteFeatureMap = {
            "VERSION": "1.1",
            "UK": {
                "CONTACTLESS_LIMIT": "85"
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, { statusCode : 200, body : remoteFeatureMap });

        //When
        const SdkFeature = require('../../js/common/Features');
        SdkFeature.loadRemoteFeatureMap();

        //Then
        process.nextTick(() => {
            SdkFeature.map.should.deep.equal(remoteFeatureMap);
            done();
        });
    });

    it('should not be updated when the remote endpoint is not reachable', (done) => {

        //Given
        let remoteFeatureMap = {
            "VERSION": "1.1",
            "UK": {
                "CONTACTLESS_LIMIT": "85"
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, { statusCode : 404 });

        //When
        const SdkFeature = require('../../js/common/Features');
        SdkFeature.loadRemoteFeatureMap();

        //Then
        process.nextTick(() => {
            SdkFeature.map.should.deep.equal(localFeatureMapMock);
            done();
        });
    });

    it('should not be updated when remote version property is invalid', (done) => {

        //Given
        let remoteFeatureMap = {
            "VERSION": "NAN",
            "UK": {
                "CONTACTLESS_LIMIT": "85"
            }
        };
        testUtils.addRequestHandler(remoteJsonUrl, { statusCode : 200, body : remoteFeatureMap });

        //When
        const SdkFeature = require('../../js/common/Features');
        SdkFeature.loadRemoteFeatureMap();

        //Then
        process.nextTick(() => {
            SdkFeature.map.should.deep.equal(localFeatureMapMock);
            done();
        });
    });

    function setup() {
        testUtils.makeMockery();

        require('manticore').getItem = (key, storage, cb) => {cb();};
        require('manticore').setItem = (fileId, storage, value, cb) => {cb();};

        //Mock the path as defined in Features.js file
        let map = {};
        Object.assign(map, localFeatureMapMock);
        mockery.registerMock('../../resources/feature-map.json', map);
        testUtils.seizeHttp();
    }

    function cleanup() {
        testUtils.releaseHttp();
        testUtils.endMockery();
    }
});