//
//  PPMiuraBluetoothDevice.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPMiuraBluetoothDevice.h"
#import "PayPalRetailSDK+Private.h"
#import "PPRetailUtils.h"

@interface PPMiuraBluetoothDevice () <
EAAccessoryDelegate,
NSStreamDelegate
>

@property (nonatomic, strong) EASession *session;
@property (nonatomic, strong) NSMutableData* queuedData;
@property (nonatomic, strong) NSMutableArray *callbackQueue;
@property (nonatomic, weak) id<PPMiuraBluetoothDeviceDelegate> delegate;

@end

@implementation PPMiuraBluetoothDevice
- (instancetype)initWithAccessory:(EAAccessory *)accessory delegate:(id<PPMiuraBluetoothDeviceDelegate>)delegate {
    if ((self = [self init])) {
        self.nativeReader = accessory;
        self.delegate = delegate;
        [self createJSObject];
    }
    return self;
}

- (void)destroy {
    [self.impl invokeMethod:@"destroy" withArguments:nil];
    self.impl = nil;
    [self disconnect];
}

- (void)createJSObject {
    
    JSValue *nativeCallbacks = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];
    
    __weak typeof(self) weakSelf = self;
    
    nativeCallbacks[@"isConnected"] = ^() {
        return [weakSelf isConnected];
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
        
        [self.callbackQueue addObject:[@{
                                       @"len" : @(dataToWrite.length),
                                       @"callback": callback
                                       } mutableCopy]];
        [weakSelf writeData:dataToWrite fromQueue:NO];
    };
    
    nativeCallbacks[@"connect"] = ^(JSValue *callback) {
        if ([weakSelf connect]) {
            [callback callWithArguments:nil];
        } else {
            JSValue *error = [JSValue valueWithNewErrorFromMessage:@"DEVICE_UNAVAILABLE" inContext:[PPRetailObject engine].context];
            [PPRetailUtils completeWithCallback:callback arguments:@[error]];
        }
    };
    
    nativeCallbacks[@"disconnect"] = ^(JSValue *callback) {
        [weakSelf disconnect];
        [PPRetailUtils completeWithCallback:callback arguments:nil];
    };
    
    nativeCallbacks[@"removed"] = ^(JSValue *callback) {
        [weakSelf disconnect];
        [weakSelf.delegate deviceRemovalRequestedForSerialNumber:weakSelf.nativeReader.serialNumber];
        [PPRetailUtils completeWithCallback:callback arguments:nil];
    };
    
    JSValue *deviceBuilder = [[PPRetailObject engine] createJSObject:@"DeviceBuilder" withArguments:nil];
    NSArray *args = @[@"MIURA", self.nativeReader.name, [[PPRetailObject engine].converter toJsBool:NO], nativeCallbacks];
    self.impl = [deviceBuilder invokeMethod:@"build" withArguments:args];
    
    [PPRetailUtils dispatchOnMainThread:^{
        [PayPalRetailSDK deviceDiscovered:weakSelf.impl];
    }];
}

- (BOOL)isConnected {
    return self.nativeReader.isConnected && self.session;
}

- (BOOL)connectToNewAccessory:(EAAccessory*)accessory {
    if (self.nativeReader && accessory != self.nativeReader) {
        [self disconnect];
    }
    
    self.nativeReader = accessory;
    return [self connect];
}

-(BOOL)connect {
    
    if ([self isConnected]) {
        return YES;
    }
    
    if (!self.nativeReader.connected) {
        return NO;
    }

    self.session = [[EASession alloc] initWithAccessory:self.nativeReader forProtocol:@"com.paypal.here.reader"];
    if (self.session) {
        self.callbackQueue = [NSMutableArray new];
        self.queuedData = [NSMutableData new];
        [self.session.inputStream setDelegate:self];
        [self.session.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.session.outputStream setDelegate:self];
        [self.session.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.session.inputStream open];
        [self.session.outputStream open];
        return YES;
    }
    return NO;
}
    
