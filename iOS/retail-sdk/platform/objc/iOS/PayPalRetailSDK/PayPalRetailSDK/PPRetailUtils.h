//
//  PPRetailUtils.h
//  Pods
//
//  Created by Chandrashekar, Sathyanarayan on 6/7/17.
//
//

#import <Foundation/Foundation.h>

@interface PPRetailUtils : NSObject

+ (void)dispatchOnMainThread:(void(^)(void))block;
+ (void)completeWithCallback:(JSValue *)callback arguments:(NSArray *)arguments;
+ (void)displayAlertView:(UIView *)alertView;
+ (void)dismissAlertView:(UIView *)alertView;

@end
