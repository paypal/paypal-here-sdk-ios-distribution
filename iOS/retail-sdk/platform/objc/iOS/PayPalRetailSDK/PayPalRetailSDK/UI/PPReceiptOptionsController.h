//
//  PPReceiptOptionsController.h
//  PPHCore
//
//  Created by Pavlinsky, Matthew on 4/8/16.
//  Copyright (c) 2016 PayPal. All rights reserved.
//

#import "PPBaseViewController.h"

typedef void (^PPReceiptDestinationCallback)(PPRetailError *error, NSDictionary *receiptDestination);

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReceiptOptionsController : PPBaseViewController
+ (void)presentReceiptOptionsControllerWithInvoice:(PPRetailInvoice *)invoice
                                             error:(PPRetailError *)error
                                           content:(PPRetailReceiptViewContent *)content
                                          callback:(PPReceiptDestinationCallback)callback;
@end
