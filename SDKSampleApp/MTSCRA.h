//
//  MTSCRA.h
//  MTSCRA
//
//  Created by Imran Jahanzeb on 1/31/12.
//  Copyright (c) 2012 MagTek. All rights reserved.
//ƒ
//
//  MTSCRA.h
//  MTSCRA
//
//  Created by Imran Jahanzeb on 1/23/12.
//  Copyright (c) 2012 MagTek. All rights reserved.
//

//#import <Foundation/Foundation.h>

//@interface MTSCRA : NSObject
//  Copyright 2011 MagTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <ExternalAccessory/ExternalAccessory.h>



enum MTSCRATransactionData
{
    TLV_OPSTS,
    TLV_CARDSTS,
    TLV_TRACKSTS,
    
    TLV_CARDNAME,
    TLV_CARDIIN,
    TLV_CARDLAST4,
    TLV_CARDEXPDATE,
    TLV_CARDSVCCODE,
    TLV_CARDPANLEN,
    
    TLV_ENCTK1,
    TLV_ENCTK2,
    TLV_ENCTK3,
    
    TLV_DEVSN,
    TLV_DEVSNMAGTEK,
    TLV_DEVFW,
    TLV_DEVNAME,
    TLV_DEVCAPS,
    TLV_DEVSTATUS,
    TLV_TLVVERSION,
    TLV_DEVPARTNUMBER,
    TLV_CAPMSR,
    TLV_CAPTRACKS,
    TLV_CAPMAGSTRIPEENCRYPTION,
    TLV_KSN,
    TLV_CMAC,
    TLV_SWPCOUNT,
    TLV_BATTLEVEL,
    TLV_CFGTLVVERSION,
    TLV_CFGDISCOVERY,
    TLV_CFGCARDNAME,
    TLV_CFGCARDIIN,
    TLV_CFGCARDLAST4,
    TLV_CFGCARDEXPDATE,
    TLV_CFGCARDSVCCODE,
    TLV_CFGCARDPANLEN,
    TLV_MSKTK1,
    TLV_MSKTK2,
    TLV_MSKTK3,
    TLV_HASHCODE,
    TLV_SESSIONID,
    TLV_MAGNEPRINT,
    TLV_MAGNEPRINT_STS
    
    
    
};


enum MTSCRATransactionStatus 
{
	TRANS_STATUS_OK,
    TRANS_STATUS_START,
    TRANS_STATUS_ERROR
};
enum MTSCRATransactionEvent 
{
	TRANS_EVENT_OK = 1,
    TRANS_EVENT_ERROR=2,
    TRANS_EVENT_START = 4,
    
};
enum MTSCRACapabilities 
{
	CAP_MASKING = 1,
    CAP_ENCRYPTION=2,
    CAP_CARD_AUTH = 4,
    CAP_DEVICE_AUTH = 8,
    CAP_SESSION_ID = 16,
    CAP_DISCOVERY= 32,
};

enum MTSCRADeviceType 
{
    MAGTEKAUDIOREADER,
    MAGTEKIDYNAMO,
    MAGTEKNONE
    
};

enum MTSCRACardDataContent
{
    MASKED_TRACKDATA,
    DEVICE_ENCRYPTION_STATUS,
    ENCRYPTED_TRACK1,
    ENCRYPTED_TRACK2,
    ENCRYPTED_TRACK3,
    MAGNEPRINT_STATUS,
    ENCRYPTED_MAGNEPRINT,
    DEVICE_SERIALNUMBER,
    ENCRYPTED_SESSIONID,
    DEVICE_KSN     
};

@interface MTSCRA : NSObject <NSStreamDelegate> 
{ 
@private

	NSString *cardIIN;
	NSString *cardData;
	NSString *cardLast4;
	NSString *cardName;
	NSString *cardExpDate;
	NSString *cardServiceCode;
	NSString *cardStatus;
	NSString *responseData;
	NSString *maskedTracks;
    NSString *stdTrack1;
    NSString *stdTrack2;
    NSString *stdTrack3;
    NSString *encryptedTrack1;
    NSString *encryptedTrack2;
    NSString *encryptedTrack3;
    NSString *encryptionStatus;
    NSString *maskedTrack1;
    NSString *maskedTrack2;
    NSString *maskedTrack3;
	NSString *trackDecodeStatus;
    NSString *encryptedMagneprint;
    NSString *magneprintStatus;
    NSString *deviceSerialNumber;
    NSString *deviceSerialNumberMagTek;
    NSString *encrypedSessionID;
    NSString *deviceKSN;
    NSString *deviceFirmware;
    NSString *deviceName;
    NSString *deviceCaps;
    NSString *deviceStatus;
    NSString *tlvVersion;
    NSString *devicePartNumber;
    NSString *capMSR;
    NSString *capTracks;
    NSString *capMagStripeEncryption;
    NSString *maskedPAN;
    NSString *additionalInfoTrack1;
    NSString *additionalInfoTrack2;
    NSString *responseType;
	NSString *batteryLevel;
	NSString *swipeCount;
	
