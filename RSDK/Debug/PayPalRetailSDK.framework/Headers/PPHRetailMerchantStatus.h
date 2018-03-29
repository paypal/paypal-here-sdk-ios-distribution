//
//  PPHRetailMerchantStatus.h
//

#import <Foundation/Foundation.h>
#import "PPHRetailMerchantCardSettings.h"

@interface PPHRetailMerchantStatus : NSObject

@property (nonatomic, copy) NSString *status;
@property (nonatomic, strong) NSArray *paymentTypes;
@property (nonatomic, strong) PPHRetailMerchantCardSettings *cardSettings;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, assign) BOOL businessCategoryExists;

@end
