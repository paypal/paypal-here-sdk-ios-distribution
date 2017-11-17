export default class FlowStepAsync {
  get flowStep() {
    const self = this;
    const stepFn = async (flow) => {
      await self.execute(flow);
    };
    stepFn.fnName = this.constructor.name;
    return stepFn;
  }

  async execute() {
    throw new Error('FlowStep must define execute method.');
  }
}
