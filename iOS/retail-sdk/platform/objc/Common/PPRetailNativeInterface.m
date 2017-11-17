//
//  PPNativeInterface.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 3/27/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPRetailNativeInterface.h"
#import "PayPalRetailSDK+Private.h"
#import "PPAlertView.h"
#import "PPSignatureController.h"
#import "PPReceiptOptionsController.h"
#import "PPSecureValueStorage.h"
#import "A0SimpleKeychain.h"
#import "PPSoundManager.h"
#import "PPLocationManager.h"
#import "PPRetailUtils.h"
#import "PlatformView+PPAutoLayout.h"
#import "PPReaderSelectionView.h"


#define DISPOSITION_SECURE_STRING @"S"
#define DISPOSITION_STRING @"V"
#define DISPOSITION_SECURE_BLOB @"E"
#define DISPOSITION_BLOB @"B"

@interface PPRetailNativeInterface () <PPReaderSelectionViewDelegate>

@property (nonatomic, strong) PPAlertView *singletonAlert;
@property (nonatomic, strong) JSValue *singletonCallback;
@property (nonatomic, strong) PPSignatureController *signatureVC;
@property (nonatomic, weak) UIView *multiCardReaderAlertView;

@end

@implementation PPRetailNativeInterface

- (instancetype)initWithEngine:(PPManticoreEngine *)engine {
    if ((self = [super init])) {
        __weak PPRetailNativeInterface *weakSelf = self;
        engine.manticoreObject[@"alert"] = ^(JSValue *options, JSValue *callback) {
            return [weakSelf alert:options callback:callback];
        };
        engine.manticoreObject[@"setItem"] = ^(JSValue *name, JSValue *disposition, JSValue *value, JSValue *callback) {
            [weakSelf setItem:name.toString withDisposition:disposition.toString value:value.toString andCallback:callback];
        };
        engine.manticoreObject[@"getItem"] = ^(JSValue *name, JSValue *disposition, JSValue *callback) {
            [weakSelf getItem:name.toString withDisposition:disposition.toString andCallback:callback];
        };
        engine.manticoreObject[@"collectSignature"] = ^(JSValue *options, JSValue *callback) {
            return [weakSelf collectSignature:options withCallback:callback];
        };
        engine.manticoreObject[@"offerReceipt"] = ^(JSValue *options, JSValue *callback) {
            return [weakSelf offerReceipt:options withCallback:callback];
        };
        engine.manticoreObject[@"getLocation"] = ^(JSValue *callback) {
            return [weakSelf getLocation:callback];
        };
    }
    return self;
}

- (JSValue *)collectSignature:(JSValue *)options withCallback:(JSValue *)callback {
    [self dismissAlert];
    self.signatureVC = nil;
    
    if (callback) {
        JSValueProtect([PPRetailObject engine].globalContext, callback.JSValueRef);
    }
    
    self.signatureVC = [PPSignatureController signatureView:options withCallback: callback];
    JSValue *handle = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];
    __weak PPRetailNativeInterface *weakSelf = self;
    handle[@"dismiss"] = ^() {
        [weakSelf.signatureVC dismiss];
        weakSelf.signatureVC = nil;
    };
    return handle;
}

- (void)offerReceipt:(JSValue *)options withCallback:(JSValue *)callback {
    [self dismissAlert];
    if (callback) {
        JSValueProtect([PPRetailObject engine].globalContext, callback.JSValueRef);
    }
    
    PPReceiptDestinationCallback receiptDestinationCallback = ^void(PPRetailError *error, NSDictionary *receiptOption) {
        if (callback) {
            [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
            JSValue *jsReceiptOption = [JSValue valueWithObject:receiptOption inContext:[PPRetailObject engine].context];
            [callback callWithArguments:@[error?:[NSNull null], jsReceiptOption]];
        }
    };
    
    PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initFromJavascript:options[@"invoice"]];
    
    PPRetailError *error = nil;
    if ([options hasProperty:@"error"] && !options[@"error"].isNull) {
        error = [[PPRetailError alloc] initFromJavascript:options[@"error"]];
    }
    
    PPRetailReceiptViewContent *receiptViewContent = [[PPRetailReceiptViewContent alloc] initFromJavascript:options[@"viewContent"]];
    
    [PPReceiptOptionsController presentReceiptOptionsControllerWithInvoice:invoice
                                                                     error:error
                                                                   content:receiptViewContent
                                                                  callback:receiptDestinationCallback];
}

- (JSValue *)getLocation:(JSValue *)callback {
    NSDictionary *location = [[PPLocationManager sharedManager] asDictionary] ?: @{@"latitude": [NSNumber numberWithInt:0], @"longitude": [NSNumber numberWithInt:0]};
    if (callback) {
        [callback callWithArguments:@[[NSNull null], location]];
        JSValueProtect([PPRetailObject engine].globalContext, callback.JSValueRef);
    }
    return nil;
}

