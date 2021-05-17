//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTRubberStampCell.h"

@interface PTRubberStampCell ()

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation PTRubberStampCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_imageView];
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:
         @[
             [self.imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
             [self.imageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
             [self.imageView.widthAnchor constraintLessThanOrEqualToAnchor:self.contentView.widthAnchor],
             [self.imageView.heightAnchor constraintLessThanOrEqualToAnchor:self.contentView.heightAnchor],
           ]];
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

@end
