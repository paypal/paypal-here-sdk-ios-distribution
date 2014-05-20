//
//  AuthorizedInvoiceInspectorViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/14/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "AuthorizedInvoiceInspectorViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import "STAppDelegate.h"

@interface AuthorizedInvoiceInspectorViewController ()
@property (strong, nonatomic) PPHTransactionRecord * transactionRecord;
@property (strong, nonatomic) NSDecimalNumberHandler *formatter;

@end

@implementation AuthorizedInvoiceInspectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionRecord:(PPHTransactionRecord *)record
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.transactionRecord = record;
        self.formatter = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                scale:2
                                                                     raiseOnExactness:NO
                                                                      raiseOnOverflow:NO
                                                                     raiseOnUnderflow:NO
                                                                  raiseOnDivideByZero:NO];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Authorized Invoice";
}

- (void)viewWillAppear:(BOOL)animated    {
    [super viewWillAppear:animated];
    
    _enteredNewAmount.delegate = self;
    [_enteredNewAmount setReturnKeyType:UIReturnKeyDone];

    _actionLabel.text = @"";    //No message at beginning.  Title is fine for now...
    _activitySpinner.hidden = YES;
    _invoiceId.text = _transactionRecord.payPalInvoiceId;
    
    NSString *totalStr = [[_transactionRecord.invoice.totalAmount amount] description];
    _originalAmount.text = totalStr;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onVoid:(id)sender {
    _activitySpinner.hidden = NO;
    [_activitySpinner startAnimating];
    _voidButton.enabled = NO;
    _captureOrigAmountButton.enabled = NO;
    _captureNewAmountButton.enabled = NO;
    _actionLabel.text = @"Voiding Authorization ...";
    
    [[PayPalHereSDK sharedTransactionManager] voidAuthorization:_transactionRecord
                                                       withCompletionHandler:^(PPHTransactionResponse *response) {
                                                           [_activitySpinner stopAnimating];
                                                           _activitySpinner.hidden = YES;
                                                           
                                                           if(!response.error) {
                                                               _actionLabel.text = @"Void Successful";
                                                               
                                                               NSString *ourInvoiceId = _transactionRecord.invoice.paypalInvoiceId;
                                                               
                                                               //Remove this record from our list of records that need captured.
                                                               STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                               for(PPHTransactionRecord *record in appDelegate.authorizedRecords) {
                                                                   if(NSOrderedSame == [ourInvoiceId caseInsensitiveCompare:record.invoice.paypalInvoiceId]) {
                                                                       [appDelegate.authorizedRecords removeObject:record];
                                                                       break;
                                                                   }
                                                               }
                                                           }
                                                           else {
                                                               _actionLabel.text = @"Void Failed";
                                                               _voidButton.enabled = YES;
                                                               _captureOrigAmountButton.enabled = YES;
                                                               _captureNewAmountButton.enabled = YES;
                                                           }
                                                       }];

}

/*
 * Let's just capture for the current amount in the PPHTransactionRecord.  i.e., let's not
 * add a tip or add/remove any line items.
 */
- (IBAction)onCapture:(id)sender {
    [self capture];
}

/* 
 * Let's capture for a new amount.  In this case the UI is asking for a tip to be entered.
 * So let's read the entered tip and, if valid, let's add it to the authorization record's 
 * invoice.  We'll then trigger the capture which will attempt to capture payment for the 
 * new amount.
 */
- (IBAction)onCaptureNewAmount:(id)sender {
    
    [_enteredNewAmount resignFirstResponder];
    
    // Make sure the user has entered some amount:
    NSString *amountString = _enteredNewAmount.text;
    if ([amountString length] == 0) {
        [self showAlertWithTitle:@"Input Error" andMessage:@"You can't add an empty tip."];
        return;
    }
    
    // Check to make sure this is a non-zero amount:
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *formattedAmount = [f numberFromString:amountString];
    if (formattedAmount == nil) {
        [self showAlertWithTitle:@"Input Error" andMessage:@"You must specify a proper numerical amount for the tip"];
        return;
    }
    
    double transactionAmount = [formattedAmount doubleValue];
    
    if (transactionAmount < 0.01 && transactionAmount > -0.01) {
		[self showAlertWithTitle:@"Input Error" andMessage:@"You cannot specify amounts less than a penny."];
		return;
	}

    // If we make it here then we probably have a legal tip amount.
    
    NSDecimalNumber *formattedTip = [self formatNumber:_enteredNewAmount.text];
    _transactionRecord.invoice.gratuity = formattedTip;
    
   [self capture];
    
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:nil
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}

- (void)capture {
    _activitySpinner.hidden = NO;
    [_activitySpinner startAnimating];
    _voidButton.enabled = NO;
    _captureOrigAmountButton.enabled = NO;
    _captureNewAmountButton.enabled = NO;
    _actionLabel.text = @"Capturing payment ...";
    
    [[PayPalHereSDK sharedTransactionManager] capturePaymentForAuthorization:_transactionRecord
                                                       withCompletionHandler:^(PPHTransactionResponse *response) {
                                                           [_activitySpinner stopAnimating];
                                                           _activitySpinner.hidden = YES;
                                                           
                                                           if(!response.error) {
                                                               _actionLabel.text = @"Capture Successful";
                                                               
                                                               NSString *ourInvoiceId = _transactionRecord.invoice.paypalInvoiceId;
                                                               
                                                               //Remove this record from our list of records that need captured.
                                                               STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                               for(PPHTransactionRecord *record in appDelegate.authorizedRecords) {
                                                                   if(NSOrderedSame == [ourInvoiceId caseInsensitiveCompare:record.invoice.paypalInvoiceId]) {
                                                                       [appDelegate.authorizedRecords removeObject:record];
                                                                       break;
                                                                   }
                                                               }
                                                               
                                                               //Place this capture record in the list of records that are refundable
                                                               [appDelegate.refundableRecords addObject:response.record];
                                                           }
                                                           else {
                                                               _actionLabel.text = @"Capture Failed";
                                                               _voidButton.enabled = YES;
                                                               _captureOrigAmountButton.enabled = YES;
                                                               _captureNewAmountButton.enabled = YES;
                                                           }
                                                       }];

}

- (NSDecimalNumber *)formatNumber:(NSString *)value
{
    NSDecimalNumber *nsdnValue = [NSDecimalNumber decimalNumberWithString:value];
    return [nsdnValue decimalNumberByRoundingAccordingToBehavior:_formatter];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[_enteredNewAmount resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [_enteredNewAmount resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	// Allow the Backspace character:
	if (!string.length)
		return YES;
    
	// Do not allow pasting of a range of characters:
	if (string.length > 1)
		return NO;
    
	// Allow leading '+' or '-' signs:
	if ([textField.text length] == 0 &&
		(
         [string rangeOfString:@"+"].location != NSNotFound ||
         [string rangeOfString:@"-"].location != NSNotFound
         )
		) {
		return YES;
	}
    
	NSUInteger currentDecimalPointLocation = [textField.text rangeOfString:@"."].location;
	NSUInteger newDecimalPointLocation = [string rangeOfString:@"."].location;
    
	// Reject any non-numeric inputs (other than '.').
	if ([string
         rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location
		!= NSNotFound  &&
		newDecimalPointLocation == NSNotFound
		)
		return NO;
    
	// If you haven't already got a decimal point yet, any numeric input is OK:
	if (currentDecimalPointLocation == NSNotFound)
		return YES;
    
	// If you've already got a decimal point, and the user tries to
	// feed you another, the input is definitely invalid:
	if (newDecimalPointLocation != NSNotFound)
		return NO;
    
    
	// Finally, check for more than 2 digits to the right of the decimal point:
	BOOL notTooManyDigitsFollowTheDecimalPoint = ([textField.text length] - currentDecimalPointLocation) <= 2;
    
	return notTooManyDigitsFollowTheDecimalPoint;
    
}

@end
