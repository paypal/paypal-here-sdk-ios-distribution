//
//  DUKPTKey.h
//  ROAMreaderUnifiedAPI
//
//  Created by Arjun on 8/5/16.
//  Copyright © 2016 ROAM. All rights reserved.
//

#import "BaseKeyMap.h"

@interface DUKPTKey : BaseKeyMap

/**
 *  DUKPT KSN
 */
@property NSString* ksn;
/**
 *  DUKPT Encrypted_value
 */
@property NSString*encryptedValue;

-(id)initWithKeyName:(NSString *)keyName ksn:(NSString*)ksn encryptedValue:(NSString*)value;
-(NSString*) toString;

@end
