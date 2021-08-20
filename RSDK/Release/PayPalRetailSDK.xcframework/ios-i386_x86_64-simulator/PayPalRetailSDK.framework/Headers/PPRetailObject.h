//
//  PPRetailObject.h
//  Pods
//
//  Created by Metral, Max on 7/23/15.
//
//

#import <Foundation/Foundation.h>
#import "PPManticoreNativeInterface.h"

@interface PPRetailObject : NSObject<PPManticoreNativeObjectProtocol>
@property (nonatomic, strong) JSValue *impl;
@end
