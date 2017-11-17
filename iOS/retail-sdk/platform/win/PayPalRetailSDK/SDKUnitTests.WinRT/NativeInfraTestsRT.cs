using System;
using System.IO;
using System.Reflection;
using PayPalRetailSDK;

#if NETFX_CORE
using Microsoft.VisualStudio.TestPlatform.UnitTestFramework;
using System.Threading.Tasks;
using PayPalRetailSDK.JsObjects;
using Jint.Native;
using Jint.Native.Function;
using Jint.Runtime.Interop;
#else
using Microsoft.VisualStudio.TestTools.UnitTesting;
#endif

namespace SDKUnitTests.WinRT
{
    [TestClass]
    public class NativeInfraTestsRT
    {
        [TestMethod]
        public void WinRTInitializeSDKTest()
        {
            RetailSDK.Initialize();
        }

        [TestMethod]
        public void WinRTInstanceCreationTest()
        {
            RetailSDK.Initialize();
            Invoice i = new Invoice("USD");
            Assert.AreEqual("USD", i.Currency);
        }

        [TestMethod]
        public void WinRTMethodCallsTest()
        {
            RetailSDK.Initialize();
            var i = new Invoice("USD");
            Assert.AreEqual("USD", i.Currency);
            var item = i.AddItem("Item", 1m, 1.50m, "UID1", null);
            Assert.AreEqual(1, i.ItemCount);
            Assert.AreEqual(1.50m, i.Total);
        }

        [TestMethod]
        public void WinRTStaticMethodCallsTest()
        {
            //ToDo make Initialize work for tests
            RetailSDK.Initialize();
            var ppe = PayPalError.MakeError(null, new PayPalErrorInfo
            {
                Code = "code",
                Domain = "domain",
                DebugId = "debugId",
                DeveloperMessage = "devMessage"
            });

            Assert.IsNotNull(ppe);
            Assert.AreEqual("code", ppe.Code);
            Assert.AreEqual("domain", ppe.Domain);
            Assert.AreEqual("debugId", ppe.DebugId);
            Assert.AreEqual("devMessage", ppe.Message);
        }

        [TestMethod]
        public async Task WinRTStringPreferenceTest()
        {
            await ValueTest("V");
        }

        [TestMethod]
        public async Task WinRTSecurePreferenceTest()
        {
            await ValueTest("S");
        }

        private async Task ValueTest(String storageType)
        {
            var engine = new Jint.Engine();
            var ni = new NativeInterface();
            var tci = new TaskCompletionSource<bool>();
            var afterCb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                Assert.IsTrue(args[1].IsNull());
                tci.SetResult(true);
                return JsValue.Undefined;
            });
            var delCb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                ni.getItem(engine, "Testing", storageType, afterCb);
                return JsValue.Undefined;
            });
            var getCb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                Assert.AreEqual("This is a stored string", args[1].AsString());
                ni.setItem(engine, "Testing", storageType, null, delCb);
                return JsValue.Undefined;
            });
            var cb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                ni.getItem(engine, "Testing", storageType, getCb);
                return JsValue.Undefined;
            });
            ni.setItem(engine, "Testing", storageType, "This is a stored string", cb);
            await tci.Task;
        }

        [TestMethod]
        public async Task WinRTBlobPreferenceTest()
        {
            await FilePrefTest("B");
        }

        [TestMethod]
        public async Task WinRTSecureBlobPreferenceTest()
        {
            await FilePrefTest("E");
        }

        private async Task FilePrefTest(String storageType)
        {
            Random random = new Random();
            byte[] randomBytes = new byte[1024000];
            random.NextBytes(randomBytes);
            var base64 = Convert.ToBase64String(randomBytes);
            
            var engine = new Jint.Engine();
            var ni = new NativeInterface();
            var tci = new TaskCompletionSource<bool>();
            var afterCb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                Assert.IsTrue(args[1].IsNull());
                tci.SetResult(true);
                return JsValue.Undefined;
            });
            var delCb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                ni.getItem(engine, "FileTest", storageType, afterCb);
                return JsValue.Undefined;
            });
            var getCb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                var actual = args[1].AsString();
                Assert.IsTrue(base64.Equals(actual));
                ni.setItem(engine, "FileTest", storageType, null, delCb);
                return JsValue.Undefined;
            });
            var cb = new ClrFunctionInstance(engine, (thisValue, args) =>
            {
                Assert.IsTrue(args[0].IsUndefined() || args[0].IsNull());
                ni.getItem(engine, "FileTest", storageType, getCb);
                return JsValue.Undefined;
            });
            ni.setItem(engine, "FileTest", storageType, base64, cb);
            await tci.Task;
        }
        
        [TestMethod]
        public async Task WinRTCallbackTest()
        {
            RetailSDK.Initialize();
            var merchant = await RetailSDK.InitializeMerchant(new StreamReader(typeof(NativeInfraTestsRT).GetTypeInfo().Assembly.GetManifestResourceStream("SDKUnitTests.WinRT.testToken.txt")).ReadToEnd());
            Assert.IsNotNull(merchant);
        }

        [TestMethod]
        public async Task WinRTNetworkDelegateTest()
        {
            RetailSDK.Shutdown();
            RetailSDK.Initialize();

            var handler = new JintTestNetworkHandler();            
            RetailSDK.SetNetworkHandler(handler);
            handler.Expect("https://www.stage2md030.stage.paypal.com/webapps/auth/protocol/openidconnect/v1/userinfo?schema=openid");
            handler.Expect("https://www.stage2md030.stage.paypal.com/webapps/hereapi/merchant/v1/status");

            var merchant = await RetailSDK.InitializeMerchant(new StreamReader(typeof(NativeInfraTestsRT).GetTypeInfo().Assembly.GetManifestResourceStream("SDKUnitTests.WinRT.testToken.txt")).ReadToEnd());
            Assert.IsNotNull(merchant);
            Assert.AreEqual(0, handler.Expectations.Count);
        }

        [ClassCleanup]
        public static void ShutdownSDK()
        {
            RetailSDK.Shutdown();
        }
    }
}
