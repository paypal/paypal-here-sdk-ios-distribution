//
//  PayPalRetailSDKTests.m
//  PayPalRetailSDKTests
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import <XCTest/XCTest.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@interface PayPalRetailSDKTests : XCTestCase
@property (nonatomic, strong) NSString *token;
@end

@implementation PayPalRetailSDKTests

- (void)setUp {
    [super setUp];
    if (!self.token) {
        NSString *path = [[NSBundle bundleForClass:[PayPalRetailSDKTests class]] pathForResource:@"testToken" ofType:@"txt"];
        self.token = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)tearDown {
    [super tearDown];
    [PayPalRetailSDK shutdownSDK];
}

- (void)testInitialize {
    [self measureBlock:^{
        PayPalSDKError *error = [PayPalRetailSDK initializeSDK];
        XCTAssert(!error, @"Expected succesful initialization.");
    }];
}

- (void)testInvoiceCreation {
    [PayPalRetailSDK initializeSDK];
    [self measureBlock:^{
        PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:@"USD"];
        XCTAssertEqualObjects(@"USD", invoice.currency);
    }];
}

-(void)testInvoiceUsage {
    [PayPalRetailSDK initializeSDK];
    PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:@"USD"];
    PPRetailInvoiceItem *item = [[PPRetailInvoiceItem alloc] initWithName:@"Item" quantity:PAYPALNUM(@"3") unitPrice:PAYPALNUM(@"1.50") itemId:@"1" detailId:nil];
    [invoice addItem:item];
    XCTAssertEqualObjects(item.unitPrice, PAYPALNUM(@"1.50"));
    XCTAssertEqualObjects(item.quantity, PAYPALNUM(@"3"));
    XCTAssertEqualObjects(invoice.total, PAYPALNUM(@"4.50"));
    XCTAssertEqual([invoice itemCount], 1);
}

-(void)testMerchantInit {
    [PayPalRetailSDK initializeSDK];

    XCTestExpectation *expect = [self expectationWithDescription:@"Init callback"];
    [PayPalRetailSDK initializeMerchant:self.token completionHandler:^(PayPalSDKError *error, PPRetailMerchant *merchant) {
        XCTAssertNil(error);
        XCTAssertNotNil(merchant);
        XCTAssertNotNil(merchant.emailAddress);
        XCTAssertNotNil(merchant.currency);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

-(void)testSaveInvoice {
    [PayPalRetailSDK initializeSDK];

    XCTestExpectation *expect = [self expectationWithDescription:@"Init callback"];
    [PayPalRetailSDK initializeMerchant:self.token completionHandler:^(PayPalSDKError *error, PPRetailMerchant *merchant) {
        XCTAssertNil(error);
        XCTAssertNotNil(merchant);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:@"USD"];
    PPRetailInvoiceItem *item = [[PPRetailInvoiceItem alloc] initWithName:@"Item" quantity:PAYPALNUM(@"3") unitPrice:PAYPALNUM(@"1.50") itemId:@"1" detailId:nil];
    [invoice addItem:item];
    XCTAssertNil(invoice.number);
    XCTAssertNil(invoice.payPalId);

    expect = [self expectationWithDescription:@"Save Invoice"];
    [invoice save:^(PayPalSDKError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(invoice.payPalId);
        XCTAssertNotNil(invoice.number);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
