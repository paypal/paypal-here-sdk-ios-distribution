//
//  MFIBluetoothManager.h
//  MPOSCommunicationManager
//
//  Created by Wu Robert on 10/13/15.
//  Copyright (c) 2015 Landi 联迪. All rights reserved.
//

#import "LDBluetoothManager.h"

@interface MFIBluetoothManager : LDBluetoothManager

+(MFIBluetoothManager*)sharedInstance;
-(NSArray*)getDevicesSet;

@end
