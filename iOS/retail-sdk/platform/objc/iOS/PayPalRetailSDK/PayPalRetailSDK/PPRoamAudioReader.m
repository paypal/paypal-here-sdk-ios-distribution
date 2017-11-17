//
//  PPRoamAudioReader.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/21/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//
#ifdef INCLUDE_ROAM_AUDIO

#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CoreTelephony/CTCallCenter.h>
#import "PPRoamAudioReader.h"
#import "SwiperController.h"
#import "PayPalRetailSDK+Private.h"
#import "PPRetailUtils.h"

@interface PPRoamAudioReader () <
    SwiperControllerDelegate,
    AVAudioPlayerDelegate
>

@property (nonatomic, strong) NSMutableOrderedSet *connectCallbacks;
@property (nonatomic, strong) SwiperController *swiper;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSTimer *waitedTooLongForRoamDeviceTimer;
@property (nonatomic, strong) NSTimer *retryInitialRoamDetectionTimer;
@property (nonatomic, assign) NSInteger isSwiperHereRetryCount;
@property (nonatomic, assign) BOOL ranDetection;
@property (nonatomic, assign) BOOL itsAReader;
@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, assign) BOOL youveBeenWarned;
@property (nonatomic, assign) BOOL retry;
@property (nonatomic, assign) BOOL listening;
@property (nonatomic, copy) NSString *previousAudioCategory;
@property (nonatomic, weak) id<PPRoamAudioReaderDelegate> delegate;

@end

@implementation PPRoamAudioReader

- (instancetype)initWithDelegate:(id<PPRoamAudioReaderDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}


- (BOOL) isAudioInUseForSomethingElse {
    if ([[AVAudioSession sharedInstance] isOtherAudioPlaying]) {
        return YES;
    }
    return [[[CTCallCenter alloc] init] currentCalls].count > 0;
}

- (void)startListening {
    if (self.listening) {
        return;
    }
    
    SDK_DEBUG(@"PPRoamAudioReader", @"PPRoamAudioReader::startListening");
    self.listening = YES;
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(routeChanged:) name: AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:0 context:nil];
    
    if ([self isAudioInUseForSomethingElse] && [self isHeadsetPluggedIn]) {
        self.ranDetection = YES;
        self.itsAReader = NO;
        return;
    }
    
    if ([self isHeadsetPluggedIn]) {
        [self newAudioState:YES fromWarningPlayback: NO];
    }
}

- (void)stopListening {
    if (!self.listening) {
        return;
    }
    
    SDK_DEBUG(@"PPRoamAudioReader", @"PPRoamAudioReader::stopListening");
    self.listening = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume"];
    }
    @catch (NSException *exception) {
        // If we never regsitered succesfully, this throws. We don't generally care.
    }

    [self closeRoamAudio];
}

- (void)dealloc {
    [self stopListening];
    self.swiper.delegate = nil;
    self.swiper = nil;
}

- (void)playSound:(NSString *)fName ofType:(NSString *)ext {
    NSString *path  = [[PayPalRetailSDK sdkBundle] pathForResource:fName ofType:ext];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [self pumpUpTheVolume];
        [PPRetailUtils dispatchOnMainThread:^{
            [[AVAudioSession sharedInstance] setActive:YES error: nil];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            NSURL *pathURL = [NSURL fileURLWithPath:path];
            SDK_DEBUG(@"PPRoamAudioReader", @"AudioReaderDelegate::Playing warning");
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:nil];
            self.player.volume = 1.0;
            if ([self youveBeenWarned] && UIAccessibilityIsVoiceOverRunning()) {
                self.player.enableRate = YES;
                self.player.rate = 1.75;
            }
            [self.player setDelegate:self];
            [self.player play];
        }];
    }
    else {
        //file not found error
        NSAssert(NO, @"Sound file %@ was not found. Usually this means the resource bundle has not been added to the project.", fName);
        [self handleAudioPlayerFinish:YES];
    }
}

