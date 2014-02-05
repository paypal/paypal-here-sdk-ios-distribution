//
//  SASettingsViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import "SASettingsViewController.h"
#import "STReaderInfoViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>

@interface SASettingsViewController ()
@property (nonatomic,strong) PPHCardReaderBasicInformation *readerInfo;
@property (nonatomic,strong) PPHCardReaderMetadata *readerMetadata;
@property (nonatomic,strong) PPHCardReaderWatcher *cardWatcher;


@end

@implementation SASettingsViewController

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

- (IBAction)onReaderDetailsPressed:(id)sender {
    
	// Transition to the Reader Info screen:
	STReaderInfoViewController *readerInfoVC = nil;
    
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		readerInfoVC = [[STReaderInfoViewController alloc]
                        initWithNibName:@"STReaderInfoViewController_iPhone"
                        bundle:nil];
	}
	else {
		readerInfoVC = [[STReaderInfoViewController alloc]
                        initWithNibName:@"STReaderInfoViewController_iPad"
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


@end
