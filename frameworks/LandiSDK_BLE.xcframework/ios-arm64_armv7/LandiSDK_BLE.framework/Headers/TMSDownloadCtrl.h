//
//  TMSDownloadCtrl.h
//  MPOSCommunicationManager
//
//  Created by Wu Robert on 10/22/14.
//  Copyright (c) 2014 Landi 联迪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunicationManagerBase.h"
#import "LDTmsFileVersionInfo.h"
#import "LDTmsCmdVersionInfo.h"
#import "LDTmsCmdCrtVersionInfo.h"



@interface TMSDownloadCtrl : NSObject

-(void)download:(RDeviceInfo*)di path:(NSString*)filePath callback:(id<CommDownloadCallback>)cb;
-(void)newDownload:(RDeviceInfo *)di path:(NSString *)filePath callback:(id<CommDownloadCallback>)cb;
-(void)cancelDownload;

// Version info
-(BOOL)CheckIsValid:(NSString*)filePath;
-(NSUInteger)GetFileCount:(NSString*)filePath;
-(LDTmsFileVersionInfo*)GetFileVersionInfo:(NSString*)filePath targetFile:(NSUInteger)index;
-(LDTmsCmdVersionInfo*)GetCmdVersionInfo:(NSData*)cmd;
-(LDTmsCmdCrtVersionInfo*)GetCmdCrtVersionInfo:(NSData*)cmd;
-(NSArray*)GetFileVersionInfoSet:(NSString*)filePath;

@end
