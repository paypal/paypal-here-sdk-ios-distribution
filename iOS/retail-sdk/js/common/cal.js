import manticore from 'manticore';
import manticoreLog from 'manticore-log';
import stringify from 'qs/lib/stringify';
import * as retailSDKUtil from '../common/retailSDKUtil';

function generateGroupId() {
  return `${Date.now()}-${Math.random()}`;
}

const Log = manticoreLog('cal');
const MAX_CAL_EVENT_LENGTH = 20;
const CAL_LOG_SUCCESS = 0;
const CAL_LOG_FAIL = -1;
const CAL_LOG_STORE_KEY = 'CalLogStore';
const RootCalConfig = {
  level: 'INFO',
  children: {},
};

let queueDetails;
let logGroup = generateGroupId();
let logInvoiceId = '';
let requestSource = 'RetailSDK';
let savingLogStore = false;
let overlappedSaves = [];
let messageRunCounter = 0;

function saveLogStore(cb) {
  if (savingLogStore) {
    // Even if it's null, because we need to know to save again
    overlappedSaves.push(cb);
    return;
  }
  manticore.setItem(CAL_LOG_STORE_KEY, retailSDKUtil.StorageType.SecureBlob, JSON.stringify(queueDetails),
    (saveError) => {
      savingLogStore = false;
      if (overlappedSaves.length) {
        const nextSaves = overlappedSaves;
        overlappedSaves = [];
        saveLogStore((e) => {
          for (const savedCallback of nextSaves) {
            if (savedCallback) {
              savedCallback(e);
            }
          }
        });
      }
      if (cb) {
        cb(saveError);
      }
    });
}

function setDefaultCalLogData(calLogData, level) {
  // Set the actionId to message if not specified
  if (!calLogData.actionId) {
    calLogData.actionId = 'message';
  }
  // Set the status based on level, if not specified in calLogData
  if (!calLogData.status) {
    switch (level.toLowerCase()) {
      case 'debug':
        calLogData.status = CAL_LOG_SUCCESS;
        break;
      case 'info':
        calLogData.status = CAL_LOG_SUCCESS;
        break;
      case 'error':
        calLogData.status = CAL_LOG_FAIL;
        break;
      case 'warn':
        calLogData.status = CAL_LOG_FAIL;
        break;
      default:
        calLogData.status = CAL_LOG_FAIL;
        break;
    }
  }

  // Build the msgId which is an incrementing-per-sdk-launch "runId", a forever-incrementing message counter, and a
  // per-run message counter
  messageRunCounter += 1;
  queueDetails.msgCounter += 1;
  calLogData.msgId = `${queueDetails.runCounter}.${queueDetails.msgCounter}.${messageRunCounter}`;
}

function buildCalConfigMapping(component) {
  // Build the association of CAL configuration to manticore-log component
  const loggers = component.name.split('.');
  let myComponent = RootCalConfig;
  let parent = RootCalConfig;
  for (let i = 0; i < loggers.length; i++) {
    if (!myComponent.children[loggers[i]]) {
      myComponent.children[loggers[i]] = { children: {}, parent };
    }
    myComponent = myComponent.children[loggers[i]];
    parent = myComponent;
  }
  component.calConfig = myComponent;
}

function addCalEvent(calLogEvent) {
  const logOverflow = () => (MAX_CAL_EVENT_LENGTH <= queueDetails.events.length);
  if (logOverflow()) {
    Log.debug(`CAL log overflow. Max messages: ${MAX_CAL_EVENT_LENGTH}`);
  }

  // if the previous flush attempt was not successful, then remove an element from the array
  while (logOverflow()) {
    queueDetails.events.shift();
    if (queueDetails.saving) {
      queueDetails.saving -= 1;
    }
  }
  queueDetails.events.push(calLogEvent);
  saveLogStore();
}

/**
 * Cal logging framework for the SDK.
 * Cal logs require: name, actionId, status (0=success, -1 = fail), type (always set to "BIZ")
 * and logData consisting of actionId dependent values such as
 * timestamp (universal yyyy-MM-dd HH:mm:ss:fff +0000), duration, message details
 * The method signature is the same as the manticore log, with one additional Cal logging parameter: calLogData
 * manticore logs are verbose messages that can be logged as-is. These will be logged with "message" actionId (ToDo).
 * We could have a configuration that specifies what level of logs should be sent to Cal as messages.
 * For non-message logs, e.g. ClientInfo, NetworkResponse etc., the code will include Cal-specific log calls
 * These Cal-specific calls will send cal-specific information in the calLogData object.
 * Open for discussion: What comes first? manticore-log, and that in turn calls Cal log,
 * or Start with Cal log, and then call Manticore log from Cal?
 * @param level Debug, Trace, Info, Warn, Error
 * @param component ?
 * @param fnOrString Log message. You can pass a string, or use an es6 template INSIDE a function (for best performance).
 * @param calLogData json object with actionId dependent values
 * e.g. actionId=SWIPE/CreateInvoice etc., status=0/-1 (Success = 0, Fail = -1+ ...
 */
