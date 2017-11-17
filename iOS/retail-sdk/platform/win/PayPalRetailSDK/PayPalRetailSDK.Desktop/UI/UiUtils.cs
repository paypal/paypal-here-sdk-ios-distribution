using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Forms.Integration;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using PayPalRetailSDK.UI;
using Color = System.Drawing.Color;

namespace PayPalRetailSDK
{
    public class WpfOnWinForm
    {
        public Form Popup { get; set; }
        public ElementHost ElementHost { get; set; }
    }

    public static class UiUtils
    {
        private const string LogComponentName = "UiUtils";

        [DllImport("Gdi32.dll", EntryPoint = "CreateRoundRectRgn")]
        private static extern IntPtr CreateRoundRectRgn
        (
            int nLeftRect, // x-coordinate of upper-left corner
            int nTopRect, // y-coordinate of upper-left corner
            int nRightRect, // x-coordinate of lower-right corner
            int nBottomRect, // y-coordinate of lower-right corner
            int nWidthEllipse, // height of ellipse
            int nHeightEllipse // width of ellipse
        );

        internal static WpfOnWinForm ShowWithParentFormLock(this UIElement wpfControl, Form parentForm)
        {
            var popupForm = new Form
            {
                FormBorderStyle = FormBorderStyle.None,
                StartPosition = FormStartPosition.CenterScreen,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                BackColor = Color.Empty,
                TransparencyKey = Color.Empty,
            };
            var winFormElementHost = new ElementHost
            {
                Child = wpfControl,
                BackColorTransparent = true,
                AutoSize = true,
                Visible = true
            };

            popupForm.Resize += PopupForm_Resize;
            popupForm.Controls.Add(winFormElementHost);
            EventHandler onParentActivated = (sender, e) =>
            {
                popupForm.Focus();
                // TODO: Add ability to flash form to notify user that focus changed
            };

            popupForm.FormClosed += (sender, args) =>
            {
                parentForm.Focus();
                parentForm.Activated -= onParentActivated;
                if (!popupForm.IsDisposed || !popupForm.Disposing)
                    popupForm.Dispose();
            };
            parentForm.Activated += onParentActivated;
            popupForm.Show(parentForm);

            return new WpfOnWinForm
            {
                Popup = popupForm,
                ElementHost = winFormElementHost
            };
        }

        private static void PopupForm_Resize(object sender, EventArgs e)
        {
            var form = (Form) sender;
            form.Region = Region.FromHrgn(CreateRoundRectRgn(0, 0, form.Width, form.Height, 20, 20));
        }

        internal static bool TryGetBitmapImage(string fileName, out BitmapImage bmpImage)
        {
            bmpImage = null;
            if (string.IsNullOrWhiteSpace(fileName))
            {
                return false;
            }
            try
            {
                if (Path.GetExtension(fileName) == string.Empty)
                {
                    fileName = $"{fileName}.png";
                }

                var resourceFullName = $"PayPalRetailSDK.Resources.Images.{fileName}";
                var assembly = Assembly.GetExecutingAssembly();
                var imageStream = assembly.GetManifestResourceStream(resourceFullName);
                if (imageStream == null)
                {
                    return false;
                }

                bmpImage = (new Bitmap(imageStream)).ToBitMapImage();
                return true;
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("Error", LogComponentName, ex.ToString());
            }

            return false;
        }

        internal static BitmapImage ToBitMapImage(this Bitmap bmp)
        {
            using (var memory = new MemoryStream())
            {
                bmp.Save(memory, ImageFormat.Png);
                memory.Position = 0;
                var bitmapImage = new BitmapImage();
                bitmapImage.BeginInit();
                bitmapImage.StreamSource = memory;
                bitmapImage.CacheOption = BitmapCacheOption.OnLoad;
                bitmapImage.EndInit();
                return bitmapImage;
            }
        }

        /// <summary>
        /// Get a scaled image of a FrameworkElement
        /// </summary>
        /// <param name="maxWidth">Maximum width for scale</param>
        /// <param name="maxHeight">Maximum height for scale</param>
        /// <param name="fe">The FrameworkElement to be converted to an image</param>
        /// <returns>A jpeg MemoryStream for the image</returns>
        internal static MemoryStream GetScaledImageFromFrameworkElement(double maxWidth, double maxHeight, FrameworkElement fe)
        {
            //Based on the discussions at 
            //http://stackoverflow.com/questions/222756/scaling-wpf-content-before-rendering-to-bitmap
            //http://stackoverflow.com/questions/13144615/rendertargetbitmap-renders-image-of-a-wrong-size
            var memorySig = new MemoryStream();
            //Limit the ratio to 1 max. If the FrameworkElement is smaller, then we do not want to scale/enlarge it
            var ratio = 1.0;
            var ratioX = maxWidth / fe.ActualWidth;
            ratio = Math.Min(ratio, ratioX);
            var ratioY = maxHeight / fe.ActualHeight;
            ratio = Math.Min(ratio, ratioY);

            int w = (int)(fe.ActualWidth * ratio);
            int h = (int)(fe.ActualHeight * ratio);

            DrawingVisual visual = new DrawingVisual();

            using (DrawingContext context = visual.RenderOpen())
            {
                VisualBrush brush = new VisualBrush(fe);
                context.DrawRectangle(brush,
                                      null,
                                      new Rect(new System.Windows.Point(), new System.Windows.Size(fe.ActualWidth, fe.ActualHeight)));
            }

            visual.Transform = new ScaleTransform(ratio, ratio);

            var rtb = new RenderTargetBitmap(w, h, 96d, 96d, PixelFormats.Default);
            rtb.Render(visual);

            var encoder = new JpegBitmapEncoder { QualityLevel = 25 };
            encoder.Frames.Add(BitmapFrame.Create(rtb));
            encoder.Save(memorySig);
            return memorySig;
        }

        internal static ISdkMediaPlayer GetMediaPlayer()
        {
            try
            {
                return new SdkWinMediaPlayer();
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("Error", LogComponentName, ex.ToString());
            }

            return null;
        }

    }
}
