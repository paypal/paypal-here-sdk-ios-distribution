/**
 * The NetworkRequest class represents the HTTP Request object from the SDK
 * @class
 * @property {string} url Request Url
 * @property {string} method HTTP Request method
 * @property {string} format Format of the HTTP Request
 * @property {object} headers HTTP Request headers
 * @property {string} body Request body
 */
export default class NetworkRequest {
  /**
   * @private
   */
  constructor(callback) {
    this.callback = callback;
  }

  /**
   *
   * @param {error} err Error (if any) from handling network request
   * @param {bool} didHandle Indicates if the request was handled or not. When set to false, the SDK will fallback to
   * default network handler for handling the network requests
   * @param {NetworkResponse} response response to HTTP request. Can be null if didHandle is set to 'false'
   */
  continueWithResponse(err, didHandle, response) {
    this.callback(err, didHandle, response);
  }
}
