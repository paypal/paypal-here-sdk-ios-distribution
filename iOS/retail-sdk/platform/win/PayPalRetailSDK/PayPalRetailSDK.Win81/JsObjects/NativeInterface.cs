using Jint.Native;
using Jint.Native.Object;
using PayPalRetailSDK;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Web.Http;
using System.Runtime.InteropServices.WindowsRuntime;
using Jint.Native.Function;
using Windows.Storage.Streams;
using Windows.Web.Http.Filters;
using Jint.Parser;
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.DataProtection;
using Jint.Runtime.Interop;
using PayPalRetailSDK.UI;
using Manticore;
using Jint.Native.Error;

namespace PayPalRetailSDK.JsObjects
{
    public class NativeInterface
    {
        // For getItem/setItem
        private static String SecureType = "S";
        private static String BlobType = "B";
        private static String StringType = "V";
        private static String SecureBlobType = "E";

        private InternalNetworkManager NetworkManager;

        public void Register(ManticoreEngine engine)
        {
            var mo = engine.ManticoreJsObject;
            mo.FastAddProperty("ready", engine.Wrap(new Action<JsValue>((sdk) => this.ready(sdk))), false, true, false);
            mo.FastAddProperty("setItem", engine.Wrap(new Action<String, String, String, JsValue>((name, storage, value, callback) => this.setItem(engine.jsEngine, name, storage, value, callback))), false, true, false);
            mo.FastAddProperty("getItem", engine.Wrap(new Action<String, String, JsValue>((name, storage, callback) => this.getItem(engine.jsEngine, name, storage, callback))), false, true, false);
            //mo.FastAddProperty("offerReceipt", engine.Wrap(new Action<JsValue, JsValue>((opts, cb) => this.offerReceipt(opts, cb));
            //mo.FastAddProperty("collectSignature", engine.Wrap(new Action<JsValue, JsValue>((opts, cb) => this.collectSignature(opts, cb))), false, true, false);
            mo.FastAddProperty("alert", engine.Wrap(new Action<JsValue, JsValue>((opts, cb) => this.alert(opts, cb))), false, true, false);
            this.NetworkManager = new InternalNetworkManager(engine);
        }


        public void debugger()
        {
            Debugger.Break();
        }

        public void ready(JsValue sdk)
        {
            RetailSDK.ready(sdk.As<ObjectInstance>());
        }

        public void getItem(Jint.Engine engine, String name, String storage, JsValue callback)
        {
            if (callback.IsNull() || callback.IsUndefined())
            {
                return;
            }

            String key = "sdkPrefs." + storage + "." + name;
            if (StringType.Equals(storage) || SecureType.Equals(storage))
            {
                var rawValue = Windows.Storage.ApplicationData.Current.LocalSettings.Values[key];

                if (rawValue == null)
                {
                    callback.Invoke(JsValue.Null, JsValue.Null);
                }
                else if (StringType.Equals(storage))
                {
                    callback.Invoke(JsValue.Null, new JsValue(rawValue.ToString()));
                }
                else
                {
                    // Create a DataProtectionProvider object for the specified descriptor.
                    DataProtectionProvider Provider = new DataProtectionProvider("LOCAL=user");
                    var task = Provider.UnprotectAsync(((byte[])rawValue).AsBuffer()).AsTask();
                    task.ContinueWith((bufResult) =>
                    {
                        if (bufResult.IsCanceled)
                        {
                            callback.Invoke(new ErrorInstance(engine, "getItem cancelled."));
                        }
                        else if (bufResult.IsFaulted)
                        {
                            callback.Invoke(new ErrorInstance(engine, bufResult.Exception.Message));
                        }
                        else
                        {
                            var retVal = CryptographicBuffer.ConvertBinaryToString(BinaryStringEncoding.Utf8, bufResult.Result);
                            callback.Invoke(JsValue.Null, new JsValue(retVal));
                        }
                    });
                }
            }
            else
            {
                this.readFile(engine, key, SecureBlobType.Equals(storage)).ContinueWith((rz) => {
                    callback.Invoke(rz.Result);
                });
            }
        }

        private async Task<JsValue[]> readFile(Jint.Engine engine, String name, bool isSecure)
        {
            try
            {
                var stream = await Windows.Storage.ApplicationData.Current.LocalFolder.OpenStreamForReadAsync(name);
                byte[] rz = new byte[stream.Length];
                await stream.ReadAsync(rz, 0, rz.Length);
                if (isSecure)
                {
                    DataProtectionProvider Provider = new DataProtectionProvider("LOCAL=user");
                    var clearcontent = await Provider.UnprotectAsync(rz.AsBuffer());
                    rz = clearcontent.ToArray();
                }
                var retVal = Encoding.UTF8.GetString(rz, 0, rz.Length); 
                return new JsValue[] { JsValue.Undefined, new JsValue(retVal) };
            }
            catch (FileNotFoundException)
            {
                return new JsValue[] { JsValue.Undefined, JsValue.Null };
            }
            catch (Exception x)
            {
                return new JsValue[] { new ErrorInstance(engine, x.Message) };
            }
        }

