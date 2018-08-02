//
//  AudioJackManager.h
//  AudioDemo
//
//  Created by Wu Robert on 9/15/15.
//  Copyright © 2015 Wu Robert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunicationCallBack.h"
#import "CommunicationManagerBase.h"



#define ERROR_AUDIOJACK_DECODE_WAVE_FAIL (3)
#define ERROR_AUDIOJACK_MEMORY_NOT_ENOUGH (4)
#define ERROR_AUDIOJACK_TIMEOUT (5)
#define ERROR_AUDIOJACK_BYTE_FORMAT_ERROR (6)
#define ERROR_AUDIOJACK_FRAME_FORMAT_ERROR (7)
#define ERROR_AUDIOJACK_UNKNOW_ERROR (8)
#define ERROR_AUDIOJACK_WRITE_DATA_ERROR (9)
#define ERROR_AUDIOJACK_READ_DATA_ERROR (10)
#define ERROR_AUDIOJACK_EXCHANGE_STATE_ERROR (11)
#define ERROR_AUDIOJACK_CANCEL_SUCCESS (12)
#define ERROR_AUDIOJACK_CANCEL_FAIL (13)
#define ERROR_AUDIOJACK_NODEVICEDETEDC (14)
#define ERROR_AUDIOJACK_AUDIOFOCUSLOSS (15)
#define ERROR_AUDIOJACK_AUDIOSERVICE_TERMINATE (16)
#define ERROR_AUDIOJACK_AUDIOSERVICE_INTERRUPT (17)

#define STR_CANCEL_SUCCESS @"Cancel exchange success."
#define STR_CANCEL_FAILURE @"Cancel exchange failure."
#define STR_ERROR_AUDIOTRACK_INIT @"Initial or start AudioTrack occur error."
#define STR_ERROR_AUDIORECORD_INIT @"Initial or start AudioRecord occur error."
#define STR_ERROR_AUDIORECORD_READ @"AudioRecord record data fail."
#define STR_ERROR_AUDIOTRACK_WRITE @"AudioTrack write data fail."
#define STR_ERROR_SEND_WAIT_ACK_TIIMEOUT @"Wait ack of sended sub data timeout."
#define STR_ERROR_SEND_DEAL_ACK_ERROR @"Deal with ACK of sended sub data wrong."
#define STR_ERROR_NODEVICEDETECTED @"No device detected."
#define STR_ERROR_LOSSAUDIOFOCUS @"There is the other primary audio of application to start."
#define STR_ERROR_UNPACK @"Unpack data failure."
#define STR_ERROR_AUDIO_SERVICE_TERMINATE @"Audio service terminates."
#define STR_ERROR_AUDIO_INTERRUPT_OCCUR @"Audio interruption occur."
#define STR_ERROR_UNKNOW @"Unknow error."

#define ERROR_AUDIOJACK_SUCCESS (0)
// openDevice
#define ERROR_AUDIOJACK_INIT_AUDIOTRACK_FAIL (-1)
#define ERROR_AUDIOJACK_INIT_AUDIORECORD_FAIL (-2)
#define ERROR_AUDIOJACK_SHAKE_FAIL (-3)
// exchangeData
#define ERROR_AUDIOJACK_EXCHANGE_NOT_COMPLATE (-1)
#define ERROR_AUDIOJACK_DEVICE_NOT_OPEN (-2)
#define ERROR_AUDIOJACK_NO_DEVICE_DETECTED (-4)
// cancelExchange
#define ERROR_AUDIOJACK_CANCEL_NOT_NEED (-1)
#define ERROR_AUDIOJACK_BE_CANCELING (-3)




@interface AudioJackManager : CommunicationManagerBase

+(AudioJackManager*)sharedInstance;
+(NSString*)getLibVersion;
-(BOOL)hasHeadset;
-(int)openDevice;
-(int)openDevice:(NSString *)identifier cb:(id<CommunicationCallBack>) cb mode:(DeviceCommunicationMode)mode;

-(int)openDevice:(NSString*)identifier;
-(int)openDevice:(NSString *)identifier timeout:(long)timeout;
-(int)openDevice:(NSString *)identifier cb:(id<CommunicationCallBack>)cb mode:(DeviceCommunicationMode)mode timeout:(long)timeout;

-(void)closeDevice;
-(void)closeResource;
-(int)exchangeData:(NSData*) data timeout:(long)timeout cb:(id<CommunicationCallBack>)cb;
-(int)exchangeData:(NSData *)data timeout:(long)timeout;
-(int)cancelExchange;
-(BOOL)isConnected;
-(void)breakOpenDevice;



@end
