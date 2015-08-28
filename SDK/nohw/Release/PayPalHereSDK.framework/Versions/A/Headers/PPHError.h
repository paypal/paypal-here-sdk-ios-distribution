//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPPHLocalErrorDomain        @"PPHLocal"
#define kPPHHTTPErrorDomain         @"PPHHTTP"
#define kPPHInvoiceErrorDomain      @"PPHInvoice"
#define kPPHServerErrorDomain       @"PPHServer"
#define kPPHPayPalAccessDomain      @"PayPalAccess"

/*!
 * A customized error class for additional PayPal information such as a correlation id
 */
@interface PPHError : NSError

/*! Stores the last five error objects created, for easier debugging and reporting when problems occur */
+ (NSArray*)recentErrors;

/*! * "Upgrade" an NSError to a PPHError */
+ (PPHError *)pphErrorWithNSError:(NSError *)error;

+ (instancetype) errorWithDomain:(NSString *)domain code:(NSInteger)code devMessage:(NSString *)devMessage;

+ (instancetype) errorWithDomain:(NSString *)domain code:(NSInteger)code devMessage:(NSString *)devMessage userMessage:(NSString*)userMessage;

- (instancetype) initWithDomain:(NSString *)domain code:(NSInteger)code devMessage:(NSString *)devMessage userMessage:(NSString*)userMessage userInfo:(NSDictionary*)userInfo NS_DESIGNATED_INITIALIZER;

/*! The message returned from the server */
- (NSString *)apiMessage;

/*! A short version of the message returned from the server */
- (NSString *)apiShortMessage;

/*! A mapped mesage with more detailed information */
- (NSString *)mappedMessage;

/*! If the error refers to a particular parameter of your request, this value will be non-nil */
- (NSArray *)parameter;

/*! An alphanumeric id that is useful for PayPal support to diagnose problems */
- (NSString *)correlationId;

/*! The date at which the error occurred */
- (NSDate *)date;

/*! 
 * A message for developers of 3rd party apps who are using the SDK. May contain useful information or
 * suggestions about how this error came about or how to avoid it. 
 */
- (NSString *)devMessage;

/*! YES if this error is the result of the user pressing cancel (e.g. on a network request) */
- (BOOL)isCancelError;

/*! YES if this error is the result of a network request timing out */
- (BOOL)isTimeoutError;

/*! Generate an NSDictionary representing this error object, typically for writing to JSON */
- (NSDictionary *) asDictionary;

@end

