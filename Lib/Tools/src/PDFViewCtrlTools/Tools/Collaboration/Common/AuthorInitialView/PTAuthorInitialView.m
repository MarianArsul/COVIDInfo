//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAuthorInitialView.h"

#include <tgmath.h>

@interface PTAuthorInitialView ()

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTAuthorInitialView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.lightGrayColor;
        self.layer.masksToBounds = YES;
        
        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _label.textColor = UIColor.whiteColor;
        _label.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:_label];
        
        // Schedule constraints set up.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
       [self.label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
       [self.label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
       [self.label.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],
       ]];
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Set corner radius to be half of the smallest dimension.
    CGRect frame = self.frame;
    CGFloat smallestDimension = fmin(CGRectGetWidth(frame), CGRectGetHeight(frame));
    self.layer.cornerRadius = smallestDimension / 2.0;
}

#pragma mark - Updating

- (void)setName:(NSString *)name
{
    _name = [name copy];
    
    self.label.text = [(name ? name : @"?") substringToIndex:1].localizedUppercaseString;
}

@end
