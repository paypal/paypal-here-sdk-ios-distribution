//
//  PPHCardReaderStateMonitor.h
//  PayPalHereSDK
//
//  Created by Pavlinsky, Matthew on 1/14/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPHChipAndPinEvent.h"
@class PPHCardReaderMetadata;

////////////////////////////////////////////////////////////////////////////////////////////////////l
@interface PPHCardReaderStateMonitor : NSObject

- (PPHCardReaderMetadata *)availableReader;
- (PPHCardReaderMetadata *)lastConnectedReader;
- (void)resetReaderEvents;

// EMV
- (BOOL)didReadChip;
- (BOOL)chipIsBroken;
- (BOOL)fallbackIsEnabled;
- (BOOL)isWaitingForPin;
- (BOOL)isLastPINAttempt;
- (BOOL)chipRequiresPIN;
- (BOOL)chipRequiresSignature;

- (NSData *)emvData;
- (NSString *)terminalId;
- (PPHChipAndPinAuthEvent *)authEvent;
- (PPHChipAndPinEventWithEmv *)approvalEvent;
- (PPHChipAndPinDecisionEvent *)decisionEvent;

@end
