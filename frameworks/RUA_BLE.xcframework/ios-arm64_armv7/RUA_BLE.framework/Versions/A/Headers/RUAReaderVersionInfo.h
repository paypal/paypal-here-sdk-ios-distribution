//
//  RUAReaderVersionInfo.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 3/9/15.
//  Copyright (c) 2015 ROAM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RUAFileVersionInfo.h"

@interface RUAReaderVersionInfo : NSObject

/**
 * Hardware Type
 * */
@property NSString *hardwareType;

/**
 * Boot File Version
 * */
@property RUAFileVersionInfo *bootFileVersion;

/**
 * Control File Version
 * */
@property RUAFileVersionInfo *controlFileVersion;

/**
 * List User File Versions
 * */
@property NSArray *userFileVersions;

/**
 * List Parameter File Versions
 * */
@property NSArray *parameterFileVersions;

/**
 * EMV Kernel Version
 * */
@property NSString *emvKernelVersion;

/**
 * Key Version
 * */
@property NSString *keyVersion;

/**
 * PED Version
 * */
@property NSString *pedVersion;

/**
 * Font File Version
 * */
@property NSString *fontFileVersion;

/**
 * Product Serial Number
 * */
@property NSString *productSerialNumber;

/**
 * Bluetooth Mac Address
 * */
@property NSString *bluetoothMacAddress;

- (NSString *) toString;

- (RUAFileVersionInfo*) getFileVerionsInfoFor:(RUAFileVersionInfo*)info;

@end
