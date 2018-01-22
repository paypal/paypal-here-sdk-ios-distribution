//
//  RAUVASData.h
//  ROAMreaderUnifiedAPI
//
//  Created by Mallikarjun Patil on 4/20/17.
//  Copyright © 2017 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RUAVASData : NSObject

@property(nonatomic, strong, readonly) NSString* merchantID;
@property(nonatomic, strong, readonly) NSString* mobileToken;
@property(nonatomic, strong, readonly) NSString* vasData;

-(instancetype)initWithMerchantID:(NSString*)merchantID mobileToken:(NSString*)mobileToken vasData:(NSString*)data;
@end
