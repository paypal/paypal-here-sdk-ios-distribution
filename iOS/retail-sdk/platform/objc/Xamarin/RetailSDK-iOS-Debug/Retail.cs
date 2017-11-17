using System;
using Foundation;

namespace PayPal.Retail
{
	/**
	 * General helper functions for the Xamarin port of the Retail SDK
	 */
	public class Retail
	{
		public static NSDecimalNumber Number(String number) {
			return new NSDecimalNumber (number);
		}
	}
}

