using Manticore;
using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

#if WINDESKTOP
using Microsoft.ClearScript;
#else
using Jint.Native;
using Jint.Native.Object;
using Jint.Native.Function;
using System.IO;
using Jint.Parser;
using Jint.Native.Error;
#endif

namespace PayPalRetailSDK
{
    /// <summary>
    /// This class manages the SDK partner setting their own network delegate.
    /// </summary>
    class InternalNetworkManager
    {
        Manticore.ManticoreEngine Engine;

#if WINDESKTOP
        Action<dynamic, dynamic> baseHttpFunction;

        public InternalNetworkManager(Manticore.ManticoreEngine engine)
        {
            this.Engine = engine;
            baseHttpFunction = (Action<dynamic, dynamic>) engine.ManticoreJsObject.http;
            engine.ManticoreJsObject.http = new Action<dynamic, dynamic>((opts, cb) => this.DoRequest(opts, cb));
        }

        public void DoRequest(dynamic optionsValue, dynamic callback) {
            if (RetailSDK.NetworkHandler == null)
            {
                baseHttpFunction(optionsValue, callback);
                return;
            }
            var request = new LazyHttpRequest();
            request.Options = optionsValue;

            dynamic responseInfo = new ExpandoObject();
            String format = null;
            if (!(optionsValue.format is Undefined))
            {
                format = ((object)optionsValue.format).ToString();
            }

            var mitmCallback = new Action<RetailHttpResponse>((response) =>
            {
                try
                {
                    DefaultConverter<PayPalRetailObject>.ParseResponseBody(Engine, responseInfo, format, response.Body);
                    callback(null, responseInfo);
                }
                catch (ScriptEngineException se)
                {
                    dynamic exp = new JsErrorBuilder(se).Build();
                    callback(exp, responseInfo);
                }
            });
            if (!RetailSDK.NetworkHandler.DidHandleHttpRequest(request, mitmCallback))
            {
                baseHttpFunction(optionsValue, callback);
            }

        }
#else
        FunctionInstance baseHttpFunction;

        public InternalNetworkManager(Manticore.ManticoreEngine engine)
        {
            this.Engine = engine;
            baseHttpFunction = engine.ManticoreJsObject.Get("http").As<FunctionInstance>();
            engine.ManticoreJsObject.Put("http", Engine.AsJsFunction(new Func<JsValue, JsValue[], JsValue>((thisObject, args) => {
                DoRequest(args[0], args[1]);
                return JsValue.Undefined;
            })), true);
        }

        public void DoRequest(JsValue optionsValue, JsValue callback)
        {
            if (RetailSDK.NetworkHandler == null)
            {
                baseHttpFunction.Call(Engine.ManticoreJsObject, new JsValue[] { optionsValue, callback });
                return;
            }
            var request = new LazyHttpRequest();
            request.Options = optionsValue.AsObject();

            var mitmCallback = new Action<RetailHttpResponse>((response) =>
            {
                var responseInfo = new ObjectInstance(Engine.jsEngine);
                responseInfo.FastAddProperty("statusCode", new JsValue((int)response.StatusCode), false, true, false);
                if (response.Headers.Count > 0)
                {
                    var headerCollection = new ObjectInstance(Engine.jsEngine);
                    foreach (var kv in response.Headers)
                    {
                        headerCollection.FastAddProperty(kv.Key, new JsValue(kv.Value), false, true, false);
                    }
                    responseInfo.FastAddProperty("headers", headerCollection, false, true, false);
                }
                String format = null;
                if (request.Options.HasProperty("format"))
                {
                    format = request.Options.Get("format").AsString();
                }

                var errorInstance = JsValue.Null;
                try
                {
                    DefaultConverter<PayPalRetailObject>.ParseResponseBody(Engine, responseInfo, format, new MemoryStream(response.Body));
                }
                catch (ParserException p)
                {
                    errorInstance = new ErrorInstance(Engine.jsEngine, p.Message);
                }

                callback.Invoke(errorInstance, responseInfo);

            });
            if (!RetailSDK.NetworkHandler.DidHandleHttpRequest(request, mitmCallback))
            {
                baseHttpFunction.Call(Engine.ManticoreJsObject, new JsValue[] { optionsValue, callback });
            }
        }
#endif

    }
}
