//
//  PayPalHereSDK
//
//  Copyright (c) 2013 PayPal. All rights reserved.
//

/*!
 * A protocol for objects wishing to manage network requests for the PayPal Here SDK
 */
@protocol PPHNetworkRequestDelegate <NSObject>

@optional
/*!
 * Add a request to be sent over the network.
 *
 * PLEASE NOTE: You should give periodic request status updates back to the SDK if you write your own network request delegate
 * in order for things like software update progress to be reported properly. Use the PayPalHereSDK reportNetworkRequestProgress
 * method to do so.
 *
 * ALSO NOTE: Although you're passed an NSMutableURLRequest, because of the way retries work if you return NO from beginRequest
 * and have modified the request, we will not use your modifications. If you want to modify the request WE will send out, use
 * the modifyRequest delegate.
 *
 * @param inRequest the request, with headers and body and URL and such - ready to go
 * @param identifier an identifier which is used to cancel a request or group of requests sharing the same identifier
 * @param handler called when the request completes with success or failure
 *
 * @return YES if you handled the request, NO if you did not and we should process it ourselves.
 */
-(BOOL)beginRequest:(NSMutableURLRequest*)inRequest withID:(NSString*)identifier withHandler:(void (^)(NSHTTPURLResponse* response, NSError *error, NSData *data))handler;
/*!
 * Cancel all active operations with the given identifier
 * @param identifier the value passed to addRequest
 */
-(void)cancelOperationsForID:(NSString*)identifier;

/*!
 * If you just need to modify a request but not "handle" it, you can implement this selector.
 * @param inRequest the request, with headers and body and URL and such - ready to go
 */
-(void)modifyRequest:(NSMutableURLRequest*) inRequest;

/*!
 * We'll call you when a response is received. This is most useful for logging.
 *
 * @param inRequest the request, with headers and body and URL and such - ready to go
 * @param inResponse the response received from the server
 * @param data the data received with the response
 * @param error the raw error received, if any
 */
-(void)requestCompleted: (NSURLRequest*) inRequest withResponse: (NSHTTPURLResponse*) inResponse data: (NSData*) data andError: (NSError*) error;
@end