        private async Task<JsValue> deleteFile(Jint.Engine engine, String name)
        {
            try
            {
                var file = await Windows.Storage.ApplicationData.Current.LocalFolder.GetFileAsync(name);
                await file.DeleteAsync();
                return JsValue.Undefined;
            }
            catch (FileNotFoundException)
            {
                return JsValue.Undefined;
            }
            catch (Exception x)
            {
                return new ErrorInstance(engine, x.Message);
            }
        }

        public void setItem(Jint.Engine engine, String name, String storage, String value, JsValue callback)
        {
            String key = "sdkPrefs." + storage + "." + name;
            if (value == null)
            {
                if (StringType.Equals(storage) || SecureType.Equals(storage))
                {
                    Windows.Storage.ApplicationData.Current.LocalSettings.Values.Remove(key);
                    callback.Invoke(JsValue.Undefined);
                }
                else
                {
                    this.deleteFile(engine, key).ContinueWith((rz) =>
                    {
                        callback.Invoke(rz.Result);
                    });
                }
                return;
            }
            if (StringType.Equals(storage))
            {
                Windows.Storage.ApplicationData.Current.LocalSettings.Values[key] = value;
                callback.Invoke(JsValue.Undefined);
                return;
            }
            else if (SecureType.Equals(storage) || SecureBlobType.Equals(storage))
            {
                // Create a DataProtectionProvider object for the specified descriptor.
                DataProtectionProvider Provider = new DataProtectionProvider("LOCAL=user");
                // Encode the plaintext input message to a buffer.
                IBuffer buffMsg = CryptographicBuffer.ConvertStringToBinary(value, BinaryStringEncoding.Utf8);
                var saver = Provider.ProtectAsync(buffMsg).AsTask();
                saver.ContinueWith((buffResult) =>
                {
                    if (buffResult.IsFaulted)
                    {
                        callback.Invoke(new ErrorInstance(engine, buffResult.Exception.Message));
                    }
                    else if (buffResult.IsCanceled)
                    {
                        callback.Invoke(new ErrorInstance(engine, "setItem cancelled."));
                    }
                    else
                    {
                        if (SecureBlobType.Equals(storage))
                        {
                            var task = Windows.Storage.ApplicationData.Current.LocalFolder.OpenStreamForWriteAsync(key, Windows.Storage.CreationCollisionOption.ReplaceExisting);
                            task.ContinueWith((openResult) =>
                            {
                                // TODO errors
                                var bytes = buffResult.Result.ToArray();
                                openResult.Result.Write(bytes, 0, bytes.Length);
                                openResult.Result.Flush();
                                openResult.Result.Dispose();
                                callback.Invoke(JsValue.Undefined);
                            });
                        }
                        else
                        {
                            Windows.Storage.ApplicationData.Current.LocalSettings.Values[key] = buffResult.Result.ToArray();
                            callback.Invoke(JsValue.Undefined);
                        }
                    }
                });
            }
            else if (BlobType.Equals(storage))
            {
                var bytes = Encoding.UTF8.GetBytes(value);
                var task = Windows.Storage.ApplicationData.Current.LocalFolder.OpenStreamForWriteAsync(key, Windows.Storage.CreationCollisionOption.ReplaceExisting);
                task.ContinueWith((openResult) =>
                {
                    // TODO errors
                    openResult.Result.Write(bytes, 0, bytes.Length);
                    openResult.Result.Flush();
                    openResult.Result.Dispose();
                    callback.Invoke(JsValue.Undefined);
                });
            }
        }

        public JsValue alert(JsValue options, JsValue callback)
        {
            String title = null, message = null, cancel = null;
            bool showActivity = false;
            List<String> otherButtons = null;

            if (options.IsObject())
            {
                ObjectInstance opt = options.AsObject();
                JsValue v;
                if (opt.HasProperty("title") && !(v = opt.Get("title")).IsNull() && !v.IsUndefined())
                {
                    title = v.AsString();
                }
                if (opt.HasProperty("message") && !(v = opt.Get("message")).IsNull() && !v.IsUndefined())
                {
                    message = v.AsString();
                }
                if (opt.HasProperty("cancel") && !(v = opt.Get("cancel")).IsNull() && !v.IsUndefined())
                {
                    cancel = v.AsString();
                }
                if (opt.HasProperty("showActivity") && (v = opt.Get("showActivity")).IsBoolean() && v.AsBoolean())
                {
                    showActivity = true;
                }
            }

            var handle = RetailSDK.Engine.CreateJsObject();
            var avHandle = AlertView.Show(title, message, showActivity, cancel, otherButtons, (sender, index) =>
            {
                callback.As<FunctionInstance>().Call(RetailSDK.jsSdk, new JsValue[] { handle, new JsValue(index) });
            });

            DelegateWrapper dismiss = RetailSDK.Engine.Wrap(new Action(() =>
            {
                avHandle.Dismiss();
            }));
            DelegateWrapper setTitle = RetailSDK.Engine.Wrap(new Action<JsValue>((newTitle) =>
            {
                avHandle.SetTitle(newTitle.AsString());
            }));
            DelegateWrapper setMessage = RetailSDK.Engine.Wrap(new Action<JsValue>((newMessage) =>
            {
                avHandle.SetMessage(newMessage.AsString());
            }));

            handle.FastAddProperty("dismiss", dismiss, false, true, true);
            handle.FastAddProperty("setTitle", setTitle, false, true, true);
            handle.FastAddProperty("setMessage", setMessage, false, true, true);
            return handle;
        }
    }
}
