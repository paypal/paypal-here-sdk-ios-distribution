/* eslint-disable no-template-curly-in-string, max-len */

module.exports = {
  Done: 'Terminé',
  Cancel: 'Annuler',
  Ok: 'OK',
  Yes: 'Oui',
  No: 'Non',
  Error: '',
  Sig: {
    Title: 'Débiter {amount} $ à ${cardIssuer} *${lastFour}',
    Here: 'Signez ici',
    Footer: 'J\'accepte de payer le montant ci-dessus conformément aux conditions applicables à ma carte.',
  },
  Rcpt: {
    Title: '{amount} $',
    Prompt: 'Voulez-vous un reçu ?',
    EmailButtonTitle: 'Email',
    SMSButtonTitle: 'SMS',
    NoThanksButtonTitle: 'Non, merci',
    Sending: 'Envoi du reçu...',
    Disclaimer: 'Les reçus seront envoyés par PayPal.  Consulter le règlement de PayPal sur le respect de la vie privée par rapport aux reçus',
    Email: {
      Title: 'REÇU PAR EMAIL',
      Placeholder: 'moi@quelquepart.com',
      Disclaimer: 'En indiquant mon adresse email, j\'accepte de recevoir des emails pour toutes mes transactions PayPal Here ultérieures.',
      SendButtonTitle: 'Envoyer',
    },
    SMS: {
      Title: 'REÇU PAR SMS',
      Placeholder: '14085551212',
      Disclaimer: 'Vous avez accepté d\'ajouter ce numéro de téléphone et de recevoir des SMS envoyés automatiquement. Les messages et les données pourront être facturés.  Les reçus seront envoyés par PayPal.  Consulter le règlement de PayPal sur le respect de la vie privée par rapport aux reçus.',
      SendButtonTitle: 'Envoyer',
    },
  },
  Tx: {
    Alert: {
      Ready: {
        Title: 'Prêt',
        Msg: 'Présentez, insérez ou passez une carte quand vous êtes prêt.',
      },
      EnterPin: {
        Title: '{amount} $',
        Message: 'Saisissez le code sur le clavier du lecteur de cartes',
      },
      IncorrectPin: {
        Title: 'Code incorrect',
        Message: 'Le code est incorrect.  Merci de réessayer.',
      },
      ReadyForInsertOrSwipeOnly: {
        Title: 'Prêt',
        Msg: 'Insérez ou passez une carte quand vous êtes prêt.',
      },
      ReadyForSwipeOnly: {
        Title: 'Passez la carte',
        Msg: 'Passez la carte en haut du lecteur',
      },
      ReadyForInsertOnly: {
        Title: 'Prêt',
        Msg: 'Insérer une carte quand vous êtes prêt.',
      },
      Cancelled: {
        Title: 'Annulé',
        Msg: 'Transaction annulée',
      },
      Cancel: {
        Title: 'Annuler',
        Msg: 'Voulez-vous annuler cette transaction ?',
      },
      TimeOut: {
        Title: 'Transaction expirée',
        Msg: 'La transaction n\'a pas été effectuée.',
        Button: 'Annuler la transaction',
      },
      NfcNotAllowed: {
        Title: 'Insérez la carte ou passez-la dans le lecteur',
        Msg: 'L’émetteur de la carte exige que vous insériez ou passiez la carte.',
      },
      NfcFallback: {
        Title: 'Impossible de lire la carte',
        Msg: 'Insérez ou passez la carte maintenant ou essayez une autre carte.',
      },
      NfcPaymentDeclined: {
        Title: 'Transaction sans contact refusée',
        Msg: 'Voulez-vous réessayer en insérant la carte ?',
      },
      InsertOrSwipe: {
        Title: 'Insérez la carte ou passez-la dans le lecteur',
        Msg: 'L’émetteur de la carte exige que vous insériez ou passiez la carte',
        Button: 'Annuler la transaction',
      },
      IncorrectOnlinePin: {
        Title: 'Code incorrect',
        Msg: 'Le code saisi est incorrect. Merci de réessayer.',
      },
      GenericError: {
        Title: 'Transaction annulée',
        PaymentMessage: 'Impossible de traiter le paiement',
        RefundMessage: 'Impossible de traiter le remboursement',
      },
      TapDifferentCard: {
        Title: 'Impossible de lire la carte',
        Msg: 'Insérez ou passez la carte maintenant ou appuyez sur OK et présentez une autre carte',
      },
      BlockedCard: {
        Title: 'Refusé',
        Msg: 'Contactez l\'émetteur de la carte pour plus d\'informations',
      },
      BlockedCardInserted: {
        Title: 'Refusé',
        Msg: 'Retirez la carte et contactez son émetteur pour plus d\'informations.',
      },
      BlockedCardTapped: {
        Title: 'Refusé',
        Msg: 'Contactez l\'émetteur de la carte pour plus d\'informations',
      },
      BlockedCardSwiped: {
        Title: 'Refusé',
        Msg: 'Contactez l\'émetteur de la carte pour plus d\'informations',
      },
      ChipCardSwiped: {
        Title: 'Carte à puce détectée',
        Msg: 'Insérez votre carte',
      },
      UnsuccessfulInsert: {
        Title: 'Impossible de lire la carte',
        Msg: 'Merci de réessayer. Insérez fermement la carte, avec la puce en premier, en bas du lecteur',
      },
      AmountTooLow: {
        Title: 'Montant trop bas',
        Msg: 'Le montant minimum pour effectuer un paiement par carte bancaire est de {amount} $. Saisissez un autre montant ou choisissez un autre mode de paiement.',
      },
      AmountTooHigh: {
        Title: 'Montant trop élevé',
        Msg: 'Le montant maximum pour effectuer un paiement par carte bancaire est de {amount} $. Saisissez un autre montant ou choisissez un autre mode de paiement.',
      },
      Refund: {
        Title: 'Type de remboursement',
        Msg: 'Sélectionnez un type',
        Buttons: {
          WithCard: 'Remboursement par carte',
          WithoutCard: 'Remboursement sans carte',
        },
        CardMismatch: {
          Title: 'Carte différente',
          Msg: 'La carte présentée pour le remboursement ne correspond pas à celle utilisée pour le paiement initial',
        },
      },
    },
    Retry: 'Essayer à nouveau ?',
    CancelledByUser: 'Paiement annulé',
    TransactionFailed: 'Paiement refusé',
    TransactionSuccessful: 'Paiement réussi',
    RefundSuccessful: 'Remboursement effectué',
    RefundFailed: 'Échec du remboursement',
  },
  SwUpgrade: {
    Required: {
      Title: 'Mettre à jour',
      Msg: 'Vous devez mettre à jour votre lecteur de carte pour pouvoir traiter des transactions.',
    },
    Optional: {
      Title: 'Mise à jour disponible',
      Msg: 'Une mise à jour est disponible pour votre lecteur de carte.',
    },
    Buttons: {
      Ok: 'Ok',
      UpdateNow: 'Mettre à jour maintenant',
      NotNow: 'Pas maintenant',
      Retry: 'Essayez à nouveau',
    },
    Failed: {
      Title: 'Échec de la mise à jour du logiciel',
      Msg: 'La mise à jour n\'a pas pu être effectuée.',
      BatteryLow: 'Rechargez le lecteur de carte.',
    },
    Updating: {
      Title: 'Mise à jour du lecteur de cartes',
      Msg: 'Ne déconnectez pas votre lecteur de cartes',
    },
    Success: {
      Title: 'Mise à jour du logiciel réussie',
    },
    Downloading: 'Téléchargement de {count} $/{total} $',
    Initializing: 'Initialisation du lecteur de carte... Ne pas déconnecter',
    ValidatingSecurityKeys: 'Validation des clés de sécurité... Ne pas déconnecter',
    SecurityKeysInstalled: 'Clés de sécurité installées.',
    UpdatingWithDetails: 'Mise à jour de ${stage} ${progress} %... Ne pas déconnecter',
    Restarting: 'Redémarrage du lecteur de carte... Ne pas déconnecter',
    Reconnecting: 'Reconnexion au lecteur de carte... Ne pas déconnecter',
    Connected: 'Connecté',
    Usb: {
      UsbUnplug: 'Débranchez votre lecteur USB et appuyez sur OK',
      UsbWait: 'Veuillez patienter avant de brancher votre lecteur USB.',
      UsbPlug: 'Reconnectez votre lecteur USB.',
    },
  },
  EMV: {
    Tip: {
      Title: 'En attente des données du client…',
      Buttons: {
        NoTip: 'Pas de pourboire',
      },
    },
    Processing: 'Traitement en cours...',
    ProcessingPinOk: 'Traitement en cours... Code OK',
    PinOk: 'Code OK',
    ProcessingRefund: 'Remboursement en cours...',
    Cancelling: 'Annulation...',
    Finalize: 'Paiement en cours...',
    DoNotRemove: 'Ne retirez pas la carte.',
    Remove: 'Retirez la carte. ',
    Complete: '{amount} $ réglé',
    RefundComplete: '{amount} $ remboursé',
    Select: 'Choisissez une application :',
  },
  MultiCard: {
    Title: 'Sélectionnez un appareil',
    Msg: 'Sélectionnez le lecteur de cartes PayPal à utiliser :',
  },
  Device: {
    Connecting: {
      Title: 'Connexion à\n${deviceId}',
    },
    RetryConnecting: {
      Title: 'Souhaitez-vous connecter à\n${deviceId}',
      Message: 'Vérifiez que l’appareil est allumé',
      Buttons: {
        Retry: 'Réessayer',
        NotNow: 'Pas maintenant',
      },
    },
    ConnectingFailed: {
      Title: 'Impossible de se connecter à\n${deviceId}',
      Buttons: {
        Cancel: 'OK',
      },
    },
  },
};
/* eslint-enable no-template-curly-in-string, max-len */
