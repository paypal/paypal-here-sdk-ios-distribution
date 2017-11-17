package com.paypal.paypalretailsdk.pph;

import java.util.List;

public class PPHMerchantCardSettings {

  private String minimum;
  private String maximum;
  private String signatureRequiredAbove;
  private List<String> unsupportedCardTypes;

  public PPHMerchantCardSettings(String minimum,
                                 String maximum,
                                 String signatureRequiredAbove,
                                 List<String> unsupportedCardTypes) {
    this.minimum = minimum;
    this.maximum = maximum;
    this.signatureRequiredAbove = signatureRequiredAbove;
    this.unsupportedCardTypes = unsupportedCardTypes;
  }

  public String getMinimum() {
    return minimum;
  }

  public String getMaximum() {
    return maximum;
  }

  public String getSignatureRequiredAbove() {
    return signatureRequiredAbove;
  }

  public List<String> getUnsupportedCardTypes() {
    return unsupportedCardTypes;
  }
}
