//
//  PPHSignatureViewController.h
//  PayPalHereSDK
//
//  Created by Erceg,Boris on 19/02/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPHSDKBaseViewController.h"
#import "PPHCardEnums.h"
#import "PPHAmount.h"

@class PPHSignatureViewController;

////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol PPHSignatureViewControllerDelegate <NSObject>

- (void)takeSignatureViewController:(PPHSignatureViewController *)viewController collectedSignatureImage:(UIImage *)signatureImage;
- (void)takeSignatureViewControllerCanceledCollectingSignature:(PPHSignatureViewController *)viewController;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPHSignatureViewController : PPHSDKBaseViewController

+ (instancetype)newWithDelegate:(id<PPHSignatureViewControllerDelegate>)delegate
                      forRefund:(BOOL)forRefund
                         amount:(PPHAmount *)amount
               maskedCardNumber:(NSString *)maskedCardNumber
                       cardType:(PPHCreditCardType)cardType
               hideCancelButton:(BOOL)hideCancelButton;

@end
