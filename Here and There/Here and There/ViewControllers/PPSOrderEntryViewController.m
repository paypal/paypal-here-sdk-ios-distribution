//
//  PPSOrderEntryViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/26/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>

#import "PPSKeypad.h"
#import "NITextField.h"
#import "PPSAlertView.h"
#import "PPSProgressView.h"
#import "PPSChargeViewController.h"
#import "PPSOrderEntryViewController.h"
#import "NimbusBadge.h"

@interface PPSOrderEntryViewController () <
UITextFieldDelegate,
CLLocationManagerDelegate,
PPHLocationWatcherDelegate,
PPHCardReaderDelegate
>
@property (nonatomic,strong) NITextField *amount;
@property (nonatomic,strong) PPSKeypad *keypad;
@property (nonatomic,strong) UIButton *charge;
@property (nonatomic,strong) CLLocationManager *tracker;
@property (assign) BOOL gotValidLocation;
@property (nonatomic,strong) PPHLocationWatcher *watcher;
@property (nonatomic,strong) NIBadgeView *badge;
@property (nonatomic,strong) PPHCardReaderWatcher *upgradeWatcher;
@end

@implementation PPSOrderEntryViewController

-(void)dealloc
{
    [self.tracker stopUpdatingLocation];
}

-(void)viewDidLoad
{
    // If you are using a custom accessory swiper that we support (such as a Magtek custom branded one),
    // set it up before calling beginMonitoring like so:
    PPHCardReaderBasicInformation *basic = [[PPHCardReaderBasicInformation alloc] init];
    basic.readerType = ePPHReaderTypeDockPort;
    basic.protocolName = @"com.youare.socool";
    [[PayPalHereSDK sharedCardReaderManager] setPreferenceOrder:@[basic,[PPHCardReaderBasicInformation anyReader]]];
    // ALSO DO NOT FORGET - add this same protocol string to your plist supported accessories
    
    [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view buildSubviews:@[
                               [NITextField new], @"#amount",
                               [UIButton buttonWithType:UIButtonTypeCustom], @"#charge", @".primaryBtn", SELECT_SELF(chargePressed),
                               [NIBadgeView new], @"#badge"
                               ] inDOM:self.dom];
    self.keypad = [PPSKeypad new];
    self.keypad.frameWidth = self.view.frameWidth;
    
    self.amount.inputView = self.keypad;
    self.amount.delegate = self;
    self.amount.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.amount addTarget:self action:@selector(validate) forControlEvents:UIControlEventEditingChanged];
    
    self.keypad.delegate = self.amount;
    self.charge.enabled = NO;
    
    self.tracker = [[CLLocationManager alloc] init];
    self.tracker.delegate = self;
    [self.tracker startUpdatingLocation];
    
    self.badge.hidden = YES;
    self.upgradeWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    [self.tracker stopUpdatingLocation];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.amount becomeFirstResponder];
    if (self.watcher) {
        //        [self.watcher updatePeriodically:2 withMaximumInterval:20];
    }
}

-(void)didDetectUpgradeableReader:(PPHCardReaderBasicInformation *)reader withMessage:(NSString *)message isRequired:(BOOL)required isInitial:(BOOL)initial {
    __block PPSProgressView *pv = [PPSProgressView progressViewWithTitle:@"Software Upgrade" andMessage:@"For EMV Reader" withCancelHandler:^(PPSProgressView *progressView) {
        
    }];
    [[PayPalHereSDK sharedCardReaderManager] beginUpgrade:reader];
    [pv dismiss:YES];
}

