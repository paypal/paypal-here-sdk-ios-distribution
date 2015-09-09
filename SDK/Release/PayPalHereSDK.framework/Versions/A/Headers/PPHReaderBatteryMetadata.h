//
//  PPHReaderBatteryMetadata.h
//  Bond
//
//  Created by Roman Punskyy on 6/19/12.
//  Copyright (c) 2012 PayPal UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(int, PPHReaderBatteryStatus) {
    /*!
     * Reader is currently running solely battery, reader is not charging.
     */
    ePPHReaderBatteryStatusOnBattery,
    
    /*!
     * Reader is currently charging. Running on battery which is charging.
     */
    ePPHReaderBatteryStatusCharging,
    
    /*!
     * Reader is charging, battery is fully charged.
     */
    ePPHReaderBatteryStatusChargedConnectedToPower,
    
    /*!
     * Reader running solely on battery and the battery is low.
     */
    ePPHReaderBatteryStatusBatteryLow
};


@interface PPHReaderBatteryMetadata : NSObject <NSCoding>
@property (nonatomic) PPHReaderBatteryStatus status;
@property (nonatomic) int level;
- (BOOL)connectedToPower;

+ (instancetype)batteryMetadataWithStatus:(PPHReaderBatteryStatus)status;
+ (instancetype)batteryMetadataWithStatus:(PPHReaderBatteryStatus)status level:(int)level;
- (instancetype)initBatteryMetadataForStatus:(PPHReaderBatteryStatus)status level:(int)level;

@end

