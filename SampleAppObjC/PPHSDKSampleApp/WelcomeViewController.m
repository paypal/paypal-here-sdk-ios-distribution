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
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[[self navigationController] navigationBar] setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[[self navigationController] navigationBar] setHidden:NO];
}

- (IBAction)goToInitPage:(id)sender {
    [self performSegueWithIdentifier:@"showInitPageSegue" sender:sender];
}


@end
