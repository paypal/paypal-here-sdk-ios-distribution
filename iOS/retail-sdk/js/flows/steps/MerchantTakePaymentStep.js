import manticore from 'manticore';
import moment from 'moment';
import { FormFactor, PaymentDevice, ManuallyEnteredCard, TransactionType } from 'retail-payment-device';
import log from 'manticore-log';
import { getPropertyName } from 'manticore-util';
import {
  network as networkError,
  transaction as transactionError,
  payPalError,
  domain,
} from '../../common/sdkErrors';
import FlowStep from './FlowStep';
import TransactionRecord from '../../transaction/TransactionRecord';
import * as retailSDKUtil from '../../common/retailSDKUtil';
import Merchant from '../../common/Merchant';
import PaymentType from '../../transaction/PaymentType';

const Log = log('flow.step.mtp');
const AuthCode = PaymentDevice.authCode;

export default class MerchantTakePaymentStep extends FlowStep {
  constructor(context, voidFunc) {
    super();
    this.context = context;
    this.instrument = context.card;
    this.voidFunc = voidFunc;
    this.quickChipEnabled = context.paymentOptions && context.paymentOptions.quickChipEnabled;
  }

  execute(flow) {
    if (this.context.paymentType === PaymentType.keyIn && !(this.instrument instanceof ManuallyEnteredCard)) {
      flow.abort(transactionError.cardTypeMismatch.withDevMessage('Expected card to be of type ManuallyEnteredCard'));
      return;
    }

    this._getLocation((err, location) => {
      if (err) {
        Log.error(`Error while retrieving location: ${err}`);
        flow.abort(transactionError.locationError.withDevMessage('Error while retrieving location information.'));
        return;
      }
      Log.debug(`Retrieved location information : ${JSON.stringify(location)}`);
      flow.data.location = location;
      this._performMTP(flow);
    });
  }

