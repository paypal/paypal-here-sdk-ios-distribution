package com.paypal.paypalretailsdk.pph;

import java.util.List;

public class PPHMerchantStatus {

  private String status;
  private List<String> paymentTypes;
  private PPHMerchantCardSettings cardSettings;
  private String currencyCode;
  private boolean businessCategoryExists;

  public PPHMerchantStatus(String status,
                           List<String> paymentTypes,
                           PPHMerchantCardSettings cardSettings,
                           String currencyCode,
                           boolean businessCategoryExists) {
    this.status = status;
    this.paymentTypes = paymentTypes;
    this.cardSettings = cardSettings;
    this.currencyCode = currencyCode;
    this.businessCategoryExists = businessCategoryExists;
  }

  public String getStatus() {
    return status;
  }

  public List<String> getPaymentTypes() {
    return paymentTypes;
  }

  public PPHMerchantCardSettings getCardSettings() {
    return cardSettings;
  }

  public String getCurrencyCode() {
    return currencyCode;
  }

  public boolean getBusinessCategoryExists() {
    return businessCategoryExists;
  }
}
