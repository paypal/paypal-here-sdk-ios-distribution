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
@class PPRetailInvoiceConstants;
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
@class PPRetailNetworkRequest;
@class PPRetailNetworkResponse;
@class PPRetailSdkEnvironmentInfo;
@class PPRetailRetailInvoice;
@class PPRetailRetailInvoicePayment;
@class PPRetailTokenExpirationHandler;
@class PPRetailCaptureHandler;
@class PPRetailTransactionContext;
@class PPRetailTransactionManager;
@class PPRetailTransactionBeginOptions;
@class PPRetailReceiptDestination;
@class PPRetailDeviceManager;
@class PPRetailSignatureReceiver;
@class PPRetailReceiptOptionsViewContent;
@class PPRetailReceiptEmailEntryViewContent;
@class PPRetailReceiptSMSEntryViewContent;
@class PPRetailReceiptViewContent;
@class PPRetailCard;
@class PPRetailBatteryInfo;
@class PPRetailMagneticCard;
@class PPRetailPaymentDevice;
@class PPRetailManuallyEnteredCard;
@class PPRetailDeviceUpdate;
@class PPRetailCardInsertedHandler;
@class PPRetailDeviceStatus;
@class PPRetailPayer;
@class PPRetailTransactionRecord;
@class PPRetailAuthorizedTransaction;
@class PPRetailPage;
@class PPRetailDiscoveredCardReader;
@class PPRetailCardReaderScanAndDiscoverOptions;
@class PPRetailDeviceConnectorOptions;
@class PPRetailNetworkRequest;
@class PPRetailInvoice;
@class PPRetailSdkEnvironmentInfo;
@class PPRetailPaymentDevice;
@class PPRetailError;
@class PPRetailPage;
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
@class PPRetailNetworkResponse;
@class PPRetailTransactionRecord;
@class PPRetailCard;
@class PPRetailSignatureReceiver;
@class PPRetailTokenExpirationHandler;
@class PPRetailCardInsertedHandler;
@class PPRetailCaptureHandler;
@class PPRetailMerchant;
@class PPRetailTransactionBeginOptions;
@class PPRetailTransactionContext;
@class PPRetailAuthorizedTransaction;
@class PPRetailReceiptOptionsViewContent;
@class PPRetailReceiptEmailEntryViewContent;
@class PPRetailReceiptSMSEntryViewContent;
@class PPRetailBatteryInfo;
@class PPRetailDeviceUpdate;
@class PPRetailObject;
@class PPRetailPayer;
@class PPRetailReceiptDestination;
@class PPRetailDiscoveredCardReader;



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
  PPRetailInvoiceStatusUNPAID = 10,
  PPRetailInvoiceStatusPAYMENT_PENDING = 11,
  PPRetailInvoiceStatusSCHEDULED = 12,
  PPRetailInvoiceStatusUNKNOWN = 13
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
  PPRetailInvoiceActionMore = 10,
  PPRetailInvoiceActionShare = 11,
  PPRetailInvoiceActionViewHistory = 12,
  PPRetailInvoiceActionViewInvoice = 13
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
 * The log level for the SDK
 */
typedef NS_ENUM(NSInteger, PPRetaillogLevel) {
  PPRetaillogLevelquiet = 0,
  PPRetaillogLevelerror = 1,
  PPRetaillogLevelwarn = 2,
  PPRetaillogLevelinfo = 3,
  PPRetaillogLeveldebug = 4
};

/**
 * List of possible receipt destination options, as selected by the user.
 */
typedef NS_ENUM(NSInteger, PPRetailReceiptDestinationType) {
  PPRetailReceiptDestinationTypenone = 0,
  PPRetailReceiptDestinationTypeemail = 1,
  PPRetailReceiptDestinationTypetext = 2
};

/**
 * This enum represents the state of the current payment
 */
typedef NS_ENUM(NSInteger, PPRetailPaymentState) {
  PPRetailPaymentStateidle = 0,
  PPRetailPaymentStateinProgress = 1,
  PPRetailPaymentStateretry = 2,
  PPRetailPaymentStatecomplete = 3
};

