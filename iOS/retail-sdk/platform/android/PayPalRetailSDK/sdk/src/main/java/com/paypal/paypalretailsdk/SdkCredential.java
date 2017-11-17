package com.paypal.paypalretailsdk;

public class SdkCredential {
  String accessToken;
  String refreshUrl;
  String refreshToken;
  String clientId;
  String clientSecret;
  String environment;
  String repository;

  /**
   * Build SDK Credentials
   * @param environment Executing environment for the SDK e.g. live, sandbox, stage2d0065, etc.
   * @param accessToken Access token for authentication
   */
  public SdkCredential(String environment, String accessToken, String softwareRepository) {
    this.environment = environment;
    this.accessToken = accessToken;
    this.repository = softwareRepository;
  }

  /**
   * URL to refresh an expired access token. The JSON response must contain the access token set to
   * access_token property
   */
  public SdkCredential setTokenRefreshCredentials(String refreshUrl) {
    this.refreshUrl = refreshUrl;
    return this;
  }

  /**
   * Provide credentials to refresh an expired access token using refresh token and client Id & secret
   */
  public SdkCredential setTokenRefreshCredentials(String refreshToken, String clientId, String clientSecret) {
    this.refreshToken = refreshToken;
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    return this;
  }
}
