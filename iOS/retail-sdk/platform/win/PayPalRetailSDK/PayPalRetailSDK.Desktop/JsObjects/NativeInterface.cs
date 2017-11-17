using Manticore;
using Microsoft.ClearScript;
using PayPalRetailSDK.UI;
using System;
using System.Collections.Generic;
using System.Dynamic;
using System.IO;
using System.IO.IsolatedStorage;
using System.Media;
using System.Runtime.Serialization.Formatters.Binary;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Windows;
using System.Windows.Media.Imaging;
using PayPalRetailSDK.Desktop.UI;

namespace PayPalRetailSDK.JsObjects
{
    class NativeInterface
    {
        private static readonly byte[] s_aditionalEntropy = { 61, 40, 109, 120, 5 };
        static String settingsFilename = "settings.cfg";
        private const string LogComponentName = "native.interface";

        // For getItem/setItem
        private static String SecureType = "S";
        private static String BlobType = "B";
        private static String StringType = "V";
        private static String SecureBlobType = "E";
        private ManticoreEngine engine;

        public void Register(ManticoreEngine engine)
        {
            this.engine = engine;
            engine.ManticoreJsObject.log = new Action<String, String, String>((l, c, m) => this.log(l, c, m));
            engine.ManticoreJsObject.ready = new Action<dynamic>((sdk) => this.ready(sdk));
            engine.ManticoreJsObject.setItem = new Action<dynamic, dynamic, dynamic, dynamic>((name, storage, value, callback) => this.setItem(name, storage, value, callback));
            engine.ManticoreJsObject.getItem = new Action<dynamic, dynamic, dynamic>((name, storage, callback) => this.getItem(name, storage, callback));
            engine.ManticoreJsObject.offerReceipt = new Action<dynamic, dynamic>((opts, cb) => this.offerReceipt(opts, cb));
            engine.ManticoreJsObject.collectSignature = new Func<dynamic, dynamic, dynamic>((opts, cb) => this.collectSignature(opts, cb));
            engine.ManticoreJsObject.alert = new Func<dynamic, dynamic, dynamic>((opts, cb) => this.alert(opts, cb));
            engine.ManticoreJsObject.playAudibleBeep = new Action(PlayBeepSound);
            engine.ManticoreJsObject.getLocation = new Action<dynamic>((cb) => this.GetLocation(cb));
        }

        public void GetLocation(dynamic callback)
        {
            // TODO Figure out how to get location from any windows device (fallback to default if location service is not available??)
            dynamic loc = new ExpandoObject();
            loc.latitude = "0.0";
            loc.longitude = "0.0";
            loc.accuracy = "0";
            callback(null, loc);
        }

        public void PlayBeepSound()
        {
            try
            {
                SystemSounds.Beep.Play();
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Play beep sound logged an error: {ex}");
            }
        }

        public void log(String level, String component, String message)
        {
            Console.Out.WriteLine("{0} ({1}): {2} {3}", level, Thread.CurrentThread.ManagedThreadId, component, message);

            //ToDo - Currently all log messages are also forwarded to a file, eventually logs should be forwarded to a file only on debug mode
            logToFile(level, component, message);
        }

        public void logToFile(String level, String component, String message)
        {
            NLogManager.LogToFile(level, component, message);
        }

        public void ready(dynamic sdk)
        {
            RetailSDK.ready(sdk);
        }

        public void setItem(dynamic name, dynamic storage, dynamic value, dynamic callback)
        {
            var callingCallback = false;
            var isoStore = IsolatedStorageFile.GetUserStoreForAssembly();
            var key = ((String)storage) + ((String)name);

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
                    if (engine.IsNullOrUndefined(value))
                    {
                        isoStore.DeleteFile(fileKey);
                        if (callback != null)
                        {
                            callingCallback = true;
                            callback(null);
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
                    if (callback != null)
                    {
                        callingCallback = true;
                        callback(null);
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
                    if (callback != null)
                    {
                        callingCallback = true;
                        callback(null);
                    }
                }
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Failed to set Item with key {key}: {ex}");
                if (callback != null && !callingCallback)
                {
                    dynamic error = new JsErrorBuilder(ex).Build();
                    callback(error);
                }
            }
        }

        public void getItem(dynamic name, dynamic storage, dynamic callback)
        {
            byte[] storedValue = null;
            var key = ((String)storage) + ((String)name);
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
                            BinaryFormatter formatter = new BinaryFormatter();
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
                    callback(null, null);
                    return;
                }
                if (SecureType.Equals(storage) || SecureBlobType.Equals(storage))
                {
                    storedValue = ProtectedData.Unprotect(storedValue, s_aditionalEntropy, DataProtectionScope.CurrentUser);
                }
                callback(null, Encoding.UTF8.GetString(storedValue));
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Failed to get Item with key {key}: {ex}");
                dynamic error = new JsErrorBuilder(ex).Build();
                callback(error);
            }
        }