- (void)disconnect {
    self.callbackQueue = nil;
    self.queuedData = nil;
    if (self.session) {
        [[self.session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self.session inputStream] setDelegate:nil];
        [[self.session outputStream] setDelegate:nil];
        [[self.session inputStream] close];
        [[self.session outputStream] close];
        self.session = nil;
    }
}
    
    
#pragma mark -
#pragma mark Stream handling
- (BOOL)writeData:(NSData *)data fromQueue:(BOOL)fromQueue
{
    BOOL bRet = YES;
    if (self.session) {
        NSOutputStream *oStream = [self.session outputStream];
        
        // If there is no space to write, or there is someone already waiting in queue we should go to the back of the queue to not screw up the timing.
        if (![oStream hasSpaceAvailable] || (!fromQueue && self.queuedData.length > 0)) {
            [self.queuedData appendData:data];
            bRet = NO;
        } else {
            // todo: check if there is ever we need to cache data in case we would write it all?
            // write all data
            NSUInteger writtenBytes = 0;
            const uint8_t *pData = [data bytes];
            while ([oStream hasSpaceAvailable] && writtenBytes != data.length) {
                NSUInteger maxLength = data.length - writtenBytes;
                NSInteger r = [oStream write:pData+writtenBytes maxLength:MIN(8192,maxLength)];
                if (r == -1) {
                    // error
                    bRet = NO;
                    break;
                }
                writtenBytes += r;
            }
            
            if (fromQueue) {
                [self.queuedData replaceBytesInRange:NSMakeRange(0, writtenBytes) withBytes:NULL length:0];
            } else if (writtenBytes != data.length) {
                [self.queuedData appendData:[data subdataWithRange:NSMakeRange(writtenBytes, data.length - writtenBytes)]];
            }
            
            NSUInteger unassignedBytes = writtenBytes;
            while (unassignedBytes > 0) {
                NSMutableDictionary *callbackProfile = self.callbackQueue[0];
                NSUInteger remainingLen = [callbackProfile[@"len"] unsignedIntegerValue];
                
                if (remainingLen >= unassignedBytes) {
                    remainingLen -= unassignedBytes;
                    unassignedBytes = 0;
                } else {
                    unassignedBytes -= remainingLen;
                    remainingLen = 0;
                }
 
                if (remainingLen == 0) {
                    [self.callbackQueue removeObjectAtIndex:0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [callbackProfile[@"callback"] callWithArguments:nil];
                    });
                } else {
                    callbackProfile[@"len"] = @(remainingLen);
                }
            }
        }
    } else {
        bRet = NO;
    }
    return bRet;
}


// Handle communications from the streams.
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        case NSStreamEventHasBytesAvailable:
        {
            if (theStream == [self.session inputStream]) {
                // Process the incoming stream data.
                if (self.impl) {
                    NSMutableData *data = nil;
                    while (self.session.inputStream.hasBytesAvailable) {
                        uint8_t buf[2048];
                        NSInteger len = 0;
                        len = [self.session.inputStream read:buf maxLength:2048];
                        if(len) {
                            if (data == nil) {
                                data = [NSMutableData dataWithBytes:buf length:len];
                            } else {
                                [data appendBytes:(const void *)buf length:len];
                            }
                        } else {
                            break;
                        }
                    }
                    if (data) {
                        [self.impl invokeMethod:@"received" withArguments:@[[data base64EncodedStringWithOptions:0]]];
                    }
                }
                // process data
            } else if (theStream == [self.session outputStream]) {
                // write data
            } else {
                // not a case
            }
            
        }
            break;
        case NSStreamEventHasSpaceAvailable:
            // Send the next queued command.
            while (self.session.outputStream && [self.session.outputStream hasSpaceAvailable] && self.queuedData.length > 0) {
                //                NSData* queuedData = [self.sendDataQueue objectAtIndex:0];
                //                [self.sendDataQueue removeObjectAtIndex:0];
                //
                // TODO: Handle case where space is available but it's not enough for the whole package...I really hope this doesn't happen.
                [self writeData:self.queuedData fromQueue:YES];
            }
            break;
        default:
            break;
    }
}
@end
