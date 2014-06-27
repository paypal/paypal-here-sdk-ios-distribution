//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * The error category is useful for understanding what action should be taken in response to a particular
 * domain/error code combination (mainly in the context of payment. This is powered by a JSON file hosted
 * on paypal.com and updated periodically.
 */
typedef NS_ENUM(NSInteger, PPHErrorCategory) {
    /*!
     * No additional information is available about the error.
     */
    ePPHErrorCategoryUnknown,
    /*!
     * The error indicates a PayPal or dependent system outage of some variety.
     */
    ePPHErrorCategoryOutage,
    /*!
     * The error is likely transient and a retry may be successful.
     */
    ePPHErrorCategoryRetry,
    /*!
     * The error indicates the buyer's request to pay was declined and retry is unlikely to succeed without some
     * external change such as the credit card company releasing a hold or PayPal funding sources changing (just as examples)
     */
    ePPHErrorCategoryBuyerDeclined,
    /*!
     * The error indicates there is a problem with the merchant account such as a restriction or account capability error.
     */
    ePPHErrorCategorySellerDeclined,
    /*!
     * The error is known to have multiple causes from the category list and we can't be sure which one caused this occurrence.
     */
    ePPHErrorCategoryAmbiguous,
    /*!
     * The error indicates there was a problem with the data submitted such as an invalid checkin or card number/expiration, etc.
     */
    ePPHErrorCategoryData
};


/*!
 * A customized error class for additional PayPal information such as a correlation id
 */
@interface PPHError : NSError

/*!
 * "Upgrade" an NSError to a PPHError for consistency of errors sent from our SDK to your
 * code.
 * @param error the source NSError
 */
+ (PPHError *)pphErrorWithNSError:(NSError *)error;

/*! The message returned from the server */
@property (nonatomic, strong) NSString *apiMessage;
/*! A short version of the message returned from the server */
@property (nonatomic, strong) NSString *apiShortMessage;
/*! If the error refers to a particular parameter of your request, this value will be non-nil */
@property (nonatomic, strong) NSArray *parameter;
/*! An alphanumeric id that is useful for PayPal support to diagnose problems */
@property (nonatomic, strong) NSString *correlationId;
/*! The precise date at which the error occurred */
@property (nonatomic, strong) NSDate *date;
/*! A mapped mesage with more detailed information that PPH app and our partners can use */
@property (nonatomic, readonly) NSString *mappedMessage;

/*! YES if this error is the result of the user pressing cancel (e.g. on a network request) */
- (BOOL) isCancelError;

/*!
 * The error category is useful for understanding what action should be taken in response to a particular
 * domain/error code combination (mainly in the context of payment. This is powered by a JSON file hosted
 * on paypal.com and updated periodically.
 */
- (PPHErrorCategory) errorCategory;

/*! Stores the last five error objects created, for easier debugging and reporting when problems occur */
+(NSArray*)recentErrors;

/*! Generate an NSDictionary representing this error object, typically for writing to JSON */
- (NSDictionary *) asDictionary;

/*! Generates the read-only mappedMessage by running a best guess hueristic algorithm */
- (void) createMappedMessage;

/*! Read a PPHError from a dictionary created by NSDictionary */
- (id) initWithDictionary: (NSDictionary *) dictionary;
@end

#define kPPHLocalErrorDomain        @"PPHLocal"
#define kPPHHTTPErrorDomain         @"PPHHTTP"
#define kPPHInvoiceErrorDomain      @"PPHInvoice"
#define kPPHServerErrorDomain       @"PPHServer"

