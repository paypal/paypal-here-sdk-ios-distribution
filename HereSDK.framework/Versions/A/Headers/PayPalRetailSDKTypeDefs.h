@class PPRetailSDK;
@class PPRetailError;
@class PPRetailPayPalErrorInfo;
@class PPRetailAccountSummary;
@class PPRetailAccountSummarySection;
@class PPRetailInvoiceAddress;
@class PPRetailInvoiceAttachment;
@class PPRetailInvoiceBillingInfo;
@class PPRetailInvoiceCCInfo;
@class PPRetailCountries;
@class PPRetailCountry;
@class PPRetailInvoiceCustomAmount;
@class PPRetailInvoice;
@class PPRetailInvoiceActions;
@class PPRetailInvoiceListRequest;
@class PPRetailInvoiceListResponse;
@class PPRetailInvoiceMetaData;
@class PPRetailInvoiceTemplatesResponse;
@class PPRetailInvoicingService;
@class PPRetailInvoiceItem;
@class PPRetailInvoiceMerchantInfo;
@class PPRetailInvoiceNotification;
@class PPRetailInvoicePayment;
@class PPRetailInvoicePaymentTerm;
@class PPRetailInvoiceRefund;
@class PPRetailInvoiceSearchRequest;
@class PPRetailInvoiceShippingInfo;
@class PPRetailInvoiceTemplate;
@class PPRetailInvoiceTemplateSettings;
@class PPRetailMerchant;
@class PPRetailTransactionContext;
@class PPRetailSignatureReceiver;
@class PPRetailReceiptOptionsViewContent;
@class PPRetailReceiptEmailEntryViewContent;
@class PPRetailReceiptSMSEntryViewContent;
@class PPRetailReceiptViewContent;
@class PPRetailCard;
@class PPRetailBatteryInfo;
@class PPRetailMagneticCard;
@class PPRetailPaymentDevice;
@class PPRetailEmvDevice;
@class PPRetailSecureEntryOptions;
@class PPRetailNumericEntryOptions;
@class PPRetailManuallyEnteredCard;
@class PPRetailDeviceUpdate;
@class PPRetailDeviceOperationResultHandler;
@class PPRetailVirtualPaymentDevice;
@class PPRetailPayer;
@class PPRetailTransactionRecord;
@class PPRetailInvoice;
@class PPRetailPaymentDevice;
@class PPRetailError;
@class PPRetailPayPalErrorInfo;
@class PPRetailAccountSummarySection;
@class PPRetailInvoiceAddress;
@class PPRetailInvoiceMerchantInfo;
@class PPRetailInvoiceBillingInfo;
@class PPRetailInvoiceShippingInfo;
@class PPRetailInvoiceItem;
@class PPRetailInvoicePaymentTerm;
@class PPRetailInvoiceCCInfo;
@class PPRetailInvoicePayment;
@class PPRetailInvoiceRefund;
@class PPRetailInvoiceCustomAmount;
@class PPRetailInvoiceMetaData;
@class PPRetailInvoiceAttachment;
@class PPRetailInvoiceNotification;
@class PPRetailInvoiceTemplate;
@class PPRetailInvoiceListResponse;
@class PPRetailAccountSummary;
@class PPRetailInvoiceTemplatesResponse;
@class PPRetailInvoiceListRequest;
@class PPRetailInvoiceSearchRequest;
@class PPRetailInvoiceTemplateSettings;
@class PPRetailCard;
@class PPRetailSignatureReceiver;
@class PPRetailMerchant;
@class PPRetailError;
@class PPRetailTransactionRecord;
@class PPRetailTransactionContext;
@class PPRetailReceiptOptionsViewContent;
@class PPRetailReceiptEmailEntryViewContent;
@class PPRetailReceiptSMSEntryViewContent;
@class PPRetailBatteryInfo;
@class PPRetailDeviceUpdate;
@class PPRetailManuallyEnteredCard;
@class PPRetailNumericEntryOptions;
@class PPRetailSecureEntryOptions;
@class PPRetailDeviceOperationResultHandler;
@class PPRetailPayer;



/**
 * Valid invoice statuses
 */
typedef NS_ENUM(NSInteger, PPRetailInvoiceStatus) {
  PPRetailInvoiceStatusNEW = 0,
  PPRetailInvoiceStatusDRAFT = 1,
  PPRetailInvoiceStatusSENT = 2,
  PPRetailInvoiceStatusPAID = 3,
  PPRetailInvoiceStatusMARKED_AS_PAID = 4,
  PPRetailInvoiceStatusCANCELLED = 5,
  PPRetailInvoiceStatusREFUNDED = 6,
  PPRetailInvoiceStatusPARTIALLY_REFUNDED = 7,
  PPRetailInvoiceStatusMARKED_AS_REFUNDED = 8,
  PPRetailInvoiceStatusPARTIALLY_PAID = 9,
  PPRetailInvoiceStatusUNPAID = 10
};

