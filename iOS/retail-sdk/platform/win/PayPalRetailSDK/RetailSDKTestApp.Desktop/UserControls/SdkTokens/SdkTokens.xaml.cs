using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using RetailSDKTestApp.Desktop.UserControls.AccessToken;

namespace RetailSDKTestApp
{
    /// <summary>
    /// Interaction logic for AccessTokens.xaml
    /// </summary>
    public partial class SdkTokens : UserControl
    {
        private readonly SolidColorBrush _normalBrush = new SolidColorBrush(Color.FromArgb(0xff, 0x00, 0x9c, 0xde));
        private SdkTokenViewModel _viewModel;
        public event EventHandler<TokenChangedEventArgs> TokenChanged;

        public SdkTokenViewModel ViewModel
        {
            get { return _viewModel; }
            set
            {
                DataContext = _viewModel = value;
            }
        }

        public SdkTokens()
        {
            InitializeComponent();
            ViewModel = new SdkTokenViewModel();
        }

        string lastToken = null;

        private void Tokens_OnSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (e.AddedItems.Count <= 0)
            {
                return;
            }

            var selectedItem = (SdkToken) e.AddedItems[0];
            if (selectedItem.Value != SdkTokenViewModel.AddNewLabel)
            {
                bool changed = lastToken != selectedItem.Value;
                lastToken = selectedItem.Value;                
                SdkTokenViewModel.ToCache(ViewModel);
                //Do not notify if we are not really changing the token
                if (changed)
                {
                    NotifyTokenChanged();
                }
                return;
            }
            
            UndoSelectionChange(e);
            var window = new Window
            {
                WindowStyle = WindowStyle.None,
                ResizeMode = ResizeMode.NoResize,
                Width = 450,
                Height = 50,
                Background = _normalBrush
            };

            var stackPanel = new StackPanel {Orientation = Orientation.Horizontal};
            var txtAccessToken = GetTextBox("Enter access token here...");
            stackPanel.Children.Add(txtAccessToken);
            stackPanel.Children.Add(GetButton("Save", (o, args) =>
            {
                ViewModel.AddToken(txtAccessToken.Text, true);
                //NotifyTokenChanged();//AddToken will trigger this
                window.Close();
            }));
            stackPanel.Children.Add(GetButton("Cancel", (o, args) =>
            {
                window.Close();
            }));
            window.Content = stackPanel;
            window.WindowStartupLocation = WindowStartupLocation.CenterScreen;
            window.ShowDialog();
        }

        private void UndoSelectionChange(SelectionChangedEventArgs e)
        {
            if (e.RemovedItems.Count > 0)
            {
                var previouslySelected = (SdkToken)e.RemovedItems[0];
                ViewModel.SelectedToken = previouslySelected;
            }
        }

        private void NotifyTokenChanged()
        {
            var temp = TokenChanged;
            if (temp != null)
            {
                temp(this, new TokenChangedEventArgs {Value = ViewModel.SelectedToken.Value});
            }
        }

        private Button GetButton(string text, RoutedEventHandler handler)
        {
            var button = new Button
            {
                Content = text,
                Width = 50,
                Height = 30,
                Margin = new Thickness(0, 10, 10, 10),
                BorderBrush = Brushes.LightGray
            };

            button.Click += handler;

            return button;
        }

        private TextBox GetTextBox(string hintText)
        {
            var textBox = new TextBox
            {
                Width = 300,
                FontSize = 14,
                Text = hintText,
                Height = 30,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(10)
            };

            textBox.PreviewMouseLeftButtonDown += (sender, e) =>
            {
                var tb = (sender as TextBox);
                if (tb == null || tb.IsKeyboardFocusWithin)
                {
                    return;
                }

                tb.SelectAll();
                e.Handled = true;
                tb.Focus();
            };

            return textBox;
        }

        private void ButtonBase_OnClick(object sender, RoutedEventArgs e)
        {
            var selectedAccessToken = ((FrameworkElement)sender).DataContext as SdkToken;
            if (selectedAccessToken == null)
            {
                return;
            }
            var selectedIndex = ViewModel.SdkTokens.IndexOf(selectedAccessToken);
            ViewModel.SdkTokens.RemoveAt(selectedIndex);
        }
    }

    public class TokenChangedEventArgs : EventArgs
    {
        public string Value { get; set; }
    }
}
