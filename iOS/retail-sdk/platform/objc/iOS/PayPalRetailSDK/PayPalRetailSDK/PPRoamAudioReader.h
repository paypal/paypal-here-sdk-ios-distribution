//
//  PPRoamAudioReader.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/21/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//
#ifdef INCLUDE_ROAM_AUDIO

#import <Foundation/Foundation.h>
#import "PPRetailObject.h"

@protocol PPRoamAudioReaderDelegate

- (void)readerPluggedIn;
- (void)readerPluggedOut;

@end

@interface PPRoamAudioReader : PPRetailObject

- (instancetype)initWithDelegate:(id<PPRoamAudioReaderDelegate>)delegate;
- (void)startListening;
- (void)stopListening;

@end

#endif
