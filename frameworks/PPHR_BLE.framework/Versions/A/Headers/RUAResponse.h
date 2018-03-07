//
//  RUAResponse.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 12/22/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RUAByteUtils.h"
#import "RUAParameter.h"
#import "RUACommand.h"

#ifndef RUAResponse_h
#define RUAResponse_h

typedef  enum {

    RUAErrorCodeNone = 0,

    /** Landi Reader Error Code 3: Failed to decode audio waveform. */
    RUAErrorCodeFailedToDecodeAudioWaveform = 3,

    /** Landi Reader Error Code 4: Not enough memory. */
    RUAErrorCodeNotEnoughMemory = 4,

    /** Landi Reader Error Code 5: Timeout. */
    RUAErrorCodeReaderTimeout = 5,

    /** Landi Reader Error Code 6: Byte format error. */
    RUAErrorCodeByteFormatError = 6,

    /** Landi Reader Error Code 7: Frame format error. */
    RUAErrorCodeFrameFormatError = 7,

    /** Landi Reader Error Code 8: Unknown error. */
    RUAErrorCodeUnknownError = 8,

    /** Landi Reader Error Code 9: Audio track write data error. */
    RUAErrorCodeAudioTrackWriteDataError = 9,

    /** Landi Reader Error Code 10: Audio record read data error. */
    RUAErrorCodeAudioRecordReadDataError = 10,

    /** The Exchage state error. */
    RUAErrorCodeExchageStateError = 11,

    /** The command you have sent returned an invalid response. */
    RUAErrorCodeInvalidCommandResponse = 12,

    /** This command supported is not supported by selected roam reader */
    RUAErrorCodeCommandNotSupported = 13,

    /** missing mandatory parameters required to execute a command  */
    RUAErrorCodeMISSING_MANDATORY_PARAMETERS = 14,

    RUAErrorCodeERROR_READING_KSN = 15,

    RUAErrorCodeERROR_READING_VERSION = 16,

    RUAErrorCodeG4X_FAILED_TO_GET_KSN = 17,

    /** G4x Swiper decode swipe fail. */
    RUAErrorCodeG4X_DECODE_SWIPE_FAIL = 18,

    /**  G4x Swiper decode tap fail. */
    RUAErrorCodeG4X_DECODE_TAP_FAIL = 19,

    /**  G4x Swiper decode crc error. */
    RUAErrorCodeG4X_DECODE_CRC_ERROR = 20,

    /**  G4x Swiper decode comm error. */
    RUAErrorCodeG4X_DECODE_COMM_ERROR = 21,

    /**  G4x Swiper decode card not supported. */
    RUAErrorCodeG4X_DECODE_CARD_NOT_SUPPORTED = 22,

    /**  G4x Swiper decode unknown error. */
    RUAErrorCodeG4x_DECODE_UNKNOWN_ERROR = 23,

    /** G4x Reader is interrupted */
    RUAErrorCodeReaderInterrupted = 24,

    RUAErrorCodeReaderDisconnected = 25,

    RUAErrorCodeReaderGeneralError = 26,

    /** 8E02 Invalid Transmitted DataLength */
    RUAErrorCodeInvalidTransmittedDataLength = 27,

    /** 8E04 Instruction not supported by this reader. */
    RUAErrorCodeInstructionNotSupportedByThisReader = 28,

    /** 8E05 Invalid parameters. */
    RUAErrorCodeInvalidParameters = 29,

    /** 8E09 Command not valid at this point. */
    RUAErrorCodeCommandNotValidAtThisPoint = 30,

    /** 8E0A Timeout expired. */
    RUAErrorCodeTimeoutExpired = 31,

    /** 8E0B Command cancelled upon receipt of a cancel wait command. */
    RUAErrorCodeCommandCancelledUponReceiptOfACancelWaitCommand = 32,

    /** 8E81 Card reader general error. */
    RUAErrorCodeCardReaderGeneralError = 33,

    /** 8E0C Background magnetic card reading is in the wrong state for the command that was issued. */
    RUAErrorCodeBackgroundMagneticCardReadingIsInTheWrongStateForTheCommandThatWasIssued = 34,

    /** 8E0D No background magnetic card data available. */
    RUAErrorCodeNoBackgroundMagneticCardDataAvailable = 35,

    /** C100 Mandatory emvtlv data missing. */
    RUAErrorCodeMandatoryEMVTLVDataMissing = 36,

    /** C101 Storage full. */
    RUAErrorCodeStorageFull = 37,

    /** C102 Non emv card or card error. */
    RUAErrorCodeNonEMVCardOrCardError = 38,

    /** C103 No mutually supported ai ds. */
    RUAErrorCodeNoMutuallySupportedAIDs = 39,

    /** C104 AID not in list of mutually supported ai ds. */
    RUAErrorCodeAIDNotInListOfMutuallySupportedAIDs = 40,

    /** C105 DOL not configured. */
    RUAErrorCodeDOLNotConfigured = 41,

    /** C106 RSA key not found. */
    RUAErrorCodeRSAKeyNotFound = 42,

    /** C107 No rsa keys available. */
    RUAErrorCodeNoRSAKeysAvailable = 43,

    /** C108 Duplicate rsa key. */
    RUAErrorCodeDuplicateRSAKey = 44,

    /** C109 Duplicate aid. */
    RUAErrorCodeDuplicateAID = 45,

    /** C10A Application blocked. */
    RUAErrorCodeApplicationBlocked = 46,

    /** C10B Card blocked. */
    RUAErrorCodeCardBlocked = 47,

    /** C184 Reverted contactless transaction has failed but may be attempted over a contact interface. */
    RUAErrorCodeRevertedContactlessTransactionHasFailedButMayBeAttemptedOverAContactInterface = 48,

    /** C185 ICC has been inserted but insertion was disabled. */
    RUAErrorCodeICCHasBeenInsertedButInsertionWasDisabled = 49,

    /** C186 Contactless not permitted. */
    RUAErrorCodeContactlessNotPermitted = 50,

    /** C187 Contactless application error. */
    RUAErrorCodeContactlessApplicationError = 51,

    /** C188 External device should update the display and restart contactless processing. */
    RUAErrorCodeExternalDeviceShouldUpdateTheDisplayAndRestartContactlessProcessing = 52,

    /** C189 Errors exist in the risk parameter records submitted using tag DF6B. */
    RUAErrorCodeErrorsExistInTheRiskParameterRecordsSubmittedUsingTagDF6B = 53,

    /** C18A Reverted contactless transaction has failed and may be attempted using contact icc only but pin pad icc processing is not enabled. */
    RUAErrorCodeRevertedContactlessTransactionHasFailedAndMayBeAttemptedUsingContactICCOnlyButPINPadICCProcessingIsNotEnabled = 54,

    /** 8E90 Card expired. */
    RUAErrorCodeCardExpired = 55,

    /** 8E91 Card not yet valid. */
    RUAErrorCodeCardNotYetValid = 56,

    /** 8E92 Invalid track data. */
    RUAErrorCodeInvalidTrackData = 57,

    /** 8E93 Command not valid at this point E2E. */
    RUAErrorCodeCommandNotValidAtThisPointE2E = 58,

    /** 8F01 Fleet card pin verification failed. */
    RUAErrorCodeFleetCardPINVerificationFailed = 59,

    /** 8F02 Fleet card encryption key not available. */
    RUAErrorCodeFleetCardEncryptionKeyNotAvailable = 60,

    /** 8F03 TDESDUKPT key not found. */
    RUAErrorCodeTDESDUKPTKeyNotFound = 61,

    /** 8F04 TDESDUKPTPIN encryption ormac calculation failed. */
    RUAErrorCodeTDESDUKPTPINEncryptionORMACCalculationFailed = 62,

    /** 8F05 TDESDUKPT key injection failed. */
    RUAErrorCodeTDESDUKPTKeyInjectionFailed = 63,

    /** 8F06 TDESDUKPTPIN change failed to complete successfully. */
    RUAErrorCodeTDESDUKPTPINChangeFailedToCompleteSuccessfully = 64,

    /** 8F07 Secure area already exists. */
    RUAErrorCodeSecureAreaAlreadyExists = 65,

    /** 8F0A Master or session key not found. */
    RUAErrorCodeMasterOrSessionKeyNotFound = 66,

    /** 8F0B Master or session pin encryption failed. */
    RUAErrorCodeMasterOrSessionPINEncryptionFailed = 67,

    /** 8F0C Master or session kcv doesnot match. */
    RUAErrorCodeMasterOrSessionKCVDoesnotMatch = 68,

    /** 8F0D SHA1 checksum doesnot match. */
    RUAErrorCodeSHA1ChecksumDoesnotMatch = 69,

    /** 8F0E SHA1 calculation failed. */
    RUAErrorCodeSHA1CalculationFailed = 70,

    /** 8F10 PAN decryption failed. */
    RUAErrorCodePANDecryptionFailed = 71,

    RUAErrorCodeTrackReadError = 72,

    RUAErrorCodeDownloadErrorNotSurpportFileType = 73,

    RUAErrorCodeDownloadErrorNotSurpportFileTypeinUns=74,

    RUAErrorCodeDownloadErrorHandshakeFailed=75,

    RUAErrorCodeDownloadErrorFilepathWrong = 76,
    RUAErrorCodeDownloadErrorFileOperateFailed = 77,
    RUAErrorCodeDownloadErrorDeviceNotOpen = 78,
    RUAErrorCodeDownloadErrorIsDownloadingState = 79,
    RUAErrorCodeDownloadErrorNoRespondAck = 80,
    RUAErrorCodeDownloadErrorWrongFram = 81,
    RUAErrorCodeDownloadErrorExchangeErrorState = 82,
    RUAErrorCodeDownloadErrorBluetoothDisconnected = 83,
    RUAErrorCodeDownloadErrorHandshakeTimeout = 84,
    RUAErrorCodeDownloadErrorUnsFileCrcError = 85,
    RUAErrorCodeDownloadErrorSuspendOk = 86,
    RUAErrorCodeDownloadErrorSuspendFailed = 87,
    RUAErrorCodeDownloadErrorUnknownError = 88,

    /** Transaction cancelled after allowed number of insertion attempts exceeded **/
    RUAErrorCodeExceededAllowedCardInsertions = 89,

    /** Non Certified EMV configuration check 9F33 9F40 9F35 & 9C Values.
     * Transaction can be completed even if InvalidEMVConfiguration error is returned. **/
    RUAErrorCodeNonCertifiedEMVKernelConfiguration = 90,
    /** 6986 */
    RUAErrorCodeStopContactlessInterface = 91,

    /**FFFF*/
    RUAErrorCodePinEntryAborted = 92,

    /** 8E86 Card interface general error. */
    RUAErrorCodeCardInterfaceGeneralError = 93,

    /** C1A0 Battery too low error. */
    RUAErrorCodeBatteryTooLowError = 94,

    /** Card reader is not initialized*/
    RUAErrorCodeReaderNotInitialized = 95,

    /** 8EA2 P2PE encrypt error*/
    RUAErrorCodeP2PEEncryptError = 96,

    /**
     Certificate Filve VErsion not available for the reader
     */
    RUAErrorCodeCertificateFilesVersionInfoNotAvailable =97,
    /** PinByPass*/
    RUAErrorCodePinByPass = 98,

    RUAErrorVASBadValue = 99,

    RUAErrorVASBadLength = 100,

    RUAErrorVASParamerterNotSet = 101,

    /** VAS_MAX_MERCHANTS_NB_REACHED_ERR (Max Merchants Number (24) reached)*/
    RUAErrorVASMaxMerchantLimitReached = 102,

    /** Card reader is busy processing*/
    RUAErrorCodeCardReaderBusy = 103,

    RUAErrorCodeDownloadErrorUserCancel = 104

} RUAErrorCode;


