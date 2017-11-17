package com.paypal.paypalretailsdk.pph;

import com.paypal.paypalretailsdk.SdkCredential;

public class PPHMerchant {

  private SdkCredential credential;
  private PPHMerchantStatus status;
  private PPHMerchantUserInfo userInfo;
  public PPHMerchant(SdkCredential credential, PPHMerchantUserInfo userInfo, PPHMerchantStatus status) {
    this.credential = credential;
    this.status = status;
    this.userInfo = userInfo;
  }

  public SdkCredential getCredential() {
    return credential;
  }

  public PPHMerchantStatus getStatus() {
    return status;
  }

  public PPHMerchantUserInfo getUserInfo() {
    return userInfo;
  }
}
