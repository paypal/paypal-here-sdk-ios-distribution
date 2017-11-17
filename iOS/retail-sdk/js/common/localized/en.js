/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: 'Done',
  Cancel: 'Cancel',
  Ok: 'OK',
  Yes: 'Yes',
  No: 'No',
  Error: 'Oops!',
  RemoveCard: '\nPlease remove card.',
  Sig: {
    Title: 'Charge ${amount} to ${cardIssuer} *${lastFour}',
    Here: 'Sign Here',
    Footer: 'I agree to pay the amount above according to the terms applicable to my card.',
  },
  Rcpt: {
    Title: '${amount}',
    Prompt: 'Would you like a receipt?',
    EmailButtonTitle: 'Email',
    SMSButtonTitle: 'Text',
    NoThanksButtonTitle: 'No Thanks',
    Sending: 'Sending Receipt...',
    Disclaimer: 'Receipts will be delivered by PayPal. See your receipt for PayPal\'s Privacy Policy',
    Email: {
      Title: 'EMAIL RECEIPT',
      Placeholder: 'me@somewhere.com',
      Disclaimer: 'By entering my email, I agree to receive emails for all future PayPal Here transactions.',
      SendButtonTitle: 'Send',
    },
    SMS: {
      Title: 'TEXT RECEIPT',
      Placeholder: '+14085551212',
      Disclaimer: 'You agree that you\'re authorized to add this phone number and consent to receiving automated texts. Message and data rates may apply. Receipts will be delivered by PayPal. See your receipt for PayPal\'s Privacy Policy.',
      SendButtonTitle: 'Send',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: 'Ready',
        Msg: 'Tap, Insert or Swipe a card when ready.',
      },
      EnterPin: {
        Title: '${amount}',
        Message: 'Please enter the PIN on the card reader keypad',
      },
      IncorrectPin: {
        Title: 'Incorrect PIN',
        Message: 'The PIN is incorrect. Please try again.',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: 'Ready',
        Msg: 'Insert or swipe a card when ready.',
      },
      ReadyForSwipeOnly: {
        Title: 'Please Swipe Card',
        Msg: 'Swipe the card at the top of the reader',
      },
      ReadyForInsertOnly: {
        Title: 'Ready',
        Msg: 'Insert a card when ready.',
      },
      Cancelled: {
        Title: 'Cancelled',
        Msg: 'Transaction Cancelled',
      },
      Cancel: {
        Title: 'Cancel',
        Msg: 'Would you like to cancel this transaction?',
      },
      TimeOut: {
        Title: 'Transaction Timed Out',
        Msg: 'Transaction was not completed.',
        Button: 'Cancel transaction',
      },
      NfcNotAllowed: {
        Title: 'Insert or swipe card',
        Msg: 'Card provider requires that you insert or swipe card.',
      },
      NfcFallback: {
        Title: 'Unable to Read Card',
        Msg: 'Insert or swipe card now, or try a different card.',
      },
      NfcPaymentDeclined: {
        Title: 'Contactless Transaction Declined',
        Msg: 'Do you want to try again by inserting the card?',
      },
      InsertOrSwipe: {
        Title: 'Insert or Swipe Card',
        Msg: 'Card issuer requires\nthat you insert or swipe card',
        Button: 'Cancel transaction',
      },
      IncorrectOnlinePin: {
        Title: 'Incorrect PIN',
        Msg: 'The PIN entered was incorrect. Please try again.',
      },
      GenericError: {
        Title: 'Transaction cancelled',
        PaymentMessage: 'Unable to process payment',
        RefundMessage: 'Unable to process refund',
      },
      TapDifferentCard: {
        Title: 'Unable to read card',
        Msg: 'Please insert or swipe card now, or press OK and tap a different card',
      },
      BlockedCard: {
        Title: 'Declined',
        Msg: 'Contact the card issuer for more information',
      },
      BlockedCardTapped: {
        Title: 'Declined',
        Msg: 'Please contact the card issuer for more information',
      },
      BlockedCardSwiped: {
        Title: 'Declined',
        Msg: 'Please contact the card issuer for more information',
      },
      ChipCardSwiped: {
        Title: 'Chip card detected',
        Msg: 'Please insert card',
      },
      UnsuccessfulInsert: {
        Title: 'Unable to read card',
        Msg: 'Please try again. Firmly insert the card, chip first, into the bottom of the reader',
      },
      AmountTooLow: {
        Title: 'Amount Too Low',
        Msg: 'The minimum amount for card payments is ${amount}. Please enter a new amount or choose a different payment method.',
      },
      AmountTooHigh: {
        Title: 'Amount Too High',
        Msg: 'The maximum amount for card payments is ${amount}. Please enter a new amount or choose a different payment method.',
      },
      Refund: {
        Title: 'Refund type',
        Msg: 'Please select a type',
        Buttons: {
          WithCard: 'Refund With Card',
          WithoutCard: 'Refund Without Card',
        },
        CardMismatch: {
          Title: 'Card Mismatch',
          Msg: 'Card presented for refund is not the one used for the original payment',
        },
      },
    },
    Retry: 'Try again?',
    CancelledByUser: 'Payment Cancelled',
    TransactionFailed: 'Payment Declined',
    TransactionSuccessful: 'Payment Successful',
    RefundSuccessful: 'Refund Complete',
    RefundFailed: 'Refund Failed',
  },
  SwUpgrade: {
    Required: {
      Title: 'Update Required',
      Msg: 'Your card reader must be updated before you can process transactions.',
    },
    Optional: {
      Title: 'Update available',
      Msg: 'An update is available for your card reader.',
    },
    Buttons: {
      Ok: 'OK',
      UpdateNow: 'Update Now',
      NotNow: 'Not Now',
      Retry: 'Try again',
    },
    Failed: {
      Title: 'Software Update Failed',
      Msg: 'Sorry, the update could not be completed.',
      BatteryLow: 'Please recharge the card reader.',
    },
    Updating: {
      Title: 'Updating Reader',
      Msg: '\nPlease do not close the app or disconnect the reader',
    },
    Success: {
      Title: 'Update Successful',
      Msg: 'Your card reader is ready.\nYou can now accept card payments.',
    },
    Downloading: 'Downloading ${count}/${total}',
    Initializing: 'Initializing card reader...\nPlease do not close the app or disconnect the reader',
    ValidatingSecurityKeys: 'Validating security keys...\nPlease do not close the app or disconnect the reader',
    SecurityKeysInstalled: 'Security keys installed.',
    UpdatingWithDetails: 'Updating ${stage} ${progress}%\nPlease do not close the app or disconnect the reader',
    Restarting: 'Restarting card reader...\nPlease do not close the app',
    Reconnecting: 'Reconnecting to card reader...\nPlease do not close the app',
    Connected: 'Connected',
    Usb: {
      UsbUnplug: 'Please unplug your USB reader and press OK',
      UsbWait: 'Please wait before plugging in your USB reader.',
      UsbPlug: 'Please reconnect your USB reader.',
    },
  },
  EMV: {
    Tip: {
      Title: 'Waiting for customer input...',
      Buttons: {
        NoTip: 'No Tip',
      },
    },
    QuickChip: 'Card May Be Removed\nTransaction Still Processing...',
    Processing: 'Processing...',
    ProcessingPinOk: 'Processing... PIN OK',
    PinOk: 'PIN OK',
    ProcessingRefund: 'Processing Refund...',
    Cancelling: 'Cancelling...',
    Finalize: 'Completing Payment...',
    DoNotRemove: 'Do not remove card.',
    Remove: 'Please remove card.',
    Complete: '${amount} paid',
    RefundComplete: '${amount} refunded',
    Select: 'Choose an application:',
  },
  MultiCard: {
    Title: 'Select a device',
    Msg: 'Please select the PayPal card reader you would like to use:',
  },
  Device: {
    Connecting: {
      Title: 'Connecting to\n${deviceId}',
    },
    RetryConnecting: {
      Title: 'Do you want to connect to\n${deviceId}',
      Message: 'Make sure the device is awake',
      Buttons: {
        Retry: 'Retry',
        NotNow: 'Not Now',
      },
    },
    ConnectingFailed: {
      Title: 'Could not\nconnect to\n${deviceId}',
      Buttons: {
        Cancel: 'OK',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
