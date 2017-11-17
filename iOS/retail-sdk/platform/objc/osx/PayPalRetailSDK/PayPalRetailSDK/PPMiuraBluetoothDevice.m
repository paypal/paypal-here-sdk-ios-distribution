//
//  MiuraBluetoothDevice.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/4/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPMiuraBluetoothDevice.h"
#import "PayPalRetailSDK+Private.h"

@interface PPMiuraBluetoothDevice () <
    IOBluetoothRFCOMMChannelDelegate
>
@property (nonatomic,strong) IOBluetoothRFCOMMChannel *channel;
@property (nonatomic,strong) IOBluetoothDevice *device;
@property (nonatomic,strong) NSMutableOrderedSet *connectCallbacks;
@property (nonatomic,strong) NSMutableOrderedSet *disconnectCallbacks;
@end

@implementation PPMiuraBluetoothDevice
-(instancetype)initWithDevice:(IOBluetoothDevice *)device {
    if ((self = [super init])) {
        self.device = device;
        self.connectCallbacks = [[NSMutableOrderedSet alloc] init];
        [self createJSObject];
    }
    return self;
}

-(BOOL)connect {
    if (!self.device.isConnected) {
        return NO;
    }
    IOBluetoothRFCOMMChannel *channel;
    if ([self.device openRFCOMMChannelAsync:&channel withChannelID:1 delegate:self] != kIOReturnSuccess) {
        SDK_DEBUG(@"device.miura", @"Could not open RFComm channel for Miura device.");
        self.channel = nil;
        return NO;
    }
    self.channel = channel;
    return YES;
}

-(BOOL)disconnect {
    if (!self.device.isConnected) {
        return NO;
    }
    [self.channel closeChannel];
    self.channel = nil;
    return YES;
}

-(void)createJSObject {
    JSValue *nativeCallbacks = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];

    __weak typeof(self) weakSelf = self;
    nativeCallbacks[@"isConnected"] = ^() {
        // TODO not sure both are required
        return weakSelf.channel.isOpen && weakSelf.device.isConnected;
    };
    nativeCallbacks[@"send"] = ^(JSValue *data) {
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
        [weakSelf writeData:dataToWrite fromQueue:NO];
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
    nativeCallbacks[@"disconnect"] = ^(JSValue *callback) {
        if (!callback.isNull && !callback.isUndefined) {
            JSValueProtect([PPRetailObject engine].globalContext, callback.JSValueRef);
            @synchronized (weakSelf.disconnectCallbacks) {
                [weakSelf.disconnectCallbacks addObject:callback];
            }
        }
        [weakSelf disconnect];
    };

    self.impl = [[PPRetailPaymentDevice engine] createJSObject:@"MiuraDevice" withArguments:@[self.device.name, nativeCallbacks,[[PPRetailObject engine].converter toJsBool:NO]]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [PayPalRetailSDK deviceDiscovered:self.impl];
        [self.impl invokeMethod:@"connect" withArguments:nil];
    });
    
}

- (BOOL)writeData:(NSData *)data fromQueue:(BOOL)fromQueue
{
    IOReturn ret = [self.channel writeSync:(void*)data.bytes length:data.length];
    if (ret != kIOReturnSuccess) {
        SDK_ERROR(@"Failed to send bytes to Miura device %@ (error %x)", self.device.name, ret);
    }
    return (kIOReturnSuccess == ret);
}

//delegate RFComm channel
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel
                           status:(IOReturn)error {
    NSArray *notifySet;
    @synchronized (self.connectCallbacks) {
        // The array property will get cleared when the set is cleared unless we copy it
        notifySet = [NSArray arrayWithArray:[self.connectCallbacks array]];
        [self.connectCallbacks removeAllObjects];
    }
    if (error != kIOReturnSuccess) {
        SDK_WARN(@"device.miura", @"Failed to open RFComm channel for Miura. Error %d", error);

        JSValue *jsError = [JSValue valueWithNewErrorFromMessage:@"DEVICE_UNAVAILABLE" inContext:[PPRetailObject engine].context];
        jsError[@"code"] = @(error);

        for (JSValue *callback in notifySet) {
            [callback callWithArguments:@[jsError]];
        }
        return;
    }
    for (JSValue *callback in notifySet) {
        [callback callWithArguments:nil];
    }
    SDK_DEBUG(@"device.miura", @"Miura RFComm channel open");
}

//connection closed.
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel {
    SDK_INFO(@"device.miura", @"Miura RFComm channel closed");
    NSArray *notifySet;
    @synchronized (self.disconnectCallbacks) {
        // The array property will get cleared when the set is cleared unless we copy it
        notifySet = [NSArray arrayWithArray:[self.disconnectCallbacks array]];
        [self.disconnectCallbacks removeAllObjects];
    }
    for (JSValue *callback in notifySet) {
        [callback callWithArguments:nil];
    }
    [self.impl invokeMethod:@"disconnected" withArguments:nil];
}

//reading data from rfcomm
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength {
    if (dataLength > 0) {
        NSData *received = [NSData dataWithBytes:dataPointer length:dataLength];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.impl invokeMethod:@"received" withArguments:@[[received base64EncodedStringWithOptions:0]]];
        });
    }
}

//writing data from rfcomm
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error {
    // Nothing to say here yet.
}

@end
