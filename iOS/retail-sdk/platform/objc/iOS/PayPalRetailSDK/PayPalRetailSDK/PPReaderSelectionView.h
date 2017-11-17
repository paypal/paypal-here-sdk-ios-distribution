//
//  PPReaderSelectionView.h
//  Pods
//
//  Created by Chandrashekar, Sathyanarayan on 6/8/17.
//
//

#import <Foundation/Foundation.h>

@protocol PPReaderSelectionViewDelegate <NSObject>

- (void)selectedReaderIndex:(NSInteger)index handle:(JSValue *)handle;

@end

@interface PPReaderSelectionView : UIView

- (instancetype)initWithDelegate:(id<PPReaderSelectionViewDelegate>)delegate
                           title:(NSString *)title
                         message:(NSString *)message
                    buttonImages:(NSArray *)buttonImages
                       buttonIds:(NSArray *)buttonIds
                          handle:(JSValue *)handle;

@end
