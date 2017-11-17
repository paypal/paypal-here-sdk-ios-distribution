import log from 'manticore-log';
import CachedServerFile from './CachedServerFile';

const FeatureMapJson = require('../../resources/feature-map.json');

const Log = log('features');

class Features {

  constructor() {
    this.map = FeatureMapJson;
  }

  /**
   * Loads the remote feature map
   */
  loadRemoteFeatureMap() {
    const url = 'https://www.paypalobjects.com/webstatic/mobile/retail-sdk/feature-map.json';
    const file = new CachedServerFile(Features.FileId, url);

    file.get((err, remoteMap) => {
      if (err || !remoteMap) {
        Log.error(`Could not retrieve remote feature. Error: ${err}`);
        return;
      }

      Log.info(`Version of local feature map: ${this.map.VERSION} remote/cached: ${remoteMap.VERSION}`);
      if (parseFloat(this.map.VERSION) < parseFloat(remoteMap.VERSION)) {
        Log.debug('Replacing local feature map with remote');
        this.map = remoteMap;
      }
    });
  }
}

Features.FileId = 'FeatureMapStoreKey';

module.exports = new Features();

