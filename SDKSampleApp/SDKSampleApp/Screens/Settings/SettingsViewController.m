//
//  SettingsViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import "SettingsViewController.h"
#import "ReaderInfoViewController.h"
#import "STAppDelegate.h"

#import <PayPalHereSDK/PayPalHereSDK.h>

@interface SettingsViewController ()
@property (nonatomic,strong) PPHCardReaderBasicInformation *readerInfo;
@property (nonatomic,strong) PPHCardReaderMetadata *readerMetadata;
@property (nonatomic,strong) PPHCardReaderWatcher *cardWatcher;
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLLocation *merchantLocation;
@property BOOL gotValidLocation;
@property BOOL isMerchantCheckinPending;
@end

@implementation SettingsViewController

@synthesize checkinSwitch;
@synthesize checkinMerchantSpinny;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.readerInfo = nil;
        self.readerMetadata = nil;
        self.cardWatcher = [[PPHCardReaderWatcher alloc] initWithSimpleDelegate:self];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(appDelegate.isMerchantCheckedin){
        [self.checkinSwitch setOn:YES animated:YES];
    }else{
        [self.checkinSwitch setOn:NO animated:YES];
    }
    self.checkinMerchantSpinny.hidden = YES;
    
    self.merchantLocation = nil;
    self.isMerchantCheckinPending = NO;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    [self.locationManager stopUpdatingLocation];
}

-(void)dealloc
{
    [self.locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
    
    if ([[[PayPalHereSDK sharedCardReaderManager] availableDevices] count] > 0) {
		self.readerDetectedButton.enabled = YES;
	}
	else {
		self.readerDetectedButton.enabled = NO;
	}
    
    self.detectingReaderSpinny.hidden = YES;
    
    self.sdkVersion.text = [PayPalHereSDK sdkVersion];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
	[[PayPalHereSDK sharedCardReaderManager] endMonitoring:YES];
    
}

- (IBAction)onCheckinButtonToggled:(id)sender
{
    NSLog(@"onCheckinButton clicked");
    if(self.checkinSwitch.on){
        if(nil != self.merchantLocation){
            self.checkinSwitch.hidden = YES;
            self.checkinMerchantSpinny.hidden = NO;
            [self.checkinMerchantSpinny startAnimating];
            [self getMerchantCheckin:self.merchantLocation];
        }else{
            self.isMerchantCheckinPending = TRUE;
        }
    }else{
        [self.checkinSwitch setOn:NO animated:YES];
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        PPHLocation *myLocation = appDelegate.merchantLocation;
        myLocation.isAvailable = NO;
        appDelegate.merchantLocation = nil;
        appDelegate.isMerchantCheckedin = NO;
    }
}

- (IBAction)onReaderDetailsPressed:(id)sender {
    
	// Transition to the Reader Info screen:
	ReaderInfoViewController *readerInfoVC = nil;
    
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		readerInfoVC = [[ReaderInfoViewController alloc]
                        initWithNibName:@"ReaderInfoViewController_iPhone"
                        bundle:nil];
	}
	else {
		readerInfoVC = [[ReaderInfoViewController alloc]
                        initWithNibName:@"ReaderInfoViewController_iPad"
                        bundle:nil];
	}
    
    
    // Set up the fields:
	PPHReaderType type = self.readerInfo.readerType;
	readerInfoVC.readerType = (type == ePPHReaderTypeAudioJack ?
							   @"Audio Jack Reader" :
							   (type == ePPHReaderTypeDockPort ?
								@"Dock Port Reader" :
								(type == ePPHReaderTypeChipAndPinBluetooth ?
								 @"Chip and Pin BT Reader" :
								 @"Unknown Reader Type")));
    
	readerInfoVC.readerFamily = self.readerInfo.family;
	readerInfoVC.friendlyName = self.readerInfo.friendlyName;
    
    
	// Do we have any interesting meta-data to show?
	if (self.readerMetadata != nil) {
		readerInfoVC.serialNumber = self.readerMetadata.serialNumber;
		readerInfoVC.firmwareRevision = self.readerMetadata.firmwareRevision;
		readerInfoVC.batteryLevel = [NSString stringWithFormat:@"%d", self.readerMetadata.batteryLevel];
	}
    
	[self.navigationController pushViewController:readerInfoVC animated:YES];
    
    
}



#pragma mark -
#pragma mark PPHSimpleCardReaderDelegate

-(void)didStartReaderDetection:(PPHCardReaderBasicInformation *)readerType
{
    NSLog(@"Detecting Device");
    self.detectingReaderSpinny.hidden = NO;
    [self.detectingReaderSpinny startAnimating];
}

-(void)didDetectReaderDevice:(PPHCardReaderBasicInformation *)reader
{
    NSLog(@"%@", [NSString stringWithFormat:@"Detected %@", reader.friendlyName]);
    self.detectingReaderSpinny.hidden = YES;
    [self.detectingReaderSpinny stopAnimating];
    self.readerDetectedButton.enabled = YES;
    self.readerInfo = reader;
}