- (void)handleAudioPlayerFinish:(BOOL)succesfully {
    SDK_DEBUG(@"PPRoamAudioReader", @"AudioReaderDelegate::audioPlayerDidFinishPlaying");
    self.player.delegate = nil;
    self.player = nil;
    if (succesfully && [self isHeadsetPluggedIn]) {
        [self setYouveBeenWarned: YES];
        [self newAudioState:YES fromWarningPlayback:YES];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)thePlayer successfully:(BOOL)flag {
    [self handleAudioPlayerFinish:flag];
}

- (void)startAudioDetect:(BOOL)wasWarning {
    NSString *currentCategory = [[AVAudioSession sharedInstance] category];
    if (!self.previousAudioCategory || ![currentCategory isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        self.previousAudioCategory = currentCategory;
    }
    SDK_DEBUG(@"PPRoamAudioReader", @"AudioReaderDelegate::startAudioDetect");
    if (!self.youveBeenWarned || (!wasWarning && UIAccessibilityIsVoiceOverRunning())) {
        // Figure out the warning sound manually, to reduce filesize
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        if ([language isEqualToString:@"es"]) {
            [self playSound:@"RemoveHeadphones_es" ofType:@"wav"];
        } else if ([language isEqualToString:@"ja"]) {
            [self playSound:@"RemoveHeadphones_ja" ofType:@"wav"];
        } else if ([language rangeOfString:@"zh"].location != NSNotFound) {
            [self playSound:@"RemoveHeadphones_zh" ofType:@"m4a"];
        } else { // Default to English
            [self playSound:@"RemoveHeadphones_en" ofType:@"wav"];
        }
        return;
    }
    
    [self ensureRoam];
    
    __weak typeof(self)weakSelf = self;
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        SDK_DEBUG(@"PPRoamAudioReader", @"AudioReaderDelegate::startAudioDetect::ROAM::isSwiperHere");
        weakSelf.isSwiperHereRetryCount = 0;
        [weakSelf.swiper isSwiperHere];
        weakSelf.retryInitialRoamDetectionTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                                               target:weakSelf
                                                                             selector:@selector(retryInitialRoamDetection)
                                                                             userInfo:nil
                                                                              repeats:NO];
    });
}

-(BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    BOOL foundHeadphones = NO;
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            foundHeadphones = YES;
            break;
        }
    }
    if ([AVAudioSession sharedInstance].recordPermission == AVAudioSessionRecordPermissionGranted) {
        for (AVAudioSessionPortDescription* desc in [route inputs]) {
            if ([[desc portType] isEqualToString:AVAudioSessionPortHeadsetMic]) {
                return YES;
            }
        }
    }
    return foundHeadphones;
}

- (void)ensureRoam {
    @synchronized(self) {
        if (self.swiper == nil) {
            SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::Creating SwiperController");
            self.swiper = [[SwiperController alloc] init];
            self.swiper.swipeTimeout = -1;
            self.swiper.delegate = self;
            self.swiper.detectDeviceChange = YES;
            self.swiper.fskRequired = NO;
            self.swiper.chargeUpTime = 0.4;
            self.swiper.ksnChargeUpTime = 0.8;
        }
    }
}

- (void)retryInitialRoamDetection {
    self.isSwiperHereRetryCount++;
    SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::Roam isSwiperHere did not complete. Retrying.");
    [self.swiper stopSwiper];
    SDK_DEBUG(@"PPRoamAudioReader", @"AudioReaderDelegate::retryInitialRoamDetection::ROAM::isSwiperHere");
    [self.swiper isSwiperHere];
}

-(void)newAudioState:(BOOL)dIn fromWarningPlayback: (BOOL) wasWarning {
    if (dIn) {
        [self startAudioDetect: wasWarning];
        
    } else {
        [self closeRoamAudio];
        self.itsAReader = NO;
        self.ranDetection = NO;
        // set audio category back to previous category to allow apps to play sounds again from same state
        [[AVAudioSession sharedInstance] setCategory:self.previousAudioCategory error:nil];
        self.previousAudioCategory = nil;
    }
}

-(void)openRoamAudio {
#if !TARGET_IPHONE_SIMULATOR
    SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::startSwiper");
    self.retry = NO;
    [self ensureRoam];
    [PPRetailUtils dispatchOnMainThread:^{
        [self pumpUpTheVolume];
        SDK_DEBUG(@"PPRoamAudioReader", @"AudioReaderDelegate::openRoamAudio::ROAM::isSwiperHere");
        [self.swiper startSwiper];
    }];
#endif
}

-(void)closeRoamAudio {
#if !TARGET_IPHONE_SIMULATOR
    SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::stopSwiper");
    [self.waitedTooLongForRoamDeviceTimer invalidate];
    self.retry = NO;
    [PPRetailUtils dispatchOnMainThread:^{
        @try {
            [self.swiper closeSwiper];
            [self sendDeviceRemovedToJS];
        }
        @catch (NSException *exception) {
        }
        self.swiper.delegate = nil;
        self.swiper = nil;
    }];
#endif
}

-(void)pumpUpTheVolume {
    if ([AVAudioSession sharedInstance].outputVolume < 0.7) {
        [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.7];
    }
}