typedef enum {
    /**
     Success
     */
    RUAResponseCodeSuccess,
    /**
     Error
     */
    RUAResponseCodeError,
    RUAResponseCodeUnknown
} RUAResponseCode;

typedef enum {
    RUAResponseTypeUnknown = 100,
    /** Contact EMV amount dol. */
    RUAResponseTypeContactEMVAmountDOL = 101,
    /** Contactless EMV amount dol. */
    RUAResponseTypeContactLessEMVAmountDOL = 102,
    /** Contact EMV response dol. */
    RUAResponseTypeContactEMVResponseDOL = 103,
    /** Contactless EMV response dol. */
    RUAResponseTypeContactLessEMVResponseDOL = 104,
    /** Contact EMV online dol. */
    RUAResponseTypeContactEMVOnlineDOL = 105,
    /** Contactless EMV online dol. */
    RUAResponseTypeContactLessEMVOnlineDOL = 106,
    /** Magnetic Card Data */
    RUAResponseTypeMagneticCardData = 107,
    /** List of Application Identifiers (AID) */
    RUAResponseTypeListOfApplicationIdentifiers = 108

} RUAResponseType;

typedef enum {
    RUACardTypeContactEMV,
    RUACardTypeContactlessEMV,
    RUACardTypeMagneticStripe,
    RUACardTypeUnknown
} RUACardType;

