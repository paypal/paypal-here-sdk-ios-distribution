using Jint.Native;
using Jint.Native.Error;
using Jint.Native.Object;
using Manticore;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.IsolatedStorage;
using System.Media;
using System.Runtime.Serialization.Formatters.Binary;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using Jint.Runtime.Descriptors;
using PayPalRetailSDK.Desktop.UI;
using PayPalRetailSDK.UI;

namespace PayPalRetailSDK.JsObjects
{
    public class NativeInterface
    {
        // For getItem/setItem
        private static readonly byte[] s_aditionalEntropy = { 61, 40, 109, 120, 5 };
        static String settingsFilename = "settings.cfg";
        private const string LogComponentName = "native.interface";

        private static String SecureType = "S";
        private static String BlobType = "B";
        private static String StringType = "V";
        private static String SecureBlobType = "E";
        private InternalNetworkManager NetworkManager;

        public void Register(ManticoreEngine engine)
        {            
            var mo = engine.ManticoreJsObject;
            mo.FastSetProperty("log", new PropertyDescriptor(engine.Wrap(new Action<String, String, String>((l, c, m) => this.log(l, c, m))), false, true, false));
            mo.FastAddProperty("ready", engine.Wrap(new Action<JsValue>((sdk) => this.ready(sdk))), false, true, false);
            mo.FastAddProperty("setItem", engine.Wrap(new Action<String, String, String, JsValue>((name, storage, value, callback) => this.setItem(engine.jsEngine, name, storage, value, callback))), false, true, false);
            mo.FastAddProperty("getItem", engine.Wrap(new Action<String, String, JsValue>((name, storage, callback) => this.getItem(engine.jsEngine, name, storage, callback))), false, true, false);
            mo.FastAddProperty("offerReceipt", engine.Wrap(new Action<JsValue, JsValue>(OfferReceipt)), false, true, false);
            mo.FastAddProperty("collectSignature", engine.Wrap(new Func<JsValue, JsValue, JsValue>((opts, cb) => this.collectSignature(opts, cb))), false, true, false);
            mo.FastAddProperty("alert", engine.Wrap(new Func<JsValue, JsValue, JsValue>(Alert)), false, true, false);
            NetworkManager = new InternalNetworkManager(engine);
        }

        public void debugger()
        {
            Debugger.Break();
        }

        public void log(String level, String component, String message)
        {
            Console.Out.WriteLine("{0} ({1}): {2} {3}", level, Thread.CurrentThread.ManagedThreadId, component, message);
            
#if DEBUG
            NLogManager.LogToFile(level, component, message);
#endif
        }

        public void ready(JsValue sdk)
        {
            RetailSDK.ready(sdk.As<ObjectInstance>());
        }

