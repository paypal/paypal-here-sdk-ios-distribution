import manticore from 'manticore';
import log from 'manticore-log';
import * as retailSDKUtil from '../common/retailSDKUtil';

const Log = log('cachedServerFile');

/**
 * The ServerBackedFile class is responsible to retrieve and cache a server backed file
 */
export default class CachedServerFile {

  /**
   * @param fileId    - Unique Id to the file
   * @param remoteUrl - Server URL for the file
   */
  constructor(fileId, remoteUrl) {
    this.url = remoteUrl;
    this.fileId = fileId;
    this.storageType = retailSDKUtil.StorageType.Secure;
  }

  /**
   * Looks for a JSON file from local cache store, server and returns the most recent version
   * @param callback  -   Callback will be invoked with the error (if any) and http response as first and second parameters
   */
  get(callback) {
    this._retrieveCachedFile((e, cachedJson) => {
      const request = { url: this.url, format: 'json', headers: {} };
      if (cachedJson && cachedJson.headers) {
        const lm = cachedJson.headers['Last-Modified'];
        const eTag = cachedJson.headers.ETag;

        if (lm) {
          request.headers['If-Modified-Since'] = lm;
        }

        if (eTag) {
          request.headers['If-None-Match'] = eTag;
        }
      }

      Log.debug(() => `GET File ${this.fileId}\nRequest: ${JSON.stringify(request)}`);
      manticore.http(request, (err, response) => {
        if (err || (response && response.statusCode >= 300)) {
          Log[(response && response.statusCode === 304) ? 'debug' : 'error'](() =>
            `Remote file load did not return new file. statusCode: ${response.statusCode}, ${err ? err.message : 'undefined'}`);
          callback(null, cachedJson ? cachedJson.body : null);
        } else if (response.body) {
          manticore.setItem(this.fileId, this.storageType, JSON.stringify(response), () => {
            Log.debug(() => `Using server version of ${this.fileId}`);
            callback(null, response.body);
          });
        } else {
          Log.debug(() => `Using CACHED version of ${this.fileId}`);
          callback(null, cachedJson ? cachedJson.body : null);
        }
      });
    });
  }

  _retrieveCachedFile(callback) {
    manticore.getItem(this.fileId, this.storageType, (e, cachedData) => {
      if (e) {
        Log.warn(`Failed to get cached file with Id ${this.fileId} from storage Type: '${this.storageType}'. Error: ${e}`);
        callback(e, null);
      }

      try {
        callback(null, cachedData ? JSON.parse(cachedData) : null);
      } catch (err) {
        Log.warn(`Unable to parse cached file ${cachedData} to json. Error : ${err}`);
        callback(err, null);
      }
    });
  }
}
