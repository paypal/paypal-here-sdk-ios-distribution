//
//  PPRetailCoreServices.m
//  Pods
//
//  Created by Marasinghe,Chathura on 8/18/17.
//
//

#import "PPRetailCoreServices.h"

@implementation PPRetailCoreServices

extern const NSString *countryCodeFormatList = @"RetailCountryPhoneFormats";

+ (NSDictionary *)countryPhoneCodesList {
    return [NSMutableDictionary dictionaryWithContentsOfFile:[[self rsdkBundle]  pathForResource:countryCodeFormatList ofType:@"plist" ]];
}

+ (NSBundle*)rsdkBundle {
    //http://blog.flaviocaetano.com/post/cocoapods-and-resource_bundles/
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"PayPalRetailSDKResources" ofType:@"bundle"];
    
    NSBundle *frameworkBundle = [NSBundle bundleWithPath:bundlePath];
    if(!frameworkBundle){
        
        NSString *mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"PayPalRetailSDKResources.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
        
        // TODO this is to make unit tests work, I have no idea why it's different.
        if (!frameworkBundle) {
            mainBundlePath = [[NSBundle bundleForClass:[self class]] resourcePath];
            frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"../PayPalRetailSDKResources.bundle"];
            frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
            
            if (!frameworkBundle) {
                frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"../../PayPalRetailSDKResources.bundle"];
                frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
            }
            if(!frameworkBundle){
                
                mainBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
                //http://stackoverflow.com/questions/17505856/how-to-read-resources-files-within-a-framework
                NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"PayPalRetailSDKResources.bundle"];
                frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
            }
        }
    }
    return frameworkBundle;
}

+ (NSString *)localizedStringNamed:(NSString *)name withDefault:(NSString *)defaultValue forTable:(NSString *)tableName {
    static NSBundle *stringBundle = nil;
    static dispatch_once_t onceToken;
    NSBundle *fwBundle = [PPRetailCoreServices rsdkBundle];
    NSArray *languages = [[NSLocale preferredLanguages] arrayByAddingObject:@"en"];
    [languages enumerateObjectsUsingBlock:^(NSString *language, NSUInteger idx, BOOL *stop) {
        NSString *lproj = [fwBundle pathForResource:language ofType:@"lproj"];
        if (lproj) {
            stringBundle = [NSBundle bundleWithPath:lproj];
            *stop = YES;
        }
    }];
    
    NSString *val = [stringBundle localizedStringForKey:name value:defaultValue table:tableName];
    //#ifdef DEBUG Revisit - Chathura
    //    if (!val) {
    //        val = [defaultValue copy];
    //    }
    //    objc_setAssociatedObject(val, &STRING_KEY, name, OBJC_ASSOCIATION_RETAIN);
    //#endif
    return val ?: defaultValue;
}

@end
