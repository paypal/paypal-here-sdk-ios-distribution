import log from 'manticore-log';

const Log = log('tokenExpiration.handler');

/**
 * When user session times-out during a transaction, it will emit the SessionTimeoutHandler handler
 * @class
 */
export default class TokenExpirationHandler {
  constructor(cb) {
    this._cb = cb;
  }

  /**
   * Quit the current activity
   */
  quit() {
    Log.debug('Quitting current action');
    this._cb(TokenExpirationHandler.action.end);
  }

  /**
   * Restart the last action with a valid access token
   * @param {string} accessToken Valid access token
   */
  continueWithNewToken(accessToken) {
    Log.debug(() => `Continuing transaction with ${accessToken}`);
    this._cb(TokenExpirationHandler.action.resume, accessToken);
  }
}

TokenExpirationHandler.action = {
  end: 0,
  resume: 1,
};