/**
 * PayPal payment detail indicating whether payment was made in an invoicing flow via PayPal
     * or externally. In the case of the mark-as-paid API, payment type is EXTERNAL and this
     * is what is now supported. The PAYPAL value is provided for backward compatibility.
 */
typedef NS_ENUM(NSInteger, PPRetailInvoicePaymentType) {
  PPRetailInvoicePaymentTypeNONE = 0,
  PPRetailInvoicePaymentTypeEXTERNAL = 1,
  PPRetailInvoicePaymentTypePAYPAL = 2
};

/**
 * Payment mode or method.
 */
typedef NS_ENUM(NSInteger, PPRetailInvoicePaymentMethod) {
  PPRetailInvoicePaymentMethodNONE = 0,
  PPRetailInvoicePaymentMethodBANK_TRANSFER = 1,
  PPRetailInvoicePaymentMethodCASH = 2,
  PPRetailInvoicePaymentMethodCHECK = 3,
  PPRetailInvoicePaymentMethodCREDIT_CARD = 4,
  PPRetailInvoicePaymentMethodDEBIT_CARD = 5,
  PPRetailInvoicePaymentMethodPAYPAL = 6,
  PPRetailInvoicePaymentMethodWIRE_TRANSFER = 7,
  PPRetailInvoicePaymentMethodOTHER = 8
};

/**
 * Invoice action
 */
typedef NS_ENUM(NSInteger, PPRetailInvoiceAction) {
  PPRetailInvoiceActionNone = 0,
  PPRetailInvoiceActionDelete = 1,
  PPRetailInvoiceActionSend = 2,
  PPRetailInvoiceActionRemind = 3,
  PPRetailInvoiceActionRecordPayment = 4,
  PPRetailInvoiceActionRecordRefund = 5,
  PPRetailInvoiceActionCopy = 6,
  PPRetailInvoiceActionEdit = 7,
  PPRetailInvoiceActionCall = 8,
  PPRetailInvoiceActionCancel = 9,
  PPRetailInvoiceActionMore = 10
};

/**
 * A payment term describes when payment is expected in relation to the date it is sent
 */
typedef NS_ENUM(NSInteger, PPRetailInvoicePaymentTermPaymentTerms) {
  PPRetailInvoicePaymentTermPaymentTermsNoPaymentTerms = 0,
  PPRetailInvoicePaymentTermPaymentTermsDueOnReceipt = 1,
  PPRetailInvoicePaymentTermPaymentTermsNet10 = 2,
  PPRetailInvoicePaymentTermPaymentTermsNet15 = 3,
  PPRetailInvoicePaymentTermPaymentTermsNet30 = 4,
  PPRetailInvoicePaymentTermPaymentTermsNet45 = 5,
  PPRetailInvoicePaymentTermPaymentTermsNet60 = 6,
  PPRetailInvoicePaymentTermPaymentTermsNet90 = 7
};

/**
 * A transaction context is created for a certain operation - sale
     * (meaning auth+capture), auth or refund.
 */
typedef NS_ENUM(NSInteger, PPRetailTransactionContextType) {
  PPRetailTransactionContextTypeSale = 0,
  PPRetailTransactionContextTypeAuth = 1,
  PPRetailTransactionContextTypeRefund = 2,
  PPRetailTransactionContextTypePartialRefund = 3
};

/**
 * A payment form factor describes the process used by the consumer to
     * communicate payment credentials to the merchant.
 */
typedef NS_ENUM(NSInteger, PPRetailPaymentDeviceFormFactor) {
  PPRetailPaymentDeviceFormFactorNone = 0,
  PPRetailPaymentDeviceFormFactorMagneticCardSwipe = 5,
  PPRetailPaymentDeviceFormFactorChip = 10,
  PPRetailPaymentDeviceFormFactorEmvCertifiedContactless = 15,
  PPRetailPaymentDeviceFormFactorSecureManualEntry = 20
};

/**
 * Issuer of the card that was presented to the SDK
 */
typedef NS_ENUM(NSInteger, PPRetailPaymentDeviceCardIssuer) {
  PPRetailPaymentDeviceCardIssuerUnknown = 0,
  PPRetailPaymentDeviceCardIssuerVisa = 1,
  PPRetailPaymentDeviceCardIssuerMasterCard = 2,
  PPRetailPaymentDeviceCardIssuerMaestro = 3,
  PPRetailPaymentDeviceCardIssuerAmex = 4,
  PPRetailPaymentDeviceCardIssuerDiscover = 5,
  PPRetailPaymentDeviceCardIssuerPayPal = 6
};

/**
 * The current status of the contact based card reader
 */
