//
//  CommDownloadCallback.h
//  MPOSCommunicationManager
//
//  Created by Wu Robert on 12/31/13.
//  Copyright (c) 2013 Landi 联迪. All rights reserved.
//

#import <Foundation/Foundation.h>

/************* 错误码 ********************/

#define DOWNLOAD_ERROR_SUCCESS                              (0)          // 无错误
#define DOWNLOAD_ERROR_FILE_TYPE_UNSUPPORT                  (101)        // 文件类型不支持
#define DOWNLOAD_ERROR_FILE_CONTENT_ERROR                   (102)        // 文件结构错误
#define DOWNLOAD_ERROR_HANDSHAKE_FAILED                     (103)        // 握手失败
#define DOWNLOAD_ERROR_FILE_LOAD_FAILED                     (104)        // 文件加载失败
#define DOWNLOAD_ERROR_DEVICE_OPEN_FAILED                   (105)        // 开启设备失败
#define DOWNLOAD_ERROR_DEVICE_DISCONNECTED                  (106)        // 设备未连接
#define DOWNLOAD_ERROR_LAUNCHUPDATE_FAILED                  (107)        // 启动更新失败
#define DOWNLOAD_ERROR_DOWNLOAD_COMM_FAILED                 (108)        // 下载数据时通信错误
#define DOWNLOAD_ERROR_DOWNLOAD_PARAM_ERROR                 (109)        // 下载时参数错误
#define DOWNLOAD_ERROR_ROUTINE_START_FAILED                 (110)        // 启动事务失败
#define DOWNLOAD_ERROR_USER_CANCEL                          (111)           // 用户取消流程
#define DOWNLOAD_ERROR_FILE_FILTER_FAILED                   (112)        // 抽取分文件失败

#define DOWNLOAD_ERROR_UNKNOWN                              (199)       // 未知错误

@protocol CommDownloadCallback <NSObject>
@required
-(void)onDownloadComplete;
-(void)onDownloadProgress:(unsigned int)current totalProgress:(unsigned int)total;
-(void)onDownloadError:(int)code;

@end
