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
 * in order for things like software update progress to be reported properly. Use the 
 *
 * @param inRequest the request, with headers and body and URL and such - ready to go
 * @param identifier an identifier which is used to cancel a request or group of requests sharing the same identifier
 * @param handler called when the request completes with success or failure
 */
-(void)addRequest:(NSURLRequest*)inRequest withID:(NSString*)identifier withHandler:(void (^)(NSHTTPURLResponse* response, NSError *error, NSData *data))handler;
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

@end
