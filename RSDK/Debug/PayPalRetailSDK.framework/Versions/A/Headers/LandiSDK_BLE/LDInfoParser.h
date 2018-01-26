//
//  LDInfoParser.h
//  MPOSCommunicationManager
//
//  Created by Wu Robert on 1/14/15.
//  Copyright (c) 2015 Landi 联迪. All rights reserved.
//

#ifndef __MPOSCommunicationManager__LDInfoParser__
#define __MPOSCommunicationManager__LDInfoParser__

/*!
 * \file LDInfoParser.h
 *
 * \author robert
 * \date 一月 2015
 * 针对TMS下装的UNS文件格式解析类
 * * * * * * * * * * * * * * * * *
 * 2015年1月16日14:20:36
 * 32字节部分版本域动态域识别区分，增加无效全FF域识别
 * 2015年1月29日10:42:29
 * 增加文件标志识别
 * 2015年2月5日15:07:49
 * 更新ReadVersion 指令解析（增加P/N、MAC地址信息）
 * 2015年5月26日11:03:53
 * 更新ReadCrtVersion 指令解析（增加证书文件版本获取）
 * 2015年8月27日14:40:54
 * 增加包过滤重组功能，用于按照平台条件抽取指定分文件重新合成UNS数据流
 * 2015年12月17日14:30:02
 * 增加解析处理与包过滤重组功能（for M33&M35P）
 * 2017年08月03日15:55:04
 * 增加ROAM UNS rebuild APIs
 */

#define SUCCESS_UNS_FILE (0)
#define ERROR_UNS_FILE_LENGTH (-1)
#define ERROR_UNS_FILE_HEADER (-2)
#define ERROR_UNS_FILE_CRC (-3)
#define ERROR_UNS_FILE_SUB_HEADER (-4)
#define ERROR_UNS_FILE_SIGN (-5)
#define ERROR_UNS_FILE_UNKNOWN (-6)

#define CMD_PHASE_UNKNOW (0)
#define CMD_PHASE_1 (1)
#define CMD_PHASE_2 (2)


typedef struct
{
    char  acSoftInfo[16];  // 软件类别名称，固定为“LANDI-UNS”
    unsigned char acCRC[2];       // CRC
    unsigned short sFileNum;       // 文件个数
    char  cClearUserFile; // 是否清空所有用户程序,0.不清空，1.清空
    char  cDelInvalidDrv; // 是否删除无效驱动,0.否，1.是
    char  cDownAllDrv;    // 是否下装全部驱动,0.否，1.是
    char  cDownPCT;       // 是否下装配置表,0.否，1.是
    char  cClearWater;    //是否清空所有流水 0.不清空，1.清空
    char  cDwnTMSDrv;      //是否下载TMS驱动标志:0-否，1-是
    //char  acReserve[35];    // 预留
    //linj add 2009-11-24
    unsigned char acUNSMac[4];    // 切机使用的4位Mac数据
    char  acReserve[22];    // 预留
    int  lDependBase;
    int  lDependSize;
    int  lParaInfoOffset; // 参数项信息偏移,不修改参数文件时，赋0
    char  acVerInfo[16];   // 版本信息,从0`1-01-01开始，当UNS工具升级时ZZ域加1
    char  acDescrip[32];   // 32字节, 由界面“UNS文件描述”框输入
    char  acCreateTime[16];      // 16字节, 生成UNS文件的时间
}UNS_EntireFileInfo;


// uns每一个小文件的头信息
typedef struct
{
    unsigned int uiFileOffSet;     // 该文件在UNS中的绝对起始地址
    unsigned int  uiFileLen;        // 文件长度，DDL文件包含版本控制段，PAR文件包含模版部分
    char  acFileType[3];    // 单独文件对应的后缀名，如bin,dla,par,drv等
    unsigned char cDefaultDla;      // 0. 非默认DLA  1.默认DLA
    unsigned char ucOpreate;        // 下载策略，2.更新0.替换1.删除程序文件3.删除参数
    char acReserved1[3];    // 预留19字节
    unsigned int uiExtendLen;      // 对于软件包，表示签名文件长度
    //linj add 2009-11-26
    unsigned int uiFileEOFlen;
    char  acReserved2[8];   // 预留19字节
    //char  acReserved2[12];   // 预留19字节
}UNS_SubFileInfo;

// 公共头部，国外国内统一（第一段16字节）
typedef struct
{
    // 16字节版本标志
    // 平台&芯片
    unsigned char ucPlatform[10 + 1];
    // 硬件子平台&软件子平台
    unsigned char ucSubPlatform[4 + 1];
    // 文件类型
    unsigned char ucFileType[10 + 1];
}VI_VerFlag;

