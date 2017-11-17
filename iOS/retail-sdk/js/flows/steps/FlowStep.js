export default class FlowStep {
  get flowStep() {
    const self = this;
    const stepFn = (flow) => {
      self.execute(flow);
    };
    stepFn.fnName = this.constructor.name;
    return stepFn;
  }

  execute() {
    throw new Error('FlowStep must define execute method.');
  }
}
