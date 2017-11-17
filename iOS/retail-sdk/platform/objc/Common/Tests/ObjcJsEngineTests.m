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
#import "PPRetailTest.h"

@interface ObjcJsEngineTests : XCTestCase
@property (nonatomic, strong) NSString *token;
@end

@implementation ObjcJsEngineTests

- (void)setUp {
    [super setUp];
    [PayPalRetailSDK initializeSDK];
}

- (void)tearDown {
    [super tearDown];
    [PayPalRetailSDK shutdownSDK];
}

- (void)testProperties {
    PPRetailSDKTestDefault *simple = [[PPRetailSDKTestDefault alloc] init];
    XCTAssertEqual(1, simple.test);
    XCTAssertTrue(simple.itsTrue);
    XCTAssertFalse(simple.itsFalse);
    XCTAssertNil(simple.blankDecimal);
    XCTAssertEqual(0, simple.blankInt);
    XCTAssertEqual(1, simple.intOne);
    XCTAssertNil(simple.nullString);
    XCTAssertEqualObjects([NSDecimalNumber decimalNumberWithString:@"100.01"], simple.decimalHundredOhOne);

    PPRetailSDKTest *tester = [[PPRetailSDKTest alloc] initWithStringProperty:@"STRINGISHERE"];
    XCTAssertEqual(1, tester.itsOne);
    XCTAssertTrue([tester respondsToSelector:NSSelectorFromString(@"cantTouchThis")]);
    XCTAssertFalse([tester respondsToSelector:NSSelectorFromString(@"setCantTouchThis:")]);
    XCTAssertEqualObjects(@"STRINGISHERE", tester.stringProperty);
    XCTAssertEqualObjects(nil, tester.accessorString);

    XCTAssertTrue([tester.complexType isKindOfClass:[PPRetailSDKTestDefault class]]);
    XCTAssertEqualObjects([NSDecimalNumber decimalNumberWithString:@"100.01"], simple.decimalHundredOhOne);
}

- (void)testFunctionCalls {
    PPRetailSDKTest *tester = [[PPRetailSDKTest alloc] initWithStringProperty:@""];
    PPRetailSDKTestDefault *d = [tester returnAnObject];
    XCTAssertNotNil(d);
    XCTAssertTrue([d isItTrue]);
}

- (void)testCallbacks {
    NSString *testing = @"Testing123";
    PPRetailSDKTest *tester = [[PPRetailSDKTest alloc] initWithStringProperty:testing];
    __block BOOL called = NO;
    [tester echo:testing callback:^(PayPalSDKError *error, NSString *arg) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(testing, arg);
        called = YES;
    }];
    XCTAssertTrue(called);

    XCTestExpectation *expect = [self expectationWithDescription:@"Timed callback"];
    [tester echoWithSetTimeout:testing callback:^(PayPalSDKError *error, NSString *arg) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(testing, arg);
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEvents {
    PPRetailSDKTest *tester = [[PPRetailSDKTest alloc] initWithStringProperty:@"123"];
    XCTestExpectation *expect = [self expectationWithDescription:@"Timed callback"];
    __block BOOL firedOnce = NO;
    PPRetailFakeEventSignal signal = [tester addFakeEventListener:^(PPRetailSDKTestDefault *item) {
        XCTAssertFalse(firedOnce);
        if (!firedOnce) {
            firedOnce = YES;
            XCTAssertNotNil(item);
            XCTAssertTrue([item isKindOfClass:[PPRetailSDKTestDefault class]]);
            [expect fulfill];
        }
    }];
    [tester triggerFakeAfterTimeout];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [tester removeFakeEventListener:signal];

    expect = [self expectationWithDescription:@"Timed callback"];
    [tester triggerFakeAfterTimeout];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expect fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
@end