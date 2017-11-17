/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: 'Listo',
  Cancel: 'Cancelar',
  Ok: 'Aceptar',
  Yes: 'Sí',
  No: 'No',
  Error: 'Lo sentimos.',
  Sig: {
    Title: 'Realizar cargo de ${amount} USD a ${cardIssuer} *${lastFour}',
    Here: 'Firme aquí',
    Footer: 'Acepto pagar el importe indicado más arriba de acuerdo con las condiciones que se aplican a mi tarjeta.',
  },
  Rcpt: {
    Title: '${amount} USD',
    Prompt: '¿Desea un recibo?',
    EmailButtonTitle: 'Correo electrónico',
    SMSButtonTitle: 'Texto',
    NoThanksButtonTitle: 'No, gracias',
    Sending: 'Enviando recibo...',
    Disclaimer: 'PayPal enviará los recibos. Consulte  la Política de Privacidad de PayPal en el recibo',
    Email: {
      Title: 'RECIBO POR CORREO ELECTRÓNICO',
      Placeholder: 'me@somewhere.com',
      Disclaimer: 'Al ingresar mi correo electrónico, acepto recibir correos electrónicos de todas las transacciones futuras con PayPal Here.',
      SendButtonTitle: 'Enviar',
    },
    SMS: {
      Title: 'Recibo por mensaje de texto',
      Placeholder: '14085551212',
      Disclaimer: 'Acepta que está autorizado para asociar este número de teléfono y acepta recibir mensajes de texto automáticos. Podrían aplicar comisiones por mensajes y datos. PayPal enviará los recibos. Consulte la Política de Privacidad de PayPal en el recibo.',
      SendButtonTitle: 'Enviar',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: 'Listo',
        Msg: 'Acerque, inserte o deslice su tarjeta cuando esté listo.',
      },
      EnterPin: {
        Title: '${amount} USD',
        Message: 'Ingrese el NIP en el teclado numérico del lector de tarjetas',
      },
      IncorrectPin: {
        Title: 'NIP incorrecto',
        Message: 'El NIP es incorrecto. Inténtelo de nuevo.',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: 'Listo',
        Msg: 'Inserte o deslice una tarjeta cuando esté listo.',
      },
      ReadyForSwipeOnly: {
        Title: 'Deslice la tarjeta',
        Msg: 'Deslice la tarjeta en la parte superior del lector',
      },
      ReadyForInsertOnly: {
        Title: 'Listo',
        Msg: 'Inserte una tarjeta cuando esté listo.',
      },
      Cancelled: {
        Title: 'Cancelada',
        Msg: 'Transacción cancelada',
      },
      Cancel: {
        Title: 'Cancelar',
        Msg: '¿Desea cancelar esta transacción?',
      },
      TimeOut: {
        Title: 'Se ha agotado el tiempo de espera para la transacción',
        Msg: 'La transacción no se ha completado.',
        Button: 'Cancelar transacción',
      },
      NfcNotAllowed: {
        Title: 'Inserte o deslice la tarjeta',
        Msg: 'El proveedor de la tarjeta requiere que inserte o deslice la tarjeta.',
      },
      NfcFallback: {
        Title: 'No se puede leer la tarjeta',
        Msg: 'Inserte o deslice la tarjeta ahora o intente con otra tarjeta.',
      },
      NfcPaymentDeclined: {
        Title: 'Transacción sin contacto declinada',
        Msg: '¿Desea intentar de nuevo insertando la tarjeta?',
      },
      InsertOrSwipe: {
        Title: 'Inserte o deslice la tarjeta',
        Msg: 'El emisor de la tarjeta requiere\nque inserte o deslice la tarjeta',
        Button: 'Cancelar transacción',
      },
      IncorrectOnlinePin: {
        Title: 'NIP incorrecto',
        Msg: 'El NIP que ingresó es incorrecto. Inténtelo de nuevo.',
      },
      GenericError: {
        Title: 'Transacción cancelada',
        PaymentMessage: 'No se puede procesar el pago',
        RefundMessage: 'No se puede procesar el reembolso',
      },
      TapDifferentCard: {
        Title: 'No es posible leer la tarjeta',
        Msg: 'Inserte o deslice la tarjeta ahora, o haga clic en Aceptar y acerque otra tarjeta',
      },
      BlockedCard: {
        Title: 'Declinada',
        Msg: 'Comuníquese con el emisor de la tarjeta para obtener más información',
      },
      BlockedCardInserted: {
        Title: 'Declinada',
        Msg: 'Retire la tarjeta y comuníquese con el emisor de la tarjeta para obtener más información.',
      },
      BlockedCardTapped: {
        Title: 'Declinada',
        Msg: 'Comuníquese con el emisor de la tarjeta para obtener más información',
      },
      BlockedCardSwiped: {
        Title: 'Declinada',
        Msg: 'Comuníquese con el emisor de la tarjeta para obtener más información',
      },
      ChipCardSwiped: {
        Title: 'Tarjeta con chip detectada',
        Msg: 'Inserte la tarjeta',
      },
      UnsuccessfulInsert: {
        Title: 'No es posible leer la tarjeta',
        Msg: 'Inténtelo de nuevo. Inserte firmemente la tarjeta, introduciendo el chip primero, en la parte inferior del lector',
      },
      AmountTooLow: {
        Title: 'Importe demasiado bajo',
        Msg: 'El importe mínimo para pagos con tarjeta es ${amount} USD. Ingrese un importe nuevo o elija una forma de pago diferente.',
      },
      AmountTooHigh: {
        Title: 'Importe demasiado alto',
        Msg: 'El importe máximo para pagos con tarjeta es ${amount} USD. Ingrese un importe nuevo o elija una forma de pago diferente.',
      },
      Refund: {
        Title: 'Tipo de reembolso',
        Msg: 'Seleccione un tipo',
        Buttons: {
          WithCard: 'Reembolso con tarjeta',
          WithoutCard: 'Reembolso sin tarjeta',
        },
        CardMismatch: {
          Title: 'La tarjeta no coincide',
          Msg: 'La tarjeta presentada para el reembolso no es la que se utilizó para el pago original',
        },
      },
    },
    Retry: 'Volver a intentar',
    CancelledByUser: 'Pago cancelado',
    TransactionFailed: 'Pago declinado',
    TransactionSuccessful: 'El pago ha sido realizado correctamente',
    RefundSuccessful: 'Reembolso completado',
    RefundFailed: 'Reembolso erróneo',
  },
  SwUpgrade: {
    Required: {
      Title: 'Actualización necesaria',
      Msg: 'El lector de tarjetas debe estar actualizado antes de que pueda procesar transacciones.',
    },
    Optional: {
      Title: 'Actualización disponible',
      Msg: 'Hay una actualización disponible para su lector de tarjetas.',
    },
    Buttons: {
      Ok: 'Aceptar',
      UpdateNow: 'Actualizar ahora',
      NotNow: 'Ahora no',
      Retry: 'Inténtelo de nuevo',
    },
    Failed: {
      Title: 'Actualización del software errónea',
      Msg: 'No se ha podido completar la actualización.',
      BatteryLow: 'Recargue el lector de tarjetas.',
    },
    Updating: {
      Title: 'Actualizando el lector de tarjetas',
      Msg: 'No desconecte su lector de tarjetas',
    },
    Success: {
      Title: 'Actualización de software correcta',
    },
    Downloading: 'Descargando ${count} de ${total}',
    Initializing: 'Inicializando el lector de tarjetas... No desconectar',
    ValidatingSecurityKeys: 'Validando claves de seguridad... No desconectar',
    SecurityKeysInstalled: 'Claves de seguridad instaladas.',
    UpdatingWithDetails: 'Actualizando ${stage} de ${progress}%... No desconectar',
    Restarting: 'Reiniciando el lector de tarjetas... No desconectar',
    Reconnecting: 'Reconectando al lector de tarjetas... No desconectar',
    Connected: 'Conectado',
    Usb: {
      UsbUnplug: 'Desconecte su lector de USB y haga clic en Aceptar',
      UsbWait: 'Espere antes de conectar al lector de USB.',
      UsbPlug: 'Vuelva a conectar su lector de USB.',
    },
  },
  EMV: {
    Tip: {
      Title: 'Esperando a que el cliente ingrese la información…',
      Buttons: {
        NoTip: 'Sin propina',
      },
    },
    Processing: 'Procesando...',
    ProcessingPinOk: 'Procesando... NIP OK',
    PinOk: 'NIP OK',
    ProcessingRefund: 'Procesando reembolso...',
    Cancelling: 'Cancelando...',
    Finalize: 'Completando el pago...',
    DoNotRemove: 'No retire la tarjeta.',
    Remove: 'Retire la tarjeta',
    Complete: '${amount} USD pagado',
    RefundComplete: '${amount} USD reembolsado',
    Select: 'Elija una solicitud:',
  },
  MultiCard: {
    Title: 'Seleccione un dispositivo',
    Msg: 'Seleccione el lector de tarjetas de PayPal que desea utilizar:',
  },
  Device: {
    Connecting: {
      Title: 'Conectando a\n${deviceId}',
    },
    RetryConnecting: {
      Title: '¿Desea conectarse a\n${deviceId}?',
      Message: 'Asegúrese de que el dispositivo no esté suspendido',
      Buttons: {
        Retry: 'Volver a intentarlo',
        NotNow: 'Ahora no',
      },
    },
    ConnectingFailed: {
      Title: 'No fue posible\nconectarse a\n${deviceId}',
      Buttons: {
        Cancel: 'Aceptar',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
