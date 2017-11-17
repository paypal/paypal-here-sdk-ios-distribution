
using System;
using NUnit.Framework;
using PayPal.Retail;
using Foundation;

namespace RetailSDKiOSDebugTests
{
	[TestFixture]
	public class InvoiceTests
	{
		[SetUp]
		public void InitSDK() {
			RetailSDK.InitializeSDK ();
		}

		[Test]
		public void MakeInvoice ()
		{
			var invoice = new Invoice ("USD");
			Assert.AreEqual ("USD", invoice.Currency);
			var item = new InvoiceItem ("Test Item", Retail.Number ("1"), Retail.Number ("1.50"), "ID1", String.Empty);
			invoice.AddItem (item);
			Assert.AreEqual (1, invoice.ItemCount);
			Assert.AreEqual (Retail.Number ("1.50"), invoice.Total);
		}
	}
}
