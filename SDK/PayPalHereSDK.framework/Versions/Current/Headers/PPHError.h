//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

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

/*! YES if this error is the result of the user pressing cancel (e.g. on a network request) */
- (BOOL) isCancelError;

/*! Stores the last five error objects created, for easier debugging and reporting when problems occur */
+(NSArray*)recentErrors;

@end

#define kPPHLocalErrorDomain        @"PPHLocal"
#define kPPHHTTPErrorDomain         @"PPHHTTP"
#define kPPHInvoiceErrorDomain      @"PPHInvoice"

