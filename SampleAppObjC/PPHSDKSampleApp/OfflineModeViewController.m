//
//  OfflineModeViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "OfflineModeViewController.h"
#import "OfflineModeViewControllerDelegate.h"


@interface OfflineModeViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *offlineModeSwitch;
@property (weak, nonatomic) IBOutlet UIButton *getOfflineStatusBtn;
@property (weak, nonatomic) IBOutlet UIButton *getOfflineStatusViewCodeBtn;
@property (weak, nonatomic) IBOutlet UITextView *getOfflineStatusCodeTxtView;
@property (weak, nonatomic) IBOutlet UIButton *replayOfflineTransactionBtn;
@property (weak, nonatomic) IBOutlet UIButton *replayOfflineTransactionViewCodeBtn;
@property (weak, nonatomic) IBOutlet UITextView *replayOfflineTransactionCodeTxtView;
@property (weak, nonatomic) IBOutlet UIButton *stopReplayBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopReplayViewCodeBtn;
@property (weak, nonatomic) IBOutlet UITextView *stopReplayCodeTxtView;
@property (weak, nonatomic) IBOutlet UILabel *resultsLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *replayTransactionIndicatorView;
@end

@implementation OfflineModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setMode];
    // Set the offlineMode switch on/off according to the value passed from PaymentViewController. Originally false.
    [self.offlineModeSwitch setOn:self.offlineMode];
    // Stop Replay Button is only needed when we are replaying transactions. Otherwise it is disabled.
    self.stopReplayBtn.enabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableReplayTransactionButton) name:@"offlineModeIsChanged" object:nil];
}

// If offlineMode is set to true then we will start taking offline payments and if it is set to false
// then we stop taking offline payments. To Start/Stop taking offline payments, we ned to make a call to
// the SDK. If we start taking online payments then we MUST call the stopOfflinePayment() in order to start
// taking live payments again.
-(void) setMode {
    if(self.offlineMode) {
        [[PayPalRetailSDK transactionManager]  startOfflinePayment];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"offlineModeIsChanged" object:nil];
    } else {
        [[PayPalRetailSDK transactionManager] stopOfflinePayment];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"offlineModeIsChanged" object:nil];
    }
}

// If the offlineModeSwitch is toggled. Set the value for the offlineMode Flag which will make the appropriate call
// to the SDK.
// - Parameter sender: UISwitch for the offlineMode.
- (IBAction)offlineModeSwitchPressed:(id)sender {
    self.offlineMode = self.offlineModeSwitch.isOn;
    [self setMode];
}

// The function will get the offline Status. It is a callback. It will give you an array of status which will
// tell you about the status of the payment.
// - Parameter sender: UIButton assoicated with the Get Offline Status button.
- (IBAction)getOfflineStatus:(id)sender {
    [[PayPalRetailSDK transactionManager] getOfflinePaymentStatus:^(PPRetailError *error, NSArray *status) {
        if(error != nil) {
            NSLog(@"Error: %@", error.description);
        } else {
            int uncompleted = 0;
            int completed = 0;
            int failed = 0;
            int declined = 0;
            for (PPRetailOfflinePaymentStatus *s in status) {
                if(s.errNo == 0) {
                    if(s.retry > 0) {
                        completed++;
                    } else {
                        uncompleted++;
                    }
                } else if(s.isDeclined) {
                    declined++;
                } else {
                    failed++;
                }
            }
            self.resultsLabel.text = [NSString stringWithFormat:@"Results: Uncompleted: %d | Completed: %d | Failed: %d | Declined: %d",uncompleted,completed,failed,declined];
        }
    }];
}

