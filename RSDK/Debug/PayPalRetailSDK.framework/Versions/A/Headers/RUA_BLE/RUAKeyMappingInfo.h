//
//  RUAKeyMappingInfo.h
//  ROAMreaderUnifiedAPI
//
//  Created by Arjun on 8/4/16.
//  Copyright © 2016 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUKPTKey.h"
#import "ThreeDesKey.h"

@interface RUAKeyMappingInfo : NSObject

/**
 *  List of DUKPT keys
 */
@property NSMutableArray* mDukptKeyList;
/**
 *  List of 3DES keys
 */
@property NSMutableArray* mThreeDesKeyList;

-(id)initWithData:(NSData*)data;

- (NSString *) toString;

@end
