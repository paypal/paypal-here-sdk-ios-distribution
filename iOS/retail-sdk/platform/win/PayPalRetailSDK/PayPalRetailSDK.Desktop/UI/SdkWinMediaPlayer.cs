using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using WMPLib;

namespace PayPalRetailSDK.UI
{
    class SdkWinMediaPlayer : ISdkMediaPlayer
    {
        private const string LogComponentName = "SdkWinMediaPlayer";
        private readonly WindowsMediaPlayer _player;

        public SdkWinMediaPlayer()
        {
            _player = new WindowsMediaPlayer();
        }

        public void PlayAudio(string fullFilePath)
        {
            try
            {
                _player.URL = fullFilePath;
                _player.controls.play();
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("Error", LogComponentName, ex.ToString());
            }
        }
    }
}