-(void)detectNextReader {
    self.itsAReader = NO;
}

#pragma mark -
#pragma mark Javascript swiper creation

-(void)ensureJsReader {
    if (!self.impl) {
        self.connectCallbacks = [NSMutableOrderedSet new];
        JSValue *nativeCallbacks = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];
        
        __weak typeof(self)weakSelf = self;
        nativeCallbacks[@"isConnected"] = ^() {
            return [weakSelf isConnected];
        };
        nativeCallbacks[@"send"] = ^(JSValue *data, JSValue *callback) {
            if ([data isString] && weakSelf.swiper) {
                [PPRetailUtils  dispatchOnMainThread:^{
                    [weakSelf handleReaderActivationWithCommand:[data toString]];
                }];
            }
            [PPRetailUtils completeWithCallback:callback arguments:nil];
        };
        nativeCallbacks[@"connect"] = ^(JSValue *callback) {
            if (weakSelf.itsAReader) {
                if (!callback.isNull && !callback.isUndefined) {
                    JSValueProtect([PPRetailObject engine].globalContext, callback.JSValueRef);
                    @synchronized (weakSelf.connectCallbacks) {
                        [weakSelf.connectCallbacks addObject:callback];
                    }
                }
                [weakSelf openRoamAudio];
                return;
            }
            JSValue *error = [JSValue valueWithNewErrorFromMessage:@"DEVICE_UNAVAILABLE" inContext:[PPRetailObject engine].context];
            [callback callWithArguments:@[error]];
        };
        nativeCallbacks[@"disconnect"] = ^(JSValue *callback) {
            [weakSelf disconnect];
            [PPRetailUtils completeWithCallback:callback arguments:nil];
        };
        
        nativeCallbacks[@"removed"] = ^(JSValue *callback) {
            [weakSelf disconnect];
            [PPRetailUtils completeWithCallback:callback arguments:nil];
        };
        
        JSValue *deviceBuilder = [[PPRetailObject engine] createJSObject:@"DeviceBuilder" withArguments:nil];
        NSArray *args = @[@"ROAM", @"PayPal Audio Reader", [[PPRetailObject engine].converter toJsBool:NO], nativeCallbacks];
        self.impl = [deviceBuilder invokeMethod:@"build" withArguments:args];
        [PPRetailUtils dispatchOnMainThread:^{
            [PayPalRetailSDK deviceDiscovered:weakSelf.impl];
            [weakSelf.impl invokeMethod:@"connect" withArguments:nil];
        }];
    }
}

- (void)handleReaderActivationWithCommand:(NSString *)command {
    if ([command isEqualToString:@"listenForCardEvents"]) {
        [self.swiper startSwiper];
    } else if ([command isEqualToString:@"stopListeningForCardEvents"]) {
        [self.swiper stopSwiper];
    }
}

-(void)disconnect {
    [self.swiper stopSwiper];
    self.isReady = NO;
    self.impl = nil;
    self.connectCallbacks = nil;
}

-(void)connect {
    
}

-(BOOL)isConnected {
    return self.isReady;
}

- (void)sendDeviceRemovedToJS {
    [PPRetailUtils dispatchOnMainThread:^{
        [self.impl invokeMethod:@"removed" withArguments:nil];
    }];
}

- (PPRetailMagneticCard *)cardFromSwipeData:(NSDictionary *)data {
    NSString *expDate = [data objectForKey:@"expiryDate"];
    
    // Make sure the swipe is good
    if ([expDate isEqualToString:@"0000"]) {
        self.retry = YES;
        [self.swiper startSwiper];
        return nil;
    }
    
    PPRetailMagneticCard *card = [[PPRetailMagneticCard alloc] init];
    JSValue *jsCard = [((id<PPManticoreNativeObjectProtocol>)card) impl];
    jsCard[@"reader"] = self.impl;
    
    NSString *encTrack = [data objectForKey:@"encTrack1"] ?: [data objectForKey:@"encTrack"];
    NSString *partialTrack = [data objectForKey:@"partialTrack"];
    NSString *formatID = [data objectForKey:@"formatID"];
    
    // TODO if this isn't there, no track data gets sent. That should be a failed swipe right?
    if (partialTrack) {
        jsCard[@"partialTrack"] = partialTrack;
        card.track1 = [self.swiper packEncTrackData:formatID encTrack:encTrack partialTrack:partialTrack];
    }
    NSString *ksn = [data objectForKey:@"ksn"];
    card.ksn = ksn;
    if (ksn && ksn.length > 6) {
        self.impl[@"serialNumber"] = [ksn substringToIndex: ksn.length - 6];
    }
    card.pan = [data objectForKey:@"maskedPAN"];
    card.expiration = expDate;
    
    NSString *cardHolderName = [data objectForKey:@"cardHolderName"];
    if (cardHolderName && cardHolderName.length) {
        [jsCard invokeMethod:@"parseName" withArguments:@[cardHolderName]];
    }
    jsCard[@"formatID"] = formatID;
    return card;
}

