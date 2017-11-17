//
//  PPRetailObject.m
//  Pods
//
//  Created by Metral, Max on 7/23/15.
//
//

#import "PPRetailObject.h"

@interface PPRetailObject () <
PPManticoreNativeObjectProtocol
>
@property (nonatomic, strong) JSValue *impl;
@end

@implementation PPRetailObject
+ (Class)nativeClassForObject:(JSValue *)value {
    return self;
}

-(instancetype)initFromJavascript:(JSValue *)value {
    if ((self = [super init])) {
        self.impl = value;
    }
    return self;
}

static PPManticoreEngine *_engine;
+ (void)setManticoreEngine:(PPManticoreEngine *)engine {
    _engine = engine;
}

+ (PPManticoreEngine *)engine {
    return _engine;
}

@end
