/**
 * The log level for the SDK
 * @enum {int}
 */
const logLevel = {
  /**
   * No logs statements will be included in the output
   */
  quiet: 0,
  /**
   * Error logs will be forwarded to the output
   */
  error: 1,
  /**
   * Warn and Error logs will be forwarded to the output
   */
  warn: 2,
  /**
   * Info, Warn & Error logs will be forwarded to output
   */
  info: 3,
  /**
   * Debug, Info, Warn & Error logs will be forwarded to output
   */
  debug: 4,
};

export default logLevel;
