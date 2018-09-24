//
//  OfflineModeViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "OfflineModeViewController.h"
#import "UIButton+CustomButton.h"
#import "OfflineModeViewControllerDelegate.h"


@interface OfflineModeViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *offlineModeSwitch;
@property (weak, nonatomic) IBOutlet UIButton *getOfflineStatusBtn;
@property (weak, nonatomic) IBOutlet UITextView *getOfflineStatusCodeTxtView;
@property (weak, nonatomic) IBOutlet UIButton *replayOfflineTransactionBtn;
@property (weak, nonatomic) IBOutlet UITextView *replayOfflineTransactionCodeTxtView;
@property (weak, nonatomic) IBOutlet UIButton *stopReplayBtn;
@property (weak, nonatomic) IBOutlet UITextView *stopReplayCodeTxtView;
@property (weak, nonatomic) IBOutlet UITextView *replayTransactionResultsTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *replayTransactionIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *offlineModeLabel;
@end

@implementation OfflineModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpDefaultView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleOfflineModeUI) name:@"offlineModeIsChanged" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [delegate offlineModeController: self offline: self.offlineMode];
}

// If the offlineModeSwitch is toggled. Set the value for the offlineMode Flag which will make the appropriate call
// to the SDK.
// - Parameter sender: UISwitch for the offlineMode.
- (IBAction)offlineModeSwitchPressed:(UISwitch *)sender {
    self.offlineMode = self.offlineModeSwitch.isOn;
    [self setMode];
}

// If offlineMode is set to true then we will start taking offline payments and if it is set to false
// then we stop taking offline payments. To Start/Stop taking offline payments, we ned to make a call to
// the SDK. If we start taking online payments then we MUST call the stopOfflinePayment() in order to start
// taking live payments again.
-(void) setMode {
    if(self.offlineMode) {
        if ([[PayPalRetailSDK transactionManager] getOfflinePaymentEligibility]) {
            [[PayPalRetailSDK transactionManager] startOfflinePayment:^(PPRetailError *error, NSArray *status) {
                if (error != nil){
                    NSLog(@"%@", error.developerMessage);
                } else {
                    [self offlineTransactionStatusList:status];
                }
            }];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"offlineModeIsChanged" object:nil];
        } else {
            NSLog(@"Merchant is not eligible to take Offline Payments");
            self.offlineMode = NO;
            [self.offlineModeSwitch setOn:NO animated:YES];
        }
    } else {
        [[PayPalRetailSDK transactionManager] stopOfflinePayment:^(PPRetailError *error, NSArray *status) {
            if (error != nil){
                NSLog(@"Error: %@", error.debugDescription);
            } else {
                [self offlineTransactionStatusList:status];
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"offlineModeIsChanged" object:nil];
    }
}

// The function will get the offline Status. It is a callback. It will give you an array of status which will
// tell you about the status of the payment.
// - Parameter sender: UIButton assoicated with the Get Offline Status button.
- (IBAction)getOfflineStatus:(UIButton *)sender {
    [[PayPalRetailSDK transactionManager] getOfflinePaymentStatus:^(PPRetailError *error, NSArray *status) {
        if(error != nil) {
            NSLog(@"Error: %@", error.description);
        } else {
            [self offlineTransactionStatusList:status];
        }
    }];
}

// If payments are taken in offline mode then those payments are saved on the device. This function, if the
// device is online, will go through those payments saved on the device and process those payments.
// The call back will give you the result whether those payments are completed, failed or were declined.
// - Parameter sender: UIButton associated with "Replay Offline Transaction" button
- (IBAction)replayOfflineTransaction:(UIButton *)sender {
    [self.replayTransactionIndicatorView startAnimating];
    self.stopReplayBtn.enabled = YES;
    [[PayPalRetailSDK transactionManager] startReplayOfflineTxns:^(PPRetailError *error, NSArray *status) {
        [self.replayTransactionIndicatorView stopAnimating];
        if(error != nil) {
            NSLog(@"Error: %@", error.description);
        } else {
            [self offlineTransactionStatusList:status];
        }
    }];
}

// If we are replaying transactions and we want to stop replayingTransactions then we can call this function.
// For example: If you went offline when replaying transactions.
// - Parameter sender: UIButton associated with "Stop Replay" Button
- (IBAction)stopReplay:(UIButton *)sender {
    [self.replayTransactionIndicatorView stopAnimating];
    [[PayPalRetailSDK transactionManager] stopReplayOfflineTxns:^(PPRetailError *error, NSArray *status) {
        if (error != nil) {
            NSLog(@"Stopped replaying offline transactions");
        } else {
            [self offlineTransactionStatusList:status];
        }
    }];
}

-(void) offlineTransactionStatusList:(NSArray *)status{
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
    self.replayTransactionResultsTextView.text = [NSString stringWithFormat:@"Results:\n Uncompleted: %d \n Completed: %d \n Failed: %d \n Declined: %d",uncompleted,completed,failed,declined];
    self.stopReplayBtn.enabled = NO;
}

-(void)setDelegate:(UIViewController *)delegateController{
    delegate = delegateController;
}

-(void)setUpDefaultView{
    [self setMode];
    // Set the offlineMode switch on/off according to the value passed from PaymentViewController. Originally false.
    [self.offlineModeSwitch setOn:self.offlineMode];
    [self toggleOfflineModeUI];
    // Stop Replay Button is only needed when we are replaying transactions. Otherwise it is disabled.
    self.stopReplayBtn.enabled = NO;
    self.getOfflineStatusCodeTxtView.text = @"[[PayPalRetailSDK transactionManager]  getOfflinePaymentStatus:^(PPRetailError *error, NSArray *status) {\n <code to handle success/failure> \n}];";
    self.replayOfflineTransactionCodeTxtView.text = @"[[PayPalRetailSDK transactionManager]  startReplayOfflineTxns:^(PPRetailError *error, NSArray *status) {\n <code to handle success/failure> \n}];";
    self.stopReplayCodeTxtView.text = @"[[PayPalRetailSDK transactionManager] stopReplayOfflineTxns];";
    self.replayTransactionResultsTextView.text = @"";
    [self offlineSDKInit];
    
    [CustomButton customizeButton:_getOfflineStatusBtn];
    [CustomButton customizeButton:_replayOfflineTransactionBtn];
    [CustomButton customizeButton:_stopReplayBtn];
}

-(void) offlineSDKInit{
   NSUserDefaults *tokenDefault =  [NSUserDefaults standardUserDefaults];
    BOOL offlineInit = [tokenDefault boolForKey:@"offlineSDKInit"];
    if (offlineInit){
        self.offlineModeSwitch.enabled = NO;
    }
}

// THIS FUNCTION IS ONLY FOR UI. This function will enable/disable "Replay Transaction" Button
// depending on if the offlineMode is on or off.
-(void)toggleOfflineModeUI{
    if (self.offlineMode){
        _offlineModeLabel.text = @"ENABLED";
        _offlineModeLabel.textColor = UIColor.greenColor;
        [_replayOfflineTransactionBtn setEnabled:NO];
    } else {
        _offlineModeLabel.text = @"";
        _offlineModeLabel.textColor = UIColor.redColor;
        [_replayOfflineTransactionBtn setEnabled:YES];
    }
}

@end
