//
//  PPHReceiptOption.h
//  PayPalHereSDK
//
//  Created by Beiser, Chris on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHTransactionRecord.h"

typedef void (^PPHReceiptOptionBlock)(PPHTransactionRecord *record, UIView *presentedView);
typedef BOOL (^PPHReceiptOptionPredicateBlock)(PPHTransactionRecord *record);

/*
 * A class to define an option presented during the receipt flow alongside "Email" and "Text"
 * A common use case for this would be to present a "Print" option to send the receipt to a printer
 */
@interface PPHReceiptOption : NSObject

- (instancetype)initWithBlock:(PPHReceiptOptionBlock)optionBlock predicate:(PPHReceiptOptionPredicateBlock)shouldShowOption buttonLabel:(NSString *)buttonLabel;

/*
 * The text that will appear in the receipt options table
 */
@property (nonatomic, copy) NSString *optionButtonLabelText;

/*
 * The block that will get executed when the user selects this option
 */
@property (nonatomic, strong) PPHReceiptOptionBlock optionBlock;

/*
 * A predicate block that gets executed before displaying the options that determines wether or not
 * this option should be available
 */
@property (nonatomic, strong) PPHReceiptOptionPredicateBlock shouldShowOption;

@end
