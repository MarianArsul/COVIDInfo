//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailSliderViewCell.h"

#import "PTThumbnailSliderLayout.h"
#import "NSLayoutConstraint+PTPriority.h"

@interface PTThumbnailSliderViewCell ()

@property (nonatomic) UICollectionElementCategory representedElementCategory;

@property (nonatomic) BOOL drawsShadow;

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic) CGFloat aspectRatio;
@property (nonatomic, strong, nullable) NSLayoutConstraint *aspectRatioConstraint;

@property (nonatomic) BOOL constraintsLoaded;

@end

@implementation PTThumbnailSliderViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _representedElementCategory = UICollectionElementCategoryCell;
        
        _containerView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _containerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:_containerView];
        
        _imageView = [[UIImageView alloc] initWithFrame:_containerView.bounds];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _imageView.layer.minificationFilter = kCAFilterTrilinear;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _imageView.layer.borderColor = UIColor.lightGrayColor.CGColor;
        _imageView.layer.borderWidth = 0.5;
        
        [_containerView addSubview:_imageView];
        
        // Set default shadow appearance.
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowRadius = 2.5;
        
        _aspectRatio = 1.0;
        
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)updateAspectRatioConstraint
{
    if (self.aspectRatioConstraint) {
        self.aspectRatioConstraint.active = NO;
    }
    
    self.aspectRatioConstraint = [self.imageView.widthAnchor constraintEqualToAnchor:self.imageView.heightAnchor multiplier:self.aspectRatio];

    self.aspectRatioConstraint.active = YES;
}

- (void)updateAspectRatioConstraintWithSize:(CGSize)size
{
    if (self.aspectRatioConstraint) {
        self.aspectRatioConstraint.active = NO;
    }
    
    CGFloat aspectRatio = 1.0;
    if (size.width > 0 && size.height > 0) {
        aspectRatio = (size.width / size.height);
    }
    
    self.aspectRatioConstraint = [self.imageView.widthAnchor constraintEqualToAnchor:self.imageView.heightAnchor multiplier:aspectRatio];
    
    self.aspectRatioConstraint.active = YES;
}

- (void)loadConstraints
{
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
       [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
       [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
       [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
       
       // Image view is centered inside its superview.
       [self.imageView.centerXAnchor constraintEqualToAnchor:self.imageView.superview.centerXAnchor],
       [self.imageView.centerYAnchor constraintEqualToAnchor:self.imageView.superview.centerYAnchor],
       // Image view must fit inside its superview.
       [self.imageView.widthAnchor constraintLessThanOrEqualToAnchor:self.imageView.superview.widthAnchor],
       [self.imageView.heightAnchor constraintLessThanOrEqualToAnchor:self.imageView.superview.heightAnchor],
       ]];
    
    [NSLayoutConstraint pt_activateConstraints:
     @[
       // Image view tries to fill its superview (while respecting the image's aspect ratio).
       [self.imageView.widthAnchor constraintEqualToAnchor:self.imageView.superview.widthAnchor],
       [self.imageView.heightAnchor constraintEqualToAnchor:self.imageView.superview.heightAnchor],
       ] withPriority:UILayoutPriorityDefaultHigh];
    
    if (!self.aspectRatioConstraint) {
        [self updateAspectRatioConstraint];
    }
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        // Constraints are loaded.
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
    
    if (self.drawsShadow) {
        // Draw shadow.
        self.layer.shadowOpacity = 0.25;
    } else {
        // Disable shadow.
        self.layer.shadowOpacity = 0.0;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
            [self update];
        }
    }
}

#pragma mark - UICollectionViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.drawsShadow = NO;
}

- (void)setRepresentedElementCategory:(UICollectionElementCategory)representedElementCategory
{
    _representedElementCategory = representedElementCategory;
    
    [self update];
}

#pragma mark - Layout Attributes

- (void)applySupplementaryViewLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if ([layoutAttributes.representedElementKind isEqualToString:PTThumbnailSliderFloatingItemKind]) {
        self.drawsShadow = YES;
        
        self.imageView.layer.borderWidth = 2.0;
    }
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];
    
    self.representedElementCategory = layoutAttributes.representedElementCategory;
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell:
            break;
        case UICollectionElementCategorySupplementaryView:
            [self applySupplementaryViewLayoutAttributes:layoutAttributes];
            break;
        case UICollectionElementCategoryDecorationView:
            break;
    }
}

- (void)configureWithItem:(PTThumbnailSliderViewItem *)item
{
    self.imageView.image = item.image;
    
    if (!CGSizeEqualToSize(item.size, CGSizeZero)) {
        CGSize size = item.size;
        CGFloat aspectRatio = 1.0;
        if (size.width > 0 && size.height > 0) {
            aspectRatio = (size.width / size.height);
        }
        
        self.aspectRatio = aspectRatio;
    }
    
    [self update];
}

- (void)setNightModeEnabled:(BOOL)nightModeEnabled
{
    if (_nightModeEnabled == nightModeEnabled) {
        // No change.
        return;
    }
    
    _nightModeEnabled = nightModeEnabled;
    
    [self update];
}

- (void)update
{
    UIColor *borderColor = nil;
    
    switch (self.representedElementCategory) {
        case UICollectionElementCategoryCell:
        {
            if ([self isNightModeEnabled]) {
                borderColor = UIColor.grayColor;
            } else {
                borderColor = [UIColor.grayColor colorWithAlphaComponent:0.8];
            }
        }
            break;
        case UICollectionElementCategorySupplementaryView:
        {
            if ([self isNightModeEnabled]) {
                borderColor = UIColor.lightGrayColor;
            } else {
                borderColor = [UIColor.blackColor colorWithAlphaComponent:0.7];
                if (@available(iOS 13.0, *)) {
                    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                        borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.7];
                    }
                }
            }
        }
            break;
        case UICollectionElementCategoryDecorationView:
            break;
    }
    
    self.imageView.layer.borderColor = borderColor.CGColor;
}

#pragma mark - Aspect ratio

- (void)setAspectRatio:(CGFloat)aspectRatio
{
    if (_aspectRatio == aspectRatio) {
        // No change.
        return;
    }
    
    _aspectRatio = aspectRatio;
    
    [self updateAspectRatioConstraint];
}

@end
