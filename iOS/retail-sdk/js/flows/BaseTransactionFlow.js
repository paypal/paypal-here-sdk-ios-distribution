import log from 'manticore-log';
import {
  PaymentDevice,
  deviceError,
  FormFactor,
  TransactionType,
} from 'retail-payment-device';
import {
  restError,
  paypalRestErrorDomain,
} from 'paypalrest-manticore';
import { getPropertyName } from 'manticore-util';
import { network as networkError } from '../common/sdkErrors';
import PaymentErrorHandler from './PaymentErrorHandler';
import Flow from '../common/flow';
import * as Cal from '../common/cal';
import * as messageHelper from './messageHelper';
import TokenExpirationHandler from '../common/TokenExpirationHandler';
import Merchant from '../common/Merchant';

const Log = log('flow.baseTransactionFlow');
const AuthCode = PaymentDevice.authCode;

/**
 * Parent class to manage payment flows (swipe, nfc and emv)
 */
export default class BaseTransactionFlow {
  constructor(card, context, onCompleteCallback) {
    this.card = card;
    this.context = context;
    this.onCompleteCallback = onCompleteCallback;
    this.transactionCancelRequested = () => {
      Log.info(`Transaction cancel was requested from device ${this.card.reader.id}`);
      this.card.reader.abortTransaction(this.context, () => {
        Log.info(`Deactivated card reader ${this.card.reader.id}`);
        this.flow.abortFlow(deviceError.paymentCancelled);
      });
    };
    this.transactionCancelled = () => {
      Log.info(`Transaction on device ${this.card.reader.id} was cancelled`);
      this.flow.abortFlow(deviceError.paymentCancelled);
    };
  }

  /**
   * Sets the flow steps for the controller
   * @param flowName - Name for the flow
   * @param flowSteps - Sequence flow steps that will be executed by the flow controller
   * @returns {BaseTransactionFlow} - Returns 'this' object for enabling Fluent Interface
   */
  setFlowSteps(flowName, flowSteps) {
    this.flowName = flowName;
    this.flowSteps = flowSteps;
    this.flow = new Flow(this, this.flowSteps);
    return this;
  }

  addFlowEndedHandler(handler) {
    if (this.flow === undefined) {
      throw new Error('Flow needs to be initialized first');
    }
    this.flow.on('ended', handler);
    return this;
  }

  /**
   * Sets the flow that should be triggered on completion of the flowSteps registered via 'setFlowSteps' function
   * @param completionFlowName - Name fr the completion flow
   * @param flowCompletionSteps - List of flow steps
   * @returns {BaseTransactionFlow} - Returns 'this' object for enabling Fluent Interface
   */
  setCompletionSteps(completionFlowName, flowCompletionSteps) {
    this.completionFlowName = completionFlowName;
    this.completionFlowSteps = flowCompletionSteps;
    return this;
  }

  /**
   * Starts executing the flow steps that were set by the 'setFlowSteps' function
   */
  startFlow() {
    Log.debug(() => `Start executing ${this.flowSteps.length} steps for ${this.flowName} flow`);
    this.flow.name = this.flowName;
    this.flow.on('completed', (data) => {
      this.completeTransaction(data);
    });
    this.flow.on('aborted', (data) => {
      this.abortTransaction(data);
    });

    this.flow.start();
  }

  invokeCompleteCallback(flowData, action) {
    if (flowData.alert
      && (action === PaymentErrorHandler.action.abort || action === PaymentErrorHandler.action.offlineDecline)) {
      flowData.alert.dismiss();
    }
    const transactionRecord = flowData.tx || {};
    transactionRecord.card = transactionRecord.card || this.card;
    this.onCompleteCallback(flowData.error, action, transactionRecord);
  }

  completeTransaction(data, action) {
    Log.debug(() => `Starting completion steps for ${this.flowName} flow`);
    if (!this.completionFlowSteps) {
      Log.debug(() => 'Flow ended and completion steps not defined. Proceeding to invoke complete callback');
      this.invokeCompleteCallback(data, action);
      return;
    }

    this.completionFlow = new Flow(this, this.completionFlowSteps);
    this.completionFlow.name = this.completionFlowName;
    this.completionFlow.data = data;
    this.completionFlow.on('ended', (dt) => {
      Log.debug(() => `Flow ended. Proceeding to invoke flow complete callback (error: ${dt.error})`);
      this.invokeCompleteCallback(dt, action);
    });

    if (this.completionFlow) {
      if (this.card && this.card.reader) {
        // Reset the terminal
        this.card.reader.postTransactionCleanup(() => {
          this.completionFlow.start();
        });
      } else {
        this.completionFlow.start();
      }
    } else {
      Log.debug('Did not find any completionFlow');
    }
  }