-(void)didRemoveReader:(PPHReaderType)readerType
{
    NSLog(@"Reader Removed");
    self.detectingReaderSpinny.hidden = YES;
    [self.detectingReaderSpinny stopAnimating];
    self.readerDetectedButton.enabled = NO;
    self.readerInfo = nil;
}

-(void)didCompleteCardSwipe:(PPHCardSwipeData*)card
{
	NSLog(@"Got card swipe!");
}

-(void)didFailToReadCard
{
	NSLog(@"Card swipe failed!!");
    
    UIAlertView *alertView;
    
    alertView = [[UIAlertView alloc]
                 initWithTitle:@"Problem reading card"
                 message: @"Looks like there was a failed swipe.  Please try again."
                 delegate:nil
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil];
    
    [alertView show];
}

-(void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata
{
	if (metadata == nil) {
		NSLog(@"didReceiveCardReaderMetadata got NIL metada! Ignoring..");
		return;
	}
    
	self.readerMetadata = metadata;
    
	if (metadata.serialNumber != nil) {
		NSLog(@"Transaction VC: %@",[NSString stringWithFormat:@"Reader Serial %@", metadata.serialNumber]);
	}
    
	if (metadata.firmwareRevision != nil) {
		NSLog(@"Transaction VC: %@",[NSString stringWithFormat:@"Firmware Revision %@", metadata.firmwareRevision]);
	}
    
	const NSInteger kZero = 0;
    
	if (metadata.batteryLevel != kZero) {
		NSLog(@"Transaction VC: %@",[NSString stringWithFormat:@"Battery Level %d", metadata.batteryLevel]);
	}
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // We just set this once in the sample app. In a real app you would want to update the location as the merchant moves any meaningful distance. Threshold should be set by your needs, but usually something like 1/4 mile would work
    NSLog(@"Got the LocationUpdate. newLocation Latitude:%f Longitude:%f ",newLocation.coordinate.latitude,newLocation.coordinate.longitude);
    
    if (!self.gotValidLocation) {
        self.gotValidLocation = YES;
        self.merchantLocation = newLocation;
        [self.locationManager stopUpdatingLocation];
        if(self.isMerchantCheckinPending){
            self.isMerchantCheckinPending = NO;
            [self getMerchantCheckin:self.merchantLocation];
        }
    }
}

-(void) getMerchantCheckin: (CLLocation*)newLocation
{
    [[PayPalHereSDK sharedLocalManager] beginGetLocations:^(PPHError *error, NSArray *locations){
        if (error) {
            return;
        }
        PPHLocation *myLocation = nil;
        if(nil != locations && 0 < [locations count]){
            NSLog(@"This merchant has already checked-in locations. Will try to find if the current location is in the list or not");
            NSString *currentName = @"TestAppLocation";
            if (currentName && currentName.length > 0) {
                for (PPHLocation *loc in locations) {
                    if ([loc.internalName isEqualToString:currentName]) {
                        NSLog(@"Yes. we found the current location as one of the merchant's checked-in locations.");
                        myLocation = loc;
                        break;
                    }
                }
            }
        }
        
        if(nil == myLocation){
            NSLog(@"We didn't find or match the current location in any of the merchants checked-in locations. Hence creating the new checking location");
            myLocation = [[PPHLocation alloc] init];
        }
        
        myLocation.contactInfo = [PayPalHereSDK activeMerchant].invoiceContactInfo;
        myLocation.internalName = @"TestAppLocation";
        myLocation.displayMessage = @"SDKSampleApp POS";
        myLocation.gratuityType = ePPHGratuityTypeStandard;
        myLocation.checkinType = ePPHCheckinTypeStandard;
        //myLocation.contactInfo.businessName = @"SDKSampleApp Business";
        //myLocation.contactInfo.phoneNumber = @"4086573456";
        //myLocation.contactInfo.city = @"San Jose";
        myLocation.contactInfo.countryCode=@"US";
        myLocation.contactInfo.lineOne=@"2211 North 1st Street";
        myLocation.contactInfo.lineTwo=@"San Jose";
        //myLocation.logoUrl = @"https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcQ3TotXBdfo9zyQhf4eCP33T6vQXh3A9GAe_lsqUOVLMNbdLolO";
        myLocation.location = newLocation.coordinate;
        myLocation.isMobile = YES;
        myLocation.isAvailable = YES;
        
        [myLocation save:^(PPHError *error) {
            if (error == nil) {
                NSLog(@"Successfully saved the current location with locationID: %@",myLocation.locationId);
                STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.merchantLocation = myLocation;
                appDelegate.isMerchantCheckedin = YES;
                [self.checkinSwitch setOn:YES animated:YES];
            }else{
                NSLog(@"Oops.. We got error while saving the location. Error Code: %d Error Description: %@",error.code, error.description);
                [self.checkinSwitch setOn:NO animated:YES];
            }
            [self.checkinMerchantSpinny stopAnimating];
            self.checkinMerchantSpinny.hidden = true;
            self.checkinSwitch.hidden=NO;

        }];
    }];
}
@end