/**
 * This enum represents the state of the current tipping
 */
typedef NS_ENUM(NSInteger, PPRetailTippingState) {
  PPRetailTippingStatenotStarted = 0,
  PPRetailTippingStateinProgress = 1,
  PPRetailTippingStatecomplete = 2
};

/**
 * This enum represents the state of the auth transaction
 */
typedef NS_ENUM(NSInteger, PPRetailAuthStatus) {
  PPRetailAuthStatuspending = 0,
  PPRetailAuthStatuscanceled = 1
};

/**
 * Battery status
 */
typedef NS_ENUM(NSInteger, PPRetailbatteryStatus) {
  PPRetailbatteryStatusunknown = 0,
  PPRetailbatteryStatusdraining = 1,
  PPRetailbatteryStatusdrained = 2,
  PPRetailbatteryStatuscharging = 3,
  PPRetailbatteryStatuscharged = 4
};

/**
 * The device capability types
 */
typedef NS_ENUM(NSInteger, PPRetaildeviceCapabilityType) {
  PPRetaildeviceCapabilityTypenone = 0,
  PPRetaildeviceCapabilityTypedisplay = 1,
  PPRetaildeviceCapabilityTypekeyboard = 2,
  PPRetaildeviceCapabilityTypesecureEntry = 3,
  PPRetaildeviceCapabilityTypecontactless = 4
};

/**
 * The current status of the contact based card reader
 */
typedef NS_ENUM(NSInteger, PPRetailCardStatus) {
  PPRetailCardStatusNone = 0,
  PPRetailCardStatusNonEmvCard = 1,
  PPRetailCardStatusEmvCard = 3
};

/**
 * Issuer of the card that was presented to the SDK
 */
typedef NS_ENUM(NSInteger, PPRetailCardIssuer) {
  PPRetailCardIssuerUnknown = 0,
  PPRetailCardIssuerVisa = 1,
  PPRetailCardIssuerMasterCard = 2,
  PPRetailCardIssuerMaestro = 3,
  PPRetailCardIssuerAmex = 4,
  PPRetailCardIssuerDiscover = 5,
  PPRetailCardIssuerPayPal = 6
};

/**
 * A payment form factor describes the process used by the consumer to
     * communicate payment credentials to the merchant.
 */
typedef NS_ENUM(NSInteger, PPRetailFormFactor) {
  PPRetailFormFactorNone = 0,
  PPRetailFormFactorMagneticCardSwipe = 1,
  PPRetailFormFactorChip = 2,
  PPRetailFormFactorEmvCertifiedContactless = 3,
  PPRetailFormFactorSecureManualEntry = 4,
  PPRetailFormFactorManualCardEntry = 5
};

/**
 * A transaction context is created for a certain operation - sale
     * (meaning auth+capture), auth or refund.
 */
typedef NS_ENUM(NSInteger, PPRetailTransactionType) {
  PPRetailTransactionTypeSale = 0,
  PPRetailTransactionTypeAuth = 1,
  PPRetailTransactionTypeRefund = 2,
  PPRetailTransactionTypePartialRefund = 3
};

/**
 * Indicates the type synonymous to the payment acceptance method.
 */
typedef NS_ENUM(NSInteger, PPRetailreaderType) {
  PPRetailreaderTypeUnknown = 0,
  PPRetailreaderTypeMagstripe = 1,
  PPRetailreaderTypeEmv = 2
};

/**
 * Indicates the channel through which the reader is connected.
 */
typedef NS_ENUM(NSInteger, PPRetailreaderConnectionType) {
  PPRetailreaderConnectionTypeUnknown = 0,
  PPRetailreaderConnectionTypeAudioJack = 1,
  PPRetailreaderConnectionTypeBluetooth = 2,
  PPRetailreaderConnectionTypeDockPort = 3
};

/**
 * Card reader model
 */
typedef NS_ENUM(NSInteger, PPRetailReaderModel) {
  PPRetailReaderModelUnknown = 0,
  PPRetailReaderModelSwiper = 1,
  PPRetailReaderModelM003 = 2,
  PPRetailReaderModelM010 = 3,
  PPRetailReaderModelMoby3000 = 4,
  PPRetailReaderModelRP450 = 5
};


