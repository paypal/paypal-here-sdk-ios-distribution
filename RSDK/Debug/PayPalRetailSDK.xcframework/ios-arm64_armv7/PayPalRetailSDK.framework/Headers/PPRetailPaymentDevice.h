/**
 * PPRetailPaymentDevice.h
 *
 * DO NOT EDIT THIS FILE! IT IS AUTOMATICALLY GENERATED AND SHOULD NOT BE CHECKED IN.
 * Generated from: node_modules/@paypalcorp/retail-payment-device/dist/PaymentDevice.js
 *
 * 
 */

#import "PayPalRetailSDKTypeDefs.h"
#import "PPRetailObject.h"


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
@class PPRetailBraintreeManager;
@class PPRetailSimulationManager;
@class PPRetailMerchantManager;
@class PPRetailCaptureHandler;
@class PPRetailRecord;
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
@class PPRetailOfflinePaymentStatus;
@class PPRetailOfflinePaymentInfo;
@class PPRetailOfflineTransactionRecord;
@class PPRetailQRCRecord;
@class PPRetailTokenExpirationHandler;
@class PPRetailCard;
@class PPRetailBatteryInfo;
@class PPRetailMagneticCard;
@class PPRetailDigitalCard;
@class PPRetailPaymentDevice;
@class PPRetailManuallyEnteredCard;
@class PPRetailDeviceUpdate;
@class PPRetailCardInsertedHandler;
@class PPRetailDeviceStatus;
@class PPRetailPayer;
@class PPRetailDigitalCardInfo;
@class PPRetailTransactionRecord;
@class PPRetailVaultRecord;
@class PPRetailAuthorizedTransaction;
@class PPRetailPage;
@class PPRetailDiscoveredCardReader;
@class PPRetailCardReaderScanAndDiscoverOptions;
@class PPRetailDeviceConnectorOptions;
@class PPRetailReaderConfiguration;
@class PPRetailSimulationOptions;

/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
/**
 * A payment device represents the abstract concept of something that can read
 * payment information from a customer. This includes card swipe readers, EMV
 * readers, barcode scanners, biometric devices we don't have yet, and DNA
 * sequencers. Ok, not so much that last bit.
 */
@interface PPRetailPaymentDevice : PPRetailObject
/**
 * A unique identifier for the device @readonly
 */
@property (nonatomic,strong,nullable,readonly) NSString* id;/**
 * Hardware address of this device
 */
@property (nonatomic,strong,nullable) NSString* address;/**
 * A friendly name for the device @readonly
 */
@property (nonatomic,strong,nullable,readonly) NSString* name;/**
 * The model of the card reader @readonly
 */
@property (nonatomic,assign,readonly) PPRetailReaderModel model;/**
 * The serial number of the device, if available @readonly
 */
@property (nonatomic,strong,nullable,readonly) NSString* serialNumber;/**
 * Status of the device battery @readonly
 */
@property (nonatomic,strong,nullable,readonly) PPRetailBatteryInfo* lastKnownBatteryInfo;/**
 * shows if the device has any active transaction @readonly
 */
@property (nonatomic,assign,readonly) BOOL activated;/**
 * The payment form factors
 * this device can support @readonly
 */
@property (nonatomic,strong,nullable,readonly) NSArray* formFactors;/**
 * Any pending software update for
 * this device, or null if the device is current
 */
@property (nonatomic,strong,nullable) PPRetailDeviceUpdate* pendingUpdate;/**
 * Indicates the type of reader @readonly
 */
@property (nonatomic,assign,readonly) PPRetailreaderType type;/**
 * Indicates the connection channel of the reader @readonly
 */
@property (nonatomic,assign,readonly) PPRetailreaderConnectionType connectionType;/**
 * Indicates whether a card is inserted within the reader at this moment @readonly
 */
@property (nonatomic,assign,readonly) BOOL cardInSlot;/**
 * Indicates whether a card reader is blacklisted or not @readonly
 * *
 */
@property (nonatomic,assign,readonly) BOOL isBlacklisted;

- (instancetype _Nullable)initWithUniqueId:(NSString* _Nullable)uniqueId native:(PPRetailObject* _Nullable)native app:(PPRetailObject* _Nullable)app connectionType:(PPRetailreaderConnectionType)connectionType hardwareAddress:(NSString* _Nullable)hardwareAddress;
    - (instancetype _Nullable)init NS_UNAVAILABLE;
+ (instancetype _Nullable)new NS_UNAVAILABLE;




/**
 * EXTERNAL USE ONLY
 * Get manufacturer of the device
 */
-(NSString* _Nullable)getManufacturer;

/**
 * Extract logs from the device.
 */
-(void)extractReaderLogs:(PPRetailPaymentDeviceDeviceLogsHandler _Nullable)callback;

/**
 * Returns true if the passed FormFactor is active
 */
-(BOOL)isFormFactorActive:(PPRetailFormFactor)formFactor;

