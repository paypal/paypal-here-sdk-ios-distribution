//
//  PPSignatureView.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/26/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 * A delegate that receives events related to buyer signatures in the PPHSignatureView
 */
@protocol PPSignatureViewDelegate <NSObject>

@required
/*!
 * Called when a signature gesture has begun, so that you can hide potentially conflicting UI
 */
-(void)signatureTouchesBegan;
/*!
 * Called when a signature gesture has completed. Note that it may "begin again" such as a
 * disconnected gesture for last name.
 * @param isEmpty whether the new signature is empty
 */
-(void)signatureUpdated:(BOOL)isEmpty;
@end

/*!
 * A UIView subclass that will record user touches into a signature image.
 * Generally should be used "full-ish" screen.
 */
@interface PPSignatureView : UIView

/*! A receiver of events on the signature view */
@property (unsafe_unretained) id<PPSignatureViewDelegate> delegate;

/*!
 * Is the current signature considered empty?
 */
- (BOOL)isEmptySignature;

/*!
 * Get the signature image for printing or upload purposes
 */
- (UIImage *)printableImage;

/*!
 * Clear the current signature. It's good practice to do this after you're done with it as well
 * to avoid memory usage and potential data exposure.
 */
- (void)clearSignaturePad;

@end
