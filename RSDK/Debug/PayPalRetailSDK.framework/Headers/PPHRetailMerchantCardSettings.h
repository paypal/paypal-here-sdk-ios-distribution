//
//  PPHRetailMerchantCardSettings.h
//

#import <Foundation/Foundation.h>

@interface PPHRetailMerchantCardSettings : NSObject

@property (nonatomic, copy) NSString *minimum;
@property (nonatomic, copy) NSString *maximum;
@property (nonatomic, copy) NSString *signatureRequiredAbove;
@property (nonatomic, strong) NSArray *unsupportedCardTypes;

@end
