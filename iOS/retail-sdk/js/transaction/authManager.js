import log from 'manticore-log';
import moment from 'moment';
import {
  isDatesWithinOffset,
} from '../common/retailSDKUtil';
import {
  sdk as sdkError,
} from '../common/sdkErrors';
import retrieveTransactions from './authorizedTransactionsRetriever';
import AuthStatus from './AuthStatus';

const Log = log('authManager');

function _getQueryParams(startDateTime, endDateTime, pageSize, status, nextPageToken, callback) {
  let queryParams = null;
  // If there is a next page token use that, if not build the queryParam
  if (nextPageToken) {
    queryParams = nextPageToken;
  } else {
    let validationErrorDeveloperMessage = null;
    // Start date time is a required field and should be less than current date time
    if (!startDateTime || !(moment(startDateTime).isValid()) || moment(startDateTime) > moment()) {
      validationErrorDeveloperMessage = 'startDateTime is missing or is invalid';
    } else if (endDateTime && !moment(endDateTime).isValid()) {
      validationErrorDeveloperMessage = 'endDateTime is invalid';
    } else if (endDateTime && startDateTime.getTime() > endDateTime.getTime()) {
      validationErrorDeveloperMessage = 'startDateTime should not greater than endDateTime';
    } else if (endDateTime && !isDatesWithinOffset(startDateTime, endDateTime, 5)) {
      // We are limiting the difference in days to 5 because of server side limitations
      validationErrorDeveloperMessage = 'endDateTime - startDateTime cannot be greater than 5 days';
    } else if (!Number.isInteger(pageSize) || pageSize <= 0 || pageSize > 30) {
      validationErrorDeveloperMessage = 'pageSize is invalid. It should be greater than 0 and less than 31';
    }

    if (validationErrorDeveloperMessage) {
      Log.error(`Invalid input: ${validationErrorDeveloperMessage}`);
      const validationError = sdkError.validationError;
      validationError.developerMessage = validationErrorDeveloperMessage;
      callback(validationError);
      return undefined;
    }

    // End date time is optional, if missing set it to startDateTime + 5 days
    let finalEndTime = null;
    if (!endDateTime) {
      finalEndTime = new Date(startDateTime);
      finalEndTime.setDate(finalEndTime.getDate() + 5);
    } else {
      finalEndTime = endDateTime;
    }

    queryParams = `start_time=${moment(startDateTime).toISOString()}`;
    queryParams = `${queryParams}&end_time=${moment(finalEndTime).toISOString()}`;
    queryParams = `${queryParams}&page_size=${pageSize}`;

    // status filter is optional, so fill in the list of provided status into queryParams
    if (status && status.length > 0) {
      queryParams = `${queryParams}&statuses=`;
      status.forEach((id) => {
        switch (id) {
          case AuthStatus.pending:
            queryParams = `${queryParams}PENDING,`;
            break;
          case AuthStatus.canceled:
            queryParams = `${queryParams}CANCELED,`;
            break;
          default:
        }
      });
      // Remove the extra comma(,) in the end
      queryParams = queryParams.substring(0, queryParams.length - 1);
    }
  }
  Log.debug(() => `the query params are ${queryParams}`);

  return queryParams;
}

export default function retrieveAuthorizedTransactions(
  startDateTime, endDateTime, pageSize = 10, status, nextPageToken, callback) {
  Log.debug(() => `the startTime object is ${JSON.stringify(startDateTime)} and is of the type ${typeof startDateTime}`);
  Log.debug(() => `the endTime object is ${JSON.stringify(endDateTime)} and is of the type ${typeof endDateTime}`);
  Log.debug(() => `the pageSize object is ${JSON.stringify(pageSize)} and is of the type ${typeof pageSize}`);
  Log.debug(() => `the status object is ${JSON.stringify(status)} and is of the type ${typeof status}`);
  Log.debug(() => `the nextPageToken object is ${JSON.stringify(nextPageToken)} and is of the type ${typeof nextPageToken}`);

  const queryParams = _getQueryParams(startDateTime, endDateTime, pageSize, status, nextPageToken, callback);
  if (queryParams) {
    retrieveTransactions(queryParams, callback);
  }
}
