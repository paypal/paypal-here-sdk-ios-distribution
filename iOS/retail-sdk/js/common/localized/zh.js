/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: '完成',
  Cancel: '取消',
  Ok: '确定',
  Yes: '是',
  No: '否',
  Error: '糟糕！',
  Sig: {
    Title: '从${cardIssuer} *${lastFour}收取${amount}',
    Here: '在此签名',
    Footer: '我同意根据适用于我的卡的条款支付以上金额。',
  },
  Rcpt: {
    Title: '${amount}',
    Prompt: '您要收据吗？',
    EmailButtonTitle: '电子邮件',
    SMSButtonTitle: '短信',
    NoThanksButtonTitle: '不，谢谢',
    Sending: '正在发送收据……',
    Disclaimer: '收据将由PayPal递送。请查看您的收据，了解PayPal的《隐私权保护规则》',
    Email: {
      Title: '电子邮件收据',
      Placeholder: 'me@somewhere.com',
      Disclaimer: '输入我的电子邮件地址即表示，我同意接收所有有关日后PayPal Here交易的电子邮件。',
      SendButtonTitle: '发送',
    },
    SMS: {
      Title: '短信收据',
      Placeholder: '14085551212',
      Disclaimer: '您同意您有权添加此电话号码并同意接收自动发送的短信。运营商可能会收取信息费和数据费。收据将由PayPal递送。请查看您的收据，了解PayPal的《隐私权保护规则》。',
      SendButtonTitle: '发送',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: '做好准备',
        Msg: '准备好后，轻触一下，然后插入卡或刷卡。',
      },
      EnterPin: {
        Title: '${amount}',
        Message: '请在读卡机键盘上输入识别码',
      },
      IncorrectPin: {
        Title: '识别码不正确',
        Message: '识别码不正确。请重试。',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: '做好准备',
        Msg: '准备好后，插入卡或刷卡。',
      },
      ReadyForSwipeOnly: {
        Title: '请刷卡',
        Msg: '在读卡机顶部刷卡。',
      },
      ReadyForInsertOnly: {
        Title: '做好准备',
        Msg: '准备好后，插入卡。',
      },
      Cancelled: {
        Title: '已取消',
        Msg: '交易已取消',
      },
      Cancel: {
        Title: '取消',
        Msg: '您要取消此交易吗？',
      },
      TimeOut: {
        Title: '交易已超时',
        Msg: '交易未完成。',
        Button: '取消交易',
      },
      NfcNotAllowed: {
        Title: '插入卡或刷卡',
        Msg: '发卡方要求您插入卡或刷卡。',
      },
      NfcFallback: {
        Title: '无法读卡',
        Msg: '请插入卡或刷卡，或尝试使用另一张卡。',
      },
      NfcPaymentDeclined: {
        Title: '非接触式交易被拒绝',
        Msg: '是否要重新尝试插卡？',
      },
      InsertOrSwipe: {
        Title: '插入卡或刷卡',
        Msg: '发卡方要求\n您插入卡或刷卡。',
        Button: '取消交易',
      },
      IncorrectOnlinePin: {
        Title: '识别码不正确',
        Msg: '输入的识别码不正确。请重试。',
      },
      GenericError: {
        Title: '交易已取消',
        PaymentMessage: '无法处理付款',
        RefundMessage: '无法处理退款',
      },
      TapDifferentCard: {
        Title: '无法读卡',
        Msg: '现在，请插入卡或刷卡，或按“确定”并轻触另一张卡',
      },
      BlockedCard: {
        Title: '被拒绝',
        Msg: '如需了解更多信息，请联系发卡方',
      },
      BlockedCardInserted: {
        Title: '被拒绝',
        Msg: '请移除卡并联系发卡方了解更多信息',
      },
      BlockedCardTapped: {
        Title: '被拒绝',
        Msg: '如需了解更多信息，请联系发卡方',
      },
      BlockedCardSwiped: {
        Title: '被拒绝',
        Msg: '如需了解更多信息，请联系发卡方',
      },
      ChipCardSwiped: {
        Title: '已检测到芯片卡',
        Msg: '请插入卡',
      },
      UnsuccessfulInsert: {
        Title: '无法读卡',
        Msg: '请重试。将卡稳固地插入到读卡机的底部，有芯片的一端在前',
      },
      AmountTooLow: {
        Title: '金额太低',
        Msg: '卡付款的最低金额为${amount}。请输入其他金额，或选择不同的付款方式。',
      },
      AmountTooHigh: {
        Title: '金额太高',
        Msg: '卡付款的最高金额为${amount}。请输入其他金额，或选择不同的付款方式。',
      },
      Refund: {
        Title: '退款类型',
        Msg: '请选择一种类型',
        Buttons: {
          WithCard: '有卡退款',
          WithoutCard: '无卡退款',
        },
        CardMismatch: {
          Title: '卡不一致',
          Msg: '用于退款的卡不是原付款所用的卡',
        },
      },
    },
    Retry: '重试？',
    CancelledByUser: '付款已取消',
    TransactionFailed: '付款被拒绝',
    TransactionSuccessful: '付款成功',
    RefundSuccessful: '退款完成',
    RefundFailed: '退款失败',
  },
  SwUpgrade: {
    Required: {
      Title: '需要更新',
      Msg: '您的读卡机必须先更新才能处理交易。',
    },
    Optional: {
      Title: '有可用的更新',
      Msg: '您的读卡机有可用的更新。',
    },
    Buttons: {
      Ok: '确定',
      UpdateNow: '立即更新',
      NotNow: '以后再说',
      Retry: '重新尝试',
    },
    Failed: {
      Title: '软件更新失败',
      Msg: '很抱歉，更新无法完成。',
      BatteryLow: '请为读卡机充电。',
    },
    Updating: {
      Title: '正在更新读卡机',
      Msg: '请不要断开读卡机',
    },
    Success: {
      Title: '软件更新成功',
    },
    Downloading: '正在下载${count}/${total}',
    Initializing: '正在初始化读卡机......请不要断开',
    ValidatingSecurityKeys: '正在验证密钥......请不要断开',
    SecurityKeysInstalled: '密钥已安装。',
    UpdatingWithDetails: '正在更新${stage} ${progress}%......请不要断开',
    Restarting: '正在重新启动读卡机......请不要断开',
    Reconnecting: '正在重新连接到读卡机......请不要断开',
    Connected: '已连接',
    Usb: {
      UsbUnplug: '请拔下USB读卡机，然后按“确定”',
      UsbWait: '请稍等片刻，然后插入USB读卡机。',
      UsbPlug: '请重新连接USB读卡机。',
    },
  },
  EMV: {
    Tip: {
      Title: '正在等待客户输入……',
      Buttons: {
        NoTip: '没有小费',
      },
    },
    Processing: '正在处理……',
    ProcessingPinOk: '正在处理……识别码有效',
    PinOk: '识别码有效',
    ProcessingRefund: '正在处理退款…',
    Cancelling: '正在取消...',
    Finalize: '正在完成付款…',
    DoNotRemove: '不要取出卡。',
    Remove: '请取出卡。',
    Complete: '已支付${amount}',
    RefundComplete: '已退还${amount}',
    Select: '选择应用程序：',
  },
  MultiCard: {
    Title: '选择设备',
    Msg: '请选择您要使用的PayPal读卡机：',
  },
  Device: {
    Connecting: {
      Title: '正在连接到\n${deviceId}',
    },
    RetryConnecting: {
      Title: '您是否要连接到\n${deviceId}',
      Message: '请确保设备处于活动状态',
      Buttons: {
        Retry: '重试',
        NotNow: '以后再说',
      },
    },
    ConnectingFailed: {
      Title: '无法\n连接到\n${deviceId}',
      Buttons: {
        Cancel: '确定',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
