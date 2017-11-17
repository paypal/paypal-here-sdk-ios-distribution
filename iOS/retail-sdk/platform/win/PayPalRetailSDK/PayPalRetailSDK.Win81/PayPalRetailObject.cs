using Jint.Native;
using Jint.Native.Array;
using Jint.Native.Date;
using Jint.Native.Function;
using Jint.Native.Object;
using Manticore;
using PayPalRetailSDK.JsObjects;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Reflection;

namespace PayPalRetailSDK
{
    public class PayPalRetailObject
    {
        internal ObjectInstance impl;
        internal static NativeInterface Native;

        public PayPalRetailObject() { }

        public PayPalRetailObject(ObjectInstance value)
        {
            this.impl = value;
        }

        /// <summary>
        /// All the classes generated against a particular base class must share a single Manticore engine.
        /// This is because we expose raw constructors which need to instantiate Js objects without having
        /// to pass the engine around all over the place.
        /// </summary>
        public static ManticoreEngine Engine { get; private set; }

        internal static void CreateJsEngine(String script) {
            Engine = new ManticoreEngine();
            Engine.Converter = new DefaultConverter<PayPalRetailObject>(Engine,
                (native) => native.impl,
                (jsErr) => new RetailSDKException(jsErr));
            Native = new NativeInterface();
            Native.Register(Engine);
            Engine.LoadScript(script);
        }

        internal static ObjectInstance CreateJSObject(String name, JsValue[] args)
        {
            return Engine.JsWithReturn(() =>
            {
                return RetailSDK.Engine.CreateJsObject(name, args);
            });
        }

        internal static JsValue GetJsValue(Object value)
        {
            return ((PayPalRetailObject)value).impl;
        }

        internal static T AsNative<T>(JsValue value) where T : class
        {
            // TODO the performance of Activator.CreateInstance is crap. We should foist this onto the
            // codegen and get rid of this method.
#if WINDOWS_PHONE_APP || WINDOWS_APP
            if (typeof(T).GetTypeInfo().IsSubclassOf(typeof(PayPalRetailObject)))
#else
            if (typeof(T).GetType().IsSubclassOf(typeof(PayPalRetailObject)))
#endif
            {
                return (T) Activator.CreateInstance(typeof(T), value);
            }
            return null;
        }

        internal static JsValue AsJs<T>(T value) where T : class
        {
            if (value == null)
            {
                return JsValue.Null;
            }
            if (value is PayPalRetailObject)
            {
                return PayPalRetailObject.GetJsValue(value);
            }
            return JsValue.FromObject(Engine.jsEngine, value);
        }
    }
}