    AudioUnit					rioUnit;
    AURenderCallbackStruct		inputProc;  
    
    AudioStreamBasicDescription	thruFormat;
    AudioBufferList             bufferlist;
    AudioBuffer                 buf;
    AudioBuffer                 buf1;
    BOOL                        isDeviceConnected;
    long eventMask;
    long devCapabilities;
    
    Byte *commandBits;
    int commandBitsIndex;
    
    EAAccessory * _accessory;
	EASession *   _session;
	EAAccessoryManager *eaAccessory;
    NSMutableString *dataFromiDynamo;
	NSMutableString *deviceProtocolString;
	NSMutableString *configParams;
    
    
    enum MTSCRADeviceType devType;
@public    
    
    
}

//Initialize device
-(BOOL) openDevice; 

//Close device
-(BOOL) closeDevice;


//Retrieves if the device is connected
- (BOOL) isDeviceConnected;

//Retrieve Masked Track1 if any
- (NSString *) getTrack1Masked;

//Retrieve Masked Track2 if any
- (NSString *) getTrack2Masked;

//Retrieve Masked Track3 if any
- (NSString *) getTrack3Masked;

//Retrieves existing stored Masked data, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getMaskedTracks;

//Retrieve Encrypted Track1 if any
- (NSString *) getTrack1;

//Retrieve Encrypted Track2 if any
- (NSString *) getTrack2;

//Retrieve Encrypted Track3 if any
- (NSString *) getTrack3;

//Retrieve Encrypted MagnePrint, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getMagnePrint;

//Retrieve MagnePrint Status, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getMagnePrintStatus;

//Retrieve Device Serial Number
- (NSString *) getDeviceSerial;

//Retrieve Device Serial Number created by MagTek
- (NSString *) getMagTekDeviceSerial;

//Retrieve Firmware Vsersion Number
- (NSString *) getFirmware;

//Retrieve Device Name
- (NSString *) getDeviceName;

//Retrieve Device Capabilities
- (NSString *) getDeviceCaps;

//Retrieve Device Status
- (NSString *) getDeviceStatus;

//Retrieve TLV Version
- (NSString *) getTLVVersion;

//Retrieve Device Part Number
- (NSString *) getDevicePartNumber;

//Retrieve Key Serial Number
- (NSString *) getKSN;

//Retrieve individual tag value, only supported in audio reader
- (NSString *) getTagValue: (UInt32)tag;

//Retrieve MSR Capability
- (NSString *) getCapMSR;

//Retrieve Tracks Capability
- (NSString *) getCapTracks;

//Retrieve MagStripe Encryption Capability
- (NSString *) getCapMagStripeEncryption;

//Send Commands To The Device
- (void) sendCommandToDevice:(NSString *)pData; 

//Sets the protocol String for iDynamo
- (void) setDeviceProtocolString:(NSString *)pData; 
//Sets the config params for SDK
- (void) setConfigurationParams:(NSString *)pData; 

//Setup the events to listen for
- (void) listenForEvents:(UInt32)event;

//Retrieves the Device Type
- (int) getDeviceType;

//Retrieves the Length of teh PAN
- (int) getCardPANLength;

//Retrieve Session ID, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getSessionID;

//Retrieved the whole Response from the reader
- (NSString *) getResponseData;

//Retrieves the Name in the Card
- (NSString *) getCardName;

//Retrieves the IIN in the Card
- (NSString *) getCardIIN;

//Retrieves the Last 4 of the PAN
- (NSString *) getCardLast4;

//Retrieves the Expiration Date
- (NSString *) getCardExpDate;

//Retrieves the Service Code
- (NSString *) getCardServiceCode;

//Retrieves the Card Status
- (NSString *) getCardStatus;

//Retrieves the Track Decode Status
- (NSString *) getTrackDecodeStatus;

//Retrieve Response Type
- (NSString *) getResponseType;

//Sets the type of device to Open
-(void) setDeviceType: (UInt32)deviceType;

//Retrieves device opened status
- (BOOL) isDeviceOpened;

// Clears all the buffer that is stored during card swipe or command response
- (void) clearBuffers;
//Retrieves the battery Level
- (long) getBatteryLevel;
//Retrieves the swipe count
- (long) getSwipeCount;
//Gets the current version of the SDK.
- (NSString *) getSDKVersion;
//Retrieves the Operation Status
- (NSString *) getOperationStatus;
//Config Functions
- (NSString *) getEncryptionStatus;
//Config Functions



@end
