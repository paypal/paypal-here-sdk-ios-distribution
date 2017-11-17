//
//  PPSoundManager.m
//
//  Created by Chandrashekar, Sathyanarayan on 7/18/16.
//
//

#import "PPSoundManager.h"

@interface PPSoundManager()

@property (nonatomic) SystemSoundID audioEffect;
@property (strong) NSTimer *timer;

@end

@implementation PPSoundManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PPSoundManager *soundManager = nil;
    dispatch_once(&onceToken, ^{
        soundManager = [[PPSoundManager alloc] init];
    });
    return soundManager;
}

static void soundCompleted (SystemSoundID  mySSID, void* myself) {
    AudioServicesRemoveSystemSoundCompletion (mySSID);
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
}

- (void)playSoundWithFilePathURL: (NSURL * )pathURL {
    // if the category is not the default category
    if ([[AVAudioSession sharedInstance] category] != AVAudioSessionCategorySoloAmbient) {
        return;
    }
    
    //route sound to speaker
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)pathURL, &_audioEffect);
    
    AudioServicesAddSystemSoundCompletion (self.audioEffect,NULL,NULL,
                                           soundCompleted,
                                           (__bridge void*) self);
    
    AudioServicesPlaySystemSound(self.audioEffect);
}

- (void)dealloc {
    AudioServicesDisposeSystemSoundID(self.audioEffect);
}

- (void)playCardReadSound {
    NSString *path  = [[PayPalRetailSDK sdkBundle] pathForResource:@"success_card_read" ofType:@"mp3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        __weak typeof(PPSoundManager) *weakSelf = self;
        [self executeBlock:^{
            [weakSelf playSoundWithFilePathURL:pathURL];
        }];
    } else {
        //file not found error
    }
}

- (void)playSystemSoundForCount:(int)playCount {
    __weak typeof(PPSoundManager) *weakSelf = self;
    [self executeBlock:^{
        for (int i=0; i<playCount; i++) {
            [weakSelf playSystemSound];
            [NSThread sleepForTimeInterval:0.5];
        }
    }];
}

- (void)executeBlock:(void(^)())block {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        block();
    });
}

- (void)playSystemSound {
    NSURL *pathURL = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/new-mail.caf"];
    [self playSoundWithFilePathURL:pathURL];
}

@end
