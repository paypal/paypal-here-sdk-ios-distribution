//
//  BluetoothManager.h
//  BLEBaseDriver
//
//  Created by Landi 联迪 - Robert on 13-8-7.
//  Copyright (c) 2013年 Landi 联迪. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "CommunicationCallBack.h"
#import "DeviceSearchListener.h"
#import "CommunicationManagerBase.h"
@class BLECommDriver;
@class SyncQueue;

@interface LDBluetoothManager : CommunicationManagerBase

+(LDBluetoothManager*)sharedInstance;
-(int)searchDevices:(id<DeviceSearchListener>)btsl;
-(int)searchDevices:(id<DeviceSearchListener>)btsl duration:(NSTimeInterval)timeout;
-(int)searchDevices:(id<DeviceSearchListener>)btsl duration:(NSTimeInterval)timeout lowRSSI:(NSInteger)lr hiRSSI:(NSInteger)hr; // 2016-06-06 16:35:10 新增用于RSSI限定
-(void)stopSearching;
-(int)openDevice:(NSString*) uuid;
-(int)openDevice:(NSString *)uuid cb:(id<CommunicationCallBack>) cb mode:(DeviceCommunicationMode)mode;
-(int)openDevice:(NSString *)uuid timeout:(long)timeout;
-(int)openDevice:(NSString *)uuid cb:(id<CommunicationCallBack>)cb mode:(DeviceCommunicationMode)mode timeout:(long)timeout;
-(int)exchangeData:(NSData *)data timeout:(long)timeout;
-(void)closeDevice;
-(void)closeResource;
-(int)exchangeData:(NSData*)data timeout:(long)timeout cb:(id<CommunicationCallBack>)cb;
-(int)cancelExchange;
-(BOOL)isConnected;
-(void)breakOpenDevice;
+(NSString*)getLibVersion;
 

@end