  abortTransaction(data) {
    Log.debug(() => `Aborting ${this.context.id}`);
    this.voidPaymentIfApplicable(data);
    const err = data.error;
    const formFactor = this.card && this.card.formFactor;
    const reader = this.card && this.card.reader;

    if (!err) {
      if (reader) {
        reader.display({
          id: PaymentDevice.Message.TransactionCancelled,
          substitutions: messageHelper.formattedInvoiceTotal(this.context.invoice),
        }, () => this.completeTransaction(data));
      } else {
        this.completeTransaction(data);
      }
      return;
    }

    Log.warn(`Flow (${getPropertyName(FormFactor, formFactor)}) aborted with error code: '${err.code}' domain: ${err.domain}\n${err}`);
    if (this.context.timeoutHandler
      && err.domain === paypalRestErrorDomain
      && err.code === restError.unauthorized.code) {
      const timeoutHandler = new TokenExpirationHandler((timeoutAction) => {
        Log.debug(() => `TokenExpirationHandler was invoked with handler: ${getPropertyName(TokenExpirationHandler.action, timeoutAction)}`);
        if (timeoutAction === TokenExpirationHandler.action.resume) {
          throw new Error('Not implemented');
        }
        this.invokeCompleteCallback(data);
      });
      if (data.alert) {
        data.alert.dismiss();
      }
      this.context.timeoutHandler(timeoutHandler);
      return;
    }

    const handler = new PaymentErrorHandler(this.context);
    handler.handle(err, formFactor, reader, (action) => {
      if (action === PaymentErrorHandler.action.abort) {
        this.completeTransaction(data, action);
      } else {
        this.invokeCompleteCallback(data, action);
      }
    });
  }

  voidPaymentIfApplicable(data) {
    if (!(data && data.tx && data.tx.transactionHandle)) {
      Log.debug('Will not void transaction as transaction handle was not assigned');
      return;
    }
    const body = { invoiceId: this.context.invoice.payPalId };
    if (data.tx.responseCode) {
      body.responseCode = data.tx.responseCode;
    }

    if (data.cardResponse && data.cardResponse.apdu && data.cardResponse.apdu.data) {
      body.emvData = data.cardResponse.apdu.data.toString('hex');
    }

    let transactionQueryParam = data.tx.transactionHandle;
    if (this.context.type === TransactionType.Auth) {
      transactionQueryParam = data.tx.transactionNumber;
    }
    const op = `checkouts/${transactionQueryParam}/void`;
    Log.debug(() => `Invoice void request:${JSON.stringify(body, null, 4)}`);
    Merchant.active.request({
      service: 'retail',
      op,
      format: 'json',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }, (error, voidRz) => {
      if (error) {
        Log.error(`Void request ${op} returned an error for payload: ${JSON.stringify(body, null, 4)}\n${error} `);
        return;
      }
      Log.info(`Successfully voided invoice id: ${this.context.invoice.payPalId}. ${JSON.stringify(voidRz)}`);
    });
  }

  saveInvoiceStep(flow) {
    Log.debug(() => `Saving invoice\n${JSON.stringify(this.context.invoice, null, 4)}`);
    this.context.invoice.save((error) => {
      if (error && this.card && this.card.reader) {
        Log.error(`Unable to save invoice. Error: ${error}\n${JSON.stringify(this.context.invoice, null, 4)}`);
        let authCode = AuthCode.TransactionFailure;
        if (error.code === networkError.networkOffline.code) {
          authCode = AuthCode.NoNetwork;
        }
        Log.debug(`Pushing authCode : ${authCode}`);
        this.card.reader.completeTransaction(authCode, (err) => {
          if (err) {
            Log.error(`Error response on pushing auth code to terminal ${JSON.stringify(err)}`);
          }
          return flow.abortFlow(error);
        });
      } else if (error) {
        flow.abortFlow(error);
      } else {
        Log.debug(() => `Saved invoice successfully ${JSON.stringify(this.context.invoice, null, 4)}`);
        Cal.setInvoiceId(this.context.invoice.payPalId);
        flow.next();
      }
    });
  }

  createFlowMessageStep(messageHelperFunc) {
    return (flow) => {
      messageHelperFunc(this.context, flow.data, () => {
        flow.next();
      });
    };
  }
}
