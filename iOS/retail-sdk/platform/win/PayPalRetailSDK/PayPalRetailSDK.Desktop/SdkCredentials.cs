using System;

namespace PayPalRetailSDK
{
    public class SdkCredentials
    {
        internal string AccessToken;
        internal string Environment;
        internal string ClientId;
        internal string ClientSecret;
        internal string RefreshUrl;
        internal string RefreshToken;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="environment">Executing environment for the SDK e.g. live, sandbox, stage2d0065</param>
        /// <param name="accessToken">Access token for authentication></param>
        public SdkCredentials(string environment, string accessToken)
        {
            Environment = environment;
            AccessToken = accessToken;
        }

        /// <summary>
        /// URL to refresh an expired access token. The JSON response must contain the access token set to
        /// access_token property
        /// </summary>
        public SdkCredentials SetTokenRefreshCredentials(string refreshUrl)
        {
            RefreshUrl = refreshUrl;
            return this;
        }

        /// <summary>
        /// Provide credentials to refresh an expired access token using refresh token and client Id & secret
        /// </summary>
        public SdkCredentials SetTokenRefreshCredentials(string refreshToken, string clientId, string clientSecret)
        {
            RefreshToken = refreshToken;
            ClientId = clientId;
            ClientSecret = clientSecret;
            return this;
        }
    }
}
