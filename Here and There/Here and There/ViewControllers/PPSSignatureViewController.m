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
    
    /* Example of sending unencrypted swipe data (which should never be done from the client, but just so you know the format...)
    self.cardData = [[PPHCardSwipeData alloc] initWithTrack1:@"%B4111111111111111^CardUser/John^150310100000019301000000877000000?" track2:@";41111111111111111=1503101193010877?" readerSerial:@"109283019823" withType:@"mySwiperMaker" andExtraInfo:nil];
     */
    
    [[PayPalHereSDK sharedPaymentProcessor] beginCardPresentChargeAttempt: self.cardData forInvoice:self.invoice withSignature:self.signature.printableImage completionHandler:^(PPHCardChargeResponse *response) {
        [pv dismiss:YES];
        if (response.error.isCancelError) { return; }
        if (response.error) {
            NSString *msg = response.error.localizedDescription;
            // These message are crap, just an example.
            switch (response.error.errorCategory) {
                case ePPHErrorCategoryRetry:
                    msg = [NSString stringWithFormat: @"Your transaction failed, please try again. Reference code %@.", response.error.correlationId?:@"unavailable"];
                    break;
                case ePPHErrorCategoryAmbiguous:
                case ePPHErrorCategoryUnknown:
                case ePPHErrorCategoryData:
                    msg = [NSString stringWithFormat: @"An unknown error has occurred. Reference code %@.", response.error.correlationId?:@"unavailable"];
                    break;
                case ePPHErrorCategoryBuyerDeclined:
                    msg = [NSString stringWithFormat: @"The payment has been declined. Reference code %@.", response.error.correlationId?:@"unavailable"];
                    break;
                case ePPHErrorCategorySellerDeclined:
                    msg = [NSString stringWithFormat: @"There is a problem with your merchant account. Reference code %@.", response.error.correlationId?:@"unavailable"];
                    break;
                case ePPHErrorCategoryOutage:
                    msg = [NSString stringWithFormat: @"We were unable to contact the server to complete payment. Reference code %@.", response.error.correlationId?:@"unavailable"];
                    break;
                default:
                    break;
            }
            [PPSAlertView showAlertViewWithTitle:@"Payment Failed" message: msg buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
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
