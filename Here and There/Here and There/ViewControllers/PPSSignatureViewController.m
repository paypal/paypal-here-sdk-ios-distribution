//
//  PPSSignatureViewController.m
//  Here and There
//
//  Created by Metral, Max on 3/4/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSSignatureViewController.h"
#import <PayPalHereSDK/PPHSignatureView.h>
#import "PPSProgressView.h"
#import "PPSAlertView.h"

@interface PPSSignatureViewController () <
    PPHSignatureViewDelegate
>
@property (nonatomic,strong) PPHInvoice* invoice;
@property (nonatomic,strong) PPHCardSwipeData* cardData;

@property (nonatomic,strong) PPHSignatureView* signature;
@property (nonatomic,strong) UIButton* charge;
@end

@implementation PPSSignatureViewController
-(id)initWithInvoice:(PPHInvoice *)invoice andCardData:(PPHCardSwipeData *)cardData
{
    if ((self = [super init])) {
        self.invoice = invoice;
        self.cardData = cardData;
    }
    return self;
}

-(void)viewDidLoad
{
    [self.navigationController setNavigationBarHidden:NO];
    [self.view buildSubviews:@[
     [[PPHSignatureView alloc] initWithFrame: self.view.frame], @"#signature",
     [UIButton buttonWithType:UIButtonTypeCustom], @"#charge", SELECT_SELF(chargePressed)
     ] inDOM:self.dom];
    self.signature.delegate = self;
    self.charge.enabled = NO;
}

-(void)signatureTouchesBegan {
    self.charge.hidden = YES;
}

-(void)signatureUpdated:(BOOL)isEmpty
{
    self.charge.enabled = !isEmpty;
    self.charge.hidden = NO;
}

-(void)chargePressed
{
    PPSProgressView *pv = [PPSProgressView progressViewWithTitle:@"Processing Payment" andMessage:nil withCancelHandler:^(PPSProgressView *progressView) {
        [[PayPalHereSDK networkDelegate] cancelOperationsForID: kPPHPaymentNetworkRequestId];
    }];
    [[PayPalHereSDK sharedPaymentProcessor] beginCardPresentChargeAttempt:self.cardData forInvoice:self.invoice withSignature:self.signature.printableImage completionHandler:^(PPHCardChargeResponse *response) {
        [pv dismiss:YES];
        if (response.error.isCancelError) { return; }
        if (response.error) {
            [PPSAlertView showAlertViewWithTitle:@"Payment Failed" message:response.error.localizedDescription buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
        } else {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

-(NSString *)stylesheetName
{
    return @"signaturePage";
}
@end
