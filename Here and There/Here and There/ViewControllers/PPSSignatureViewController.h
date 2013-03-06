//
//  PPSSignatureViewController.h
//  Here and There
//
//  Created by Metral, Max on 3/4/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>
#import "PPSBaseViewController.h"

@interface PPSSignatureViewController : PPSBaseViewController

-(id)initWithInvoice: (PPHInvoice*) invoice andCardData: (PPHCardSwipeData*) cardData;

@end
