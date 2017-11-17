/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: '完了',
  Cancel: 'キャンセル',
  Ok: 'OK',
  Yes: 'はい',
  No: 'いいえ',
  Error: '申し訳ありません。',
  Sig: {
    Title: '${cardIssuer}　*${lastFour}に${amount}を請求します',
    Here: 'ここにサイン',
    Footer: 'カードに適用される利用条件に従い、上記の金額を支払うことに同意します。',
  },
  Rcpt: {
    Title: '${amount}',
    Prompt: 'レシートを発行しますか? ',
    EmailButtonTitle: 'メール',
    SMSButtonTitle: 'テキスト',
    NoThanksButtonTitle: '不要',
    Sending: 'レシートを送信中…',
    Disclaimer: 'レシートはPayPalからお送りします。PayPalのプライバシーポリシーについては、レシートをご確認ください',
    Email: {
      Title: 'メールで送信',
      Placeholder: 'me@somewhere.com',
      Disclaimer: 'メールアドレスを入力することで、今後のすべてのPayPal Here取引についてメールを受け取ることに同意します。',
      SendButtonTitle: '送信',
    },
    SMS: {
      Title: 'SMSで送信',
      Placeholder: '14085551212',
      Disclaimer: 'この電話番号を追加する権限があることと、自動送信メールを受け取ることに同意します。メール・データ料金が適用される場合があります。レシートはPayPalからお送りします。PayPalのプライバシーポリシーについては、レシートをご確認ください。',
      SendButtonTitle: '送信',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: '準備完了',
        Msg: '用意ができたらカードをタップ、挿入、またはスワイプします。',
      },
      EnterPin: {
        Title: '${amount}',
        Message: 'カードリーダーのキーパッドに暗証番号を入力してください',
      },
      IncorrectPin: {
        Title: '暗証番号が間違っています',
        Message: '暗証番号が間違っています。もう一度お試しください。',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: '準備完了',
        Msg: '用意ができたらカードを挿入またはスワイプします。',
      },
      ReadyForSwipeOnly: {
        Title: 'カードをリーダーに通してください',
        Msg: 'カードをリーダーの上部で通してください',
      },
      ReadyForInsertOnly: {
        Title: '準備完了',
        Msg: '用意ができたらカードを挿入します。',
      },
      Cancelled: {
        Title: 'キャンセルされました',
        Msg: '取引がキャンセルされました',
      },
      Cancel: {
        Title: 'キャンセル',
        Msg: 'この取引をキャンセルしますか? ',
      },
      TimeOut: {
        Title: '取引がタイムアウトになりました',
        Msg: '取引は完了しませんでした。',
        Button: '取引のキャンセル',
      },
      NfcNotAllowed: {
        Title: 'カードの挿入またはリーダーに通す',
        Msg: 'クレジットカード会社により、カードの挿入またはスワイプが求められています。',
      },
      NfcFallback: {
        Title: 'カードを読み取れません',
        Msg: 'カードを挿入するかスワイプしてください。または別のカードをお試しください。',
      },
      NfcPaymentDeclined: {
        Title: '非接触式取引が拒否されました',
        Msg: 'カードを挿入して再度実行しますか? ',
      },
      InsertOrSwipe: {
        Title: 'カードの挿入またはスワイプ',
        Msg: 'カード会社により、\nカードの挿入またはスワイプが求められています',
        Button: '取引のキャンセル',
      },
      IncorrectOnlinePin: {
        Title: '暗証番号が間違っています',
        Msg: '入力された暗証番号が正しくありません。もう一度お試しください。',
      },
      GenericError: {
        Title: '取引がキャンセルされました',
        PaymentMessage: '支払いを実行できません',
        RefundMessage: '返金を実行できません',
      },
      TapDifferentCard: {
        Title: 'カードを読み取れません',
        Msg: 'カードを挿入するかスワイプしてください。または[OK]を押して別のカードをタップしてください。',
      },
      BlockedCard: {
        Title: '拒否済み',
        Msg: '詳細についてはカード会社にお問い合わせください',
      },
      BlockedCardInserted: {
        Title: '拒否済み',
        Msg: 'カードを取り外し、カード会社に詳細をお問い合わせください',
      },
      BlockedCardTapped: {
        Title: '拒否済み',
        Msg: '詳細についてはカード会社にお問い合わせください',
      },
      BlockedCardSwiped: {
        Title: '拒否済み',
        Msg: '詳細についてはカード会社にお問い合わせください',
      },
      ChipCardSwiped: {
        Title: 'ICカードを認識しました',
        Msg: 'カードを挿入してください',
      },
      UnsuccessfulInsert: {
        Title: 'カードを読み取れません',
        Msg: 'もう一度お試しください。カードリーダーの下部にある挿入口にICチップ側を先にしてカードをしっかり入れます',
      },
      AmountTooLow: {
        Title: '金額が低すぎます',
        Msg: 'カード支払いの場合の最低ご利用額は${amount}です。金額を入力し直すか、別の支払方法をお選びください。',
      },
      AmountTooHigh: {
        Title: '金額が高すぎます',
        Msg: 'カード支払いの場合のご利用最高額は${amount}です。金額を入力し直すか、別の支払方法をお選びください。',
      },
      Refund: {
        Title: '返金の種類',
        Msg: '種類を選択してください',
        Buttons: {
          WithCard: 'カードを使用して返金',
          WithoutCard: 'カードを使用せずに返金',
        },
        CardMismatch: {
          Title: 'カードが一致しません',
          Msg: '返金用に提示されたカードは最初の支払い時に使用されたものではありません',
        },
      },
    },
    Retry: '再度実行しますか? ',
    CancelledByUser: '支払いのキャンセル',
    TransactionFailed: '支払いが拒否されました',
    TransactionSuccessful: '支払い完了',
    RefundSuccessful: '返金が完了しました',
    RefundFailed: '返金に失敗しました',
  },
  SwUpgrade: {
    Required: {
      Title: '更新が必要です',
      Msg: '取引を処理する前に、カードリーダーを更新する必要があります。',
    },
    Optional: {
      Title: '更新を利用できます',
      Msg: 'カードリーダーの更新を利用できます。',
    },
    Buttons: {
      Ok: 'OK',
      UpdateNow: '今すぐ更新する',
      NotNow: '後で実行',
      Retry: '再度実行',
    },
    Failed: {
      Title: 'ソフトウェアの更新に失敗しました',
      Msg: '申し訳ありませんが、更新を完了できませんでした。',
      BatteryLow: 'カードリーダーを充電してください。',
    },
    Updating: {
      Title: 'カードリーダーを更新しています',
      Msg: 'カードリーダーを取り外さないでください',
    },
    Success: {
      Title: 'ソフトウェアの更新が完了しました',
    },
    Downloading: '${count}/${total}をダウンロードしています',
    Initializing: 'カードリーダーを初期化中...取り外さないでください',
    ValidatingSecurityKeys: 'セキュリティキーを確認しています...取り外さないでください',
    SecurityKeysInstalled: 'セキュリティキーをインストールしました。',
    UpdatingWithDetails: '${stage} ${progress}%を更新しています...取り外さないでください',
    Restarting: 'カードリーダーを再起動しています....取り外さないでください',
    Reconnecting: 'カードリーダーに再接続しています...取り外さないでください',
    Connected: '接続済みです',
    Usb: {
      UsbUnplug: 'USBリーダーを抜いて[OK]を押してください',
      UsbWait: '時間をおいてからUSBリーダーを接続してください。',
      UsbPlug: 'USBリーダーを再度接続してください。',
    },
  },
  EMV: {
    Tip: {
      Title: '顧客の入力を待機中…',
      Buttons: {
        NoTip: 'チップ不要',
      },
    },
    Processing: '処理中...',
    ProcessingPinOk: '処理中...暗証番号はOKです',
    PinOk: '暗証番号はOKです',
    ProcessingRefund: '返金処理中...',
    Cancelling: '取消中...',
    Finalize: '支払い処理を完了中...',
    DoNotRemove: 'カードを取り出さないでください。',
    Remove: 'カードを取り出してください。',
    Complete: '${amount}を支払いました',
    RefundComplete: '${amount}を返金しました',
    Select: 'アプリを選択します: ',
  },
  MultiCard: {
    Title: '端末を選択します',
    Msg: '使用するPayPalカードリーダーを選択してください: ',
  },
  Device: {
    Connecting: {
      Title: '${deviceId}に\n接続しています',
    },
    RetryConnecting: {
      Title: '${deviceId}に\n接続しますか? ',
      Message: '端末が起動していることを確認します',
      Buttons: {
        Retry: '再度実行',
        NotNow: '後で実行',
      },
    },
    ConnectingFailed: {
      Title: '${deviceId}に\n接続できません\nでした',
      Buttons: {
        Cancel: 'OK',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