-(void)didUpgradeReader:(BOOL)successful withMessage:(NSString *)message {
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // We just set this once in the sample app. In a real app you would want to update the location as the merchant moves
    // any meaningful distance. Threshold should be set by your needs, but usually something like 1/4 mile would work
    if (!self.gotValidLocation) {
        self.gotValidLocation = YES;
        // Make sure location is setup for checkin
        [[PayPalHereSDK sharedLocalManager] beginGetLocations:^(PPHError *error, NSArray *locations) {
            if (error) {
                // Error handling would be nice.
                return;
            }
            if (locations == nil || [locations count] == 0) {
                // Make a location
                PPHLocation *loc = [[PPHLocation alloc] init];
                loc.contactInfo = [PayPalHereSDK activeMerchant].invoiceContactInfo;
                loc.internalName = @"TestLocation";
                loc.location = newLocation.coordinate;
                loc.isMobile = YES;
                loc.isAvailable = YES;
                [loc save:^(PPHError *error) {
                    // Error handling would be a good thing.
                    if (error == nil) {
                        self.watcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:loc.locationId withDelegate:self];
                        //                        [self.watcher updatePeriodically:2 withMaximumInterval:20];
                    }
                }];
            } else {
                // Here, you may have multiple locations, so you'd need to employ some logic to pick the one you want.
                NSString *currentName = [PPSPreferences currentLocationName];
                PPHLocation *myLocation = [locations objectAtIndex: 0];
                if (currentName && currentName.length > 0) {
                    for (PPHLocation *loc in locations) {
                        if ([loc.internalName isEqualToString:currentName]) {
                            myLocation = loc;
                            break;
                        }
                    }
                }
                myLocation.location = newLocation.coordinate;
                myLocation.isMobile = myLocation.isAvailable = YES;
                [myLocation save:^(PPHError *error) {
                    
                }];
                //                self.watcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:myLocation.locationId withDelegate:self];
                //                [self.watcher updatePeriodically:2 withMaximumInterval:20];
                NSLog(@"%@", myLocation);
            }
        }];
    }
}

-(void)locationWatcher:(PPHLocationWatcher *)watcher didDetectNewTab:(PPHLocationCheckin *)tab
{
    
}

-(void)locationWatcher:(PPHLocationWatcher *)watcher didDetectRemovedTab:(PPHLocationCheckin *)tab
{
    
}

-(void)locationWatcher:(PPHLocationWatcher *)watcher didReceiveError:(PPHError *)error
{
    
}

-(void)locationWatcher:(PPHLocationWatcher *)watcher didCompleteUpdate:(NSArray *)openTabs wasModified:(BOOL)wasModified
{
    if (!wasModified) {
        return;
    }
    
    if ([openTabs count]) {
        if (self.badge.hidden) {
            self.badge.alpha = 0;
            self.badge.hidden = NO;
            // Do this dance to get the now non-zero frame of the badge in the right place
            self.badge.text = @"0";
            [self.badge sizeToFit];
            [self.dom refreshView:self.badge];
        }
        [UIView animateWithDuration:.1 animations:^{
            self.badge.alpha = 1;
            self.badge.text = [NSString stringWithFormat:@"%d", openTabs.count];
            [self.badge sizeToFit];
            [self.dom refreshView:self.badge];
        }];
    } else {
        [UIView animateWithDuration:.1 animations:^{
            self.badge.alpha = 0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.badge.hidden = YES;
            }
        }];
    }
}

-(void)chargePressed
{
    // Build an invoice for this order
    NSString * currency = [PayPalHereSDK activeMerchant].currencyCode;
    PPHInvoice *invoice = [[PPHInvoice alloc] initWithCurrency:currency];
    [invoice addItemWithId:@"Purchase"
                      name:@"Purchase"
                  quantity:[NSDecimalNumber one]
                 unitPrice:[PPHAmount amountWithString:self.amount.text inCurrency:currency].amount
                   taxRate:nil taxRateName:nil];
    
    // TODO support cancellation
    __block PPSProgressView *progress = [PPSProgressView progressViewWithTitle:@"Saving Order" andMessage:nil withCancelHandler:nil];
    [invoice save:^(PPHError *error) {
        if (error) {
            // TODO
            [progress dismiss:NO];
            [PPSAlertView showAlertViewWithTitle:@"Error" message:error.localizedDescription buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
        } else {
            [self.watcher stopPeriodicUpdates];
            [progress dismiss:YES];
            PPSChargeViewController *charge = [[PPSChargeViewController alloc] initWithInvoice: invoice andLocationWatcher:self.watcher];
            [self.navigationController pushViewController:charge animated:YES];
        }
    }];
}

-(NSString *)stylesheetName {
    return @"orderEntry";
}

-(void)validate
{
    PPHAmount *amount = [PPHAmount amountWithString:self.amount.text inCurrency:[PayPalHereSDK activeMerchant].currencyCode];
    self.charge.enabled = amount.isValid;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newValue = [textField.text stringByReplacingCharactersInRange:range withString:string];
    PPHAmount *amount = [PPHAmount amountWithString:newValue inCurrency:[PayPalHereSDK activeMerchant].currencyCode];
    self.charge.enabled = amount.isValid;
    return amount.isValid || [newValue isEqualToString:@"."];
}
@end
