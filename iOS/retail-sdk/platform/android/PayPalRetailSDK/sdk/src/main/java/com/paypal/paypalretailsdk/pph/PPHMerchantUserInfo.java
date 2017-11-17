package com.paypal.paypalretailsdk.pph;

import com.paypal.paypalretailsdk.InvoiceAddress;

public class PPHMerchantUserInfo {

  private String name;
  private String givenName;
  private String familyName;
  private String email;
  private String businessSubCategory;
  private String businessCategory;
  private InvoiceAddress address;

  public PPHMerchantUserInfo(String name,
                             String givenName,
                             String familyName,
                             String email,
                             String businessCategory,
                             String businessSubCategory,
                             InvoiceAddress address) {
    this.name = name;
    this.givenName = givenName;
    this.familyName = familyName;
    this.email = email;
    this.businessCategory = businessCategory;
    this.businessSubCategory = businessSubCategory;
    this.address = address;
  }

  public String getName() {
    return name;
  }

  public String getGivenName() {
    return givenName;
  }

  public String getFamilyName() {
    return familyName;
  }

  public String getEmail() {
    return email;
  }

  public String getBusinessSubCategory() {
    return businessSubCategory;
  }

  public String getBusinessCategory() {
    return businessCategory;
  }

  public InvoiceAddress getAddress() {
    return address;
  }
}
