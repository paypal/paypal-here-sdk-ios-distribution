//
//  CommunicationManagerBase.h
//  BLEBaseDriver
//
//  Created by Landi 联迪 - Robert on 13-8-27.
//  Copyright (c) 2013年 Landi 联迪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceSearchListener.h"
#import "CommunicationCallBack.h"
#import "CommDownloadCallback.h"
#import "RDeviceInfo.h"

@class TMSDownloadCtrl;

typedef enum _enumDeviceCommunicationMode{
    MASTERSLAVE,
    DUPLEX,
}DeviceCommunicationMode;

typedef enum{
    LD_PlatformFilterType_COMMON,  // Platfrom || subPlatform || FileType
    LD_PlatformFilterType_M3X,     // SubPlatform || HardwareConfig
}LD_PlatformFilterType;

@interface LDPlatformFilter : NSObject<NSCopying>

- (instancetype)initForCommon:(NSString *)platform subPlatform:(NSString *)subPlatform fileType:(NSString *)fileType;
- (instancetype)initForM3X:(NSString *)subPlatform hardwareConfig:(NSString *)hardwareConfig;

@property (nonatomic, assign) LD_PlatformFilterType FilterType;
@property (nonatomic, strong) NSString *Platform;
@property (nonatomic, strong) NSString *SubPlatform;
@property (nonatomic, strong) NSString *FileType;
@property (nonatomic, strong) NSString *HardwareConfig;

@end

typedef enum{
    LD_MPOS_PROTOCOL_0,
    LD_MPOS_PROTOCOL_FY,
    LD_MPOS_PROTOCOL_RAW,
    LD_MPOS_PROTOCOL_0_NA,
}LD_MPOS_PROTOCOL;

@interface CommunicationManagerBase : NSObject

+ (CommunicationManagerBase *)sharedInstance:(DeviceCommunicationChannel)channel;
// (available but deprecated in v2.4.7.0520)
+ (int)searchDevices:(id<DeviceSearchListener>)dsl detectAudioDevice:(BOOL)detectAudioDevcie detectBluetooth:(BOOL)detectBluetoothDevice timeout:(long)timeout;
/*
 * searchDevices with detectDeviceType
 * detectDeviceType can be combination of value of DeviceCommunicationChannel.
 * If u want to search all device for any type, detectDeviceType should be ANYDEVICETYPE;
 */
+ (int)searchDevices:(id<DeviceSearchListener>)dsl detectDeviceType:(DeviceCommunicationChannel)flag timeout:(long)timeout;
/*
 * searchDevices with RSSI
 * u can search device in RSSI-Range by set lowRSSI and hiRSSI arguments.
 */
+ (int)searchDevices:(id<DeviceSearchListener>)dsl detectDeviceType:(DeviceCommunicationChannel)flag timeout:(long)timeout lowRSSI:(NSInteger)lr hiRSSI:(NSInteger)hr;
+ (void)stopSearching;
+ (NSString *)getLibVersion;
+ (void)switchLog:(BOOL)bOpen;
- (int)openDevice:(NSString *)identifier;
- (int)openDevice:(NSString *)identifier cb:(id<CommunicationCallBack>)cb mode:(DeviceCommunicationMode)mode;
- (int)openDevice:(NSString *)identifier timeout:(long)timeout;
- (int)openDevice:(NSString *)identifier cb:(id<CommunicationCallBack>)cb mode:(DeviceCommunicationMode)mode timeout:(long)timeout;
- (int)exchangeData:(NSData *)data timeout:(long)timeout cb:(id<CommunicationCallBack>)cb;
- (int)exchangeData:(NSData *)data timeout:(long)timeout;
- (int)cancelExchange;
- (void)closeDevice;
- (void)closeResource;
- (BOOL)isConnected;


- (void)breakOpenDevice;


+ (void)download:(RDeviceInfo *)di path:(NSString *)filePath callback:(id<CommDownloadCallback>)cb;
+ (void)download:(RDeviceInfo *)di path:(NSString *)filePath filter:(LDPlatformFilter *)pf callback:(id<CommDownloadCallback>)cb;
//+(void)TMSDownload:(RDeviceInfo*)di path:(NSString*)filePath callback:(id<CommDownloadCallback>)cb;
+ (TMSDownloadCtrl *)getTMSDownloadCtrl;

@end
