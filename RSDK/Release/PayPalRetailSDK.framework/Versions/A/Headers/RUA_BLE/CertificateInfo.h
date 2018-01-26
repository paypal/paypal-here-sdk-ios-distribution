//
//  CertificateInfo.h
//  ROAMreaderUnifiedAPI
//
//  Created by Mallikarjun Patil on 10/26/16.
//  Copyright © 2016 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CertificateInfo : NSObject

/**
 *  CertificateInfo commonName value
 */
@property NSString* commonName;

/**
 *  CertificateInfo oid value
 */
@property NSString* oid;

/**
 *  CertificateInfo date value
 */
@property NSString* dateValue;

-(id)initWithData:(NSString*) certificateInfo;

-(id)initCustomerCertificateWithData:(NSString*) certificateInfo;
    
-(NSString*) toString;

@end
