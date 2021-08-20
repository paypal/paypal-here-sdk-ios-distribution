/**
 * PPRetailTransactionContext.h
 *
 * DO NOT EDIT THIS FILE! IT IS AUTOMATICALLY GENERATED AND SHOULD NOT BE CHECKED IN.
 * Generated from: dist/transaction/TransactionContext.js
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
 * The TransactionContext class is returned by RetailSDK.getTransactionManager().createTransaction and allows
 * you to control many aspects of the payment or refund flow and observe events that
 * occur during the flows. Simply creating a TransactionContext will not kick off any behaviors,
 * so that you have a chance to configure the transaction context as you wish (enable on-reader tipping
 * , specify transaction options, etc). When you're ready to proceed with the payment flow,
 * call beginPayment()
 */
@interface PPRetailTransactionContext : PPRetailObject
/**
 * The invoice being processed for this transaction @readonly
 */
@property (nonatomic,strong,nullable,readonly) PPRetailRetailInvoice* invoice;/**
 * The type of transaction being attempted
 * (defaults to Sale if the invoice is not already paid, Refund if it is already paid)
 */
@property (nonatomic,assign) PPRetailTransactionType type;/**
 * Given the current state of the invoice and transaction,
 * is a signature required to secure payment? @readonly
 */
@property (nonatomic,assign,readonly) BOOL isSignatureRequired;/**
 * Digital Card information
 */
@property (nonatomic,strong,nullable) PPRetailDigitalCard* digitalCard;/**
 * id of the PP order for payment
 */
@property (nonatomic,strong,nullable) NSString* orderId;/**
 * While building your invoice, the running total
 * will be displayed on PaymentDevices capable of displaying messages. If you set
 * totalDisplayFooter, that will be displayed (centered) after the total
 * amount. Note that once the payment flow starts, EMV certification requires that the display
 * just show the total and iconography corresponding to expected payment types. Your message
 * will not be on that screen.
 */
@property (nonatomic,strong,nullable) NSString* totalDisplayFooter;

- (instancetype _Nullable)initWithInvoice:(PPRetailRetailInvoice* _Nullable)invoice merchant:(PPRetailMerchant* _Nullable)merchant offlinePaymentEnabled:(BOOL)offlinePaymentEnabled;
    - (instancetype _Nullable)init NS_UNAVAILABLE;
+ (instancetype _Nullable)new NS_UNAVAILABLE;




/**
 * Returns the current state of payment
 */
-(PPRetailPaymentState)getPaymentState;

/**
 * Returns the current state of tipping
 */
-(PPRetailTippingState)getTippingState;

/**
 * Clear the on-reader tip that was acquired for this transaction
 */
-(void)clearOnReaderTip;

/**
 * Begin the payment flow (activate payment devices, listen for relevant events from devices)
 */
-(PPRetailTransactionContext* _Nullable)beginPayment:(PPRetailTransactionBeginOptions* _Nullable)paymentOptions;

/**
 * Begin the flow to issue a refund on the current invoice.
 */
-(PPRetailTransactionContext* _Nullable)beginRefund:(BOOL)promptForCardOptions amount:(NSDecimalNumber* _Nullable)amount;

/**
 * Begin the flow to issue a refund on the current invoice.
 */
-(PPRetailTransactionContext* _Nullable)beginRefund:(BOOL)promptForCardOptions amount:(NSDecimalNumber* _Nullable)amount refundTag:(NSString* _Nullable)refundTag;

/**
 * Is the transaction a type of refund?
 */
-(BOOL)isRefund;

/**
 * Deactivate form factors without ending the transaction. Once deactivated, you should re-begin the transaction to
 * start taking payments
 */
-(void)deactivateFormFactors:(NSArray* _Nullable)formFactors callback:(PPRetailTransactionContextCompleteHandler _Nullable)callback;

/**
 * Abort an idle transaction abandoning activated readers and all event listeners. The completed event
 * will NOT be fired for this TransactionContext given that you have explicitly abandoned it
 */
-(void)clear:(PPRetailTransactionContextCompleteHandler _Nullable)callback;