#pragma mark -
#pragma mark Swiper Controller Delegate

-(void)onSwiperHere:(BOOL)isHere {
    [self.retryInitialRoamDetectionTimer invalidate];
    self.ranDetection = YES;
    if (isHere) {
        // Roam
        [PPRetailUtils dispatchOnMainThread:^{
            self.itsAReader = YES;
            [self ensureJsReader];
        }];
    } else {
        [self detectNextReader];
    };
}

-(void)onDecodeCompleted:(NSDictionary *)data {
    PPRetailMagneticCard *card = [self cardFromSwipeData:data];
    NSError *error;
    NSData *nsData = [NSJSONSerialization dataWithJSONObject:data
                                    options:NSJSONWritingPrettyPrinted error:&error];
    NSString *base64EncodedString = [nsData base64EncodedStringWithOptions:0];
    NSDictionary *dataToSend = @{
                                 @"decodeData" : base64EncodedString,
                                 @"track1" : (card && card.track1) ? card.track1 : @""
                                 };
    [PPRetailUtils dispatchOnMainThread:^{
        [self.impl invokeMethod:@"received" withArguments:@[dataToSend]];
    }];
}

-(void)onDecodeError:(SwiperControllerDecodeResult)decodeState {
    // TODO the failure reason
    self.retry = YES;
    [self.swiper startSwiper];
}

-(void)onNoDeviceDetected {
    if (self.isSwiperHereRetryCount > 0) {
        [self detectNextReader];
    }
}

-(void)onTimeout {
    
}

-(void)onError:(NSString *)errorMessage {
    
}

-(void)onInterrupted {
    
}

-(void)onGetKsnCompleted:(NSString *)ksn {
    
}

-(void)onCardSwipeDetected {
    if (self.impl) {
        // send a swipe started event.
    }
}

-(void)onWaitingForCardSwipe {
    SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::onWaitingForCardSwipe");
    [self.waitedTooLongForRoamDeviceTimer invalidate];

    if (self.retry) {
        self.retry = NO;
        if (self.impl) {
            // send a swipe failed event.
        }
        return;
    }
    
    self.isReady = YES;
    NSArray *notifySet;
    @synchronized (self.connectCallbacks) {
        // The array property will get cleared when the set is cleared unless we copy it
        notifySet = [NSArray arrayWithArray:[self.connectCallbacks array]];
        [self.connectCallbacks removeAllObjects];
    }
    for (JSValue *callback in notifySet) {
        [PPRetailUtils completeWithCallback:callback arguments:nil];
    }
}

-(void)onWaitingForDevice {
    SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::onWaitingForDevice");
    [self.waitedTooLongForRoamDeviceTimer invalidate];
    self.waitedTooLongForRoamDeviceTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(waitedTooLongForRoamDevice) userInfo:nil repeats:NO];
}

- (void)waitedTooLongForRoamDevice {
    [self.waitedTooLongForRoamDeviceTimer invalidate];
    
    SDK_DEBUG(@"PPRoamAudioReader", @"ROAM::waited too long for device, so calling openRoamAudio");
    
    [self openRoamAudio];
}

#pragma mark -
#pragma mark - Audio framework helper routines

- (void)routeChanged:(NSNotification*)note {
    NSNumber *reason = note.userInfo[AVAudioSessionRouteChangeReasonKey];
    if (reason.integerValue == AVAudioSessionRouteChangeReasonOldDeviceUnavailable && ![self isHeadsetPluggedIn]) {
        [PPRetailUtils dispatchOnMainThread:^{
            [self newAudioState:NO fromWarningPlayback:NO];
            [self.delegate readerPluggedOut];
        }];
    } else if (reason.integerValue == AVAudioSessionRouteChangeReasonNewDeviceAvailable && [self isHeadsetPluggedIn]) {
        [PPRetailUtils dispatchOnMainThread:^{
            [self newAudioState:YES fromWarningPlayback:NO];
            [self.delegate readerPluggedIn];
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.itsAReader) {
        [self pumpUpTheVolume];
    }
}

@end

#endif
