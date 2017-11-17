//
//  PPSoundManager.h
//
//  Created by Chandrashekar, Sathyanarayan on 7/18/16.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface PPSoundManager : NSObject

+ (instancetype)sharedInstance;
- (void)playCardReadSound;
- (void)playSystemSoundForCount:(int)playCount;

@end
