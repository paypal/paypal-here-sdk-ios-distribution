//
//  NoHWCardReaderManager.m
//  NOHWSampleApp
//
//  Created by Samuel Jerome on 7/30/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "NoHWCardReaderManager.h"
#import "MTSCRA.h"

static  MTSCRA *mtSCRALib;
static void (^trackDataReadyBlock)(PPHCardSwipeData *);
static void (^connectionChangedBlock)(BOOL);

@implementation NoHWCardReaderManager

+(MTSCRA *)getMtSCRALib {
    if (!mtSCRALib) {
        mtSCRALib = [[MTSCRA alloc] init];
        [mtSCRALib listenForEvents:(TRANS_EVENT_OK|TRANS_EVENT_START|TRANS_EVENT_ERROR)];
        
        //Audio
        [mtSCRALib setDeviceType:(MAGTEKAUDIOREADER)];
        [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(dataEvent:) name:@"trackDataReadyNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(devConnStatusChange) name:@"devConnectionNotification" object:nil];

    }
    return mtSCRALib;
}

+(void) listenForCardsWithCallbackBlock:(void (^)(PPHCardSwipeData *))readyBlock andDeviceConnectedBlock:(void (^)(BOOL))conChangedBlock{
    mtSCRALib = [NoHWCardReaderManager getMtSCRALib];
    [mtSCRALib openDevice];
    trackDataReadyBlock = readyBlock;
    connectionChangedBlock = conChangedBlock;
}

+(void) stopListening {
    [mtSCRALib closeDevice];
}

+(void)dataEvent:(id)notification {
    NSNumber *status = [[notification userInfo] valueForKey:@"status"];
    if ([status intValue] == TRANS_STATUS_OK) {
        PPHCardSwipeData *swipeData = [[PPHCardSwipeData alloc] initWithTrack1:[mtSCRALib getTrack1] track2:[mtSCRALib getTrack2] readerSerial:[mtSCRALib getDeviceSerial] withType:@"MAGTEK" andExtraInfo:@{@"ksn":[mtSCRALib getKSN]}];
        [swipeData parseTracks:[mtSCRALib getMaskedTracks]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (trackDataReadyBlock) {
                trackDataReadyBlock(swipeData);
            }
        });
    }
}

+(void)devConnStatusChange {
    mtSCRALib = [NoHWCardReaderManager getMtSCRALib];
    if (connectionChangedBlock) {
        connectionChangedBlock([mtSCRALib isDeviceConnected]);
    }
}

+(BOOL)isDeviceConnected {
    mtSCRALib = [NoHWCardReaderManager getMtSCRALib];
    return [mtSCRALib isDeviceConnected];
}

@end
