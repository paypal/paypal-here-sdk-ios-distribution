using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using Newtonsoft.Json.Linq;

namespace RetailSDKTestApp.Desktop.UserControls.AccessToken
{
    public class SdkTokenViewModel : INotifyPropertyChanged
    {
        internal const string AddNewLabel = "<Add New>";
        private const string CacheFileName = @"sdkTokens.json";
        private SdkToken _selectedToken;
        public ObservableCollection<SdkToken> SdkTokens { get; set; }

        public SdkTokenViewModel()
        {
            SdkTokens = new ObservableCollection<SdkToken>();
        }

        public SdkToken SelectedToken
        {
            get { return _selectedToken; }
            set
            {
                _selectedToken = value;
                RaisePropertyChanged();
            }
        }

        public void AddToken(string accessToken, bool selected = false)
        {
            if (SdkTokens.All(x => x.Value != AddNewLabel))
            {
                SdkTokens.Add(new SdkToken { Value = AddNewLabel });
            }

            if (!string.IsNullOrWhiteSpace(accessToken) && !SdkTokens.Any(x => x.Value.Equals(accessToken)))
            {
                SdkTokens.Insert(1, new SdkToken { Value = accessToken });
            }

            if (selected || SelectedToken == null)
            {
                SelectedToken = SdkTokens.First(x => x.Value == accessToken);
            }
        }

        public void LoadFromCache()
        {
            if (!File.Exists(CacheFileName))
            {
                return;
            }

            try
            {
                using (var sw = new StreamReader(CacheFileName))
                using (JsonReader reader = new JsonTextReader(sw))
                {
                    var se = new JsonSerializer();
                    var jObj = (JObject)se.Deserialize(reader);
                    var cachedVal = jObj.ToObject<SdkTokenViewModel>();
                    SdkTokens = cachedVal.SdkTokens;
                    if (cachedVal.SelectedToken != null)
                    {
                        var selectedToken = SdkTokens.FirstOrDefault(x => x.Value == cachedVal.SelectedToken.Value);
                        if (selectedToken != null)
                        {
                            SelectedToken = selectedToken;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex);
            }
        }

        private static readonly object Obj = new object();
        public static void ToCache(SdkTokenViewModel value)
        {
            lock (Obj)
            {
                try
                {
                    var serializer = new JsonSerializer();
                    serializer.Converters.Add(new JavaScriptDateTimeConverter());
                    serializer.NullValueHandling = NullValueHandling.Ignore;
                    using (var sw = new StreamWriter(CacheFileName))
                    using (JsonWriter writer = new JsonTextWriter(sw))
                    {
                        serializer.Serialize(writer, value);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex);
                }
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;
        public void RaisePropertyChanged([CallerMemberName] string propertyName = null)
        {
            if (PropertyChanged != null)
            {
                var eventArgs = new PropertyChangedEventArgs(propertyName);
                PropertyChanged(this, eventArgs);
            }
        }
    }

    public class SdkToken
    {
        public string Value { get; set; }

        [JsonIgnore]
        public string DisplayValue
        {
            get { return Value.Length > 20 ? Value.Substring(0, 20) + "..." : Value; }
        }
    }
}
