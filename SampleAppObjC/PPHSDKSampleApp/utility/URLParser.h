//
//  URLParser.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/19/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLParser : NSObject {
    NSArray *variables;
}

@property (nonatomic, retain) NSArray *variables;

- (id)initWithURLString:(NSString *)url;
- (NSString *)valueForVariable:(NSString *)varName;

@end
