//
//  AuthCompletedViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/20/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "AuthCompletedViewController.h"
#import "CaptureAuthViewController.h"
#import "PaymentViewController.h"
#import "UIButton+CustomButton.h"

@interface AuthCompletedViewController ()
@property (weak, nonatomic) IBOutlet UILabel *successMsg;
@property (weak, nonatomic) IBOutlet UIButton *voidAuthBtn;
@property (weak, nonatomic) IBOutlet UITextView *voidCodeViewer;
@property (weak, nonatomic) IBOutlet UIButton *captureAuthBtn;
@property (weak, nonatomic) IBOutlet UITextView *captureAuthCodeViewer;
@property (nonatomic, assign) BOOL isTip;
@end

@implementation AuthCompletedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpDefaultView];
}

- (IBAction)voidAuthorization:(id)sender {
    [PayPalRetailSDK.transactionManager voidAuthorization:self.authTransactionNumber callback:^(PPRetailError *error) {
        if(error != nil) {
            NSLog(@"Error Code: %@", error.code);
            NSLog(@"Error Code: %@", error.message);
            NSLog(@"Error Code: %@", error.debugId);
            return;
        }
        UIAlertController *alert = [UIAlertController
                                     alertControllerWithTitle:@"Void successful"
                                     message:@"The Auth was successfully voided."
                                     preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * _Nonnull action) {
                                       UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                       PaymentViewController *paymentViewController = [storyboard instantiateViewControllerWithIdentifier:@"PaymentViewController"];
                                       NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
                                       [navigationArray removeLastObject];
                                       [navigationArray setObject:paymentViewController atIndexedSubscript:3];
                                       [[self navigationController] setViewControllers:navigationArray animated:YES];
                                   }];
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
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

-(void)setUpDefaultView{
    self.successMsg.text = [NSString stringWithFormat:@"Your authorization was successful: $%@", self.invoice.total];;
    [self.successMsg sizeToFit];
    self.voidCodeViewer.text = @"[PayPalRetailSDK.transactionManager voidAuthorization:self.authTransactionNumber callback:^(PPRetailError *error) { \n <code to handle success/failure> \n }];";
     self.captureAuthCodeViewer.text = @"[PayPalRetailSDK.transactionManager captureAuthorization:self.authTransactionNumber invoiceId:self.invoice.payPalId totalAmount:amountToCapture gratuityAmount:0 currency:self.invoice.currency callback:^(PPRetailError *error, NSString *captureId) { \n <code to handle success/failure> \n }];";
    
    [CustomButton customizeButton:_voidAuthBtn];
    [CustomButton customizeButton:_captureAuthBtn];
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
