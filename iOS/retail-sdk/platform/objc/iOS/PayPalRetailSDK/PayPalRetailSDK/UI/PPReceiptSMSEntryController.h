//
//  PPReceiptSMSEntryController.h
//  PayPal Retail SDK
//
//  Created by Pavlinsky, Matthew on 4/8/16.
//  Copyright (c) 2016 PayPal. All rights reserved.
//

#import "PPBaseViewController.h"
#import "PPReceiptOptionsController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReceiptSMSEntryController : PPBaseViewController <
UIPickerViewDelegate,
UIPickerViewDataSource>

- (instancetype)initWithContent:(PPRetailReceiptSMSEntryViewContent *)content
                   suggestedPhone:(NSString *)suggestedPhone
                         callback:(PPReceiptDestinationCallback)callback;

@end
