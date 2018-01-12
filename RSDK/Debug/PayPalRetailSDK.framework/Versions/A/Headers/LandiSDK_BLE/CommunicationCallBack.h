//
//  CommunicationCallBack.h
//  BLEBaseDriver
//
//  Created by Landi 联迪 - Robert on 13-8-7.
//  Copyright (c) 2013年 Landi 联迪. All rights reserved.
//

#ifndef BLEBaseDriver_CommunicationCallBack_h
#define BLEBaseDriver_CommunicationCallBack_h

#import <Foundation/Foundation.h>

@protocol CommunicationCallBack <NSObject>

-(void)onSendOK;
-(void)onReceive:(NSData*)data;
-(void)onTimeout;
-(void)onError:(NSInteger)code message:(NSString*)msg;
-(void)onProgress:(NSData*)data;

@end

#endif