/**
 * This callback will be invoked every time the SDK wants to do a HTTP Request, the listener could intercept this call
     * and provide
 */
typedef void (^PPRetailSDKInterceptHandler)(PPRetailNetworkRequest* request);

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
typedef void (^PPRetailInvoicingServiceGetInvoiceHandler)(PPRetailError* error, PPRetailInvoice* response);

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
typedef void (^PPRetailInvoicingServiceUploadFileHandler)(PPRetailError* error, PPRetailInvoiceAttachment* response);

/**
 * After an attempt has been made to send your receipt to the PayPal servers,
     * the completion handler will be called with the error (if any, or null if not)
 */
typedef void (^PPRetailMerchantReceiptForwardedHandler)(PPRetailError* error);

/**
 * Called when either payment completes or fails.
     * Note that other events may be fired in the meantime.
 */
typedef void (^PPRetailTransactionContextTransactionCompletedHandler)(PPRetailError* error, PPRetailTransactionRecord* record);

/**
 * Indicates that the card data was read. Depending on your region and the buyer payment type, this can mean a magnetic
     * card was swiped, an EMV card was inserted, or an NFC card/device was tapped.
 */
typedef void (^PPRetailTransactionContextCardPresentedHandler)(PPRetailCard* card);

/**
 * 
 */
typedef void (^PPRetailTransactionContextSignatureCollectorHandler)(PPRetailSignatureReceiver* signatureReceiver);

/**
 * 
 */
typedef void (^PPRetailTransactionContextTokenExpirationHandlerHandler)(PPRetailTokenExpirationHandler* tokenExpirationHandler);

/**
 * Called when EMV card inserted was detected. This occurs before card data read.
 */
typedef void (^PPRetailTransactionContextCardInsertedHandlerHandler)(PPRetailCardInsertedHandler* cardInsertedHandler);

/**
 * 
 */
typedef void (^PPRetailTransactionContextOnAuthCompleteHandler)(PPRetailError* Error, PPRetailCaptureHandler* captureHandler, PPRetailTransactionRecord* record);

/**
 * Called when one of the additional receipt option is selected.
 */
typedef void (^PPRetailTransactionContextReceiptOptionHandlerHandler)(int index, NSString* name, PPRetailTransactionRecord* record);

/**
 * 
 */
typedef void (^PPRetailTransactionContextCompleteHandler)(PPRetailError* error);

/**
 * The callback for creating a transaction
 */
typedef void (^PPRetailTransactionManagerTransactionHandler)(PPRetailError* error, PPRetailTransactionContext* context);

/**
 * The callback for retrieveAuthorizedTransactions completion
 */
typedef void (^PPRetailTransactionManagerRetrieveAuthorizedTransactionsHandler)(PPRetailError* error, NSArray* listOfAuths, NSString* nextPageToken);

/**
 * The callback for voidTransaction completion
 */
typedef void (^PPRetailTransactionManagerVoidAuthorizationHandler)(PPRetailError* error);

/**
 * The callback for captureAuthorizedTransaction completion
 */
typedef void (^PPRetailTransactionManagerCaptureAuthorizedTransactionHandler)(PPRetailError* error, NSString* captureId);

/**
 * The callback invoked while connecting to the last active card reader
 */
typedef void (^PPRetailDeviceManagerConnectionHandler)(PPRetailError* error, PPRetailPaymentDevice* cardReader);

/**
 * The battery status has been updated
 */
typedef void (^PPRetailPaymentDeviceBatteryInfoHandler)(PPRetailError* error, PPRetailBatteryInfo* batteryInfo);

/**
 * 
 */
typedef void (^PPRetailPaymentDeviceConnectHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailPaymentDeviceDisconnectHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailPaymentDeviceDeviceLogsHandler)(PPRetailError* error);

/**
 * Called when either the software update completed, failed, or was canceled. (To detect the user having chosen
     * not to update, check that the error is null but deviceUpgraded is false.
 */
