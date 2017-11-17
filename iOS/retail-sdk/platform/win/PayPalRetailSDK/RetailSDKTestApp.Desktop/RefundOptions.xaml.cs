using System.Windows;

namespace RetailSDKTestApp.Desktop
{
    /// <summary>
    /// Interaction logic for RefundOptions.xaml
    /// </summary>
    public partial class RefundOptions : Window
    {
        public RefundOptions()
        {
            InitializeComponent();
            ValidationError.Visibility = Visibility.Hidden;
        }

        private void RefundButton_OnClick(object sender, RoutedEventArgs e)
        {
            ValidationError.Visibility = Visibility.Hidden;
            if (Amount == null)
            {
                ValidationError.Visibility = Visibility.Visible;
                return;
            }
            DialogResult = true;
            Close();
        }

        private void CancelButton_OnClickButton_OnClick(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }

        public string TransactionId
        {
            set { InvoiceIdLabel.Content = value; }
        }

        public bool CardPresent => CardPresentOption.IsChecked.HasValue && CardPresentOption.IsChecked.Value;

        public decimal? Amount
        {
            get
            {
                decimal value;
                if (decimal.TryParse(RefundAmount.Text, out value))
                {
                    return value;
                }
                return null;
            }
            set { RefundAmount.Text = value.ToString(); }
        }
    }
}
