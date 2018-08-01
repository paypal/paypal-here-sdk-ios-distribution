//
//  RUAApplicationIdentifier.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/18/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RUAApplicationIdentifier : NSObject<NSCopying>

@property NSString *aid;

@property NSString *applicationLabel;

/**
 * The registered application provider identifier (RID)
 */
@property NSString *rid;

/**
 * The proprietary application identifier extension (PIX)
 */
@property NSString *pix;

/** The Terminal application version. */
@property NSString *terminalApplicationVersion;

/** The Lowest supported icc application version. */
@property NSString *lowestSupportedICCApplicationVersion;

/** The Priority index. */
@property NSString *priorityIndex;

/** The Application selection flags. */
@property NSString *applicationSelectionFlags;

/** Only applicable for contactless ApplicationIdentifier*/
@property NSString *CVMLimit;

/** Only applicable for contactless ApplicationIdentifier*/
@property NSString *FloorLimit;

/** Only applicable for contactless ApplicationIdentifier*/
@property NSString *TLVData;

/** Only applicable for contactless ApplicationIdentifier*/
@property NSString *TermCaps;

/** Only applicable for contactless ApplicationIdentifier*/
@property NSString *TxnLimit;

- (id)                           initWithRID:(NSString *)rid
                                     withPIX:(NSString *)pix
                                withAID:(NSString *)aid
                        withApplicationLabel:(NSString *)label
              withTerminalApplicationVersion:(NSString *)TerminalApplicationVersion
    withLowestSupportedICCApplicationVersion:(NSString *)LowestSupportedICCApplicationVersion
                           withPriorityIndex:(NSString *)priorityIndex
               withApplicationSelectionFlags:(NSString *)applicationSelectionFlags;

- (id)                           initWithRID:(NSString *)rid
                                     withPIX:(NSString *)pix
                                     withAID:(NSString *)aid
                        withApplicationLabel:(NSString *)label
              withTerminalApplicationVersion:(NSString *)TerminalApplicationVersion
    withLowestSupportedICCApplicationVersion:(NSString *)LowestSupportedICCApplicationVersion
                           withPriorityIndex:(NSString *)priorityIndex
               withApplicationSelectionFlags:(NSString *)applicationSelectionFlags
                                 withTLVData:(NSString *)TLVData;

- (id)                           initWithRID:(NSString *)rid
                                     withPIX:(NSString *)pix
                                     withAID:(NSString *)aid
                        withApplicationLabel:(NSString *)label
              withTerminalApplicationVersion:(NSString *)TerminalApplicationVersion
    withLowestSupportedICCApplicationVersion:(NSString *)LowestSupportedICCApplicationVersion
                           withPriorityIndex:(NSString *)priorityIndex
               withApplicationSelectionFlags:(NSString *)applicationSelectionFlags
                                withCVMLimit:(NSString *)CVMLimit
                              withFloorLimit:(NSString *)FloorLimit
                                 withTLVData:(NSString *)TLVData
                                withTermCaps:(NSString *)TermCaps
                                withTxnLimit:(NSString *)TxnLimit;

- (NSString *)getFormattedString;

@end