// TMS 格式（第二段16字节）
typedef struct
{
    // 32字节版本 --  ROAM版本控制方案
    // ---16字节 - 行1---
    // 文件维护者ID号
    unsigned char ucMaintainerID[4 + 1];
    // 文件所在层 级
    unsigned char ucFileLevel[1 + 1];
    // 文件编号
    unsigned char ucFileSN[3 + 1];
    // ---16字节 - 行2---
    // 版本号
    unsigned char ucVersion[4 + 1];
    // 固件依赖版本号
    unsigned char ucDependVer[4 + 1];
    // 版本区别-00正式版本 其他表示测试版本
    unsigned char ucVerFlag[2 + 1];
}VI_VerCtrl;

//M33&M35P 格式
typedef struct
{
    unsigned char ucBaseVer[2 + 1];
    unsigned char ucSelfVer[2 + 1];
    unsigned char ucRelatedVer[4 + 1];
}VI_VerManager;

// 公共时间戳 格式（第三段16字节）
typedef struct
{
    // 时间戳 16字节
    unsigned char Year[4 + 1];
    unsigned char Month[2 + 1];
    unsigned char Day[2 + 1];
}VI_Timestamp;

// M33&M35P 16字节可变扩展域（第四段16字节，针对不同的类型文件，域意义不同）
typedef union
{
    unsigned char info[16 + 1];
}VI_Extend;

// TMS 格式 头部整合结构体
typedef struct {
    VI_VerFlag VerFlag;
    VI_VerCtrl VerCtrl;
    VI_Timestamp TimeStamp;
}FILE_VersionInfo;

// M33&M35P 格式 头部整合结构体
typedef struct {
    VI_VerFlag VerFlag;
    VI_VerManager VerManager;
    VI_Timestamp TimeStamp;
    VI_Extend Extend;
}LD_M3X_FILE_VersionInfo;

// 4字节对齐 TMS 版本信息指令结构
typedef struct
{
    unsigned char ucHardwareType[16 + 1];
    FILE_VersionInfo viBootVer;
    FILE_VersionInfo viCtrlVer;
    FILE_VersionInfo viUserVer;
    unsigned char ucEmvKernalVer[10 + 1];
    unsigned char ucKeyVer[10 + 1];
    unsigned char ucPedVer[10 + 1];
    FILE_VersionInfo viFontVer;
    FILE_VersionInfo viUscfgVer;
    FILE_VersionInfo viDbcfgVer;
    FILE_VersionInfo viPmptVer;
    FILE_VersionInfo viInitVer;
    unsigned char ucProductSN[31+1];
    unsigned char ucMacAddress[19+1];
}CMD_VersionInfo;

// TMS 证书信息指令结构
typedef struct
{
    FILE_VersionInfo viFlrcVer;
    FILE_VersionInfo viFsrcVer;
    FILE_VersionInfo viAlrcVer;
    FILE_VersionInfo viAsrcVer;
    FILE_VersionInfo viBrcVer;
    FILE_VersionInfo viErcVer;
    FILE_VersionInfo viTarcVer;
}CMD_CrtVersionInfo;


class LDInfoParser
{
public:
				// UNSData
				// 检查文件有效性
				static int UNS_CheckValid(unsigned char* unsData, unsigned int unsSize);
				// 获取整个UNS文件信息
				static UNS_EntireFileInfo UNS_GetEntireFileHeader(unsigned char* unsData, unsigned int unsSize);
				// 获取子文件信息
				static UNS_SubFileInfo UNS_GetSubFileHeader(unsigned char* unsData, unsigned int unsSize, unsigned int subIndex);
				// 获取子文件个数
				static unsigned int UNS_GetSubFileCount(unsigned char* unsData, unsigned int unsSize);
				