typedef NS_ENUM(NSInteger, PPRetailEmvDeviceCardStatus) {
  PPRetailEmvDeviceCardStatusNone = 0,
  PPRetailEmvDeviceCardStatusNonEmvCard = 1,
  PPRetailEmvDeviceCardStatusEmvCard = 3
};

/**
 * When you wish to get a numeric value from the device, you must specify precisely
     * which type of number you're asking for so that prompts and formats can be selected.
 */
typedef NS_ENUM(NSInteger, PPRetailEmvDeviceNumericEntryType) {
  PPRetailEmvDeviceNumericEntryTypeGratuityAmount = 1,
  PPRetailEmvDeviceNumericEntryTypeGratuityPercentage = 2,
  PPRetailEmvDeviceNumericEntryTypeMobileNumber = 3,
  PPRetailEmvDeviceNumericEntryTypeExpirationDate = 4,
  PPRetailEmvDeviceNumericEntryTypeCvv = 5
};


/**
 * 
 */
typedef void (^PPRetailInvoiceGotDetailsHandler)(PPRetailError* error);

/**
 * After an attempt has been made to save your invoice to the PayPal servers,
     * the completion handler will be called with the error (if any, or null if not)
     * and the invoice object will be updated appropriately.
 */
typedef void (^PPRetailInvoiceSavedHandler)(PPRetailError* error);

/**
 * After an attempt has been made to send your invoice, the completion handler
     * will be called with the error (if any, or null if not) and the invoice object
     * will be updated appropriately.
 */
typedef void (^PPRetailInvoiceSentHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailInvoiceDeletedHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailInvoiceRemindedHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailInvoiceCancelledHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailInvoicePaidHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailInvoiceRefundedHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailInvoicingServiceGetInvoicesHandler)(PPRetailError* error, PPRetailInvoiceListResponse* response);

/**
 * 
 */
typedef void (^PPRetailInvoicingServiceSearchInvoicesHandler)(PPRetailError* error, PPRetailInvoiceListResponse* response);

/**
 * 
 */
typedef void (^PPRetailInvoicingServiceGetAccountSummaryHandler)(PPRetailError* error, PPRetailAccountSummary* response);

/**
 * 
 */
typedef void (^PPRetailInvoicingServiceGetTemplatesHandler)(PPRetailError* error, PPRetailInvoiceTemplatesResponse* response);

/**
 * 
 */
typedef void (^PPRetailInvoicingServiceGetNextInvoiceNumberHandler)(PPRetailError* error, NSString* response);

/**
 * 
 */
typedef void (^PPRetailTransactionContextSignatureCollectorHandler)(PPRetailSignatureReceiver* signatureReceiver);

/**
 * 
 */
typedef void (^PPRetailPaymentDeviceCallbackHandler)(PPRetailError* error);

/**
 * Called after a request for amount entry (via promptForAmountEntry) completes.
 */
typedef void (^PPRetailEmvDeviceAmountEnteredHandler)(PPRetailError* error, NSString* amount);

/**
 * Called after a request to secure account number entry
 */
typedef void (^PPRetailEmvDeviceSecureEntryHandler)(PPRetailError* error, PPRetailManuallyEnteredCard* card);

/**
 * Called when either the software update completed, failed, or was canceled. (To detect the user having chosen
     * not to update, check that the error is null but deviceUpgraded is false.
 */
typedef void (^PPRetailDeviceUpdateCompletedHandler)(PPRetailError* error, BOOL deviceUpgraded);

/**
 * You must implement this function to begin a connection to the device
 */
typedef void (^PPRetailVirtualPaymentDeviceConnectFunctionHandler)(PPRetailDeviceOperationResultHandler* resultHandler);

/**
 * You must implement this function to determine whether the device is connected
 */
typedef BOOL (^PPRetailVirtualPaymentDeviceIsConnectedFunctionHandler)();

/**
 * You must implement this function
 */
typedef void (^PPRetailVirtualPaymentDeviceDisconnectFunctionHandler)(PPRetailDeviceOperationResultHandler* resultHandler);

/**
 * You must implement this function to deliver bytes to the device
 */
typedef void (^PPRetailVirtualPaymentDeviceSendFunctionHandler)(NSString* base64Data, int offset, int length, PPRetailDeviceOperationResultHandler* resultHandler);


 
/**
 * A PaymentDevice has been discovered. For further events, such as device readiness, removal or the
     * need for a software upgrade, your application should subscribe to the relevant events on the device
     * parameter. Please note that this doesn't always mean the device is present. In certain cases (e.g. Bluetooth)
     * we may know about the device independently of whether it's currently connected or available.
 */
typedef void (^PPRetailDeviceDiscoveredEvent)(PPRetailPaymentDevice* device);
/**
 * Returned from addDeviceDiscoveredListener and used to unsubscribe from the event.
 */