function calLog(level, component, fnOrString, calLogData) {
  // avoid recursive calls.
  if (component.name === 'cal') {
    return;
  }

  if (!component.calConfig) {
    buildCalConfigMapping(component);
  }

  if (manticoreLog.Ranks[level] < manticoreLog.levelFor(component.calConfig)) {
    return;
  }

  // default actionId = message
  if (!calLogData) {
    calLogData = { actionId: 'Message' }; // eslint-disable-line no-param-reassign
  }

  setDefaultCalLogData(calLogData, level, fnOrString);

  // ToDo: calculate status based on the level, if it is not available in calLogData
  const calLogEvent = {
    status: calLogData.status,
    type: 'BIZ',
    name: `${calLogData.actionId}.CLIENT`,
  };

  // cal log data expects the status as 'result', so change that before stringifying the json object.
  calLogData.result = calLogData.status;
  delete calLogData.status;
  if (typeof fnOrString === 'function') {
    // ToDo:Question save this in details or reason?
    calLogData.details = fnOrString().toString();
  } else {
    calLogData.details = fnOrString.toString();
  }
  calLogData.logGroup = logGroup;
  calLogData.invoiceId = logInvoiceId;
  calLogEvent.data = stringify(calLogData, { encode: false });
  manticore.setTimeout(() => addCalEvent(calLogEvent), 0);
}

function removePostedLogs(cb) {
  Log.debug(() => `Removing ${queueDetails.saving} posted logs.`);
  queueDetails.events.splice(0, queueDetails.saving);
  queueDetails.saving = 0;
  saveLogStore(cb);
}

function doHttpPost(calLogMessageBody, cb) {
  const Merchant = require('../common/Merchant').default; // eslint-disable-line global-require
  const saved = queueDetails.saving;
  if (Merchant.active) {
    Merchant.active.request({
      service: 'retail',
      op: 'secure-terminal-config/cal',
      method: 'POST',
      headers: {
        'X-PAYPAL-REQUEST-SOURCE': requestSource,
        'Content-Type': 'application/json',
      },
      body: calLogMessageBody,
    }, (error, rz) => {
      if (!error && rz && rz.statusCode === 200) {
        removePostedLogs((e) => {
          if (cb) {
            cb(e, saved);
          }
        });
      } else {
        queueDetails.saving = 0;
        // TODO decide whether to re-post now or some other time... Or whether
        // someone else should handle that decision based on the callback
        if (cb) {
          cb(error);
        }
      }
    });
  } else if (cb) {
    cb(new Error('No merchant available, cannot post CAL logs'));
  }
}

/**
 * Attach the CAL logger to the manticore logging infra and setup the various counters.
 * @param callback
 */
export function attach(callback) {
  // Load the existing log set
  manticore.getItem(CAL_LOG_STORE_KEY, retailSDKUtil.StorageType.Secure, (e, jsonString) => {
    if (e) {
      Log.error(`Failed to get persisted CAL queue ${e.message}`);
    }
    if (jsonString) {
      queueDetails = JSON.parse(jsonString);
      // Increment the run counter since this is a new run
      queueDetails.runCounter += 1;
    } else {
      queueDetails = {
        // Currently queued events
        events: [],
        // When we're in the process of posting, we need to know how many we're saving
        // so that we can recover gracefully
        saving: 0,
        runCounter: 1,
        msgCounter: 0,
      };
    }
    manticoreLog.addLogger(calLog);
    callback(e);
  });
}

export function configure(json) {
  manticoreLog.configure(json, RootCalConfig);
}

/**
 * Mostly for testing purposes, but this will shut down CAL logging and unregister from manticore logging
 * @param callback
 */
export function detach(callback) {
  saveLogStore((e) => {
    manticoreLog.removeLogger(calLog);
    if (callback) {
      callback(e);
    }
  });
}

/**
 * Flush the queued logs to the server
 * @param cb
 */
export function flush(cb) {
  if (queueDetails.saving) {
    if (cb) {
      cb(new Error('Save already in progress.'));
    }
    return;
  }
  if (queueDetails.events.length) {
    const body = JSON.stringify({ events: queueDetails.events });
    queueDetails.saving = queueDetails.events.length;
    Log.debug(`Flushing ${queueDetails.saving} to CAL server.`);
    doHttpPost(body, cb);
  } else if (cb) {
    cb(null, 0);
  }
}

// TODO these won't work like this if and when we don't have a single active transaction. We should restructure
// this soon to avoid the problem later. Easiest thing is probably to have some closure trick that will create a
// "logging facade" that stores this info and merges it with the fourth argument to regular logging.

// Log grouping
// Logs can grouped by associating a logGroup with each log within a transaction
// The transaction manager can invoke newLogGroup() to generate a new log group

export function newGroup(groupId) {
  logGroup = groupId || generateGroupId();
  logInvoiceId = '';
  Log.debug(() => `Set group Id to ${logGroup}`);
  return logGroup;
}

