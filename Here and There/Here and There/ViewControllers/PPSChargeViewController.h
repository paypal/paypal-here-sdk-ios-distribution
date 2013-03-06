//
//  PPSChargeViewController.h
//  Here and There
//
//  Created by Metral, Max on 2/27/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSBaseViewController.h"

@class PPHInvoice;

@interface PPSChargeViewController : PPSBaseViewController
-(id)initWithInvoice: (PPHInvoice*) invoice andLocationWatcher: (PPHLocationWatcher*) watcher;
@end
