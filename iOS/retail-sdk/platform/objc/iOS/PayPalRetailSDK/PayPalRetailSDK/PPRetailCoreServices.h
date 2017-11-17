//
//  PPRetailCoreServices.h
//  Pods
//
//  Created by Marasinghe,Chathura on 8/18/17.
//
//

#import <Foundation/Foundation.h>

#define RSDK_LOCALIZED_STRING(name,defaultValue) [PPRetailCoreServices localizedStringNamed: name withDefault: defaultValue forTable: @"PPRSDK"]

@interface PPRetailCoreServices : NSObject

// TODO : Fill this class with common core functions - Chathura.

/*
 * Country phone code list in standard format. i.e. {US : +1 (###) ###-*, AU: ..}
 */
+ (NSDictionary *)countryPhoneCodesList;

/*
 * Returns a localized version of the externalized string. i.e. French, Japanese ..
 */
+ (NSString *)localizedStringNamed:(NSString *)name withDefault:(NSString *)defaultValue forTable:(NSString *)tableName;
@end
