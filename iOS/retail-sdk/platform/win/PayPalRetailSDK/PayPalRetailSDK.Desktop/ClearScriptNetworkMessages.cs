using Microsoft.ClearScript;
using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PayPalRetailSDK
{
    class LazyHttpRequest : RetailHttpRequest
    {
        public dynamic Options;

        public override Uri Url
        {
            get
            {
                if (base.Url == null)
                {
                    base.Url = new Uri(Options.url);
                }
                return base.Url;
            }
        }

        public override string Method
        {
            get
            {
                if (base.Method == null && !(Options.method is Undefined))
                {
                    base.Method = ((object)Options.method).ToString();
                }
                return base.Method ?? "GET";
            }
        }

        public override Dictionary<string, string> Headers
        {
            get
            {
                if (base.Headers == null && !(Options.headers is Undefined))
                {
                    Dictionary<String, String> requestHeaders = new Dictionary<string, string>();
                    DynamicObject dopts = (DynamicObject)Options.headers;
                    foreach (var p in dopts.GetDynamicMemberNames())
                    {
                        requestHeaders.Add(p, Options.headers[p]);
                    }
                    base.Headers = requestHeaders;
                }
                return base.Headers;
            }
        }

        public override byte[] Body
        {
            get
            {
                if (base.Body == null && !(Options.body is Undefined))
                {
                    var body = ((object)Options.body).ToString();
                    if ((!(Options.base64Body is Undefined)) && Options.base64Body == true)
                    {
                        base.Body = Convert.FromBase64String(body);
                    }
                    else
                    {
                        base.Body = Encoding.UTF8.GetBytes(body);
                    }
                }
                return base.Body;
            }
        }
    }
}
