//
//  ReaderSearchListener.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/19/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "RUADevice.h"

#ifndef ROAMreaderUnifiedAPI_RUAReaderSearchListener_h
#define ROAMreaderUnifiedAPI_RUAReaderSearchListener_h

@protocol RUADeviceSearchListener <NSObject>

/**
 * Invoked when a reader is discovered.
 * @param RoamReader
 * */
- (void)discoveredDevice:(RUADevice *)reader;

/**
 * Invoked when the discover process is complete.
 * */
- (void)discoveryComplete;

@end

#endif
