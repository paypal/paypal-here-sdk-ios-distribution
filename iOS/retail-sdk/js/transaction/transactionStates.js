/**
 * This enum represents the state of the current payment
 * @enum {int}
 */
export const PaymentState = {
  /**
   * Transaction is in idle state
   */
  idle: 0,

  /**
   * Card is currently presented and payment is in progress
   */
  inProgress: 1,

  /**
   * Payment was retried
   */
  retry: 2,

  /**
   * A payment was completed
   */
  complete: 3,
};

/**
 * This enum represents the state of the current tipping
 * @enum {int}
 */
export const TippingState = {
  /**
   * Tipping flow has not started
   */
  notStarted: 0,

  /**
   * Tipping flow is in progress
   */
  inProgress: 1,

  /**
   * Tipping flow is complete
   */
  complete: 2,
};

