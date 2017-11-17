package com.paypal.paypalretailsdk;

/**
 * The error codes & domains as defined on JavaScript side
 * TODO - manticore-gen should be generating these enums based on their JavaScript definitions
 */

enum PayPalHereSdkError
{
  CardReaderNotAvailable(Domain.PAYMENT_DEVICE, 34);

  private PayPalError error;

  PayPalHereSdkError(Domain domain, int code)
  {
    PayPalErrorInfo errorInfo = new PayPalErrorInfo();
    errorInfo.setCode(Integer.toString(code));
    errorInfo.setDomain(domain.toString());
    error = PayPalError.makeError(null, errorInfo);
  }

  public PayPalError getError()
  {
    return error;
  }

  private enum Domain
  {
    PAYMENT_DEVICE("PaymentDevice");

    private final String text;

    Domain(final String text)
    {
      this.text = text;
    }

    @Override
    public String toString()
    {
      return text;
    }
  }
}
