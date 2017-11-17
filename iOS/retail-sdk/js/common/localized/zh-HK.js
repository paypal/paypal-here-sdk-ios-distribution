/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: '完成',
  Cancel: '取消',
  Ok: '確定',
  Yes: '是',
  No: '否',
  Error: '抱歉！',
  Sig: {
    Title: '向 ${cardIssuer} *${lastFour} 收取 ${amount}',
    Here: '在此簽名',
    Footer: '我同意依照信用卡相關條款支付上述金額。',
  },
  Rcpt: {
    Title: '${amount}',
    Prompt: '你需要收據嗎？',
    EmailButtonTitle: '電郵',
    SMSButtonTitle: '短訊',
    NoThanksButtonTitle: '不需要，謝謝',
    Sending: '正在發送收據...',
    Disclaimer: 'PayPal 將會發出收據。查看你的 PayPal 私隱權政策收據',
    Email: {
      Title: '電郵收據',
      Placeholder: 'me@somewhere.com',
      Disclaimer: '當我輸入電郵地址，即表示我同意就所有未來的 PayPal Here 交易接收電郵通知。',
      SendButtonTitle: '發送',
    },
    SMS: {
      Title: '文字收據',
      Placeholder: '14085551212',
      Disclaimer: '你同意你獲授權新增此手機號碼，並同意收取系統自動發出的短訊。可能需支付訊息與數據費用。PayPal 將會發出收據。查看你的 PayPal 私隱權政策收據。',
      SendButtonTitle: '發送',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: '準備就緒',
        Msg: '準備好即可拍卡、插卡或刷卡。',
      },
      EnterPin: {
        Title: '${amount}',
        Message: '請在讀卡器鍵盤上輸入 PIN 碼',
      },
      IncorrectPin: {
        Title: 'PIN 碼不正確',
        Message: 'PIN 碼不正確，請重試。',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: '準備就緒',
        Msg: '準備好即可插入信用卡或刷卡。',
      },
      ReadyForSwipeOnly: {
        Title: '請刷卡',
        Msg: '請於讀卡器頂部刷卡',
      },
      ReadyForInsertOnly: {
        Title: '準備就緒',
        Msg: '準備好即可插入信用卡。',
      },
      Cancelled: {
        Title: '已取消',
        Msg: '交易已取消',
      },
      Cancel: {
        Title: '取消',
        Msg: '要取消此交易嗎？',
      },
      TimeOut: {
        Title: '交易已逾時',
        Msg: '交易未完成。',
        Button: '取消交易',
      },
      NfcNotAllowed: {
        Title: '插入信用卡或刷卡',
        Msg: '發卡方要求你插入信用卡或刷卡。',
      },
      NfcFallback: {
        Title: '無法讀取信用卡',
        Msg: '請即插入信用卡或刷卡，或者改用其他信用卡。',
      },
      NfcPaymentDeclined: {
        Title: '已拒絕感應式交易',
        Msg: '想插入信用卡再試一次嗎？',
      },
      InsertOrSwipe: {
        Title: '插入信用卡或刷卡',
        Msg: '發卡方要求\n你插入信用卡或刷卡',
        Button: '取消交易',
      },
      IncorrectOnlinePin: {
        Title: 'PIN 碼不正確',
        Msg: '輸入的 PIN 碼不正確。請重試。',
      },
      GenericError: {
        Title: '交易已取消',
        PaymentMessage: '無法處理付款',
        RefundMessage: '無法處理退款',
      },
      TapDifferentCard: {
        Title: '無法讀取信用卡',
        Msg: '請即插入信用卡或刷卡，或按「確定」並以另一張卡拍卡',
      },
      BlockedCard: {
        Title: '已拒絕',
        Msg: '請聯絡發卡方以了解詳情',
      },
      BlockedCardInserted: {
        Title: '已拒絕',
        Msg: '請取出信用卡並聯絡發卡方以了解詳情。',
      },
      BlockedCardTapped: {
        Title: '已拒絕',
        Msg: '請聯絡發卡方以了解詳情',
      },
      BlockedCardSwiped: {
        Title: '已拒絕',
        Msg: '請聯絡發卡方以了解詳情',
      },
      ChipCardSwiped: {
        Title: '已偵測到晶片',
        Msg: '請插入信用卡',
      },
      UnsuccessfulInsert: {
        Title: '無法讀取信用卡',
        Msg: '請重試。將信用卡插入讀卡器，晶片先入，並確保插穩到底',
      },
      AmountTooLow: {
        Title: '金額過低',
        Msg: '信用卡付款的最低金額為 ${amount}。請輸入另一個金額，或選擇另一種付款方式。',
      },
      AmountTooHigh: {
        Title: '金額過高',
        Msg: '信用卡付款的最高金額為 ${amount}。請輸入另一個金額，或選擇另一種付款方式。',
      },
      Refund: {
        Title: '退款類型',
        Msg: '請選擇類型',
        Buttons: {
          WithCard: '有卡退款',
          WithoutCard: '無卡退款',
        },
        CardMismatch: {
          Title: '信用卡不符',
          Msg: '退款所用的並非原先付款時使用的信用卡',
        },
      },
    },
    Retry: '要重試嗎？',
    CancelledByUser: '付款已取消',
    TransactionFailed: '付款被拒絕',
    TransactionSuccessful: '付款成功',
    RefundSuccessful: '完成退款',
    RefundFailed: '退款失敗',
  },
  SwUpgrade: {
    Required: {
      Title: '需要更新',
      Msg: '你必須先更新讀卡器，才能繼續處理交易。',
    },
    Optional: {
      Title: '有更新可用',
      Msg: '讀卡器有更新可用。',
    },
    Buttons: {
      Ok: '確定',
      UpdateNow: '立即更新',
      NotNow: '稍後再說',
      Retry: '重試',
    },
    Failed: {
      Title: '軟件更新失敗',
      Msg: '抱歉，更新無法完成。',
      BatteryLow: '請為讀卡器充電。',
    },
    Updating: {
      Title: '正在更新讀卡器',
      Msg: '請勿中途拔除讀卡器',
    },
    Success: {
      Title: '軟件更新成功',
    },
    Downloading: '正在下載 ${count}/${total}',
    Initializing: '正在啟動讀卡器…請勿中途拔除裝置',
    ValidatingSecurityKeys: '正在驗證安全金匙…請勿中途拔除裝置',
    SecurityKeysInstalled: '已安裝安全金匙。',
    UpdatingWithDetails: '正在更新 ${stage} ${progress}%…請勿中途拔除裝置',
    Restarting: '正在重新啟動讀卡器…請勿中途拔除裝置',
    Reconnecting: '正在重新連接讀卡器…請勿中途拔除裝置',
    Connected: '已連接',
    Usb: {
      UsbUnplug: '請拔除 USB 讀卡器，然後按「確定」',
      UsbWait: '請稍後再插入 USB 讀卡器。',
      UsbPlug: '請重新連接 USB 讀卡器。',
    },
  },
  EMV: {
    Tip: {
      Title: '正在等待客戶輸入資料...',
      Buttons: {
        NoTip: '沒有小費',
      },
    },
    Processing: '處理中...',
    ProcessingPinOk: '處理中...PIN 碼確認',
    PinOk: 'PIN 碼確認',
    ProcessingRefund: '正在處理退款...',
    Cancelling: '正在取消…',
    Finalize: '正在完成付款…',
    DoNotRemove: '請勿取出信用卡。',
    Remove: '請取出信用卡。',
    Complete: '已支付 ${amount}',
    RefundComplete: '已退回 ${amount}',
    Select: '選擇應用程式：',
  },
  MultiCard: {
    Title: '選擇裝置',
    Msg: '請選擇你要使用的 PayPal 讀卡器：',
  },
  Device: {
    Connecting: {
      Title: '正在連接\n${deviceId}',
    },
    RetryConnecting: {
      Title: '你要連接\n${deviceId} 嗎',
      Message: '請確保裝置並非處於休眠狀態',
      Buttons: {
        Retry: '重試',
        NotNow: '稍後再說',
      },
    },
    ConnectingFailed: {
      Title: '無法\n連接\n${deviceId}',
      Buttons: {
        Cancel: '確定',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