/**
 * Check to see if payment is in 'retry' state. This check helps with
 * disconnection/connection logic when the app goes in the background.
 */
-(BOOL)isPaymentInRetryOrProgress;

/**
 * Request to cancel a payment. The request will only be accepted if payment is not already in progress.
 */
-(void)requestPaymentCancellation:(PPRetailTransactionContextCancellationHandlerHandler _Nullable)handler;

/**
 * Request to cancel an ongoing payment.
 * The request will only be accepted if there is a partial digital card payment and payment is not in progress.
 */
-(void)requestDigitalCardCancellation:(PPRetailTransactionContextVoidCompletedHandler _Nullable)voidCompletedHandler;

/**
 * Remove all handlers
 */
-(void)dropHandlers;

/**
 * Discard the presented card for non-EMV transactions only
 */
-(void)discardPresentedCard:(PPRetailCard* _Nullable)card;

/**
 * Begin the flow to issue a refund on the current invoice.
 */
-(void)continueWithCard:(PPRetailCard* _Nullable)card tag:(NSString* _Nullable)tag;

/**
 * Continue processing transaction with Digital Card/Code information
 */
-(void)continueWithDigitalCard:(PPRetailDigitalCard* _Nullable)digitalCard;

/**
 * Continue processing a transaction - the behavior of which depends on the presented card.
 * If it's a magnetic card or an NFC tap, payment will be attempted and money will move
 * (if successful). If it's an EMV card insertion, we will start the EMV flow which includes
 * a few calls to the server, potentially asking the user to enter a PIN, etc.
 */
-(void)continueWithCard:(PPRetailCard* _Nullable)card;

/**
 * Sync the Invoice total to the reader display. Use this function to sync
 * invoice amount on the app to the reader. This automatic invoice syncing will stop based on the transaction state.
 * Use 'syncInvoiceOnce' to do an on-demand push invoice total to the card reader display
 */
-(void)startInvoiceSync;

/**
 * Do a one time sync of invoice total to card reader
 */
-(void)syncInvoiceOnce;

/**
 * Continue processing a cash transaction.
 */
-(void)continueWithCash;

/**
 * Continue processing a QRC transaction.
 */
-(void)continueWithQRC;

/**
 * Continue processing a check transaction.
 */
-(void)continueWithCheck;

/**
 * If you acquire signatures yourself, for example from a Topaz Pen Pad or with an external
 * camera, set this property to a handler that will be invoked when signature should be
 * collected. Once you've collected the signature, call the supplied signatureReceiver
 * with a base64 encoded JPG of the signature. Try to keep it under 100k.
 */
-(void)setSignatureCollector:(PPRetailTransactionContextSignatureCollectorHandler _Nullable)collector;

/**
 * Provide a token expiration handler if you want to handle token expirations during a transaction
 */
-(void)setTokenExpiredHandler:(PPRetailTransactionContextTokenExpirationHandlerHandler _Nullable)expirationHandler;

/**
 * Provide a handler to get notified after chip card insert is detected but before EMV data is read.
 * cardInsertedHandler.continueWithCardDataRead must be invoked to continue with transaction
 */
-(void)setCardInsertedHandler:(PPRetailTransactionContextCardInsertedHandlerHandler _Nullable)cardInsertedHandler;

-(void)setCaptureHandler:(PPRetailTransactionContextOnAuthCompleteHandler _Nullable)captureHandler;

/**
 * Provide a handler to get notified when card was presented and emv/magstripe data was read.
 * TransactionContext.continueWithCard should be invoked to continue the payment
 */
-(void)setCardPresentedHandler:(PPRetailTransactionContextCardPresentedHandler _Nullable)cardPresentedHandler;

/**
 * Provide a handler to get notifications for QRC Payment
 */
-(void)setQRCStatusHandler:(PPRetailTransactionContextOnQRCStatusHandler _Nullable)qrcStatusHandler;

/**
 * Provide a handler to get notified once transaction is complete
 */
