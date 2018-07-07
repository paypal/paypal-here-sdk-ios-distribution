//
//  OfflinePaymentCompletedViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/6/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "OfflinePaymentCompletedViewController.h"
#import "PaymentViewController.h"


@interface OfflinePaymentCompletedViewController ()

@end

@implementation OfflinePaymentCompletedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// THIS FUNCTION IS ONLY FOR UI.
// This takes an array of UIViewControllers that are in the current Navigation Controller stack and removes the
// 4th index which is this ("OfflinePaymentCompletedViewController") and replaces the PaymentViewController with
// a newly instantiated PaymentViewController and makes that the new Navigation Stack and pushes to that new
// PaymentViewController.
// viewController array has at index 0 : "WelcomeViewController", 1 : "InitializeViewController"
// 2 : "DeviceDiscoveryViewController", 3 : "PaymentViewController", 4 : "OfflinePaymentCompletedViewController"
// - Parameter sender: UIButton for No Sale
- (IBAction)newSaleBtnPressed:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PaymentViewController *paymentViewController = [storyboard instantiateViewControllerWithIdentifier:@"PaymentViewController"];
    NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
    [navigationArray removeLastObject];
    [navigationArray setObject:paymentViewController atIndexedSubscript:3];
    self.navigationController.viewControllers = navigationArray;
}


@end
