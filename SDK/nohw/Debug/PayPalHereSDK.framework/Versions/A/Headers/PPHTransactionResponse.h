//
//  PPHTransactionResponse.h
//  PayPalHereSDK
//
//  Created by Pavlinsky, Matthew on 8/10/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPHError.h"
#import "PPHTransactionRecord.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPHTransactionResponse : NSObject

@property (nonatomic,strong) PPHError* error;
@property (nonatomic,strong) PPHTransactionRecord* record;

@property (nonatomic,assign) BOOL isSignatureRequiredToFinalize;

@end