-(JSValue *)alert:(JSValue *)options callback:(JSValue *)callback {
    
    if ([self hasAudioFile:options]) {
        [self playAudioWithOptions:options callback:callback];
    }
    
    return [self displayAlertWithOptions:options callback:callback];
}

- (JSValue *)displayAlertWithOptions:(JSValue *)options callback:(JSValue *)callback {
    NSString *title = nil, *message = nil, *cancel = nil;
    BOOL showActivity = NO;
    NSArray *otherButtonTitles = nil;
    title = [self getStringValueFromOptions:options key:@"title"];
    message = [self getStringValueFromOptions:options key:@"message"];
    cancel = [self getStringValueFromOptions:options key:@"cancel"];
    if ([options hasProperty:@"buttons"]) {
        otherButtonTitles = options[@"buttons"].toArray;
    }
    if ([options hasProperty:@"showActivity"]) {
        showActivity = options[@"showActivity"].toBool;
    }
    if ([options hasProperty:@"mcrDialog"]) {
        NSArray *buttonImages = options[@"buttonsImages"].toArray;
        NSArray *buttonIds = options[@"buttonsIds"].toArray;
        return [self displayMultiCardReaderDialogWithTitle:title message:message buttonImages:buttonImages buttonIds:buttonIds callback:callback];
    }
    
    return [self displayAlertWithOptions:options
                                callback:callback
                                   title:title
                                 message:message
                       cancelButtonTitle:cancel
                       otherButtonTitles:otherButtonTitles
                            showActivity:showActivity];
}

- (JSValue *)displayAlertWithOptions:(JSValue *)options
                            callback:(JSValue *)callback
                              title :(NSString *)title
                             message:(NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(NSArray *)otherButtonTitles
                        showActivity:(BOOL)showActivity {
    
    JSValue *handle = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];
    __weak PPRetailNativeInterface *weakSelf = self;
    __block PPAlertView *alertView = [PPAlertView showAlertWithTitle:title
                                                             message:message
                                                   cancelButtonTitle:cancelButtonTitle
                                                   otherButtonTitles:otherButtonTitles
                                                        showActivity:showActivity
                                                    selectionHandler:^(PPAlertView *alertView, NSInteger selectedIndex) {
                                                        if (weakSelf.singletonCallback && !weakSelf.singletonCallback.isUndefined) {
                                                            [weakSelf.singletonCallback callWithArguments:@[handle, @(selectedIndex)]];
                                                            weakSelf.singletonCallback = nil;
                                                        }
                                                    }];
    [self dismissAlert];
    self.singletonAlert = alertView;
    self.singletonCallback = callback;
    handle[@"alert"] = alertView;
    handle[@"dismiss"] = ^() {
        if (alertView) {
            [alertView dismissAnimated:YES];
            JSValueUnprotect([PPRetailObject engine].globalContext, callback.JSValueRef);
            // Dismiss even if we are out of sync and alertView != weakSelf.singletonAlert
            [weakSelf dismissAlert];
            alertView = nil;
        } else {
            // Dismiss even if we are out of sync and alertView = nil
            [weakSelf dismissAlert];
        }
    };
    handle[@"setTitle"] = ^(JSValue *title) {
        if (alertView) {
            alertView.title = title.toString;
        }
    };
    handle[@"setMessage"] = ^(JSValue *message) {
        if (alertView) {
            alertView.message = message.toString;
        }
    };
    handle[@"isShowing"] = ^() {
        return (alertView != nil);
    };
    
    return handle;
}

- (JSValue *)displayMultiCardReaderDialogWithTitle:(NSString *)title message:(NSString *)message buttonImages:(NSArray *)buttonImages buttonIds:(NSArray *)buttonIds callback:(JSValue *)callback {
    JSValue *handle = [JSValue valueWithNewObjectInContext:[PPRetailObject engine].context];
    __block UIView *alertView = [[PPReaderSelectionView alloc] initWithDelegate:self
                                                                          title:title
                                                                        message:message
                                                                   buttonImages:buttonImages
                                                                      buttonIds:buttonIds
                                                                         handle:handle];
    self.multiCardReaderAlertView = alertView;
    self.singletonCallback = callback;
    
    __weak typeof(self) weakSelf = self;
    handle[@"alert"] = alertView;
    handle[@"dismiss"] = ^() {
        JSValueUnprotect([PPRetailObject engine].globalContext, callback.JSValueRef);
        if (alertView && weakSelf.multiCardReaderAlertView == alertView) {
            [PPRetailUtils dismissAlertView:weakSelf.multiCardReaderAlertView];
            weakSelf.multiCardReaderAlertView = nil;
            alertView = nil;
        }
    };
    
    [PPRetailUtils dispatchOnMainThread:^{
        [PPRetailUtils displayAlertView:self.multiCardReaderAlertView];
    }];
    
    return handle;
}
    
    
- (NSString *)getStringValueFromOptions:(JSValue *)options key:(NSString *)key {
    return ([options hasProperty:key] && !options[key].isNull) ? options[key].toString : nil;
}
    
