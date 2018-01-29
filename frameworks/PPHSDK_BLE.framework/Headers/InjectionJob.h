#pragma once

#import <Foundation/Foundation.h>
#import "CommunicationManagerBase.h"

#define _IN_    // input arguments
#define _OUT_   // output arguments


//Ìá¹©¸øµ÷ÓÃInjectionJob½Ó¿ÚµÄ´íÎóÂë
//Éè±¸¶ËµÄ
#define EM_DEV_Success	  					0x00
#define EM_DEV_CmdNotSupport  				0x02
#define EM_DEV_ErrorGeneratNonce  			0x04
#define	EM_DEV_VerifySignError				0x05
#define	EM_DEV_CalHashError				    0x07
#define	EM_DEV_GenerateSignErr				0x0A
#define	EM_DEV_GetRkmsPubKeyErr			    0x0B
#define EM_DEV_GetIPAndPortError            0x0C
#define	EM_DEV_GetDevCrtError				0x12
#define	EM_DEV_RecvRkmsCrtError			    0x15
#define	EM_DEV_VerRkmsCrtError				0x16
#define EM_DEV_BadKeyName                   0x1A
#define	EM_DEV_GetSkError					0x20
#define	EM_DEV_GetTkError					0x21
#define	EM_DEV_RecvRkmsRetErr				0x22
#define	EM_DEV_CompleteInjectErr			0x23
#define	EM_DEV_RecvMsgErr					0x24
#define	EM_DEV_ErrorParam					0x8b


//rkms¶Ë

//--------------´ÓRKMS»ñÈ¡µ½±êÇ©µÄÄÚÈÝÎª¿Õ
#define EM_RKMS_EncCertIsNone               0x30//CD
#define EM_RKMS_SignCertIsNone              0x31//CC
#define EM_RKMS_RandomNumIsNone             0x32
#define EM_RKMS_KeyNumIsNone                0x33
#define EM_RKMS_TR34BlobIsNone              0x34//»ñÈ¡µ½APµÄ³¤¶ÈÎª¿Õ
#define EM_RKMS_TR31BlockIsNone             0x35//»ñÈ¡µ½KBµÄ³¤¶ÈÎª¿Õ
#define EM_RKMS_PadMethodIsNone             0x36//CEÎª¿Õ
#define EM_RKMS_SignedDataIsNone            0x37//KAÎª¿Õ
#define EM_RKMS_ANIsNone                    0x38//ANÎª¿Õ
#define EM_RKMS_BBIsNone                    0x39//BBÎª¿Õ

#define EM_RKMS_InitSocketErr               0x41
#define EM_RKMS_CreateSocketErr             0x42
#define EM_RKMS_DGLenIsZero                 0x43
#define EM_RKMS_SetSocketTimeoutErr         0x44
#define EM_RKMS_SendPEDIErr                 0x45
#define EM_RKMS_RecvDataTimeOut             0x46
#define EM_RKMS_NotGetCmdTag                0x47
#define EM_RKMS_SendPEDKErr                 0x48
#define EM_RKMS_GetANVauleIsN               0x49//ANN
#define EM_RKMS_SendPEDVErr                 0x4A


//rkms AM ´íÎóÂë
#define EM_RKMS_FiledOutOfRange             0x50//01 Field out of range
#define EM_RKMS_InvalidChar                 0x51//02 Invalid character
#define EM_RKMS_ValueOutOfRange             0x52//03 Value out of range
#define EM_RKMS_TokenMissing                0x53//04 Token missing
#define EM_RKMS_MFKMissing                  0x54//06 Master File Key missing
#define EM_RKMS_HardwareFail                0x55//08Hardware failure
#define EM_RKMS_InvalidMsgFormat            0x56//09Invalid message format
#define EM_RKMS_InvalidMsgLen               0x57//13 Invalid message length
#define EM_RKMS_CommunicationErr            0X58//14Communication error
#define EM_RKMS_FunNotSupport               0x59//19 Function not supported
#define EM_RKMS_InvalidToken                0x5A//34 Invalid token
#define EM_RKMS_InvalidKeyBlock             0x5B//48Invalid key block
#define EM_RKMS_FunNotFound                 0x5C//52 Function not found
#define EM_RKMS_InvalidPubKeyData           0x5D//57Invalid public key data
#define EM_RKMS_InvalidPriKeyData           0x5E//58 Invalid private key data
#define EM_RKMS_InvalidCertData             0x5F//59Invalid certificate data
#define EM_RKMS_InvalidCertRequest          0x60//60 Invalid certificate request
#define EM_RKMS_NoCertsInPKCS7              0x61//61No certificates in PKCS #7 data
#define EM_RKMS_NoNamesMatchSpecName        0x62//62 No names match specified name
#define EM_RKMS_IncorrectKeyType            0x63//63 Incorrect key type
#define EM_RKMS_InvalidDevice               0x64//65 Invalid device
#define EM_RKMS_DevNotIdentified            0x65//66 Device not identified
#define EM_RKMS_RegKeyNotInRegSlot          0x66//67 Register key not in register slot
#define EM_RKMS_CannotLoadKey               0x67//68 Default passwords - cannot load key
#define EM_RKMS_CertsAlgoMismatch           0x68//70 Certificate algorithm mismatch
#define EM_RKMS_DGNotSupportAlgo            0x69//71 Device group does not support algorithm
#define EM_RKMS_HashAlgoMissing             0x6A//72 Hashing algorithm missing
#define EM_RKMS_GenerateNonceErr            0x6B//73 Error generating nonce
#define EM_RKMS_VerNotSupported             0x6C//74 Version not supported
#define EM_RKMS_CertsTreeIsNotChain         0x6D//75 User certificate tree is not chain
#define EM_RKMS_ValidateDevNameErr          0x6E//76 Error validating device name
#define EM_RKMS_NoSupCmdInProtoVer          0x6F//77 Command not supported in protocol version
#define EM_RKMS_MissDevEncCert              0x70//78 Missing device encryption certificate
#define EM_RKMS_CreateKBSErr                0x71//79 Error creating key block structure
#define EM_RKMS_InternalErr                 0x72//80 Internal error
#define EM_RKMS_ProccessSKErr               0x73//81 Error processing session key
#define EM_RKMS_DevIsLocked                 0x74//82 DEVICE IS LOCKED


//General error code
#define EM_General_TLVLenghthErr            0x80
#define EM_General_TLVTagErr                0x81
#define EM_General_NotHaveRF                0x82
#define EM_General_Bin2HexErr               0x83
#define EM_General_Hex2BinErr               0x84

@protocol CRemoteKeyInjectionParam <NSObject>

-(void)post_msg:(NSString*)str;
-(void)post_error:(NSString*)str;
-(void)post_success:(NSString*)str;

@end


@interface RKMSJob : NSObject

-(int)InjectionJob:(NSString*)identifier DeviceType:(DeviceCommunicationChannel) devType RKMSDg:(NSString*)rkmsDg RKMSIP:(NSString* __autoreleasing*) rkmsIp RKMSPort:(unsigned short*)rkmsPort Oberver:(id<CRemoteKeyInjectionParam>) pDlg CommCB:(id<CommunicationCallBack>)cb CommMode:(DeviceCommunicationMode) md;

+(NSString*)GetVersion;

@end

