//
//  AuthCompletedViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/20/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "AuthCompletedViewController.h"
#import "CaptureAuthViewController.h"

@interface AuthCompletedViewController ()
@property (weak, nonatomic) IBOutlet UILabel *successMsg;
@property (weak, nonatomic) IBOutlet UIButton *voidAuthBtn;
@property (weak, nonatomic) IBOutlet UIButton *voidCodeViewBtn;
@property (weak, nonatomic) IBOutlet UITextView *voidCodeViewer;
@property (weak, nonatomic) IBOutlet UIButton *captureAuthBtn;
@property (weak, nonatomic) IBOutlet UIButton *captureAuthCodeViewBtn;
@property (weak, nonatomic) IBOutlet UITextView *captureAuthCodeViewer;
@property (weak, nonatomic) IBOutlet UIButton *startOverBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;
@property (weak, nonatomic) IBOutlet UILabel *voidSuccessLbl;
@property (nonatomic, assign) BOOL isTip;
@end

@implementation AuthCompletedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.successMsg.text = [NSString stringWithFormat:@"Your authorization was successful: $%@", self.invoice.total];;
    [self.successMsg sizeToFit];
    self.activitySpinner.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)voidAuthorization:(id)sender {
    self.activitySpinner.hidden = NO;
    [self.activitySpinner startAnimating];
    [PayPalRetailSDK.transactionManager voidAuthorization:self.authTransactionNumber callback:^(PPRetailError *error) {
        if(error != nil) {
            NSLog(@"Error Code: %@", error.code);
            NSLog(@"Error Code: %@", error.message);
            NSLog(@"Error Code: %@", error.debugId);
            [self.activitySpinner stopAnimating];
            return;
        }
        [self.activitySpinner stopAnimating];
        self.activitySpinner.hidden = YES;
        UIImage *voidAuthImage = [UIImage imageNamed:@"small-greenarrow"];
        [self.voidAuthBtn setImage:voidAuthImage forState: UIControlStateDisabled];
        self.voidSuccessLbl.hidden = NO;
        self.captureAuthBtn.enabled = NO;
        UIImage *captureAuthImage = [UIImage imageNamed:@"small-grayarrow"];
        [self.captureAuthBtn setImage:captureAuthImage forState: UIControlStateDisabled];
        self.startOverBtn.hidden = NO;
    }];

}

- (IBAction)captureAuthorization:(id)sender {
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Adding a tip?"
                                 message:@"Are you trying to do a regular capture or add a tip to a previous transaction?"
                                 preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction* captureButton = [UIAlertAction
                                actionWithTitle:@"Capture"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    self.isTip = false;
                                    [self performSegueWithIdentifier:@"goToCaptureAuthView" sender:self];
                                }];
    
    UIAlertAction* tipButton = [UIAlertAction
                                    actionWithTitle:@"Add Tip"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        self.isTip = true;
                                        [self performSegueWithIdentifier:@"goToCaptureAuthView" sender:self];
                                    }];
    
    UIAlertAction* cancelButton = [UIAlertAction
                                    actionWithTitle:@"Cancel"
                                    style:UIAlertActionStyleCancel
                                    handler: nil];
    
    //Add your buttons to alert controller
    [alert addAction:captureButton];
    [alert addAction:tipButton];
    [alert addAction:cancelButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showInfo:(id)sender {
    switch (((UIView*)sender).tag) {
    case 0:
        if (self.voidCodeViewer.hidden) {
            [self.voidCodeViewBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
            self.voidCodeViewer.hidden = NO;
            self.voidCodeViewer.text = @"[PayPalRetailSDK.transactionManager voidAuthorization:self.authTransactionNumber callback:^(PPRetailError *error) { \n <code to handle success/failure> \n }];";
        } else {
            [self.voidCodeViewBtn setTitle:@"View Code" forState:UIControlStateNormal];
            self.voidCodeViewer.hidden = YES;
        }
        break;
    case 1:
        if (self.captureAuthCodeViewer.hidden) {
            [self.captureAuthCodeViewBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
            self.captureAuthCodeViewer.hidden = NO;
            self.captureAuthCodeViewer.text = @"[PayPalRetailSDK.transactionManager captureAuthorization:self.authTransactionNumber invoiceId:self.invoice.payPalId totalAmount:amountToCapture gratuityAmount:0 currency:self.invoice.currency callback:^(PPRetailError *error, NSString *captureId) { \n <code to handle success/failure> \n }];";
        } else {
            [self.captureAuthCodeViewBtn setTitle:@"View Code" forState:UIControlStateNormal];
            self.captureAuthCodeViewer.hidden = YES;
        }
        break;
    default:
        NSLog(@"No Button Tag Found");
        break;
    }
}

- (IBAction)startOver:(id)sender {
     [self performSegueWithIdentifier:@"goToPaymentsView" sender:self];
}

- (UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"goToCaptureAuthView"]) {
        CaptureAuthViewController *captureAuthViewController = [segue destinationViewController];
        captureAuthViewController.authTransactionNumber = self.authTransactionNumber;
        captureAuthViewController.invoice = self.invoice;
        captureAuthViewController.paymentMethod = self.paymentMethod;
        captureAuthViewController.isTip = self.isTip;
    }
}


@end