                //////////////////////////////////////////
                // 获取UNS各个子文件版本信息 --- (国外版本)
				static FILE_VersionInfo UNS_GetSubFileVersionInfo(unsigned char* unsData, unsigned int unsSize, unsigned int subIndex);
				static FILE_VersionInfo UNS_GetSubFileVersionInfo(unsigned char* data, unsigned int size);
				// 获取标准子版本信息 --- （通用）
				static VI_VerFlag UNS_GetSubFileVersionFlag(unsigned char* unsData, unsigned int unsSize, unsigned int subIndex);
                //////////////////////////////////////////
                // 获取UNS个个子文件版本信息 --- （国内版本）
                static LD_M3X_FILE_VersionInfo UNS_GetSubM3XFileVersionInfo(unsigned char* unsData, unsigned int unsSize, unsigned int subIndex);
                static LD_M3X_FILE_VersionInfo UNS_GetSubM3XFileVersionInfo(unsigned char* data, unsigned int size);
                // 获取标准子版本信息 --- （M33&M35P）
				static VI_Extend UNS_GetSubM3XFileExtend(unsigned char* unsData, unsigned int unsSize, unsigned int subIndex);
                //////////////////////////////////////////
				// CMD
				// 获取版本指令解析
				static CMD_VersionInfo CMD_GetVersionInfo(unsigned char* cmdData, unsigned int cmdSize);
				static CMD_CrtVersionInfo CMD_GetCrtVersionInfo(unsigned char* cmdData, unsigned int cmdSize);
				// 确定Phase类型
				static int CMD_GetPhaseValue(unsigned char* cmdData, unsigned int cmdSize);
				
    
                //////////////////////////////////////////
                // UNS rebuild APIs for RPxxx
                static void* UNS_UNSFileRuleIndexSetAdd(void* indexSet, int iIndex);
				static int UNS_CreateNewUNSFileFromOtherOne(unsigned char* unsData, unsigned int unsSize, unsigned char* newUNSData, unsigned int newUNSSize, void* indexSet);
				static void UNS_UNSFileRuleIndexSetRelease(void* indexSet);
    
				//////////////////////////////////////////
				// step 1：填充子文件数据内容
				static bool UNS_FillSubFileData(UNS_SubFileInfo* sfi, unsigned int subIndex, unsigned int total,
                                                unsigned char* fileData, unsigned int fileSize,
                                                unsigned char* unsData, unsigned int unsSize);
				// step 2：填充子文件信息
				static bool UNS_FillSubFileHeader(UNS_SubFileInfo* sfi, unsigned int subIndex,
                                                  unsigned char* unsData, unsigned int unsSize);
				// step 3：填充UNS文件信息 --- 最后填充，用于更新CRC
				static bool UNS_FillEntireFileHeader(UNS_EntireFileInfo* efi, unsigned int total, unsigned char* unsData, unsigned int unsSize);
                //////////////////////////////////////////
				// 索引符合版本头信息的域
				static int UNS_FindNextSubFileIndex(unsigned char* ucPlatform, unsigned char* ucSubPlatform, unsigned char* ucFileType,
                                                    int posIndex, unsigned char* unsData, unsigned int unsSize);
				// 索引符合版本头信息的域个数
				static unsigned int UNS_FindSubFileCount(unsigned char* ucPlatform, unsigned char* ucSubPlatform, unsigned char* ucFileType,
                                                         unsigned char* unsData, unsigned int unsSize);
				// 创建新UNS临时包 - 通用
				static int UNS_CreateSinglePlatformTempPackage(unsigned char* ucPlatform, unsigned char* ucSubPlatform, unsigned char* ucFileType,
                                                               unsigned char* unsData, unsigned int unsSize,
                                                               unsigned char* newUNSData, unsigned int newUNSSize);
                ///////////////////////////////////////////
                // 索引符合要求的信息的域 --- M33&M35P
                static int UNS_FindNextSubFileIndex(unsigned char* ucSubPlatform, unsigned char* ucExtend, int posIndex, unsigned char* unsData, unsigned int unsSize);
                // 索引符合要求的信息的域的个数
                static int UNS_FindSubFileCount(unsigned char* ucSubPlatform, unsigned char* ucExtend, unsigned char* unsData, unsigned int unsSize);
                // 创建新UNS临时波 - M33&M35P
                static int UNS_CreateM3XSinglePlatformExtendTempPackage(unsigned char* ucSubPlatform, unsigned char* ucExtend, unsigned char* unsData, unsigned int unsSize, unsigned char* newUNSData, unsigned int newUNSSize);
				~LDInfoParser();
private:
                // 公共平台版本处理
                static bool parseVerFlagEx(unsigned char* verInfo, unsigned int infoSize, VI_VerFlag* vf);
				static VI_VerFlag parseVerFlag(unsigned char* verInfo, unsigned int infoSize);
                // TMS
				static VI_VerCtrl parseVerCtrl(unsigned char* verInfo, unsigned int infoSize);
                // TMS 时间戳 下标从48开始
                // M33&M35P下标从32开始
				static VI_Timestamp parseTimeStamp(unsigned char* verInfo, unsigned int infoSize);
                // M33&M35P
                static VI_VerManager parseVerManager(unsigned char* verInfo, unsigned int infoSize);
                static VI_Extend parseExtend(unsigned char* verInfo, unsigned int infoSize);
				// 其他方法
				static unsigned short crc16(unsigned char* buf, unsigned int len);
				static int datachar(unsigned char* str, unsigned int len, unsigned char ch);
				static int datacharcount(unsigned char* str, unsigned int len, unsigned char ch);
				LDInfoParser();
};

#endif /* defined(__MPOSCommunicationManager__LDInfoParser__) */