typedef void (^PPRetailDeviceUpdateCompletedHandler)(PPRetailError* error, BOOL deviceUpgraded);

/**
 * 
 */
typedef void (^PPRetailAuthorizedTransactionVoidCompleteHandler)(PPRetailError* error);

/**
 * 
 */
typedef void (^PPRetailAuthorizedTransactionCaptureCompleteHandler)(PPRetailError* error, NSString* captureId);


 
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
 * A page has been viewed
 */
typedef void (^PPRetailPageViewedEvent)(PPRetailError* error, PPRetailPage* page);
/**
 * Returned from addPageViewedListener and used to unsubscribe from the event.
 */
typedef id PPRetailPageViewedSignal;

                                                                            
/**
 * Contactless reader was de-activated and the transaction still remains active.
 */
typedef void (^PPRetailContactlessReaderDeactivatedEvent)();
/**
 * Returned from addContactlessReaderDeactivatedListener and used to unsubscribe from the event.
 */
typedef id PPRetailContactlessReaderDeactivatedSignal;


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
 * Called when the tipping on reader flow has been completed
 */
typedef void (^PPRetailReaderTippingCompletedEvent)(NSDecimalNumber* tipAmount);
/**
 * Returned from addReaderTippingCompletedListener and used to unsubscribe from the event.
 */
typedef id PPRetailReaderTippingCompletedSignal;


/**
 * Called when the signature entry is completed
 */
typedef void (^PPRetailDidCompleteSignatureEvent)(PPRetailError* error);
/**
 * Returned from addDidCompleteSignatureListener and used to unsubscribe from the event.
 */
typedef id PPRetailDidCompleteSignatureSignal;

          
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
 * The reader is now selected and active to be used.
 */
typedef void (^PPRetailSelectedEvent)();
/**
 * Returned from addSelectedListener and used to unsubscribe from the event.
 */
typedef id PPRetailSelectedSignal;


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
 * The battery status has been updated
 */
typedef void (^PPRetailBatteryStatusUpdateEvent)(PPRetailBatteryInfo* batteryInfo);
/**
 * Returned from addBatteryStatusUpdateListener and used to unsubscribe from the event.
 */
typedef id PPRetailBatteryStatusUpdateSignal;


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

                
/**
 * A Card Reader has been discovered.
 */
typedef void (^PPRetailOnCardReaderDiscoveredEvent)(PPRetailDiscoveredCardReader* device);
/**
 * Returned from addOnCardReaderDiscoveredListener and used to unsubscribe from the event.
 */
typedef id PPRetailOnCardReaderDiscoveredSignal;


/**
 * The procedure for scaning and discovering card readers is ended.
 */
typedef void (^PPRetailOnScanCompleteEvent)(PPRetailError* error);
/**
 * Returned from addOnScanCompleteListener and used to unsubscribe from the event.
 */
typedef id PPRetailOnScanCompleteSignal;


/**
 * A PaymentDevice has been discovered. For further events, such as device readiness, removal or the
     * need for a software upgrade, your application should subscribe to the relevant events on the device
     * parameter. Please note that this doesn't always mean the device is present. In certain cases (e.g. Bluetooth)
     * we may know about the device independently of whether it's currently connected or available.
 */
typedef void (^PPRetailOnConnectionStatusEvent)(PPRetailError* error, PPRetailDiscoveredCardReader* device);
/**
 * Returned from addOnConnectionStatusListener and used to unsubscribe from the event.
 */
typedef id PPRetailOnConnectionStatusSignal;

  
/**
 * A PaymentDevice has been discovered. For further events, such as device readiness, removal or the
     * need for a software upgrade, your application should subscribe to the relevant events on the device
     * parameter. Please note that this doesn't always mean the device is present. In certain cases (e.g. Bluetooth)
     * we may know about the device independently of whether it's currently connected or available.
 */
typedef void (^PPRetailOnConnectionResultEvent)(PPRetailError* Error, PPRetailPaymentDevice* device);
/**
 * Returned from addOnConnectionResultListener and used to unsubscribe from the event.
 */
typedef id PPRetailOnConnectionResultSignal;

 
