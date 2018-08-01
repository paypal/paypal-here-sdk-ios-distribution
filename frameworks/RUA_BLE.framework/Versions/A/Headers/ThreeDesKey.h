//
//  ThreeDesKey.h
//  ROAMreaderUnifiedAPI
//
//  Created by Arjun on 8/5/16.
//  Copyright © 2016 ROAM. All rights reserved.
//

#import "BaseKeyMap.h"

@interface ThreeDesKey : BaseKeyMap
/**
 *  3DES KCV
 */
@property NSString* kcv;


-(id)initWithKeyName:(NSString *)keyName kcv:(NSString*)kcv;
-(NSString*) toString;

@end