-(void)setCompletedHandler:(PPRetailTransactionContextTransactionCompletedHandler _Nullable)completedHandler;

/**
 * Provide a handler to get notified once vault is complete
 */
-(void)setVaultCompletedHandler:(PPRetailTransactionContextVaultCompletedHandler _Nullable)completedHandler;

/**
 * Provide a handler to get offline transaction addition notification
 */
-(void)setOfflineTransactionAdditionHandler:(PPRetailTransactionContextOfflineTransactionAddedHandler _Nullable)addedHandler;

/**
 * If you would like to display additional receipt options such as print, etc., you can provide them here. These
 * options would be presented on the receipt screen below the Email and Text options.
 */
-(void)setAdditionalReceiptOptions:(NSArray* _Nullable)additionalReceiptOptions receiptHandler:(PPRetailTransactionContextReceiptOptionHandlerHandler _Nullable)receiptHandler;




/**
 * Add a listener for the contactlessReaderDeactivated event
 * @returns PPRetailContactlessReaderDeactivatedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailContactlessReaderDeactivatedSignal _Nullable)addContactlessReaderDeactivatedListener:(PPRetailContactlessReaderDeactivatedEvent _Nullable)listener;

/**
 * Remove a listener for the contactlessReaderDeactivated event given the signal object that was returned from addContactlessReaderDeactivatedListener
 */
-(void)removeContactlessReaderDeactivatedListener:(PPRetailContactlessReaderDeactivatedSignal _Nullable)listenerToken;


/**
 * Add a listener for the contactlessReaderActivated event
 * @returns PPRetailContactlessReaderActivatedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailContactlessReaderActivatedSignal _Nullable)addContactlessReaderActivatedListener:(PPRetailContactlessReaderActivatedEvent _Nullable)listener;

/**
 * Remove a listener for the contactlessReaderActivated event given the signal object that was returned from addContactlessReaderActivatedListener
 */
-(void)removeContactlessReaderActivatedListener:(PPRetailContactlessReaderActivatedSignal _Nullable)listenerToken;


/**
 * Add a listener for the pinEntry event
 * @returns PPRetailPinEntrySignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailPinEntrySignal _Nullable)addPinEntryListener:(PPRetailPinEntryEvent _Nullable)listener;

/**
 * Remove a listener for the pinEntry event given the signal object that was returned from addPinEntryListener
 */
-(void)removePinEntryListener:(PPRetailPinEntrySignal _Nullable)listenerToken;


/**
 * Add a listener for the willPresentSignature event
 * @returns PPRetailWillPresentSignatureSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailWillPresentSignatureSignal _Nullable)addWillPresentSignatureListener:(PPRetailWillPresentSignatureEvent _Nullable)listener;

/**
 * Remove a listener for the willPresentSignature event given the signal object that was returned from addWillPresentSignatureListener
 */
-(void)removeWillPresentSignatureListener:(PPRetailWillPresentSignatureSignal _Nullable)listenerToken;


/**
 * Add a listener for the readerTippingCompleted event
 * @returns PPRetailReaderTippingCompletedSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailReaderTippingCompletedSignal _Nullable)addReaderTippingCompletedListener:(PPRetailReaderTippingCompletedEvent _Nullable)listener;

/**
 * Remove a listener for the readerTippingCompleted event given the signal object that was returned from addReaderTippingCompletedListener
 */
-(void)removeReaderTippingCompletedListener:(PPRetailReaderTippingCompletedSignal _Nullable)listenerToken;


/**
 * Add a listener for the didCompleteSignature event
 * @returns PPRetailDidCompleteSignatureSignal an object that can be used to remove the listener when
 * you're done with it.
 */
-(PPRetailDidCompleteSignatureSignal _Nullable)addDidCompleteSignatureListener:(PPRetailDidCompleteSignatureEvent _Nullable)listener;

/**
 * Remove a listener for the didCompleteSignature event given the signal object that was returned from addDidCompleteSignatureListener
 */
-(void)removeDidCompleteSignatureListener:(PPRetailDidCompleteSignatureSignal _Nullable)listenerToken;


@end
