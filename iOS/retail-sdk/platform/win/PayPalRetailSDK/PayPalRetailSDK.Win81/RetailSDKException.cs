#if WINDOWS_PHONE_APP || WINDOWS_APP || DOTNET4
using Jint.Native;
using Jint.Native.Object;
using Jint.Native.Error;
#endif
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PayPalRetailSDK
{
    public class RetailSDKException : Exception
    {
        public string JavascriptStack { get; private set; }

        public PayPalError PayPalError { get; private set; }

        public RetailSDKException(String errorMessage) : base(errorMessage)
        {

        }

#if WINDOWS_PHONE_APP || WINDOWS_APP || DOTNET4
        public static RetailSDKException NativeInstanceForObject(JsValue jsError)
        {
            return new RetailSDKException(jsError);
        }

        public RetailSDKException(JsValue jsError) : base(jsError.AsObject().Get("message").AsString())
        {
            var error = jsError.AsObject();
            var stack = error.Get("stack");
            if (stack.IsString()) {
                JavascriptStack = stack.AsString();
            } else if (jsError.Is<ErrorInstance>())
            {
                jsError.As<ErrorInstance>().HasOwnProperty("stack");
            }
            PayPalError = new PayPalError(error);
        }
#else
        public static RetailSDKException NativeInstanceForObject(dynamic jsError)
        {
            return new RetailSDKException(jsError);
        }

        public RetailSDKException(dynamic jsError) : base(((object)jsError.message).ToString())
        {
            JavascriptStack = jsError.stack as string;
            PayPalError = new PayPalError(jsError);
        }
#endif
    }
}
