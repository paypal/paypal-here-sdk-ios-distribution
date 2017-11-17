using Manticore;
using Microsoft.CSharp.RuntimeBinder;
using PayPalRetailSDK.JsObjects;
using System;
using System.Collections.Generic;
using System.Reflection;

namespace PayPalRetailSDK
{
    public class PayPalRetailObject
    {
        private static DateTime Epoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        internal dynamic impl;

        public PayPalRetailObject()
        {

        }

        internal PayPalRetailObject(object value)
        {
            this.impl = value is JsValueHolder ? ((JsValueHolder)value).jsValue : value;
        }

        /// <summary>
        /// All the classes generated against a particular base class must share a single Manticore engine.
        /// This is because we expose raw constructors which need to instantiate Js objects without having
        /// to pass the engine around all over the place.
        /// </summary>
        internal static ManticoreEngine Engine { get; private set; }
        internal static NativeInterface Native;
        internal static InternalNetworkManager NetworkManager;

        internal static void CreateJsEngine(String script)
        {
            if (Engine != null && Engine.IsStarted)
            {
                throw new InvalidOperationException("You must shut down the existing engine before creating a new one.");
            }
            var e = new ManticoreEngine();
            e.Converter = new DefaultConverter<PayPalRetailObject>(e,
                (native) => native.impl,
                (jsErr) => new RetailSDKException(jsErr));
            Native = new NativeInterface();
            Native.Register(e);
            NetworkManager = new InternalNetworkManager(e);
            e.LoadScript(script);
            Engine = e;
        }

        internal static dynamic CreateJsObject(String name, dynamic args)
        {
            return RetailSDK.jsSdk.impl.make(name, args);
        }

    }
}