typedef id PPRetailDeviceDiscoveredSignal;

                                      
/**
 * The amount represented by this line item has changed.
 */
typedef void (^PPRetailAmountChangedEvent)(NSString* field);
/**
 * Returned from addAmountChangedListener and used to unsubscribe from the event.
 */
typedef id PPRetailAmountChangedSignal;

                      
/**
 * Called when either payment completes or fails.
     * Note that other events may be fired in the meantime.
 */
typedef void (^PPRetailCompletedEvent)(PPRetailError* error, PPRetailTransactionRecord* record);
/**
 * Returned from addCompletedListener and used to unsubscribe from the event.
 */
typedef id PPRetailCompletedSignal;


/**
 * Depending on your region and the buyer payment type, this can mean a magnetic
     * card was swiped, an EMV card was inserted, or an NFC card/device was tapped.
 */
typedef void (^PPRetailCardPresentedEvent)(PPRetailCard* card);
/**
 * Returned from addCardPresentedListener and used to unsubscribe from the event.
 */
typedef id PPRetailCardPresentedSignal;


/**
 * Called when PIN entry is in progress or complete
 */
typedef void (^PPRetailPinEntryEvent)(BOOL complete, BOOL correct, int pinDigits, BOOL lastAttempt);
/**
 * Returned from addPinEntryListener and used to unsubscribe from the event.
 */
typedef id PPRetailPinEntrySignal;


/**
 * Called when the signature input interface will be displayed
 */
typedef void (^PPRetailWillPresentSignatureEvent)();
/**
 * Returned from addWillPresentSignatureListener and used to unsubscribe from the event.
 */
typedef id PPRetailWillPresentSignatureSignal;


/**
 * Called when the signature entry is completed
 */
typedef void (^PPRetailDidCompleteSignatureEvent)(PPRetailError* error);
/**
 * Returned from addDidCompleteSignatureListener and used to unsubscribe from the event.
 */
typedef id PPRetailDidCompleteSignatureSignal;


/**
 * Called when one of the additional receipt option is selected.
 */
typedef void (^PPRetailAdditionalReceiptOptionSelectedEvent)(int index, NSString* name);
/**
 * Returned from addAdditionalReceiptOptionSelectedListener and used to unsubscribe from the event.
 */
typedef id PPRetailAdditionalReceiptOptionSelectedSignal;

  
/**
 * Called when the transaction is cancelled while waiting to collect the signature
 */
typedef void (^PPRetailCancelledEvent)();
/**
 * Returned from addCancelledListener and used to unsubscribe from the event.
 */
typedef id PPRetailCancelledSignal;

                
/**
 * The reader is now connected and ready.
 */
typedef void (^PPRetailConnectedEvent)();
/**
 * Returned from addConnectedListener and used to unsubscribe from the event.
 */
typedef id PPRetailConnectedSignal;


/**
 * The connection attempt with the reader failed
 */
typedef void (^PPRetailConnectionErrorEvent)(PPRetailError* error);
/**
 * Returned from addConnectionErrorListener and used to unsubscribe from the event.
 */
typedef id PPRetailConnectionErrorSignal;


/**
 * The reader is now disconnected.
 */
typedef void (^PPRetailDisconnectedEvent)(PPRetailError* error);
/**
 * Returned from addDisconnectedListener and used to unsubscribe from the event.
 */
typedef id PPRetailDisconnectedSignal;


/**
 * A software update is required for the reader.
 */
typedef void (^PPRetailUpdateRequiredEvent)(PPRetailDeviceUpdate* update);
/**
 * Returned from addUpdateRequiredListener and used to unsubscribe from the event.
 */
typedef id PPRetailUpdateRequiredSignal;


/**
 * A card has been removed (generally from an EMV reader, where the card
     * stays in the reader for some time)
 */
typedef void (^PPRetailCardRemovedEvent)();
/**
 * Returned from addCardRemovedListener and used to unsubscribe from the event.
 */
typedef id PPRetailCardRemovedSignal;


/**
 * Depending on your region and the buyer payment type, this can mean a magnetic card
     * was swiped, an EMV card was
     * inserted, or an NFC card/device was tapped.
 */
typedef void (^PPRetailCardPresentedEvent)(PPRetailCard* card);
/**
 * Returned from addCardPresentedListener and used to unsubscribe from the event.
 */
typedef id PPRetailCardPresentedSignal;

          
/**
 * Payment device connected via USB needs to be unplugged and plugged back to the USB port for the software
     * update to complete
 */
typedef void (^PPRetailReconnectReaderEvent)(int waitTime);
/**
 * Returned from addReconnectReaderListener and used to unsubscribe from the event.
 */
typedef id PPRetailReconnectReaderSignal;

         
