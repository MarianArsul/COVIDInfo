//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailViewCell.h"

#import "PTCheckmarkView.h"
#import "PTToolsUtil.h"
#import "NSLayoutConstraint+PTPriority.h"

#import <tgmath.h>

@interface PTThumbnailViewCell ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *labelBackgroundView;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *thumbnailView;

@property (nonatomic, strong, nullable) NSLayoutConstraint *thumbnailViewAspectRatioConstraint;

@property (nonatomic, strong) PTCheckmarkView *checkmarkView;

@property (nonatomic) BOOL didSetupConstraints;

@property (nonatomic, assign, getter=isCurrent) BOOL current;

@end

@implementation PTThumbnailViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Clear background looks nicer for drag and drop.
        self.backgroundColor = [UIColor clearColor];
        [self setOpaque:NO];
        
        // Thumbnail image.
        _thumbnailView = [[UIImageView alloc] init];
        _thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        _thumbnailView.opaque = YES;
        
        _thumbnailView.layer.minificationFilter = kCAFilterTrilinear;
        
        [self.contentView addSubview:_thumbnailView];
        
        // Page number indicator.
        _labelBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        _labelBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        _labelBackgroundView.layer.cornerRadius = 4.0;
        _labelBackgroundView.layoutMargins = UIEdgeInsetsMake(2, 10, 2, 10);
        
        [self.contentView addSubview:_labelBackgroundView];
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = UIColor.whiteColor;
        _label.adjustsFontSizeToFitWidth = YES;
        
        [_labelBackgroundView addSubview:_label];
        
        // Checkbox shown while selected in edit mode.
        _checkmarkView = [[PTCheckmarkView alloc] init];
        _checkmarkView.hidden = YES;
        
        [self.contentView addSubview:_checkmarkView];
        
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        self.thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Aspect fit setup.
        // https://stackoverflow.com/questions/25766747/emulating-aspect-fit-behaviour-using-autolayout-constraints-in-xcode-6
        if (!self.thumbnailViewAspectRatioConstraint) {
            self.thumbnailViewAspectRatioConstraint =
            [self.thumbnailView.widthAnchor constraintEqualToAnchor:self.thumbnailView.heightAnchor];
        }
        
        [NSLayoutConstraint activateConstraints:
         @[
           (self.thumbnailViewAspectRatioConstraint),
           [self.thumbnailView.centerXAnchor constraintEqualToAnchor:self.thumbnailView.superview.centerXAnchor],
           [self.thumbnailView.centerYAnchor constraintEqualToAnchor:self.thumbnailView.superview.centerYAnchor],
           [self.thumbnailView.widthAnchor constraintLessThanOrEqualToAnchor:self.thumbnailView.superview.widthAnchor],
           [self.thumbnailView.heightAnchor constraintLessThanOrEqualToAnchor:self.thumbnailView.superview.heightAnchor],
           ]];
        
        [NSLayoutConstraint pt_activateConstraints:
         @[
           [self.thumbnailView.widthAnchor constraintEqualToAnchor:self.thumbnailView.superview.widthAnchor],
           [self.thumbnailView.heightAnchor constraintEqualToAnchor:self.thumbnailView.superview.heightAnchor],
           ]
                                      withPriority:UILayoutPriorityDefaultHigh];
        
        self.labelBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.checkmarkView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [NSLayoutConstraint activateConstraints:
         @[
           [self.labelBackgroundView.centerXAnchor constraintEqualToAnchor:self.labelBackgroundView.superview.centerXAnchor],
           [self.labelBackgroundView.bottomAnchor constraintEqualToAnchor:self.labelBackgroundView.superview.layoutMarginsGuide.bottomAnchor],
           
           [self.label.centerXAnchor constraintEqualToAnchor:self.label.superview.centerXAnchor],
           [self.label.widthAnchor constraintEqualToAnchor:self.label.superview.layoutMarginsGuide.widthAnchor],
           [self.label.centerYAnchor constraintEqualToAnchor:self.label.superview.centerYAnchor],
           [self.label.heightAnchor constraintEqualToAnchor:self.label.superview.layoutMarginsGuide.heightAnchor],
           
           [self.checkmarkView.trailingAnchor constraintEqualToAnchor:self.thumbnailView.layoutMarginsGuide.trailingAnchor],
           [self.checkmarkView.topAnchor constraintEqualToAnchor:self.thumbnailView.layoutMarginsGuide.topAnchor],
           /* Use intrinsic PTCheckmarkView width. */
           /* Use intrinsic PTCheckmarkView height. */
           ]];
        
        // Constraints are set up.
        self.didSetupConstraints = YES;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

