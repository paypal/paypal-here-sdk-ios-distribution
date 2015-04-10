//
//  PPHMagStripeTracks.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 2/5/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

typedef NS_ENUM(NSInteger, PPHMagStripeTracks) {
    ePPHMagStripeTrackNone,
    ePPHMagStripeTrackOne,
    ePPHMagStripeTrackTwo,
    ePPHMagStripeTrackThree
};

typedef NS_OPTIONS(NSInteger, PPHMagStripeTracksMask) {
    ePPHMagStripeTracksMaskNone = 0,
    ePPHMagStripeTracksMaskTrackOne = 1 << ePPHMagStripeTrackOne,
    ePPHMagStripeTracksMaskTrackTwo = 1 << ePPHMagStripeTrackTwo,
    ePPHMagStripeTracksMaskTrackThree = 1 << ePPHMagStripeTrackThree,
    ePPHMagStripeTracksMaskAll =
    ePPHMagStripeTracksMaskTrackOne |
    ePPHMagStripeTracksMaskTrackTwo |
    ePPHMagStripeTracksMaskTrackThree
};