typedef enum {
    RUAPinTypeTDESBlock,
    RUAPinTypeMasterSessionKey,
    RUAPinTypeUnknown
} RUAPinType;

#endif /* ifndef RUAResponse_h */

@interface RUAResponse : NSObject

/**
 Enumeration of the ResponseType
 @see RUAResponseType
 */
@property RUAResponseType responseType;

/**
 List of Application Identifiers
 @see RUAApplicationIdentifier
 */
@property NSArray* listOfApplicationIdentifiers;

/**
 Enumeration of the command
 @see RUACommand
 */
@property RUACommand command;
/**
 Enumeration of the response code, indicates whether the command is processed successfully or not
 @see RUAResponseCode
 */
@property RUAResponseCode responseCode;
/**
 Enumeration of the error code
 @see RUAErrorCode
 */
@property RUAErrorCode errorCode;
/**
 Enumeration of the card type that has been used
 @see RUACardType
 */
@property RUACardType cardType;
/**
 Returns the response data in a dictionary (For example, contains EMV tag data for EMV transaction commands) with RUAParameter as key
 @see RUAParameter
 */
@property NSDictionary *responseData;

/**
 Returns the additionals details about the error
 */
@property NSString *additionalErrorDetails;

- (id)init:(RUACommand)command
      withResponseCode:(RUAResponseCode)responseCode
         withErrorCode:(RUAErrorCode)errorCode
      withResponseData:(NSDictionary *)responseData
      withResponseType:(RUAResponseType)responseType
      withApplicationIdentifeirs:(NSArray *)applicationIdentifiers
          withCardType:(RUACardType)cardType;

- (id)init:(RUACommand)command withResponseCode:(RUAResponseCode)responseCode withErrorCode:(RUAErrorCode)errorCode withAdditionalErrorDetails:(NSString *)errorMessage;

@end
