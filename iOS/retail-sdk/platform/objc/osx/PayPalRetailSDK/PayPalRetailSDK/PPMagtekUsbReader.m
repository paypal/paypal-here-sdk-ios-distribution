//
//  PPMagtekUsbReader.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/17/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPMagtekUsbReader.h"
#import <IOKit/hid/IOHIDDevice.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "PayPalRetailSDK+Private.h"

@interface PPMagtekUsbReader ()
@property (nonatomic,assign) IOHIDDeviceRef device;
@property (nonatomic,strong) NSString *serial;
@property (nonatomic,strong) NSMutableData *inputBuffer;
@property (nonatomic,strong) NSMutableOrderedSet *connectCallbacks;
-(void)report:(NSData*)data;
@end


void HID_Callback(void *                  context,
                         IOReturn                result,
                         void *                  sender,
                         IOHIDReportType         type,
                         uint32_t                reportID,
                         uint8_t *               report,
                         CFIndex                 reportLength){
    if (reportLength > 0 && reportLength < 1024) {
        NSData *reportData = [NSData dataWithBytes:report length:reportLength];
        PPMagtekUsbReader *monitor = (__bridge PPMagtekUsbReader *)context;
        [monitor report:reportData];
    }
}

@implementation PPMagtekUsbReader
-(instancetype)initWithDevice:(IOHIDDeviceRef)device andSerial:(NSString *)serial {
    if ((self = [super init])) {
        self.device = device;
        self.serial = serial;
        self.isAvailable = YES;
        self.connectCallbacks = [[NSMutableOrderedSet alloc] init];
        [self createJSObject];
    }
    return self;
}

-(BOOL)connect {
    if (!self.isAvailable) {
        return NO;
    }
    self.inputBuffer = [[NSMutableData alloc] initWithCapacity:1024];
    IOHIDDeviceOpen(self.device, 0);
    IOHIDDeviceRegisterInputReportCallback(self.device, (uint8_t*)self.inputBuffer.bytes, 1024, HID_Callback, (__bridge void *) self);
    NSArray *notifySet;
    @synchronized (self.connectCallbacks) {
        // The array property will get cleared when the set is cleared unless we copy it
        notifySet = [NSArray arrayWithArray:[self.connectCallbacks array]];
        [self.connectCallbacks removeAllObjects];
    }
    for (JSValue *callback in notifySet) {
        [callback callWithArguments:nil];
    }
    return YES;
}

-(void)disconnect {
    if (self.inputBuffer) {
        IOHIDDeviceRegisterInputReportCallback(self.device, NULL, 0, NULL, NULL);
        IOHIDDeviceClose(self.device, 0);
        self.inputBuffer = nil;
        [self connect];
    }
}

-(void)report:(NSData*)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.impl invokeMethod:@"received" withArguments:@[[data base64EncodedStringWithOptions:0]]];
    });
}

-(void)createJSObject {
    JSValue *nativeCallbacks = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];

    __weak typeof(self) weakSelf = self;
    nativeCallbacks[@"isConnected"] = ^() {
        return weakSelf.isAvailable && weakSelf.inputBuffer;
    };
    nativeCallbacks[@"send"] = ^(JSValue *data, JSValue *callback) {
    };
    nativeCallbacks[@"connect"] = ^(JSValue *callback) {
        if (!callback.isNull && !callback.isUndefined) {
            JSValueProtect([PPRetailObject engine].globalContext, callback.JSValueRef);
            @synchronized (weakSelf.connectCallbacks) {
                [weakSelf.connectCallbacks addObject:callback];
            }
        }
        [weakSelf connect];
    };
    nativeCallbacks[@"disconnect"] = ^() {
        [weakSelf disconnect];
    };
    
    self.impl = [[PPRetailObject engine] createJSObject:@"MagtekRawUsbReaderDevice" withArguments:@[self.serial, nativeCallbacks]];
    self.impl[@"manufacturer"] = @"Magtek";
    dispatch_async(dispatch_get_main_queue(), ^{
        [PayPalRetailSDK deviceDiscovered:self.impl];
    });
}
@end
