
using System;
using System.IO;
using NUnit.Framework;

using PayPal.Retail;

namespace RetailSDKiOSDebugTests
{
	[TestFixture]
	public class InitializeTests
	{
		String token;

		[SetUp]
		public void ReadToken() {
			using (var tokenStream = System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream ("RetailSDKiOSDebugTests.Resources.testToken.txt")) {
				using (var streamReader = new StreamReader(tokenStream))
				{
					token = streamReader.ReadToEnd();
				}
			}
		}

		[Test]
		public void Init ()
		{
			var waitForMe = new System.Threading.ManualResetEvent (false);

			RetailSDK.InitializeSDK ();
			RetailSDK.InitializeMerchant (token, (error, merchant) => {
				Assert.IsNull(error);
				waitForMe.Set();
			});
			if (waitForMe.WaitOne (30000)) {
				Assert.Fail ("Expected completion of initialization");
			}
		}

	}
}
