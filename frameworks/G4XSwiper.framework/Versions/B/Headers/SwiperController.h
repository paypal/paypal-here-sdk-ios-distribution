//
//  SwiperController.h
//  SwiperAPI-4.8.6
//
//  Created by TeresaWong on 8/6/10.
//  Copyright 2011 BBPOS LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SwiperControllerStateIdle,
    SwiperControllerStateWaitingForDevice,
    SwiperControllerStateRecording,
	SwiperControllerStateDecoding
} SwiperControllerState;

typedef enum {
    SwiperControllerDecodeResultSuccess,
	SwiperControllerDecodeResultSwipeFail,
	SwiperControllerDecodeResultCRCError,
	SwiperControllerDecodeResultCommError,
	SwiperControllerDecodeResultUnknownError,
    SwiperControllerDecodeResultTapError,
    SwiperControllerDecodeResultCardNotSupported
} SwiperControllerDecodeResult;

@protocol SwiperControllerDelegate;

@interface SwiperController : NSObject {
	NSObject <SwiperControllerDelegate>* delegate;
	BOOL detectDeviceChange;
    SwiperControllerState swiperState;
}

@property (nonatomic, assign) NSObject <SwiperControllerDelegate>* delegate;
@property (nonatomic, assign) BOOL detectDeviceChange;
@property (nonatomic, assign) double swipeTimeout;
@property (nonatomic, assign) double chargeUpTime;
@property (nonatomic, assign) double ksnChargeUpTime;
@property (nonatomic, assign) BOOL fskRequired;


- (BOOL)isDevicePresent;
- (void)startSwiper;
- (void)stopSwiper;
- (SwiperControllerState)getSwiperState;
- (void)getSwiperKsn;
- (void)isSwiperHere;
- (NSString*)packEncTrackData:(NSString *)formatID
                     encTrack:(NSString *)encTrack
                 partialTrack:(NSString *)partialTrack;
- (NSString*)getSwiperAPIVersion;
- (NSString*)getSwiperFirmwareVersion;
- (NSString*)getSwiperBatteryVoltage;
- (void)closeSwiper;

@end

@protocol SwiperControllerDelegate <NSObject>

- (void)onDecodeCompleted:(NSDictionary *)data;

- (void)onDecodeError:(SwiperControllerDecodeResult)decodeState;
- (void)onError:(NSString *)errorMessage;
- (void)onInterrupted;
- (void)onNoDeviceDetected;
- (void)onTimeout;
- (void)onWaitingForCardSwipe;
- (void)onWaitingForDevice;
- (void)onGetKsnCompleted:(NSString *)ksn;
- (void)onCardSwipeDetected;
- (void)onSwiperHere:(BOOL)isHere;

@optional
- (void)onDevicePlugged;
- (void)onDeviceUnplugged;

@end
