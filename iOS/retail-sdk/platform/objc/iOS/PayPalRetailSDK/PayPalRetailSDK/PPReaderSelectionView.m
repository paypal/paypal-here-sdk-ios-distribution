//
//  PPReaderSelectionView.m
//  Pods
//
//  Created by Chandrashekar, Sathyanarayan on 6/8/17.
//
//

#import "PPReaderSelectionView.h"
#import "PPAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import "PayPalRetailSDKStyles.h"
#import "PlatformView+PPAutoLayout.h"
#import "UIButton+PPStyle.h"

#pragma mark -
#pragma mark Private

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReaderSelectionView ()

@property (nonatomic, weak) id<PPReaderSelectionViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *viewsAndSpacers;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) JSValue *handle;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PPReaderSelectionView

#pragma mark -
#pragma mark Init
- (instancetype)initWithDelegate:(id<PPReaderSelectionViewDelegate>)delegate
                           title:(NSString *)title
                           message:(NSString *)message
                    buttonImages:(NSArray *)buttonImages
                       buttonIds:(NSArray *)buttonIds
                          handle:(JSValue *)handle {
    
    if (self = [super initWithFrame:[[UIApplication sharedApplication] keyWindow].bounds]) {
        self.delegate = delegate;
        self.handle = handle;
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        self.maskView = [[UIView alloc] initWithFrame:CGRectMake(-100000, -100000, 1000000, 1000000)];
        self.maskView.backgroundColor = [PayPalRetailSDKStyles screenMaskColor];
        self.maskView.userInteractionEnabled = YES;
        [self addSubview:self.maskView];
        
        self.contentView = [UIView new];
        [self.contentView setBackgroundColor:[PayPalRetailSDKStyles viewBackgroundColor]];
        self.contentView.accessibilityIdentifier = @"PPHReaderSelectionView";
        self.contentView.layer.cornerRadius = 6;
        [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView constrainToWidth:260];
        [self addSubview:self.contentView];
        
        //This is an array of arrays containg a view and its spacing below the previous view @[[UIView, NSNumber]...]
        self.viewsAndSpacers = [NSMutableArray new];
        
        UILabel *titleLabel = [UILabel new];
        titleLabel.text = title;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.viewsAndSpacers addObject:@[titleLabel, @16.0f]];
        [self.contentView addSubview:titleLabel];
        [titleLabel constrainToWidth:240];
        [titleLabel sizeToFit];
        [titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        UILabel *messageLabel = [UILabel new];
        messageLabel.text = message;
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.textColor = [UIColor grayColor];
        [self.viewsAndSpacers addObject:@[messageLabel, @16.0f]];
        [self.contentView addSubview:messageLabel];
        [messageLabel constrainToWidth:240];
        [messageLabel sizeToFit];
        [messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        UIView *readersView = [UIView new];
        [readersView setTranslatesAutoresizingMaskIntoConstraints:NO];
        UIView *previousView = nil;
        CGFloat height = 0;
        CGFloat width = 0;
        
        for (int index = 0; index < buttonImages.count; index++) {
            NSString *imageName = buttonImages[index];
            NSInteger imageId = buttonIds[index];
            UIImage *readerImage = [PayPalRetailSDK sdkImageNamed:imageName];
            UIButton *newButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [newButton setImage:readerImage forState:UIControlStateNormal];
            [newButton addTarget:self action:@selector(readerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [newButton setTranslatesAutoresizingMaskIntoConstraints:NO];
            [newButton setTag:index];
            [newButton constrainToHeight:readerImage.size.height];
            [newButton constrainToWidth:readerImage.size.width];
            [readersView addSubview:newButton];
            [newButton pinInSuperviewToEdges:PPViewEdgeTop withInset:0];
            if (previousView) {
                width = width + readerImage.size.width + 16;
                [newButton pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:previousView inset:16.f];
                if (readerImage.size.height > readersView.frameHeight) {
                    height = readerImage.size.height;
                    previousView.frameMidY = readersView.frameHeight / 2;
                }
            } else {
                width = readerImage.size.width;
                height = readerImage.size.height;
                [newButton pinInSuperviewToEdges:PPViewEdgeLeft withInset:0];
            }
            newButton.frameMidY = readersView.frameHeight / 2;
            previousView = newButton;
        }
        [readersView constrainToHeight:height];
        [readersView constrainToWidth:width];
        
        [self.contentView addSubview:readersView];
        [self.viewsAndSpacers addObject:@[readersView, @16.0f]];
        
        UIView *bottomSpacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];
        [bottomSpacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [bottomSpacerView constrainToHeight:16];
        [bottomSpacerView constrainToWidth:self.contentView.frameWidth];
        [self.viewsAndSpacers addObject:@[bottomSpacerView, @0.0f]];
        [self.contentView addSubview:bottomSpacerView];
        
        [self.contentView centerInSuperview];
    }
    
    return self;
}

- (void)updateConstraints {
    UIView *previousView;
    for (NSArray *viewAndSpacing in self.viewsAndSpacers) {
        UIView *view = (UIView *)viewAndSpacing[0];
        NSNumber *spacing = (NSNumber *)viewAndSpacing[1];
        if (previousView) {
            [view pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:previousView inset:spacing.floatValue];
        } else {
            [view pinInSuperviewToEdges:PPViewEdgeTop withInset:spacing.floatValue];
        }
        previousView = view;
        [view centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
    }
    
    if (previousView) {
        [previousView pinInSuperviewToEdges:PPViewEdgeBottom withInset:0]; // There is a bottom spacer view in viewsAndSpacers
    }
    [super updateConstraints];
}

- (void)readerButtonPressed:(UIButton *)button {
    [self.delegate selectedReaderIndex:button.tag handle:self.handle];
}

@end
