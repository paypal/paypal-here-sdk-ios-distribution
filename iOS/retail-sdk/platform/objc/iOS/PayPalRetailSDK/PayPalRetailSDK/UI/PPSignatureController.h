//
//  PPSignatureController.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/26/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "PPBaseViewController.h"

@interface PPSignatureController : PPBaseViewController

+(PPSignatureController *)signatureView:(JSValue *)options withCallback:(JSValue *)callback;

-(void)dismiss;

@end
