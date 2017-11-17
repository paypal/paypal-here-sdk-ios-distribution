import manticore from 'manticore';
import log from 'manticore-log';
import NetworkRequest from './NetworkRequest';

const Log = log('NetworkInterceptor');

/**
 * Add a network handler to intercept all outgoing SDK network calls
 * @param {SDK~intercept} interceptor
 */
export default function setNetworkHandler(interceptor) {
  const prevHttp = manticore.http;
  manticore.http = (opt, callback) => {
    const networkRequest = new NetworkRequest((err, didHandleRequest, networkResponse) => {
      if (!didHandleRequest) {
        prevHttp(opt, callback); // Falling back to internal network handler
        return;
      }
      Log.debug(() => `Request ${opt.url} was handled by custom handler`);
      if (networkResponse.format === 'json') {
        try {
          networkResponse.body = JSON.parse(networkResponse.body);
        } catch (x) {
          Log.error(`Error parsing provided JSON body ${networkResponse.body}\n${x}`);
          throw x;
        }
      }
      callback(err, networkResponse);
    });
    networkRequest.url = opt.url;
    networkRequest.method = opt.method;
    networkRequest.headers = opt.headers;
    networkRequest.body = opt.body;

    try {
      interceptor(networkRequest);
    } catch (x) {
      Log.error(`Error invoking custom network interceptor... Will fallback to default\n${x}`);
      prevHttp(opt, callback);
    }
  };
}