// If payments are taken in offline mode then those payments are saved on the device. This function, if the
// device is online, will go through those payments saved on the device and process those payments.
// The call back will give you the result whether those payments are completed, failed or were declined.
// - Parameter sender: UIButton associated with "Replay Offline Transaction" button
- (IBAction)replayOfflineTransaction:(id)sender {
    [self.replayTransactionIndicatorView startAnimating];
    self.stopReplayBtn.enabled = YES;
    [[PayPalRetailSDK transactionManager] startReplayOfflineTxns:^(PPRetailError *error, NSArray *status) {
        [self.replayTransactionIndicatorView stopAnimating];
        if(error != nil) {
            NSLog(@"Error: %@", error.description);
        } else {
            int completed = 0;
            int failed = 0;
            int declined = 0;
            for (PPRetailOfflinePaymentStatus *s in status) {
                if(s.errNo == 0) {
                    completed++;
                } else if(s.isDeclined) {
                    declined++;
                } else {
                    failed++;
                }
            }
            self.resultsLabel.text = [NSString stringWithFormat:@"Results: Completed: %d | Failed: %d | Declined: %d",completed,failed,declined];
            self.stopReplayBtn.enabled = NO;
        }
    }];
}

// If we are replaying transactions and we want to stop replayingTransactions then we can call this function.
// For example: If you went offline when replaying transactions.
// - Parameter sender: UIButton associated with "Stop Replay" Button
- (IBAction)stopReplay:(id)sender {
    [self.replayTransactionIndicatorView stopAnimating];
    [[PayPalRetailSDK transactionManager] stopReplayOfflineTxns];
}


// This function will pass the offlineMode value to the PaymentViewController and dimiss this controller.
// - Parameter sender: "Run Transaction" button
- (IBAction)dismissScreen:(id)sender {
    [self.delegate offlineMode:self :true];
    [self dismissViewControllerAnimated:true completion:nil];
}

// THIS FUNCTION IS ONLY FOR UI. This funciton will show/hide code snippets for the appropriate function calls.
// Here, we are basically checking thier tags and changing the UI appropriatly.
// - Parameter sender: View/Hide Code Buttons
- (IBAction)viewCodeBtnPressed:(id)sender {
    switch(((UIView*)sender).tag){
        case 0:
            if(self.getOfflineStatusCodeTxtView.hidden) {
                [self.getOfflineStatusViewCodeBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
                self.getOfflineStatusCodeTxtView.hidden = NO;
                self.getOfflineStatusCodeTxtView.text = @"[[PayPalRetailSDK transactionManager]  getOfflinePaymentStatus:^(PPRetailError *error, NSArray *status) {\n <code to handle success/failure> \n}];";
            } else {
                [self.getOfflineStatusViewCodeBtn setTitle:@"View Code" forState:UIControlStateNormal];
                self.getOfflineStatusCodeTxtView.hidden = YES;
            }
            break;
        case 1:
            if(self.replayOfflineTransactionCodeTxtView.hidden) {
                [self.replayOfflineTransactionViewCodeBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
                self.replayOfflineTransactionCodeTxtView.hidden = NO;
                self.replayOfflineTransactionCodeTxtView.text = @"[[PayPalRetailSDK transactionManager]  startReplayOfflineTxns:^(PPRetailError *error, NSArray *status) {\n <code to handle success/failure> \n}];";
            } else {
                [self.replayOfflineTransactionViewCodeBtn setTitle:@"View Code" forState:UIControlStateNormal];
                self.replayOfflineTransactionCodeTxtView.hidden = YES;
            }
            break;
        case 2:
            if(self.stopReplayCodeTxtView.hidden) {
                [self.stopReplayViewCodeBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
                self.stopReplayCodeTxtView.hidden = NO;
                self.stopReplayCodeTxtView.text = @"[[PayPalRetailSDK transactionManager] stopReplayOfflineTxns];";
            } else {
                [self.stopReplayViewCodeBtn setTitle:@"View Code"  forState:UIControlStateNormal];
                self.stopReplayCodeTxtView.hidden = YES;
            }
            break;
        default:
            break;
    }
}


// THIS FUNCTION IS ONLY FOR UI. This function will enable/disable "Replay Transaction" Button
// depending on if the offlineMode is on or off.
// - Parameter isEnabled: A Bool to enable/disable the "Replay Transaction Button"
- (void)enableReplayTransactionButton {
    if(self.offlineMode) {
        self.replayOfflineTransactionBtn.enabled = NO;
    } else {
        self.replayOfflineTransactionBtn.enabled = YES;
    }
}


@end
