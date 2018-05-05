//
//  WelcomeViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/16/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goToInitPage:(id)sender {
    [self performSegueWithIdentifier:@"showInitPageSegue" sender:sender];
}


@end
