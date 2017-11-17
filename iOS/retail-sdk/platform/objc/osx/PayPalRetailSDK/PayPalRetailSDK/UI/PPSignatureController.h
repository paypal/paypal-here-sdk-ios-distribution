//
//  PPSignatureView.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/25/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface PPSignatureController : NSWindow
+(PPSignatureController*)signatureView:(JSValue*) options withCallback:(JSValue*)callback;
@end
