//
//  ReaderStatusHandler.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/9/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef ROAMreaderUnifiedAPI_RUAStatusHandler_h
#define ROAMreaderUnifiedAPI_RUAStatusHandler_h

@protocol  RUADeviceStatusHandler <NSObject>

/**
 * Invoked when the reader is connected.
 * */
- (void)onConnected;

/**
 * Invoked when the reader is disconnected (unplugged).
 * */
- (void)onDisconnected;

/**
 * Invoked when the reader returns an error while connecting.
 * */
- (void)onError:(NSString *)message;

@optional

- (void)onPlugged;

- (void)onDetectionStarted;

- (void)onDetectionStopped;


@end

#endif
