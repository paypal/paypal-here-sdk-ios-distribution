using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using PayPalRetailSDK;

#if NETFX_CORE
using Microsoft.VisualStudio.TestPlatform.UnitTestFramework;
#else
using Microsoft.VisualStudio.TestTools.UnitTesting;
#endif

namespace SDKUnitTests.WinRT
{
    class JintTestNetworkHandler : IRetailNetworkRequestHandler
    {
        public List<Func<RetailHttpRequest, Action<RetailHttpResponse>, bool>> Expectations = new List<Func<RetailHttpRequest, Action<RetailHttpResponse>, bool>>();

        public int RequestCount { get; private set; }
        
        public bool DidHandleHttpRequest(RetailHttpRequest request, Action<RetailHttpResponse> callback)
        {
            RequestCount++;
            if (Expectations.Count > 0)
            {
                var returnValue = Expectations[0](request, callback);
                Expectations.RemoveAt(0);
                return returnValue;
            }
            return false;
        }

        public void Expect(String url)
        {
            Expectations.Add(new Func<RetailHttpRequest, Action<RetailHttpResponse>, bool>((rq, cb) =>
            {
                Assert.AreEqual(url, rq.Url.AbsoluteUri);
                return false;
            }));
        }
    }
}