export function setInvoiceId(invoiceId) {
  logInvoiceId = invoiceId;
}

export function setRequestSourceId(id) {
  if (id) {
    requestSource = `RetailSDK.${id.substr(0, 150)}`;
  }
}

// calLog('debug', 'cal', 'debug message 1');
// newLogGroup();
// calLog('info', 'cal', 'info message 1');
// setCurrentInvoiceId('Invoice1');
// calLog('error', 'cal', 'error message 1');

// Cal log examples from the Windows SDK:
// BuildAbstractHereJsonRequest(_serverMapping.HereAPIBaseURI, "/webapps/hereapi/merchant/v1/cal/", HttpMethodEnum.Post)
// live log content:
// {"events":[{"status":0,"type":"BIZ","name":"Message.CLIENT","data":"sessionId=d6696eda-238f-4c81-a904-499496acc778&timestamp=2015-07-21 18:43:47:605 +0000&actionId=Message&level=Debug&result=0&reason=PPHSDK%2BCardReaderManager-Activate&modelNo=Dell+Inc.+-+Latitude+E7240&osVersion=Windows+NT+6.3&sdkVersion=1.0.0.0&appVersion=1.0.0.0&appName=PayPalHereSDKPrivateSampleApp"},{"status":0,"type":"BIZ","name":"Message.CLIENT","data":"sessionId=d6696eda-238f-4c81-a904-499496acc778&timestamp=2015-07-21 18:43:47:605 +0000&actionId=Message&level=Debug&result=0&reason=PPHSDK%2BCardReaderManager-isMandatoryUpdateRequired+%3A+False&modelNo=Dell+Inc.+-+Latitude+E7240&osVersion=Windows+NT+6.3&sdkVersion=1.0.0.0&appVersion=1.0.0.0&appName=PayPalHereSDKPrivateSampleApp"},{"status":0,"type":"BIZ","name":"Message.CLIENT","data":"sessionId=d6696eda-238f-4c81-a904-499496acc778&timestamp=2015-07-21 18:43:47:902 +0000&actionId=Message&level=Debug&result=0&reason=PPHSDK.CardReaderWatcher.InvalidAudio-Not+a+valid+audio+device+%5C%5C%3F%5CSWD%23MMDEVAPI%23%7B0.0.0.00000000%7D.%7Bde63f815-d337-4765-ad7f-e96a54610559%7D%23%7Be6327cad-dcec-4949-ae8a-991e976a79d2%7D(True)+-+audioEndpointType%3A+DigitalAudioDisplayDeviceHDMI%2C+EnclosureLocation+%3A+Unknown&modelNo=Dell+Inc.+-+Latitude+E7240&osVersion=Windows+NT+6.3&sdkVersion=1.0.0.0&appVersion=1.0.0.0&appName=PayPalHereSDKPrivateSampleApp"},{"status":0,"type":"BIZ","name":"Message.CLIENT","data":"sessionId=d6696eda-238f-4c81-a904-499496acc778&timestamp=2015-07-21 18:43:47:980 +0000&actionId=Message&level=Debug&result=0&reason=PPHSDK.CardReaderWatcher.InvalidAudio-Not+a+valid+audio+device+%5C%5C%3F%5CSWD%23MMDEVAPI%23%7B0.0.0.00000000%7D.%7B897d524e-a5d5-4dc1-94c9-49b516bd68f5%7D%23%7Be6327cad-dcec-4949-ae8a-991e976a79d2%7D(True)+-+audioEndpointType%3A+Speakers%2C+EnclosureLocation+%3A+Unknown&modelNo=Dell+Inc.+-+Latitude+E7240&osVersion=Windows+NT+6.3&sdkVersion=1.0.0.0&appVersion=1.0.0.0&appName=PayPalHereSDKPrivateSampleApp"},{"status":0,"type":"BIZ","name":"Message.CLIENT","data":"sessionId=d6696eda-238f-4c81-a904-499496acc778&timestamp=2015-07-21 18:43:47:980 +0000&actionId=Message&level=Debug&result=0&reason=PPHSDK.CardReaderWatcher.InvalidAudio-Not+a+valid+audio+device+%5C%5C%3F%5CSWD%23MMDEVAPI%23%7B0.0.1.00000000%7D.%7B085aa242-6239-45a2-89a6-3efb67ce3549%7D%23%7B2eef81be-33fa-4800-9670-1cd474972c3f%7D(True)+-+audioEndpointType%3A+UnknownFormFactor%2C+EnclosureLocation+%3A+Unknown&modelNo=Dell+Inc.+-+Latitude+E7240&osVersion=Windows+NT+6.3&sdkVersion=1.0.0.0&appVersion=1.0.0.0&appName=PayPalHereSDKPrivateSampleApp"}]}
// POST https://www.paypal.com/webapps/hereapi/merchant/v1/cal/ HTTP/1.1