- (BOOL)hasAudioFile:(JSValue *)options {
    return [options hasProperty:@"audio"] && !options[@"audio"].isNull && !options[@"audio"].isUndefined;
}

- (void)playAudioWithOptions:(JSValue *)options callback:(JSValue *)callback {
    JSValue *audio = options[@"audio"];
    NSString *file = audio[@"file"].toString;
    BOOL playSystemSound = YES;
    if([file isEqualToString:@"success_card_read.mp3"]) {
        playSystemSound = NO;
    }
    int playCount = 1;
    if ([audio hasProperty:@"playCount"] && !audio[@"playCount"].isNull && !audio[@"playCount"].isUndefined) {
        playCount = audio[@"playCount"].toInt32;
    }
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        playSystemSound ? [[PPSoundManager sharedInstance] playSystemSoundForCount:playCount] : [[PPSoundManager sharedInstance] playCardReadSound];
    });
}

- (void)getItem:(NSString *)name withDisposition:(NSString *)disposition andCallback:(JSValue *)callback {
    NSString *value = nil;
    NSError *readError = nil;
    if ([disposition isEqualToString:DISPOSITION_BLOB]) {
        NSArray *cachePathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath    = [[cachePathList  objectAtIndex:0] stringByAppendingPathComponent:@"RetailSDK"];
        NSString *filePath     = [cachePath stringByAppendingPathComponent:[PPSecureValueStorage hashForKey:name]];
        
        value = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&readError];
        if (readError.code == 260) {
            readError = nil; // Just means file not found
        }
    } else if ([disposition isEqualToString:DISPOSITION_SECURE_STRING]) {
        value = [[A0SimpleKeychain keychain] stringForKey:[self keyForName:name disposition:disposition]];
    } else if ([disposition isEqualToString:DISPOSITION_STRING]) {
        value = [[NSUserDefaults standardUserDefaults] stringForKey:[self keyForName:name disposition:disposition]];
    } else {
        // Secure blob
        // TODO don't blindly stick it in the keychain
        value = [[A0SimpleKeychain keychain] stringForKey:[self keyForName:name disposition:disposition]];
    }
    
    [PPRetailUtils dispatchOnMainThread:^{
        [PPRetailUtils completeWithCallback:callback arguments:@[[NSNull null], value?:[NSNull null]]];
    }];
}

- (void)setItem:(NSString *)name withDisposition:(NSString *)disposition value:(NSString*)value andCallback:(JSValue*)callback {
    NSError *writeError = nil;
    if ([disposition isEqualToString:DISPOSITION_BLOB]) {
        NSArray *cachePathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath    = [[cachePathList  objectAtIndex:0] stringByAppendingPathComponent:@"RetailSDK"];
        NSString *filePath     = [cachePath stringByAppendingPathComponent:[PPSecureValueStorage hashForKey:name]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&writeError];
        }
        
        if (!writeError) {
            [value writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        }
    } else if ([disposition isEqualToString:DISPOSITION_SECURE_STRING]) {
        if (value) {
            [[A0SimpleKeychain keychain] setString:value forKey:[self keyForName:name disposition:disposition]];
        } else {
            [[A0SimpleKeychain keychain] deleteEntryForKey:[self keyForName:name disposition:disposition]];
        }
    } else if ([disposition isEqualToString: DISPOSITION_STRING]) {
        if (value) {
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:[self keyForName:name disposition:disposition]];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self keyForName:name disposition:disposition]];
        }
    } else {
        // Secure blob
        // TODO don't blindly stick it in the keychain
        if (value) {
            [[A0SimpleKeychain keychain] setString:value forKey:[self keyForName:name disposition:disposition]];
        } else {
            [[A0SimpleKeychain keychain] deleteEntryForKey:[self keyForName:name disposition:disposition]];
        }
    }
    
    [PPRetailUtils dispatchOnMainThread:^{
        [PPRetailUtils completeWithCallback:callback arguments:@[writeError?:[NSNull null]]];
    }];
}

- (NSString *)keyForName:(NSString*)name disposition:(NSString*)disposition {
    return [@[@"PayPalRetail", disposition, name] componentsJoinedByString:@"."];
}

- (void)dismissAlert {
    if (self.singletonAlert) {
        [self.singletonAlert dismissAnimated:NO];
        self.singletonAlert = nil;
    }
}

#pragma mark -
#pragma mark - PPReaderSelectionViewDelegate

- (void)selectedReaderIndex:(NSInteger)index handle:(JSValue *)handle {
    if (self.singletonCallback && !self.singletonCallback.isUndefined) {
        [self.singletonCallback callWithArguments:@[handle, @(index)]];
        self.singletonCallback = nil;
    }
}

@end
