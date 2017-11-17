using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PayPalRetailSDK
{
    public class RetailHttpRequest
    {
        /// <summary>
        /// The URL you should access
        /// </summary>
        public virtual Uri Url { get; protected set; }
        /// <summary>
        /// The HTTP method to use
        /// </summary>
        public virtual String Method { get; protected set; }
        /// <summary>
        /// The request headers that should be sent - read only but defined this way for .Net 4.0 compatibility
        /// </summary>
        public virtual Dictionary<String, String> Headers { get; protected set; }
        /// <summary>
        /// The HTTP body of the request, if any
        /// </summary>
        public virtual byte[] Body { get; protected set; }

        protected RetailHttpRequest()
        {

        }

        internal RetailHttpRequest(Uri url, String method, Dictionary<String, String> headers, byte[] body)
        {
            this.Url = url;
            this.Method = method;
            this.Headers = headers;
            this.Body = body;
        }
    }

    public class RetailHttpResponse
    {
        /// <summary>
        /// The response body
        /// </summary>
        public byte[] Body { get; set; }
        /// <summary>
        /// The response headers - read only but defined this way for .Net 4.0 compatibility
        /// </summary>
        public Dictionary<String, String> Headers { get; set; }
        /// <summary>
        /// The HTTP status code of the response
        /// </summary>
        public short StatusCode { get; set; }
    }
    
    /// <summary>
    /// If you have a need to route our HTTP traffic through your own proxies or network layers, implement
    /// this interface and set it as the delegate on the RetailSDK object.
    /// </summary>
    public interface IRetailNetworkRequestHandler
    {
        /// <summary>
        /// If your delegate will handle the request, return true, otherwise return false and the SDK
        /// will process the request. When the request completes, you MUST call the callback function.
        /// You MUST call the callback exactly once.
        /// </summary>
        /// <param name="request">The request to perform</param>
        /// <param name="callback">The action to be invoked exactly once after the request is complete</param>
        /// <returns></returns>
        bool DidHandleHttpRequest(RetailHttpRequest request, Action<RetailHttpResponse> callback);
    }
}
