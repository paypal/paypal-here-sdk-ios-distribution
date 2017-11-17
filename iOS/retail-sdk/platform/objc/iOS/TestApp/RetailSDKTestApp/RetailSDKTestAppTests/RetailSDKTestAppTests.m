//
//  RetailSDKTestAppTests.m
//  RetailSDKTestAppTests
//
//  Created by Ashar, Snehanshu on 10/11/16.
//  Copyright © 2016 PayPal. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface RetailSDKTestAppTests : XCTestCase

@end

@implementation RetailSDKTestAppTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPass1 {
    XCTAssert(YES);
    // This is an example of a passing functional test case.
}

- (void)testPass2 {
    XCTAssert(YES);
    // This is an example of another passing functional test case.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
