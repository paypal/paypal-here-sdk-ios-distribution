//
//  PPMiuraUsbDevice.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/5/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPMiuraUsbDevice.h"
#import <ORSSerialPort/ORSSerialPort.h>
#import "PayPalRetailSDK+Private.h"

@interface PPMiuraUsbDevice () <
    ORSSerialPortDelegate
>
@property (nonatomic,strong) ORSSerialPort *port;
@property (nonatomic,strong) NSMutableOrderedSet *connectCallbacks;
@end

@implementation PPMiuraUsbDevice
-(instancetype)initWithPort:(NSString *)serialPort {
    if ((self = [super init])) {
        self.connectCallbacks = [NSMutableOrderedSet new];
        self.port = [ORSSerialPort serialPortWithPath:[serialPort stringByReplacingOccurrencesOfString:@"cu." withString:@"tty."]];
        self.port.baudRate = @115200;
        self.port.delegate = self;
        [self createJSObject];
    }
    return self;
}

-(BOOL)connect {
    if (self.port.isOpen) {
        return NO;
    }
    [self.port open];
    return YES;
}

-(void)createJSObject {
    JSValue *nativeCallbacks = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];

    __weak typeof(self) weakSelf = self;
    nativeCallbacks[@"isConnected"] = ^() {
        return weakSelf.port.isOpen;
    };
    nativeCallbacks[@"send"] = ^(JSValue *data, JSValue *callback) {
        NSData *dataToWrite = nil;
        if ([data isObject]) {
            // Partial send
            JSValue *fullString = data[@"data"];
            JSValue *offset = data[@"offset"];
            JSValue *length = data[@"len"];
            // TODO we could be cute about initializing without translating the whole string.
            NSData *fullData = [[NSData alloc] initWithBase64EncodedString:fullString.toString options:0];
            dataToWrite = [fullData subdataWithRange:NSMakeRange(offset.toNumber.longValue, length.toNumber.longValue)];
        } else {
            dataToWrite = [[NSData alloc] initWithBase64EncodedString:data.toString options:0];
        }
        if ([weakSelf writeData:dataToWrite fromQueue:NO]) {
          if (!callback.isUndefined && !callback.isNull) {
            [callback callWithArguments:@[]];
          }
        }
        // TODO callback if error...
    };
    nativeCallbacks[@"disconnect"] = ^() {
        if (weakSelf.port.isOpen) {
            SDK_DEBUG(@"device.miura", @"Disconnecting from %@", self.port.path);
            [weakSelf.port close];
        }
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

    self.impl = [[PPRetailPaymentDevice engine] createJSObject:@"MiuraDevice" withArguments:@[self.port.path, nativeCallbacks, [[PPRetailObject engine].converter toJsBool:YES]]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [PayPalRetailSDK deviceDiscovered:self.impl];
        [self.impl invokeMethod:@"connect" withArguments:nil];
    });
}

- (BOOL)writeData:(NSData *)data fromQueue:(BOOL)fromQueue
{
    BOOL ret = [self.port sendData:data];
    if (!ret) {
        SDK_ERROR(@"device.miura", @"Failed to send bytes to Miura device %@", self.port.path);
    }
    return ret;
}

-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data {
    if (data.length) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.impl invokeMethod:@"received" withArguments:@[[data base64EncodedStringWithOptions:0]]];
        });
    }
}

-(void)serialPortWasOpened:(ORSSerialPort *)serialPort {
    NSArray *notifySet;
    @synchronized (self.connectCallbacks) {
        // The array property will get cleared when the set is cleared unless we copy it
        notifySet = [NSArray arrayWithArray:[self.connectCallbacks array]];
        [self.connectCallbacks removeAllObjects];
    }
    for (JSValue *callback in notifySet) {
        [callback callWithArguments:nil];
    }
    SDK_DEBUG(@"device.miura", @"Miura serial channel open");
}

-(void)serialPortWasClosed:(ORSSerialPort *)serialPort {

}

-(void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error {
    SDK_DEBUG(@"device.miura", @"Miura serial channel closed.");
    [self.impl invokeMethod:@"onDisconnected" withArguments:@[error?:[NSNull null]]];
}

-(void)serialPort:(ORSSerialPort *)serialPort didReceiveResponse:(NSData *)responseData toRequest:(ORSSerialRequest *)request {
    NSAssert(NO, @"What the heck is this...");
}

-(void)serialPort:(ORSSerialPort *)serialPort requestDidTimeout:(ORSSerialRequest *)request {

}

-(void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort {

}
@end
