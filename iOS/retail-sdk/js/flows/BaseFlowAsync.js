import log from 'manticore-log';
import FlowAsync from '../common/flowAsync';

const Log = log('flow.baseFlow');

/**
 * Base class to manage All flows..
 */
export default class BaseFlowAsync {

  constructor() { // eslint-disable-line no-useless-constructor
  }

  /**
   * Sets the flow steps for the controller
   * @param flowName - Name for the flow
   * @param flowSteps - Sequence flow steps that will be executed by the flow controller
   * @returns {BaseFlowAsync} - Returns 'this' object for enabling Fluent Interface
   */
  setFlowSteps(flowName, flowSteps) {
    this.flowSteps = flowSteps;
    this.flow = new FlowAsync(this, this.flowSteps);
    this.flow.name = flowName;
    return this;
  }

  addFlowEndedHandler(handler) {
    this._check();
    this.flow.once('ended', handler);
    return this;
  }

  addFlowAbortedHandler(handler) {
    this._check();
    this.flow.once('aborted', handler);
    return this;
  }

  addFlowCompletedHandler(handler) {
    this._check();
    this.flow.once('completed', handler);
    return this;
  }

  _check() {
    if (!this.flow) {
      throw new Error('Flow needs to be initialized first');
    }
  }

  /**
   * Sets the flow that should be triggered on completion of the flowSteps registered via 'setFlowSteps' function
   * @param completionFlowName - Name fr the completion flow
   * @param flowCompletionSteps - List of flow steps
   * @returns {BaseFlowAsync} - Returns 'this' object for enabling Fluent Interface
   */
  setCompletionSteps(completionFlowName, flowCompletionSteps) {
    this.completionFlowName = completionFlowName;
    this.completionFlowSteps = flowCompletionSteps;
    return this;
  }

  /**
   * Displays an alert dialog on the application.
   * @param messageHelperFunc A function that contains the message to be displayed.
   * @returns {Function} The current flow step.
   */
  createFlowMessageStep(messageHelperFunc) {
    return (flow) => {
      messageHelperFunc(this.context, flow.data, (alert) => {
        this.alert = alert;
        flow.next();
      });
    };
  }

  /**
   * Starts executing the flow steps that were set by the 'setFlowSteps' function
   */
  async startFlow() {
    Log.debug(() => `Start executing ${this.flowSteps.length} steps for ${this.flow.name} flow`);
    await this.flow.start();
  }
}
