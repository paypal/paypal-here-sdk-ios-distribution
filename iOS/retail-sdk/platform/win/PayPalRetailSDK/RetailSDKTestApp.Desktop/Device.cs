using System.ComponentModel;
using System.Runtime.CompilerServices;
using PayPalRetailSDK;

namespace RetailSDKTestApp
{
    public class Device : INotifyPropertyChanged
    {
        private DeviceStatus _status;
        private string _id;
        private string _serialNumber;
        private bool _activePaymentDevice;
        private bool _updateAvailable;
        private bool _canToggleConnection;

        public string Id
        {
            get { return _id; }
            set
            {
                _id = value;
                RaisePropertyChanged();
            }
        }

        private bool _canExtractLogs;
        public bool CanExtractLogs
        {
            get { return _canExtractLogs; }
            set
            {
                _canExtractLogs = value;
                RaisePropertyChanged();
            }
        }

        public DeviceStatus Status
        {
            get { return _status; }
            set
            {
                _status = value;
                CanToggleConnection = _status == DeviceStatus.Connected || _status == DeviceStatus.ConnectionFailed ||
                                      _status == DeviceStatus.NotConnected || _status == DeviceStatus.UpdateSuccessful;
                CanExtractLogs = _status == DeviceStatus.Connected || _status == DeviceStatus.NeedsSoftwareUpdate ||
                                 _status == DeviceStatus.UpdateSuccessful;
                RaisePropertyChanged();
            }
        }

        public string SerialNumber
        {
            get { return _serialNumber; }
            set
            {
                _serialNumber = value;
                RaisePropertyChanged();
            }
        }

        public PaymentDevice SdkDevice { get; set; }

        public bool ActivePaymentDevice
        {
            get { return _activePaymentDevice; }
            set
            {
                _activePaymentDevice = value;
                RaisePropertyChanged();
            }
        }

        public bool UpdateAvailable
        {
            get { return _updateAvailable; }
            set
            {
                _updateAvailable = value;
                RaisePropertyChanged();
            }
        }

        public bool CanToggleConnection
        {
            get { return _canToggleConnection; }
            set
            {
                _canToggleConnection = value;
                RaisePropertyChanged();
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

    public enum DeviceStatus
    {
        Discovered,
        Connecting,
        Connected,
        NotConnected,
        Updating,
        NeedsSoftwareUpdate,
        ConnectionFailed,
        UpdateFailed,
        UpdateSuccessful,
        UnplugAndReplug,
        DownloadingDeviceLogs
    }
}
