//
//  STSettingsViewController.m
//  SDKSampleAppWithSource
//
//  Created by Chandrashekar, Sathyanarayan on 11/19/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "STSettingsViewController.h"
#import "STAppDelegate.h"

@interface STSettingsViewController ()


@end

@implementation STSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self displayStageName:appDelegate.selectedStage];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(dismissKeyboard)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)customStageButtonPressed:(id)sender {
    if (self.customStage.text && ![self.customStage.text isEqualToString:@""]) {
        [self displayStageName:self.customStage.text];
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self displayStageName:LIST_OF_STAGES[row]];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return LIST_OF_STAGES[row];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [LIST_OF_STAGES count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(void)displayStageName:(NSString *)stageName {
    self.stageName.text = stageName;
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.selectedStage = stageName;
}


#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self dismissKeyboard];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.customStage) {
        [UIView animateWithDuration:.4 animations:^{
            [self.view setFrame:CGRectMake(0, -150, self.view.frame.size.width, self.view.frame.size.height)];
        } completion:^(BOOL finished) {
            
        }];
        [UIView commitAnimations];
    }
}


-(void)dismissKeyboard {
    [self.customStage resignFirstResponder];
    
    [UIView animateWithDuration:.4 animations:^{
        [self.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    } completion:^(BOOL finished) {
        
    }];
    [UIView commitAnimations];
    
}

@end