/**
 * Connect to this device. A device connected event will be emitted once the device is connected
 */
-(void)connect:(PPRetailPaymentDeviceConnectHandler _Nullable)callback;

/**
 * Query card reader for battery information
 */
-(void)retrieveBatteryInfo:(PPRetailPaymentDeviceBatteryInfoHandler _Nullable)cb;

/**
 * Disconnect from the device.
 */
-(void)disconnect:(PPRetailPaymentDeviceDisconnectHandler _Nullable)callback;

/**
 * Gets the device version information
 */
-(NSDictionary* _Nullable)getVersionInfo;

/**
 * Return true if this device is connected
 */
-(BOOL)isConnected;

/**
 * Indicates if the device is ready for transaction
 */
-(PPRetailDeviceStatus* _Nullable)isReadyForTransaction;

/**
 * Return true if this device has the requested capability
 */
-(BOOL)doesHaveCapability:(PPRetaildeviceCapabilityType)capability;




/**
 * Add a listener for the connected event
 * @returns PPRetailConnectedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailConnectedSignal _Nullable)addConnectedListener:(PPRetailConnectedEvent _Nullable)listener;

/**
 * Remove a listener for the connected event given the signal object that was returned from addConnectedListener
 */
-(void)removeConnectedListener:(PPRetailConnectedSignal _Nullable)listenerToken;


/**
 * Add a listener for the selected event
 * @returns PPRetailSelectedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailSelectedSignal _Nullable)addSelectedListener:(PPRetailSelectedEvent _Nullable)listener;

/**
 * Remove a listener for the selected event given the signal object that was returned from addSelectedListener
 */
-(void)removeSelectedListener:(PPRetailSelectedSignal _Nullable)listenerToken;


/**
 * Add a listener for the connectionError event
 * @returns PPRetailConnectionErrorSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailConnectionErrorSignal _Nullable)addConnectionErrorListener:(PPRetailConnectionErrorEvent _Nullable)listener;

/**
 * Remove a listener for the connectionError event given the signal object that was returned from addConnectionErrorListener
 */
-(void)removeConnectionErrorListener:(PPRetailConnectionErrorSignal _Nullable)listenerToken;


/**
 * Add a listener for the disconnected event
 * @returns PPRetailDisconnectedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailDisconnectedSignal _Nullable)addDisconnectedListener:(PPRetailDisconnectedEvent _Nullable)listener;

/**
 * Remove a listener for the disconnected event given the signal object that was returned from addDisconnectedListener
 */
-(void)removeDisconnectedListener:(PPRetailDisconnectedSignal _Nullable)listenerToken;


/**
 * Add a listener for the updateRequired event
 * @returns PPRetailUpdateRequiredSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailUpdateRequiredSignal _Nullable)addUpdateRequiredListener:(PPRetailUpdateRequiredEvent _Nullable)listener;

/**
 * Remove a listener for the updateRequired event given the signal object that was returned from addUpdateRequiredListener
 */
-(void)removeUpdateRequiredListener:(PPRetailUpdateRequiredSignal _Nullable)listenerToken;


/**
 * Add a listener for the batteryStatusUpdate event
 * @returns PPRetailBatteryStatusUpdateSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailBatteryStatusUpdateSignal _Nullable)addBatteryStatusUpdateListener:(PPRetailBatteryStatusUpdateEvent _Nullable)listener;

/**
 * Remove a listener for the batteryStatusUpdate event given the signal object that was returned from addBatteryStatusUpdateListener
 */
-(void)removeBatteryStatusUpdateListener:(PPRetailBatteryStatusUpdateSignal _Nullable)listenerToken;


/**
 * Add a listener for the cardRemoved event
 * @returns PPRetailCardRemovedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailCardRemovedSignal _Nullable)addCardRemovedListener:(PPRetailCardRemovedEvent _Nullable)listener;

/**
 * Remove a listener for the cardRemoved event given the signal object that was returned from addCardRemovedListener
 */
-(void)removeCardRemovedListener:(PPRetailCardRemovedSignal _Nullable)listenerToken;


/**
 * Add a listener for the cardPresented event
 * @returns PPRetailCardPresentedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailCardPresentedSignal _Nullable)addCardPresentedListener:(PPRetailCardPresentedEvent _Nullable)listener;

/**
 * Remove a listener for the cardPresented event given the signal object that was returned from addCardPresentedListener
 */
-(void)removeCardPresentedListener:(PPRetailCardPresentedSignal _Nullable)listenerToken;


/**
 * Add a listener for the blacklisted event
 * @returns PPRetailBlacklistedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailBlacklistedSignal _Nullable)addBlacklistedListener:(PPRetailBlacklistedEvent _Nullable)listener;

/**
 * Remove a listener for the blacklisted event given the signal object that was returned from addBlacklistedListener
 */
-(void)removeBlacklistedListener:(PPRetailBlacklistedSignal _Nullable)listenerToken;


@end
