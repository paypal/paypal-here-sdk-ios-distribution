using Jint.Native.Object;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PayPalRetailSDK
{
    class LazyHttpRequest : RetailHttpRequest
    {
        public ObjectInstance Options;

        public override Uri Url
        {
            get
            {
                if (base.Url == null)
                {
                    base.Url = new Uri(Options.Get("url").AsString());
                }
                return base.Url;
            }
        }

        public override string Method
        {
            get
            {
                if (base.Method == null && Options.HasProperty("method"))
                {
                    base.Method = Options.Get("method").AsString();
                }
                return base.Method ?? "GET";
            }
        }

        public override Dictionary<string, string> Headers
        {
            get
            {
                if (base.Headers == null && Options.HasProperty("headers"))
                {
                    var headers = Options.Get("headers").AsObject();
                    Dictionary<String, String> requestHeaders = new Dictionary<string, string>();
                    foreach (var p in headers.GetOwnProperties())
                    {
                            requestHeaders.Add(p.Key, p.Value.Value.Value.AsString());
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
                if (base.Body == null && Options.HasProperty("body"))
                {
                    var body = Options.Get("body").AsString();
                    if (Options.HasProperty("base64Body") && Options.Get("base64Body").AsBoolean())
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
