//
//  RUAReadCertificateFileVersionInfo.h
//  ROAMreaderUnifiedAPI
//
//  Created by Arjun on 7/25/16.
//  Copyright © 2016 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RUAFileVersionInfo.h"
#import "CertificateInfo.h"

@interface RUACertificateFilesVersionInfo : NSObject


/**
 *
 * */
@property RUAFileVersionInfo *flrcVersion;


/**
 *
 * */
@property RUAFileVersionInfo *fsrcVersion;

/**
 *
 * */
@property RUAFileVersionInfo *alrcVersion;
/**
 *
 * */
@property RUAFileVersionInfo *asrcVersion;

/**
 *
 * */
@property RUAFileVersionInfo *brcVersion;

/**
 *
 * */
@property RUAFileVersionInfo *ercVersion;

/**
 *
 * */
@property RUAFileVersionInfo *tarcVersion;

/**
 *
 * */
@property CertificateInfo *imsRootCa;

/**
 *
 * */
@property CertificateInfo *rkmsSigningCertificate;

/**
 *
 * */
@property CertificateInfo *rkmsEncryptionCertificate;

/**
 *
 * */
@property CertificateInfo *customerCertificate;

- (NSString *) toString ;

@end
