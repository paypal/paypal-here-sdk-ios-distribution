/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: 'Done',
  Cancel: 'Cancel',
  Ok: 'OK',
  Yes: 'Yes',
  No: 'No',
  Error: 'We’re sorry.',
  Sig: {
    Title: 'Charge ${amount} to ${cardIssuer} *${lastFour}',
    Here: 'Sign here',
    Footer: 'I agree to pay the amount above according to the terms applicable to my card.',
  },
  Rcpt: {
    Title: '${amount}',
    Prompt: 'Would you like a receipt?',
    EmailButtonTitle: 'Email',
    SMSButtonTitle: 'Text',
    NoThanksButtonTitle: 'No thanks',
    Sending: 'Sending receipt...',
    Disclaimer: 'Receipts will be delivered by PayPal. See your receipt for PayPal\'s Privacy Policy',
    Email: {
      Title: 'EMAIL RECEIPT',
      Placeholder: 'me@somewhere.com',
      Disclaimer: 'By entering my email, I agree to receive emails for all future PayPal Here transactions.',
      SendButtonTitle: 'Send',
    },
    SMS: {
      Title: 'TEXT RECEIPT',
      Placeholder: '14085551212',
      Disclaimer: 'You agree that you\'re authorised to add this phone number and consent to receiving automated texts. Message and data rates may apply. Receipts will be delivered by PayPal. See your receipt for PayPal\'s Privacy Policy.',
      SendButtonTitle: 'Send',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: 'Ready',
        Msg: 'Tap, insert or swipe a card when ready.',
      },
      EnterPin: {
        Title: '${amount}',
        Message: 'Please enter the PIN on the card reader keypad',
      },
      IncorrectPin: {
        Title: 'Incorrect PIN',
        Message: 'The PIN is incorrect.  Please try again.',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: 'Ready',
        Msg: 'Insert or swipe a card when ready.',
      },
      ReadyForSwipeOnly: {
        Title: 'Please swipe card',
        Msg: 'Swipe the card at the top of the reader',
      },
      ReadyForInsertOnly: {
        Title: 'Ready',
        Msg: 'Insert a card when ready.',
      },
      Cancelled: {
        Title: 'Cancelled',
        Msg: 'Transaction cancelled',
      },
      Cancel: {
        Title: 'Cancel',
        Msg: 'Would you like to cancel this transaction?',
      },
      TimeOut: {
        Title: 'Transaction timed out',
        Msg: 'Transaction was not completed.',
        Button: 'Cancel transaction',
      },
      NfcNotAllowed: {
        Title: 'Insert or swipe card',
        Msg: 'Card provider requires that you insert or swipe card.',
      },
      NfcFallback: {
        Title: 'Unable to read card',
        Msg: 'Insert or swipe card now, or try a different card.',
      },
      NfcPaymentDeclined: {
        Title: 'Contactless transaction declined',
        Msg: 'Do you want to try again by inserting the card?',
      },
      InsertOrSwipe: {
        Title: 'Insert or swipe card',
        Msg: 'Card issuer \nrequiresthat you insert or swipe card',
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
        Msg: 'Please contact the card issuer for more information',
      },
      BlockedCardInserted: {
        Title: 'Declined',
        Msg: 'Please remove the card and contact the card issuer for more information',
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
        Title: 'Amount too low',
        Msg: 'The minimum amount for card payments is ${amount}. Please enter a new amount or choose a different funding source.',
      },
      AmountTooHigh: {
        Title: 'Amount too high',
        Msg: 'The maximum amount for card payments is ${amount}. Please enter a new amount or choose a different funding source.',
      },
      Refund: {
        Title: 'Refund type',
        Msg: 'Please select a type',
        Buttons: {
          WithCard: 'Refund with card',
          WithoutCard: 'Refund without card',
        },
        CardMismatch: {
          Title: 'Card mismatch',
          Msg: 'Card presented for refund is not the one used for the original payment',
        },
      },
    },
    Retry: 'Try again?',
    CancelledByUser: 'Payment cancelled',
    TransactionFailed: 'Payment declined',
    TransactionSuccessful: 'Payment successful',
    RefundSuccessful: 'Refund complete',
    RefundFailed: 'Refund failed',
  },
  SwUpgrade: {
    Required: {
      Title: 'Update required',
      Msg: 'Your card reader must be updated before you can process transactions.',
    },
    Optional: {
      Title: 'Update available',
      Msg: 'An update is available for your card reader.',
    },
    Buttons: {
      Ok: 'OK',
      UpdateNow: 'Update now',
      NotNow: 'Not now',
      Retry: 'Try again',
    },
    Failed: {
      Title: 'Software update failed',
      Msg: 'We\'re sorry, the update could not be completed.',
      BatteryLow: 'Please recharge the card reader.',
    },
    Updating: {
      Title: 'Updating reader',
      Msg: 'Do not disconnect your reader',
    },
    Success: {
      Title: 'Software update successful',
    },
    Downloading: 'Downloading ${count}/${total}',
    Initializing: 'Initialising card reader... Do not disconnect',
    ValidatingSecurityKeys: 'Validating security keys... Do not disconnect',
    SecurityKeysInstalled: 'Security keys installed.',
    UpdatingWithDetails: 'Updating ${stage} ${progress}%... Do not disconnect',
    Restarting: 'Restarting card reader... Do not disconnect',
    Reconnecting: 'Reconnecting to card reader... Do not disconnect',
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
        NoTip: 'No tip',
      },
    },
    Processing: 'Processing...',
    ProcessingPinOk: 'Processing... PIN OK',
    PinOk: 'PIN OK',
    ProcessingRefund: 'Processing refund...',
    Cancelling: 'Cancelling...',
    Finalize: 'Completing payment...',
    DoNotRemove: 'Do not remove card.',
    Remove: 'Please remove card. ',
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
        NotNow: 'Not now',
      },
    },
    ConnectingFailed: {
      Title: 'Could \nnotconnect to\n${deviceId}',
      Buttons: {
        Cancel: 'OK',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
