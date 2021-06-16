//
//  TransactionOptionsViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "TransactionOptionsViewController.h"

@interface TransactionOptionsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *authCaptureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *promptInAppSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *promptInCardReaderSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *tippingOnReaderSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *amountBasedTippingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableQuickChipSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableQRCPromptSwitch;
@property (weak, nonatomic) IBOutlet UITextField *tagTextField;
@property (strong, nonatomic) IBOutletCollection(UISwitch) NSArray *formFactorySwitches;
@end

@implementation TransactionOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setToolBarForTextField: self.tagTextField];
    
    // Turn the switch on/off depending on the value of the option fields.
    [self.authCaptureSwitch setOn: self.transactionOptions.isAuthCapture];
    [self.promptInAppSwitch setOn: self.transactionOptions.showPromptInApp];
    [self.promptInCardReaderSwitch setOn: self.transactionOptions.showPromptInCardReader];
    [self.tippingOnReaderSwitch setOn: self.transactionOptions.tippingOnReaderEnabled];
    [self.amountBasedTippingSwitch setOn: self.transactionOptions.amountBasedTipping];
    [self.enableQuickChipSwitch setOn: self.transactionOptions.quickChipEnabled];
    [self.enableQRCPromptSwitch setOn: self.transactionOptions.qrcPromptEnabled];
    
    // Turn the formFactor button on/off depending on the formFactors selected.
    [self toggleSwitches];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_optionsDelegate transactionOptionsController:self options:self.transactionOptions];
}

// The following 5 functions are triggered when a switch is pressed and it's value is changed.
// Depending on the if the switch is on or off, these functions will set the appropriate option to true or false.
// - Parameter sender: UISwitch assoicated with the options.
- (IBAction)authCaptureSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.isAuthCapture = self.authCaptureSwitch.isOn;
}

- (IBAction)promptInAppSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.showPromptInApp = self.promptInAppSwitch.isOn;
}

- (IBAction)promptInCardReaderSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.showPromptInCardReader = self.promptInCardReaderSwitch.isOn;
}

- (IBAction)tippingOnReaderSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.tippingOnReaderEnabled = self.tippingOnReaderSwitch.isOn;
}

- (IBAction)amountBasedTippingSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.amountBasedTipping = self.amountBasedTippingSwitch.isOn;
}

- (IBAction)enableQuickChipSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.quickChipEnabled = self.enableQuickChipSwitch.isOn;
}

- (IBAction)enableQRCPromptSwitchPressed:(UISwitch *)sender {
    self.transactionOptions.qrcPromptEnabled = self.enableQRCPromptSwitch.isOn;
}


- (IBAction)tagTextFieldEndEditing:(UITextField *)sender {
    if(sender.text != nil) {
        self.transactionOptions.tag = sender.text;
    } else {
        self.transactionOptions.tag = @"";
    }
}


// This function will be triggred when one of the formFactor buttons is pressed. Whichever button triggers this
// function, this function will get the associated formFactor and append the formFactor to the formFactorArray if
// the formFactor isSelected and remove the formFactor from the array if the formFactor was removed(clicked on again).
// - Parameter sender: UIButton assoicated with the formFactor Buttons.
- (IBAction)formFactorSwitchesPressed:(UISwitch *)sender {
    [sender setSelected:![sender isSelected]];
    NSNumber *formFactor;
    switch(((UIView*)sender).tag){
        case 1:
            formFactor = [[NSNumber alloc] initWithInteger: PPRetailFormFactorMagneticCardSwipe];
            break;
        case 2:
            formFactor = [[NSNumber alloc] initWithInteger: PPRetailFormFactorChip];
            break;
        case 3:
            formFactor = [[NSNumber alloc] initWithInteger: PPRetailFormFactorEmvCertifiedContactless];
            break;
        case 4:
            formFactor = [[NSNumber alloc] initWithInteger: PPRetailFormFactorSecureManualEntry];
            break;
        case 5:
            formFactor = [[NSNumber alloc] initWithInteger: PPRetailFormFactorManualCardEntry];
            break;
        default:
            formFactor = [[NSNumber alloc] initWithInteger: PPRetailFormFactorNone];
            break;
    }
    
    if([sender isOn]) {
        [self.formFactorArray addObject: formFactor];
        self.transactionOptions.preferredFormFactors = self.formFactorArray;
    } else {
        [self.formFactorArray removeObjectAtIndex:[self.formFactorArray indexOfObject:formFactor]];
        self.transactionOptions.preferredFormFactors = self.formFactorArray;
    }
}

-(void) toggleSwitches {
    for(NSNumber *factor in self.formFactorArray) {
        NSInteger tag;
        if(factor.integerValue == PPRetailFormFactorMagneticCardSwipe) {
            tag = 1;
        } else if(factor.integerValue == PPRetailFormFactorChip) {
            tag = 2;
        } else if(factor.integerValue == PPRetailFormFactorEmvCertifiedContactless) {
            tag = 3;
        } else if(factor.integerValue == PPRetailFormFactorSecureManualEntry) {
            tag = 4;
        } else if(factor.integerValue == PPRetailFormFactorManualCardEntry) {
            tag = 5;
        } else {
            tag = 0;
        }
        for(UISwitch *formFactorSwitch in self.formFactorySwitches) {
            if(formFactorSwitch.tag == tag) {
                [formFactorSwitch setOn:YES];
            }
        }
    }
}

-(void) setDelegate:(UIViewController *)delegateController {
    _optionsDelegate = delegateController;
}

// THIS FUNCTION IS ONLY FOR UI. This function will create a toolbar which will have a "Done" button
// to let us know that we have finished editing.
// - Parameter sender: UITextfield that we want to add the toolbar to
-(void) setToolBarForTextField :(UITextField*) sender {
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    //create left side empty space so that done button set on right side
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)];
    [toolbar setItems:@[flexSpace, doneBtn]];
    [toolbar sizeToFit];
    sender.inputAccessoryView = toolbar;
    sender.layer.borderColor = [UIColor colorWithRed:0.0f/255.0f green:159.0f/255.0f blue:228.0f/255.0f alpha:1.0f].CGColor;
}

// THIS FUNCTION IS ONLY FOR UI. It will end keyboard editing and is the action for the done button in the
// UITextfield toolbar.
-(void) dismissKeyboard {
    [self.view endEditing:true];
}

@end
