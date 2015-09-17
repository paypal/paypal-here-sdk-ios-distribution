//
//  PPHMagStripeTracks.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 2/5/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

typedef NS_OPTIONS(NSInteger, PPHMagStripeTracksMask) {
    ePPHMagStripeTracksMaskNone = 0,
    ePPHMagStripeTracksMaskTrackOne = 1 << 0,
    ePPHMagStripeTracksMaskTrackTwo = 1 << 1,
    ePPHMagStripeTracksMaskTrackThree = 1 << 2,
    ePPHMagStripeTracksMaskAll =
    ePPHMagStripeTracksMaskTrackOne |
    ePPHMagStripeTracksMaskTrackTwo |
    ePPHMagStripeTracksMaskTrackThree
};
