/**
 * This enum represents the state of the auth transaction
 * @enum {int}
 */
const AuthStatus = {
  /**
   * Authorization is still pending. Yet to capture
   */
  pending: 0,

  /**
   * Authorization has been cancelled
   */
  canceled: 1,
};
export default AuthStatus;