  _performMTP(flow) {
    const merchant = Merchant.active;
    const rq = this._buildRequest(flow.data.location);
    Log.debug(() => `MTP request :\n${JSON.stringify(rq, null, 4)}`);
    merchant.request({
      service: 'retail',
      op: 'checkouts',
      format: 'json',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rq),
    }, (err, mtpRz) => {
      let mtpError = err;
      const apiErrorCode = mtpRz && mtpRz.body && mtpRz.body.errorCode;
      const apiWarningsErrorCode = mtpRz && mtpRz.body && mtpRz.body.warnings && mtpRz.body.warnings[0];
      if (apiErrorCode) {
        // Give priority to here-api errors
        mtpError = payPalError(domain.retail, apiErrorCode, mtpRz.body.message)
            .withDebugId(mtpRz.body.correlationId);
      }
      if (apiWarningsErrorCode) {
        // Give priority to here-api errors
        mtpError = payPalError(domain.retail, mtpRz.body.warnings[0].errorCode, mtpRz.body.warnings[0].message)
          .withDebugId(mtpRz.body.correlationId);
      }
      Log.debug(() => `MTP response: ${JSON.stringify(mtpRz, null, 4)}`);
      flow.data.tx = mtpRz && mtpRz.body ? new TransactionRecord(mtpRz.body) : {};
      flow.data.tx.card = this.context.card;

      // For all non card reader transactions, finish the flow and move on.
      if (this.context.paymentType !== PaymentType.card) {
        flow.nextOrAbort(mtpError);
        return;
      }

      const mtpRzAuthCode = mtpRz && mtpRz.body && mtpRz.body.authCode
       && mtpRz.body.authCode !== 'null' ? mtpRz.body.authCode : null;

      const isEmv = rq && rq.card && rq.card.emvData
        && (this.instrument.formFactor === FormFactor.Chip ||
        this.instrument.formFactor === FormFactor.EmvCertifiedContactless);

      if (mtpError) {
        Log.error(`MPT Error: ${JSON.stringify(mtpError)}, isEmv: ${isEmv}, formFactor: ${this.instrument.formFactor},` +
          `Invoice Total: ${this.context.invoice.currency} ${this.context.invoice.total},` +
          `rz.statusCode: ${mtpRz ? mtpRz.statusCode : 'empty'}, rz.body: ${JSON.stringify(mtpRz ? mtpRz.body : {})}`);
      } else {
        Log.info(`(${this.context.id}) MTP response received for invoice total: ${this.context.invoice.currency} ${this.context.invoice.total},` +
          `ff: ${getPropertyName(FormFactor, this.instrument.formFactor)}, AuthCode: ${mtpRz && mtpRz.body && mtpRz.body.authCode},` +
          `${flow.data.tx.toString()}`);
      }

      this._processResult(isEmv, mtpRzAuthCode, flow, mtpError);
    });
  }

  _processResult(isEmv, rzAuthCode, flow, mtpError) {
    const cbStepComplete = (error, rz) => {
      flow.data.cardResponse = rz;

      // If we encountered an error while waiting on an MTP response and it eventually succeeded then we need to void.
      if (flow.data.error) {
        Log.info(`(${this.context.id}) Voiding tx as flow was aborted when MTP request was in flight with error: ${JSON.stringify(flow.data.error)}`);
        if (this.voidFunc) {
          this.voidFunc(flow.data);
        }
        return;
      }

      flow.nextOrAbort(mtpError || error);
    };

    if (isEmv) {
      // For EMV, even if we don't get an auth code from the server, we need to make one so the card
      // can function correctly. So if we got an error, we can assume failure.
      // TODO really, we want to assume success?
      if (rzAuthCode) {
        // Before we go to the next step in the flow for EMV, we need to tell the card what we got from MTP
        flow.data.tx.authCode = rzAuthCode;
      } else {
        flow.data.tx.authCode = AuthCode.TransactionSuccess;
        if (mtpError) {
          flow.data.tx.authCode = (mtpError.code === networkError.networkOffline.code)
            ? AuthCode.NoNetwork : AuthCode.TransactionFailure;
        }
      }
      if (this.quickChipEnabled) {
        // use the same EMV data for Finalize Payment
        cbStepComplete(null, this.instrument.emvData);
      } else {
        this._pushAuthCode(flow.data.tx.authCode, cbStepComplete);
      }
    } else {
      cbStepComplete(null, null);
    }
  }

  _pushAuthCode(authCode, cb) {
    // Before we go to the next step in the flow for EMV, we need to tell the card what we got from MTP
    Log.debug(`Pushing authCode : ${authCode} to ${this.instrument.reader.id}`);
    this.instrument.reader.completeTransaction(authCode, (error, rz) => {
      if (error) {
        Log.error(`(${this.context.id}) Error response on pushing auth code to terminal-${error}`);
        cb(error, rz);
        return;
      }
      Log.info(`(${this.context.id}) Pushed auth code (${authCode}) to reader ${this.instrument.reader.id}. Response template: ${rz.apdu ? rz.apdu.template : ''}`);
      cb(null, rz);
    });
  }

  _getLocation(callback) {
    Log.debug('getLocation');
    manticore.getLocation(callback);
  }

  _buildRequest(location) {
    const request = {
      invoiceId: this.context.invoice.payPalId,
      paymentType: this.context.paymentType,
      latitude: location.latitude || 0,
      longitude: location.longitude || 0,
      dateTime: moment().format(),
    };

    if (this.context.type === TransactionType.Auth) {
      Log.debug(() => `${this.context.id} MTP setting the transaction type to AUTH, expiry & honor period`);
      request.paymentAction = 'authorization';
      if (Merchant.active.status && Merchant.active.status.cardSettings) {
        request.auth_expiry_period = Merchant.active.status.cardSettings.authExpiryPeriodPos;
        request.auth_honor_period = Merchant.active.status.cardSettings.authHonorPeriodPos;
      }
    }

    if (this.context.paymentType === PaymentType.card) {
      const card = retailSDKUtil.hereAPICardDataFromCard(this.instrument);
      if (this.instrument.formFactor !== FormFactor.MagneticCardSwipe) {
        card.pinPresent = !!this.context.pinPresent;
      }
      card.signatureRequired = this.instrument.isSignatureRequired;
      request.dateTime = this.instrument.timestamp || request.dateTime;
      request.card = card;
    }

    if (this.context.paymentType === PaymentType.keyIn) {
      const expiration = this.instrument.getExpiration() || ''; // in format MMYYYY
      request.paymentType = PaymentType.card;
      request.card = {
        inputType: PaymentType.keyIn,
        accountNumber: this.instrument.getCardNumber(),
        expirationMonth: expiration.substr(0, 2),
        expirationYear: expiration.substr(2, 4),
        cvv: this.instrument.getCVV(),
      };
    }
    return request;
  }
}
