//
//  PPNativeDeviceManager.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/1/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPNativeDeviceManager.h"
#import "PayPalRetailSDK+Private.h"
#import "PPMiuraBluetoothDevice.h"
#import "PPRoamAudioReader.h"
#import "PPManticoreEngine+Private.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface PPNativeDeviceManager () <
EAAccessoryDelegate,
PPMiuraBluetoothDeviceDelegate,
PPRoamAudioReaderDelegate
>
@property (nonatomic,strong) NSMutableDictionary *knownDevices;

#ifdef INCLUDE_ROAM_AUDIO
@property (nonatomic,strong) PPRoamAudioReader *roam;
#endif
@end


@implementation PPNativeDeviceManager
-(instancetype)init {
    if ((self = [super init])) {
        self.knownDevices = [NSMutableDictionary new];
    }
    return self;
}

-(void)startWatching {
    NSArray *devices = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
    for (EAAccessory *device in devices) {
        NSNotification *fake = [[NSNotification alloc] initWithName:@"" object:self userInfo:@{EAAccessoryKey:device}];
        [self accessoryDidConnect:fake];
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    [notificationCenter addObserver:self
                           selector:@selector(accessoryDidConnect:)
                               name:EAAccessoryDidConnectNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(accessoryDidDisconnect:)
                               name:EAAccessoryDidDisconnectNotification
                             object:nil];
#ifdef INCLUDE_ROAM_AUDIO
    if([PayPalRetailSDK checkIfSwiperIsEligibleForMerchant]) {
        if (!self.roam) {
            self.roam = [[PPRoamAudioReader alloc] initWithDelegate:self];
        }
        [self.roam startListening];
    }
#endif
}

-(void)stopWatching {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:EAAccessoryDidDisconnectNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:EAAccessoryDidConnectNotification
                                object:nil];
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
#ifdef INCLUDE_ROAM_AUDIO
    if (self.roam) {
        [self.roam stopListening];
    }
#endif
}

#pragma mark -
#pragma Accessory connection handlers
-(void)accessoryDidConnect: (NSNotification*) n {
    EAAccessory *ea = [n.userInfo objectForKey: EAAccessoryKey];
    
    if (!ea || ![ea isKindOfClass:[EAAccessory class]]) {
        return;
    }
    
    NSSet *supportSet = [NSSet setWithArray:[NSBundle mainBundle].infoDictionary[@"UISupportedExternalAccessoryProtocols"]];
    if (![supportSet intersectsSet:[NSSet setWithArray:ea.protocolStrings]]) {
        SDK_DEBUG(@"paymentDevice", @"Ignoring device %@ with unsupported protocols.", ea.name);
        return;
    }
    
    JSValue *supported = [PPRetailObject engine].exportedItems[@"PaymentDevice"];
    NSAssert(!supported.isUndefined, @"PaymentDevice class not present in Core SDK Library.");
    supported = supported[@"isSupported"];
    NSDictionary *arguments = @{
                                @"id": [NSString stringWithFormat:@"%lu", (unsigned long) ea.connectionID],
                                @"name": ea.name ?: [NSNull null],
                                @"protocols": ea.protocolStrings ?: [NSNull null],
                                @"manufacturer": ea.manufacturer ?: [NSNull null],
                                @"modelNumber": ea.modelNumber ?: [NSNull null]
                                };
    
    JSValue *jsClass = [supported callWithArguments:@[arguments]];
    if (jsClass.isString) {
        NSString *readerClass = jsClass.toString;
        if (![readerClass isEqualToString:@"MiuraDevice"]) {
            SDK_ERROR(@"paymentDevice", @"Application does not support reader type %@", readerClass);
            return;
        }
        PPMiuraBluetoothDevice *knownDevice = self.knownDevices[ea.serialNumber];
        if (!knownDevice) {
            PPMiuraBluetoothDevice *miura = [[PPMiuraBluetoothDevice alloc] initWithAccessory:ea delegate:self];
            self.knownDevices[ea.serialNumber] = miura;
        } else if (!knownDevice.nativeReader.connected) {
            [knownDevice connectToNewAccessory:ea];
            [[[PayPalRetailSDK deviceManager] getDiscoveredDevices] enumerateObjectsUsingBlock:^(PPRetailPaymentDevice *pd, NSUInteger idx, BOOL * _Nonnull stop) {
                if (pd.connectionType == PPRetailreaderConnectionTypeBluetooth && ![[pd pendingUpdate] updateInProgress]) {
                    [pd connect:YES];
                }
            }];
        }
    }
}

- (void)accessoryDidDisconnect: (NSNotification*) n {
    EAAccessory *ea = [n.userInfo objectForKey: EAAccessoryKey];
    [[[PayPalRetailSDK deviceManager] getDiscoveredDevices] enumerateObjectsUsingBlock:^(PPRetailPaymentDevice *pd, NSUInteger idx, BOOL * _Nonnull stop) {
        if (pd.connectionType == PPRetailreaderConnectionTypeBluetooth && [ea.name isEqualToString:pd.id]) {
            [pd disconnect:^(PPRetailError *error) {}];
        }
    }];
}


#pragma mark -
#pragma mark - PPMiuraBluetoothDeviceDelegate

- (void)deviceRemovalRequestedForSerialNumber:(NSString *)serialNumber {
    if (!serialNumber) {
        return;
    }
    
    PPMiuraBluetoothDevice *knownDevice = self.knownDevices[serialNumber];
    if (knownDevice) {
        [self.knownDevices removeObjectForKey:serialNumber];
    }
}

#pragma mark -
#pragma mark - PPRoamAudioReaderDelegate

- (void)readerPluggedIn {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioReaderPluggedIn object:nil];
}

- (void)readerPluggedOut {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAudioReaderPluggedOut object:nil];
}

@end