        public void OfferReceipt(JsValue options, JsValue callback)
        {
            var viewContent = new ReceiptViewContent(options.AsObject().Get("viewContent").AsObject());
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                ReceiptControl.Show(viewContent, emailOrSms =>
                {
                    var jsErr = JsValue.Null;
                    if (string.IsNullOrWhiteSpace(emailOrSms))
                    {
                        PayPalRetailObject.Engine.Js(() =>
                        {
                            callback.Invoke(jsErr, JsValue.Null);
                        });
                        return;
                    }

                    var jsv = new ObjectInstance(PayPalRetailObject.Engine.jsEngine);
                    jsv.FastAddProperty("name", new JsValue("emailOrSms"), false, true, false);
                    jsv.FastAddProperty("value", new JsValue(emailOrSms), false, true, false);
                    PayPalRetailObject.Engine.Js(() =>
                    {
                        callback.Invoke(jsErr, jsv);
                    });
                });
            });
        }

        public JsValue collectSignature(JsValue options, JsValue callback)
        {
            SignatureControl.SignatureViewHandle sigHandle = null;
            var handle = PayPalRetailObject.Engine.CreateJsObject();
            string title = string.Empty, signHere = string.Empty, footer = string.Empty, cancel = string.Empty;
            if (options.IsObject())
            {
                var opt = options.AsObject();
                if (opt.HasProperty("title"))
                {
                    title = RetailSDK.Engine.Converter.AsNativeString(opt.Get("title"));
                }
                if (opt.HasProperty("signHere"))
                {
                    signHere = RetailSDK.Engine.Converter.AsNativeString(opt.Get("signHere"));
                }
                if (opt.HasProperty("footer"))
                {
                    footer = RetailSDK.Engine.Converter.AsNativeString(opt.Get("footer"));
                }
                if (opt.HasProperty("cancel"))
                {
                    cancel = RetailSDK.Engine.Converter.AsNativeString(opt.Get("cancel"));
                }
            }

            RetailSDK.RunOnUIThreadAsync(() =>
            {
                sigHandle = SignatureControl.Show(title, signHere, footer, cancel, (signature, cancelTx) =>
                {
                    var jsErr = JsValue.Null;
                    var jsSignature = JsValue.FromObject(PayPalRetailObject.Engine.jsEngine, signature);
                    PayPalRetailObject.Engine.Js(() =>
                    {
                        callback.Invoke(jsErr, jsSignature, cancelTx ? JsValue.True : JsValue.False);
                    });
                });
            });

            var dismiss = PayPalRetailObject.Engine.Wrap(new Action(() =>
            {
                if (sigHandle != null)
                {
                    RetailSDK.RunOnUiThread(() => sigHandle.Dismiss());
                }
            }));

            handle.FastAddProperty("dismiss", dismiss, false, true, true);
            return handle;
        }

        public JsValue Alert(JsValue options, JsValue callback)
        {
            string title = null, message = null, cancel = null, imageIcon = null, audioFile = null;
            var showActivity = false;
            var playCount = 1;
            List<string> buttons = null;
            AlertView.AlertViewHandle avHandle = null;

            if (options.IsObject())
            {
                ObjectInstance opt = options.AsObject();
                if (opt.HasProperty("title"))
                {
                    title = RetailSDK.Engine.Converter.AsNativeString(opt.Get("title"));
                }
                if (opt.HasProperty("message"))
                {
                    message = RetailSDK.Engine.Converter.AsNativeString(opt.Get("message"));
                }
                if (opt.HasProperty("cancel"))
                {
                    cancel = RetailSDK.Engine.Converter.AsNativeString(opt.Get("cancel"));
                }
                if (opt.HasProperty("imageIcon"))
                {
                    imageIcon = RetailSDK.Engine.Converter.AsNativeString(opt.Get("imageIcon"));
                }
                if (opt.HasProperty("showActivity"))
                {
                    showActivity = RetailSDK.Engine.Converter.AsNativeBool(opt.Get("showActivity"));
                }
                if (opt.HasProperty("audio"))
                {
                    var audioObj = opt.Get("audio").AsObject();
                    if (audioObj.HasProperty("file"))
                    {
                        audioFile = RetailSDK.Engine.Converter.AsNativeString(audioObj.Get("file"));
                    }
                    if (audioObj.HasProperty("playCount"))
                    {
                        playCount = RetailSDK.Engine.Converter.AsNativeInt(audioObj.Get("playCount"));
                    }
                }
                if (opt.HasProperty("buttons"))
                {
                    buttons = PayPalRetailObject.Engine.Converter.ToNativeArray(opt.Get("buttons"),
                        element => ((element.IsNull() || element.IsUndefined()) ? string.Empty : element.AsString()));
                }
            }

            var handle = PayPalRetailObject.Engine.CreateJsObject();
            var dismiss = PayPalRetailObject.Engine.Wrap(new Action(() =>
            {
                if (avHandle != null)
                {
                    RetailSDK.RunOnUiThread(() => avHandle.Dismiss());
                }
            }));
            var setTitle = PayPalRetailObject.Engine.Wrap(new Action<JsValue>((newTitle) =>
            {
                if (avHandle != null && !RetailSDK.Engine.IsNullOrUndefined(newTitle))
                {
                    RetailSDK.RunOnUiThread(() => avHandle.SetTitle(newTitle.AsString()));
                }
            }));
            var setMessage = PayPalRetailObject.Engine.Wrap(new Action<JsValue>((newMessage) =>
            {
                if (avHandle != null && !RetailSDK.Engine.IsNullOrUndefined(newMessage))
                {
                    RetailSDK.RunOnUiThread(() => avHandle.SetMessage(newMessage.AsString()));
                }
            }));
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                avHandle = AlertView.Show(title, message, showActivity, cancel, buttons, imageIcon, audioFile, playCount, (sender, index) =>
                {
                    var jshndl = JsValue.FromObject(PayPalRetailObject.Engine.jsEngine, handle);
                    var jsindx = JsValue.FromObject(PayPalRetailObject.Engine.jsEngine, index);
                    PayPalRetailObject.Engine.Js(() => { callback.Invoke(jshndl, jsindx); });
                });
            });

            handle.FastAddProperty("dismiss", dismiss, false, true, true);
            handle.FastAddProperty("setTitle", setTitle, false, true, true);
            handle.FastAddProperty("setMessage", setMessage, false, true, true);
            return handle;
        }


        public void getItem(Jint.Engine engine, String name, String storage, JsValue callback)
        {
            if (callback.IsNull() || callback.IsUndefined())
            {
                return;
            }

            byte[] storedValue = null;
            var key = storage + name;
            var store = IsolatedStorageFile.GetUserStoreForAssembly();

            try
            {
                if (StringType.Equals(storage) || SecureType.Equals(storage))
                {
                    lock (this)
                    {
                        if (store.FileExists(settingsFilename))
                        {
                            Dictionary<string, byte[]> settings;
                            var formatter = new BinaryFormatter();
                            using (var stream = store.OpenFile(settingsFilename, FileMode.Open, FileAccess.Read))
                            {
                                settings = (Dictionary<string, byte[]>)formatter.Deserialize(stream);
                            }
                            if (settings.ContainsKey(key))
                            {
                                storedValue = settings[key];
                            }
                        }
                    }
                }
                else
                {
                    var fileKey = Convert.ToBase64String(Encoding.UTF8.GetBytes(key));
                    lock (this)
                    {
                        if (store.FileExists(fileKey))
                        {
                            using (var stream = store.OpenFile(fileKey, FileMode.Open, FileAccess.Read))
                            {
                                storedValue = new byte[stream.Length];
                                stream.Read(storedValue, 0, storedValue.Length);
                            }
                        }
                    }
                }
                if (storedValue == null)
                {
                    PayPalRetailObject.Engine.Js(() =>
                    {
                        callback.Invoke(JsValue.Null, JsValue.Null);
                    });
                    return;
                }
                if (SecureType.Equals(storage) || SecureBlobType.Equals(storage))
                {
                    storedValue = ProtectedData.Unprotect(storedValue, s_aditionalEntropy, DataProtectionScope.CurrentUser);
                }
                var retVal = Encoding.UTF8.GetString(storedValue, 0, storedValue.Length);

                PayPalRetailObject.Engine.Js(() =>
                {
                    callback.Invoke(JsValue.Null, new JsValue(retVal));
                });
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Failed to get Item with key {key}: {ex}");
                var error = new JsErrorBuilder(PayPalRetailObject.Engine, ex).Build();
                PayPalRetailObject.Engine.Js(() =>
                {
                    callback.Invoke(error, JsValue.Null);
                });
            }
        }

        public void setItem(Jint.Engine engine, String name, String storage, String value, JsValue callback)
        {
            var callingCallback = false;
            var isoStore = IsolatedStorageFile.GetUserStoreForAssembly();
            var key = storage + name;

            try
            {
                byte[] valueToStore = null;

                if (value != null)
                {
                    if (SecureBlobType.Equals(storage) || SecureType.Equals(storage))
                    {
                        valueToStore = ProtectedData.Protect(Encoding.UTF8.GetBytes((String)value), s_aditionalEntropy, DataProtectionScope.CurrentUser);
                    }
                    else
                    {
                        valueToStore = Encoding.UTF8.GetBytes((String)value);
                    }
                }

                if (SecureBlobType.Equals(storage) || BlobType.Equals(storage))
                {
                    var fileKey = Convert.ToBase64String(Encoding.UTF8.GetBytes(key));
                    // Deleting a value?
                    if (value == null)
                    {
                        isoStore.DeleteFile(fileKey);
                        if (!(callback.IsNull() || callback.IsUndefined()))
                        {
                            callingCallback = true;
                            PayPalRetailObject.Engine.Js(() =>
                            {
                                callback.Invoke(JsValue.Null);
                            });
                        }
                        return;
                    }
                    // Setting a value
                    lock (this)
                    {
                        using (var stream = isoStore.OpenFile(fileKey, FileMode.Create, FileAccess.Write))
                        {
                            stream.Write(valueToStore, 0, valueToStore.Length);
                        }
                    }
                    if (!(callback.IsNull() || callback.IsUndefined()))
                    {
                        callingCallback = true;
                        PayPalRetailObject.Engine.Js(() =>
                        {
                            callback.Invoke(JsValue.Null);
                        });
                    }
                }
                else
                {
                    lock (this)
                    {
                        BinaryFormatter formatter = new BinaryFormatter();
                        Dictionary<string, byte[]> settings = null;
                        using (var stream = isoStore.OpenFile(settingsFilename, FileMode.OpenOrCreate, FileAccess.Read))
                        {
                            if (stream.Length > 0)
                            {
                                settings = (Dictionary<string, byte[]>)formatter.Deserialize(stream);
                            }
                        }
                        if (settings == null)
                        {
                            settings = new Dictionary<string, byte[]>();
                        }
                        if (value != null)
                        {
                            settings[key] = valueToStore;
                        }
                        else
                        {
                            settings.Remove(key);
                        }
                        using (var stream = isoStore.OpenFile(settingsFilename, FileMode.OpenOrCreate, FileAccess.Write))
                        {
                            formatter.Serialize(stream, settings);
                        }
                    }
                    if (!(callback.IsNull() || callback.IsUndefined()))
                    {
                        callingCallback = true;
                        PayPalRetailObject.Engine.Js(() =>
                        {
                            callback.Invoke(JsValue.Null);
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Failed to set Item with key {key}: {ex}");
                if (!callback.IsNull() && !callback.IsUndefined() && !callingCallback)
                {
                    var error = new JsErrorBuilder(PayPalRetailObject.Engine, ex).Build();
                    PayPalRetailObject.Engine.Js(() =>
                    {
                        callback.Invoke(error, JsValue.Null);
                    });
                }
            }
        }
    }
}