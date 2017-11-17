import log from 'manticore-log';
import { EventEmitter } from 'events';

const Log = log('flow');
const FACADE = Symbol('flow');

/**
 * Present a protected view of the flow to a particular step so that it can't call the
 * true flow step after it is deactivated.
 */
class FlowFacade extends EventEmitter {
  constructor(flow) {
    super();
    this.active = true;
    this.flow = flow;
  }

  _prepareForChange(noPush) {
    const f = this.flow;
    if (!noPush) {
      f.previousSteps.push(f.stepIndex);
    }
    if (f[FACADE]) {
      f[FACADE].active = false;
    }
    f[FACADE] = new FlowFacade(f);
  }

  _check() {
    if (!this.active) {
      Log.error(`Flow step completion function called by inactive step ${this.stepName}!`);
      this.flow.emit('flowError', new Error('Flow step completion function called by inactive step!'));
      return false;
    }
    return true;
  }

  get stepName() {
    const fn = this.flow.steps[this.flow.stepIndex];
    return fn ? (fn.fnName || fn.name) : undefined;
  }

  _executeStep(index) {
    const direction = (index < this.flow.stepIndex ? 'regressing' : 'advancing');
    this.flow.stepIndex = index;
    const stepFn = this.flow.steps[index];
    Log.debug(() => `Flow ${direction} to ${this.stepName}`);

    try {
      stepFn.call(this.flow.owner, this.flow[FACADE]);
    } catch (e) {
      Log.error(`${this.stepName} execution returned an error: ${e}`);
      this.flow[FACADE].abortFlow(e);
    }
  }

  /**
   * A flow step should call next to advance to the next step, or complete if it's the last
   */
  next() {
    if (!this._check()) {
      Log.debug('Flow::next called out of turn!');
      return;
    }
    const f = this.flow;
    if (f.stepIndex + 1 >= f.steps.length) {
      this.completeFlow();
      return;
    }
    f.emit('next', f.stepIndex);
    this._prepareForChange();
    this._executeStep(f.stepIndex + 1);
  }

  /**
   * A flow step should call back to end the current step and go back to the previous step
   * (or abort if you're the first)
   * TODO how do we continue to go back if the previous step was skipped?
   */
  back() {
    if (!this._check()) {
      Log.debug('Flow::back called out of turn!');
      return;
    }
    const f = this.flow;
    if (f.previousSteps.length === 0) {
      this.abortFlow();
      return;
    }
    f.emit('back', f.steps[f.stepIndex], f.steps[f.stepIndex - 1]);
    this._prepareForChange(true);
    this._executeStep(f.previousSteps.pop());
  }

  /**
   * Immediately complete the flow, firing the completed event
   */
  completeFlow() {
    if (!this._check()) {
      Log.debug('Flow::complete called out of turn!');
      return;
    }
    Log.debug(() => `${this.flow.name || 'Anonymous'} Flow completed.`);
    const f = this.flow;
    this._prepareForChange();
    f.stepIndex = null;
    f[FACADE] = null;
    f.emit('completed', f.data);
    f.emit('ended', f.data);
  }

  /**
   * Immediately abort the flow, firing the aborted event
   */
  abortFlow(error) {
    if (!this._check()) {
      Log.debug('Flow::abortFlow called out of order!');
      return;
    }
    Log.debug(`${this.flow.name || 'Anonymous'} Flow aborted`);
    const f = this.flow;
    if (error) {
      f.data.error = error;
    }
    f[FACADE].emit('aborted');
    this._prepareForChange();
    f.stepIndex = null;
    f[FACADE] = null;
    f.emit('aborted', f.data);
    f.emit('ended', f.data);
  }

  nextOrAbort(error) {
    if (error) {
      this.abortFlow(error);
    } else {
      this.next();
    }
  }

  get data() {
    return this.flow.data;
  }

  get stepIndex() {
    return this.flow.stepIndex;
  }

  get previousSteps() {
    return this.flow.previousSteps;
  }
}

/**
 * A flow is a series of steps in order to complete a process. Each step may complete, cancel, go forward or back
 * in the process. In code, a flow is an array of functions. The functions take one argument - a flow controller -
 * which exposes methods to control the next step in the flow.
 *
 */
export default class Flow extends EventEmitter {
  /**
   * Construct a new flow with steps pass as individual arguments (each a function) OR
   * as a single array as the second argument.
   * Call start() after setting up appropriate event handlers.
   */
  constructor(thisForSteps, allSteps) {
    super();
    this.owner = thisForSteps;
    if (Array.isArray(allSteps)) {
      this.steps = allSteps;
    } else {
      this.steps = Array.prototype.slice.call(arguments, 1); // eslint-disable-line prefer-rest-params
    }
    /**
     * A grab bag of data that can be used to share information among steps
     * @type {object}
     */
    this.data = {};
    this[FACADE] = null;
    this.stepIndex = 0;
    this.previousSteps = [];
  }

  start() {
    this[FACADE] = new FlowFacade(this);
    this[FACADE]._executeStep(0);
    return this;
  }

  abortFlow(error) {
    if (!this[FACADE]) {
      Log.error('Abort called on an inactive flow!');
      return;
    }
    this[FACADE].abortFlow(error);
  }
}