        public void offerReceipt(dynamic options, dynamic callback)
        {
            var veiwContent = new ReceiptViewContent(options.viewContent);
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                ReceiptControl.Show(veiwContent, emailOrSms =>
                {
                    if (string.IsNullOrWhiteSpace(emailOrSms))
                    {
                        callback(null, null);
                    }
                    else
                    {
                        dynamic content = new ExpandoObject();
                        content.name = "emailOrSms";
                        content.value = emailOrSms;
                        callback(null, content);
                    }
                });
            });
        }

        public dynamic alert(dynamic options, dynamic callback)
        {
            dynamic handle = PayPalRetailObject.Engine.CreateJsObject();
            AlertView.AlertViewHandle avHandle = null;
            handle.dismiss = new Action(() =>
            {
                avHandle?.Dismiss();
            });
            handle.setTitle = new Action<string>((newTitle) =>
            {
                avHandle?.SetTitle(newTitle);
            });
            handle.setMessage = new Action<string>((newMessage) =>
            {
                avHandle?.SetMessage(newMessage);
            });
            handle.isShowing = new Func<bool>(() => avHandle?.IsShowing() ?? false);
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                string title = null, message = null, cancel = null, imageIcon = null, audioFile = null;
                var showActivity = false;
                var playCount = 1;
                List<string> otherButtons = null;

                if (!engine.IsNullOrUndefined(options))
                {
                    title = options.title as string;
                    message = options.message as string;
                    cancel = options.cancel as string;
                    imageIcon = options.imageIcon as string;

                    if (!engine.IsNullOrUndefined(options.showActivity) && (bool)options.showActivity)
                    {
                        showActivity = true;
                    }

                    if (!engine.IsNullOrUndefined(options.buttons))
                    {
                        otherButtons = PayPalRetailObject.Engine.Converter.ToNativeArray((object)options.buttons, (element) => 
                            (engine.IsNullOrUndefined(element) ? null : element as string));
                    }

                    if (!engine.IsNullOrUndefined(options.audio))
                    {
                        if (!engine.IsNullOrUndefined(options.audio.file))
                        {
                            audioFile = options.audio.file as string;
                        }

                        if (!engine.IsNullOrUndefined(options.audio.playCount))
                        {
                            playCount = PayPalRetailObject.Engine.Converter.AsNativeInt(options.audio.playCount);
                        }
                    }
                }

                avHandle = AlertView.Show(title, message, showActivity, cancel, otherButtons, imageIcon, audioFile, playCount, (sender, index) =>
                {
                    callback(handle, index);
                });
            });
            return handle;
        }

        public dynamic collectSignature(dynamic options, dynamic callback)
        {
            SignatureControl.SignatureViewHandle sigHandle = null;
            dynamic handle = PayPalRetailObject.Engine.CreateJsObject();
            handle.dismiss = new Action(() =>
            {
                sigHandle?.Dismiss();
            });

            RetailSDK.RunOnUIThreadAsync(() =>
            {
                string title = string.Empty, signHere = string.Empty, footer = string.Empty, cancel = string.Empty;
                if (options != null && !(options is Undefined))
                {
                    title = options.title as string;
                    signHere = options.signHere as string;
                    footer = options.footer as string;
                    cancel = options.cancel as string;
                }

                sigHandle = SignatureControl.Show(title, signHere, footer, cancel, (signature, cancelRequested) =>
                {
                    callback(null, signature, cancelRequested);
                });
            });

            return handle;
        }
    }
}
