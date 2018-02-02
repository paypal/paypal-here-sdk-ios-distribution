//
//  RUADebugLogListener.h
//  ROAMreaderUnifiedAPI
//
//  Created by Bin Lang on 9/12/17.
//  Copyright © 2017 ROAM. All rights reserved.
//

@protocol RUADebugLogListener <NSObject>

- (void)debugLogMessage:(NSString *)message;

@end
