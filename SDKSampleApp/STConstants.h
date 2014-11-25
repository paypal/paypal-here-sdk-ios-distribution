//
//  STConstants.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/23/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#define MID_TIER_SERVER_URL @"http://sdk-sample-server.herokuapp.com/server"
#define LIST_OF_STAGES @[@"stage2mb023", @"stage2mb024", @"stage2pph10", @"stage2pph03", @"stage2mb001", @"stage2mb006"]
#define DEFAULT_STAGE @"stage2mb023"
#define CONSTRUCT_STAGE_URL(stage) ([NSString stringWithFormat:@"https://www.%@.stage.paypal.com/webapps/", stage])
#define ENVIRONMENTS @[@"Stage",@"Sandbox",@"Live"]

#define IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)