//
//  PPHRetailMerchantUserInfo.h
//

#import <Foundation/Foundation.h>
#import "PPRetailInvoiceAddress.h"

@interface PPHRetailMerchantUserInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *givenName;
@property (nonatomic, copy) NSString *familyName;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *businessSubCategory;
@property (nonatomic, copy) NSString *businessCategory;
@property (nonatomic, copy) NSString *payerId;
@property (nonatomic, strong) PPRetailInvoiceAddress *address;

@end
