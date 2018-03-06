//
//  RUAReleaseHandler.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 8/4/16.
//  Copyright © 2016 ROAM. All rights reserved.
//

#ifndef RUAReleaseHandler_h
#define RUAReleaseHandler_h

@protocol RUAReleaseHandler <NSObject>

/**
 * Invoked when a device manager releases all the resources it acquired.
 * */
- (void)done;

@end

#endif /* RUAReleaseHandler_h */
