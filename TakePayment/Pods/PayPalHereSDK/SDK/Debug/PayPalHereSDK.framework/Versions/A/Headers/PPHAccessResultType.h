//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

/*!
 * Indicates whether all the information regarding the logged in merchant was
 * successfully retrieved by the backend and the merchant setup was succcessful.
 */
typedef NS_ENUM(NSInteger, PPHAccessResultType) {
    /*!
     * If the merchant setup was successful.
     */
    ePPHAccessResultSuccess,
    
    /*!
     * If the merchant setup encountered an error.
     */
    ePPHAccessResultFailed
};