- (NSLayoutConstraint *)aspectRatioConstraintForImage:(UIImage *)image
{
    CGSize size = image.size;
    CGFloat aspectRatio = (size.height != 0.0) ? fabs(size.width / size.height) : 0.0;
    
    return [self.thumbnailView.widthAnchor constraintEqualToAnchor:self.thumbnailView.heightAnchor multiplier:aspectRatio];
}

- (void)updateAspectRatioConstraintWithImage:(UIImage *)image
{
    self.thumbnailViewAspectRatioConstraint.active = NO;
    
    self.thumbnailViewAspectRatioConstraint = [self aspectRatioConstraintForImage:image];

    self.thumbnailViewAspectRatioConstraint.active = YES;
}

- (void)setPageNumber:(NSInteger)pageNumber pageLabel:(NSString *)pageLabel
{
    if (pageLabel.length > 0) {
        self.label.text = pageLabel;
    } else {
        self.label.text = [NSString stringWithFormat:@"%ld", (long)pageNumber];
    }
}

-(void)setPageNumber:(NSInteger)pageNumber pageLabel:(NSString *)pageLabel isCurrentPage:(BOOL)isCurrent isEditing:(BOOL)isEditing isChecked:(BOOL)isChecked
{
    [self setPageNumber:pageNumber pageLabel:pageLabel];
    
    if (isCurrent) {
        self.labelBackgroundView.backgroundColor = self.labelBackgroundView.tintColor;
    } else {
        self.labelBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    }
    self.current = isCurrent;
    
    // white out reused cell
    if (!isEditing) {
        self.thumbnailView.image = nil;
        self.thumbnailView.backgroundColor = [self backgroundColorForNightMode];
    }
}

-(void)setThumbnail:(UIImage *)image forPage:(NSInteger)pageNum
{
    if (image == self.thumbnailView.image) {
        return;
    }
    
    self.thumbnailView.image = image;
    [self updateAspectRatioConstraintWithImage:image];
    if (image) {
        self.thumbnailView.backgroundColor = UIColor.clearColor;
        self.thumbnailView.layer.borderWidth = (1.0 / UIScreen.mainScreen.nativeScale);
        self.thumbnailView.layer.borderColor = UIColor.lightGrayColor.CGColor;
    } else {
        self.thumbnailView.backgroundColor = [self backgroundColorForNightMode];
        self.thumbnailView.layer.borderWidth = 0.0;
        self.thumbnailView.layer.borderColor = nil;
    }
}

- (UIColor*)backgroundColorForNightMode
{
    return self.nightMode ? UIColor.blackColor : UIColor.whiteColor;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    if ([self isCurrent]) {
        self.labelBackgroundView.backgroundColor = self.labelBackgroundView.tintColor;
    } else {
        self.labelBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    }
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (_editing == editing) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_KEY(self, editing)];

    self.checkmarkView.hidden = !editing;
    _editing = editing;
    
    [self didChangeValueForKey:PT_KEY(self, editing)];
}

+ (BOOL)automaticallyNotifiesObserversOfEditing
{
    return NO;
}

#pragma mark - UICollectionViewCell property accessors

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.thumbnailView.alpha = ([self isEditing] && selected) ? 0.75 : 1.0;
    self.layer.borderColor = self.tintColor.CGColor;
    self.layer.borderWidth = ([self isEditing] && selected) ? 3.0 : 0.0;
    // Animate checkmark if cell is attached to window.
    BOOL animate = (self.window != nil);
    [self.checkmarkView setSelected:selected animated:animate];
}

@end
