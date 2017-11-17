//
//  PPReceiptEmailEntryController.h
//  PayPal Retail SDK
//
//  Created by Pavlinsky, Matthew on 4/8/16.
//  Copyright (c) 2016 PayPal. All rights reserved.
//

#import "PPBaseViewController.h"
#import "PPReceiptOptionsController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReceiptEmailEntryController : PPBaseViewController

- (instancetype)initWithContent:(PPRetailReceiptEmailEntryViewContent *)content
                 suggestedEmail:(NSString *)suggestedEmail
                       callback:(PPReceiptDestinationCallback)callback;

@end
