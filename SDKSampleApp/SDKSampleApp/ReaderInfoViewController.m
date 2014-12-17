//
//  ReaderInfoViewController.m
//  SimplerTransaction
//
//  Created by Cotter, Vince on 12/30/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "ReaderInfoViewController.h"

@interface ReaderInfoViewController ()
@property (nonatomic,strong) PPHCardReaderWatcher *cardWatcher;
-(void)updateMetadataFields;
@end

@implementation ReaderInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.cardWatcher = [[PPHCardReaderWatcher alloc] initWithSimpleDelegate:self];
		self.serialNumber = nil;
		self.firmwareRevision = nil;
		self.batteryLevel = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated   {
    [super viewWillAppear:animated];
    
    self.title = @"Reader Info";

    self.readerTypeLabel.text = self.readerType;
	self.readerFamilyLabel.text = self.readerFamily;
	self.friendlyNameLabel.text = self.friendlyName;
    
	// Setting up the metadata fields is a bit more complicated,
	// since a given piece of metadata may or may not be "there"
	// (or "there yet"). Handle that in the 'updateMetadataFields'
	// utility routine:
	[self updateMetadataFields];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark PPHSimpleCardReaderDelegate
-(void)didRemoveReader:(PPHReaderType)readerType
{
	NSLog(@"Reader Removed");
}

-(void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata
{   
	if (metadata == nil) {
		NSLog(@"didReceiveCardReaderMetadata got NIL metada! Ignoring..");
		return;
	}

	self.serialNumber = metadata.serialNumber;

	self.firmwareRevision = metadata.firmwareRevision;

	const NSInteger kZero = 0;

	if (metadata.batteryLevel != kZero) {
		self.batteryLevel = [NSString stringWithFormat:@"%ld", (long)metadata.batteryLevel];
	} else {
		self.batteryLevel = nil;
	}

	[self updateMetadataFields];
}


#pragma mark -
#pragma mark utility functions
-(void)updateMetadataFields
{
	if (self.serialNumber != nil) {
		self.serialNumberLabel.hidden = NO;
		self.serialNumberLabelLabel.hidden = NO;
		self.serialNumberLabel.text = self.serialNumber;
	} else {
		self.serialNumberLabel.hidden = YES;
		self.serialNumberLabelLabel.hidden = YES;
	}

	if (self.firmwareRevision != nil) {
		self.firmwareRevisionLabel.hidden = NO;
		self.firmwareRevisionLabelLabel.hidden = NO;
		self.firmwareRevisionLabel.text = self.firmwareRevision;
	} else {
		self.firmwareRevisionLabel.hidden = YES;
		self.firmwareRevisionLabelLabel.hidden = YES;
	}

	if (self.batteryLevel != nil) {
		self.batteryLevelLabel.hidden = NO;
		self.batteryLevelLabelLabel.hidden = NO;
		self.batteryLevelLabel.text = self.batteryLevel;
	} else {
		self.batteryLevelLabel.hidden = YES;
		self.batteryLevelLabelLabel.hidden = YES;
	}
}

@end
