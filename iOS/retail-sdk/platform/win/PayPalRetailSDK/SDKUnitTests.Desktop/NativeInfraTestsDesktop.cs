using System;
using PayPalRetailSDK;

#if NETFX_CORE
using Microsoft.VisualStudio.TestPlatform.UnitTestFramework;
#else
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Threading.Tasks;
using System.Reflection;
using System.IO;
using PayPalRetailSDK.JsObjects;
#endif

namespace SDKUnitTests.Desktop
{
    [TestClass]
    public class NativeInfraTestsDesktop
    {
        [TestMethod]
        public void DesktopInitializeSDKTest()
        {
            RetailSDK.Initialize(true);
        }

        [TestMethod]
        public void DesktopInstanceCreationTest()
        {
            RetailSDK.Initialize(true);
            Invoice i = new Invoice("USD");
            Assert.AreEqual("USD", i.Currency);
        }

        [TestMethod]
        public void DesktopMethodCallsTest()
        {
            RetailSDK.Initialize(true);
            var i = new Invoice("USD");
            Assert.AreEqual("USD", i.Currency);
            var item = i.AddItem("Item", 1m, 1.50m, "UID1", null);
            Assert.AreEqual(1, i.ItemCount);
            Assert.AreEqual(1.50m, i.Total);
            item = i.FindItem("UID1", null);
            Assert.IsNotNull(item);
        }

        [TestMethod]
        public void DesktopStaticMethodCallsTest()
        {
            //ToDo make Initialize work for tests
            RetailSDK.Initialize(true);
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
        public void DesktopCallbackTest()
        {
            RetailSDK.Initialize(true);
            var task = RetailSDK.InitializeMerchant(new StreamReader(Assembly.GetExecutingAssembly().GetManifestResourceStream("SDKUnitTests.Desktop.testToken.txt")).ReadToEnd());
            try
            {
                task.Wait(15000);
                Assert.IsTrue(task.IsCompleted);
                Assert.IsNotNull(task.Result, "Expected valid merchant");
            }
            catch (AggregateException)
            {
                Assert.Fail("Expected valid merchant.");
            }
        }

        [TestMethod]
        public async Task DesktopStringPreferenceTest()
        {
            await RawPrefTest("V");
        }

        [TestMethod]
        public async Task DesktopSecurePreferenceTest()
        {
            await RawPrefTest("S");
        }

        private async Task RawPrefTest(String storageType)
        {
            var ni = new NativeInterface();
            var tci = new TaskCompletionSource<bool>();
            var afterCb = new Action<dynamic,dynamic>((err, value) =>
            {
                Assert.IsNull((Object)err);
                Assert.IsNull((Object)value);
                tci.SetResult(true);
            });
            var delCb = new Action<dynamic>((err) =>
            {
                Assert.IsNull((Object)err);
                ni.getItem("Testing", storageType, afterCb);
            });
            var getCb = new Action<dynamic, String>((err, value) =>
            {
                Assert.IsNull((Object)err);
                Assert.AreEqual("This is a stored string", value);
                ni.setItem("Testing", storageType, null, delCb);
            });
            var cb = new Action<dynamic>((err) =>
            {
                Assert.IsNull((Object)err);
                ni.getItem("Testing", storageType, getCb);
            });
            ni.setItem("Testing", storageType, "This is a stored string", cb);
            await tci.Task;
        }

        [TestMethod]
        public async Task DesktopBlobPreferenceTest()
        {
            await FilePrefTest("B");
        }

        [TestMethod]
        public async Task DesktopSecureBlobPreferenceTest()
        {
            await FilePrefTest("E");
        }

        private async Task FilePrefTest(String storageType)
        {
            Random random = new Random();
            byte[] randomBytes = new byte[1024000];
            random.NextBytes(randomBytes);
            var base64 = Convert.ToBase64String(randomBytes);

            var ni = new NativeInterface();
            var tci = new TaskCompletionSource<bool>();
            var afterCb = new Action<dynamic, dynamic>((err, value) =>
            {
                Assert.IsNull((Object)err);
                Assert.IsNull((Object)value);
                tci.SetResult(true);
            });
            var delCb = new Action<dynamic>((err) =>
            {
                Assert.IsNull((Object)err);
                ni.getItem("FileTest", storageType, afterCb);
            });
            var getCb = new Action<dynamic, String>((err, value) =>
            {
                Assert.IsNull((Object)err);
                Assert.IsTrue(base64.Equals(value));
                ni.setItem("FileTest", storageType, null, delCb);
            });
            var cb = new Action<dynamic>((err) =>
            {
                Assert.IsNull((Object)err);
                ni.getItem("FileTest", storageType, getCb);
            });
            ni.setItem("FileTest", storageType, base64, cb);
            await tci.Task;
        }

        [TestMethod]
        public void DesktopNetworkDelegateTest()
        {
            RetailSDK.Shutdown();

            var handler = new ClearScriptTestNetworkHandler();
            RetailSDK.SetNetworkHandler(handler);
            handler.Expect("https://www.paypalobjects.com/webstatic/mobile/retail-sdk/feature-map.json");
            handler.Expect("https://www.stage2md030.stage.paypal.com/webapps/auth/protocol/openidconnect/v1/userinfo?schema=openid");
            handler.Expect("https://www.stage2md030.stage.paypal.com/webapps/hereapi/merchant/v1/status");

            RetailSDK.Initialize(true);
            var task = RetailSDK.InitializeMerchant(new StreamReader(Assembly.GetExecutingAssembly().GetManifestResourceStream("SDKUnitTests.Desktop.testToken.txt")).ReadToEnd());
            try
            {
                task.Wait(15000);
                Assert.IsTrue(task.IsCompleted);
                Assert.IsNotNull(task.Result, "Expected valid merchant");
                Assert.AreEqual(0, handler.Expectations.Count);
            }
            catch (AggregateException)
            {
                Assert.Fail("Expected valid merchant.");
            }
        }


        [ClassCleanup]
        public static void ShutdownSDK()
        {
            RetailSDK.Shutdown();
        }

    }
}
