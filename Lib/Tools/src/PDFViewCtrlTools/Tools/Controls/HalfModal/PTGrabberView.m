//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTGrabberView.h"

#import "PTShapeView.h"

#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTGrabberView ()

@property (nonatomic, strong) PTShapeView *shapeView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTGrabberView

- (void)PTGrabberView_commonInit
{
    _shapeView = [[PTShapeView alloc] init];
    _shapeView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 13.0, *)) {
         _shapeView.layer.fillColor = UIColor.systemGray2Color.CGColor;
    } else {
        _shapeView.layer.fillColor = [UIColor colorWithWhite:0.0
                                                       alpha:0.2].CGColor;
    }
    _shapeView.layer.strokeColor = nil;
        
    [self addSubview:_shapeView];
    
    // Schedule constraints load.
    [self setNeedsUpdateConstraints];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTGrabberView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTGrabberView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.shapeView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.shapeView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.shapeView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        [self.shapeView.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
        [self.shapeView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        [self.shapeView.widthAnchor constraintEqualToConstant:36.0],
        [self.shapeView.heightAnchor constraintEqualToConstant:5.0],
    ] withPriority:UILayoutPriorityDefaultHigh];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(44, 16);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGRect bounds = self.shapeView.bounds;
    
    // Use smaller dimension for corner radius.
    const CGFloat cornerRadius = fmin(CGRectGetWidth(bounds),
                                      CGRectGetHeight(bounds)) / 2;

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                    cornerRadius:cornerRadius];
    
    self.shapeView.layer.path = path.CGPath;
}

#pragma mark - <UITraitEnvironment>

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        _shapeView.layer.fillColor = UIColor.systemGray2Color.CGColor;
    }
}

@end
