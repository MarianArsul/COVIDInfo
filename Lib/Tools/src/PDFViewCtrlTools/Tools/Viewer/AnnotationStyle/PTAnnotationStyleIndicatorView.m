//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationStyleIndicatorView.h"

#import "PTKeyValueObserving.h"
#import "PTToolsUtil.h"
#import "PTToolImages.h"

#import "UIGeometry+PTAdditions.h"

#define PT_ANIMATION_DURATION (0.1)

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationStyleIndicatorView ()

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIImageView *leadingImageView;
@property (nonatomic, strong) UIImageView *disclosureIndicatorImageView;
@property (nonatomic) NSUInteger activeDisclosureIndicatorAnimationCount;

@property (nonatomic) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotationStyleIndicatorView

- (void)PTAnnotationStyleIndicatorView_commonInit
{
    _disclosureIndicatorEnabled = NO;
    _disclosureIndicatorHidden = YES;
    
    _backgroundView = ({
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.layer.cornerRadius = 4.0;
        view.layer.masksToBounds = YES;
        
        view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        (view);
    });
    [self addSubview:_backgroundView];
    
    _stackView = ({
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentCenter;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 8;
                
        (stackView);
    });
    [self addSubview:_stackView];
    
    _leadingImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        (imageView);
    });
    [_stackView addArrangedSubview:_leadingImageView];
    
    _disclosureIndicatorView = ({
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        (view);
    });
    [_stackView addArrangedSubview:_disclosureIndicatorView];
    
    _disclosureIndicatorImageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        (imageView);
    });
    [_disclosureIndicatorView addSubview:_disclosureIndicatorImageView];
    
    _disclosureIndicatorView.hidden = !_disclosureIndicatorEnabled;
    _disclosureIndicatorImageView.hidden = _disclosureIndicatorHidden;
    
    UIImage *trailingImage = nil;
    if (@available(iOS 13.0, *)) {
        trailingImage = [UIImage systemImageNamed:@"chevron.down" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightBold]];
    } else {
        trailingImage = [PTToolsUtil toolImageNamed:@"ic_arrow_drop_down_black_24dp"];
    }
    _disclosureIndicatorImageView.image = trailingImage;
    
    _disclosureIndicatorImageView.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = PT_BITMASK_SET(self.accessibilityTraits,
                                              UIAccessibilityTraitButton);
    
    if (@available(iOS 13.0, *)) {
        self.showsLargeContentViewer = YES;
        self.scalesLargeContentImage = YES;
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTAnnotationStyleIndicatorView_commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

#pragma mark - Constraints

- (void)loadConstraints
{
    const UIEdgeInsets backgroundMargins = PTUIEdgeInsetsMakeUniform(self.backgroundView.layer.cornerRadius);
    
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.backgroundView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.backgroundView.widthAnchor constraintEqualToAnchor:self.widthAnchor
                                                        constant:(backgroundMargins.left + backgroundMargins.right)],
        [self.backgroundView.heightAnchor constraintEqualToAnchor:self.heightAnchor
                                                         constant:(backgroundMargins.top + backgroundMargins.bottom)],
        
        [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.stackView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.stackView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        
        [self.disclosureIndicatorImageView.topAnchor constraintEqualToAnchor:self.disclosureIndicatorView.topAnchor],
        [self.disclosureIndicatorImageView.leftAnchor constraintEqualToAnchor:self.disclosureIndicatorView.leftAnchor],
        [self.disclosureIndicatorImageView.bottomAnchor constraintEqualToAnchor:self.disclosureIndicatorView.bottomAnchor],
        [self.disclosureIndicatorImageView.rightAnchor constraintEqualToAnchor:self.disclosureIndicatorView.rightAnchor],
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

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    
    [self updateBackground];
}

- (void)updateBackground
{
    if ([self isSelected]) {
        self.backgroundView.tintColor = [self.tintColor colorWithAlphaComponent:0.25];
        self.backgroundView.backgroundColor = self.backgroundView.tintColor;
    } else {
        self.backgroundView.tintColor = nil;
        self.backgroundView.backgroundColor = nil;
    }
}

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
    
    // Disable user interaction on all subviews, to allow this control to receive touches.
    subview.userInteractionEnabled = NO;
}

#pragma mark - UIControl

#pragma mark Tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    
    // Send primary action triggered event when highlighted ("touched").
    if ([self isHighlighted]) {
        [self sendActionsForControlEvents:UIControlEventPrimaryActionTriggered];
    }
}

#pragma mark State

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if (enabled) {
        self.accessibilityTraits = PT_BITMASK_CLEAR(self.accessibilityTraits,
                                                    UIAccessibilityTraitNotEnabled);
    } else {
        self.accessibilityTraits = PT_BITMASK_SET(self.accessibilityTraits,
                                                  UIAccessibilityTraitNotEnabled);
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
        
    // Animate alpha when highlighted.
    const NSTimeInterval duration = PT_ANIMATION_DURATION;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.alpha = (highlighted) ? 0.5 : 1.0;
    } completion:nil];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    const NSTimeInterval duration = PT_ANIMATION_DURATION;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        [self updateBackground];
    } completion:nil];
    
    if (selected) {
        self.accessibilityTraits = PT_BITMASK_SET(self.accessibilityTraits,
                                                  UIAccessibilityTraitSelected);
    } else {
        self.accessibilityTraits = PT_BITMASK_CLEAR(self.accessibilityTraits,
                                                    UIAccessibilityTraitSelected);
    }
}

#pragma mark - Presets group

- (void)setPresetsGroup:(PTAnnotationStylePresetsGroup *)presetsGroup
{
    PTAnnotationStylePresetsGroup *previousGroup = _presetsGroup;
    [self endObservingPresetsGroup:previousGroup];
    
    _presetsGroup = presetsGroup;
    [self beginObservingPresetsGroup:presetsGroup];
    
    // Update current style.
    self.style = presetsGroup.selectedStyle;
}

#pragma mark Observation

- (void)beginObservingPresetsGroup:(PTAnnotationStylePresetsGroup *)presetsGroup
{
    if (!presetsGroup) {
        return;
    }
    
    [self pt_observeObject:presetsGroup
                forKeyPath:PT_KEY(presetsGroup, selectedStyle)
                  selector:@selector(selectedPresetStyleDidChange:)];
}

- (void)endObservingPresetsGroup:(PTAnnotationStylePresetsGroup *)presetsGroup
{
    if (!presetsGroup) {
        return;
    }
    
    [self pt_removeObservationsForObject:presetsGroup];
}

- (void)selectedPresetStyleDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.presetsGroup) {
        return;
    }
    
    self.style = self.presetsGroup.selectedStyle;
}

#pragma mark - Style

- (void)setStyle:(PTAnnotStyle *)style
{
    if (_style == style) {
        // No change.
        return;
    }
    
    PTAnnotStyle *previousStyle = _style;
    [self endObservingStyle:previousStyle];
    
    _style = style;
    [self beginObservingStyle:style];
    
    [self updateImagesForStyle:style];
}

#pragma mark Observation

- (void)beginObservingStyle:(PTAnnotStyle *)style
{
    if (!style) {
        return;
    }
    
    for (PTAnnotStyleKey styleKey in style.availableStyleKeys) {
        NSString *key = nil;
        if ([styleKey isEqualToString:PTAnnotStyleKeyColor]) {
            key = PT_KEY(style, color);
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyFillColor]) {
            key = PT_KEY(style, fillColor);
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyStrokeColor]) {
            key = PT_KEY(style, strokeColor);
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyTextColor]) {
            key = PT_KEY(style, textColor);
        }
        
        if (key.length > 0) {
            [self pt_observeObject:style
                        forKeyPath:key
                          selector:@selector(styleColorDidChange:)];
        }
    }
}

- (void)endObservingStyle:(PTAnnotStyle *)style
{
    if (!style) {
        return;
    }
    
    [self pt_removeObservationsForObject:style];
}

- (void)styleColorDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.style) {
        return;
    }
    
    [self updateImagesForStyle:self.style];
}

#pragma mark - Images

- (void)updateImagesForStyle:(PTAnnotStyle *)style
{
    for (UIView *subview in self.leadingImageView.subviews) {
        [subview removeFromSuperview];
    }
    self.leadingImageView.tintColor = nil;
    
    BOOL addedLayers = NO;
    NSArray<PTAnnotationImageLayer *> *imageLayers = [PTToolImages imageLayersForAnnotationType:style.annotType];
    if (imageLayers.count > 0) {
        addedLayers = [self addImageLayers:imageLayers style:style];
    }
    
    if (!addedLayers) {
        self.leadingImageView.image = [PTToolImages imageForAnnotationType:style.annotType];
        self.leadingImageView.tintColor = [self primaryTintColorForStyle:style];
    }
    
    if (@available(iOS 13.0, *)) {
        self.largeContentImage = [PTToolImages imageForAnnotationType:style.annotType];
        self.largeContentTitle = PTLocalizedAnnotationNameFromType(style.annotType);
    }
}

- (BOOL)addImageLayers:(NSArray<PTAnnotationImageLayer *> *)imageLayers style:(PTAnnotStyle *)style
{
    BOOL addedLayers = NO;
    
    for (PTAnnotationImageLayer *imageLayer in imageLayers) {
        const PTAnnotStyleKey styleKey = imageLayer.styleKey;
        
        UIColor *tintColor = [self tintColorForStyleKey:styleKey style:style];
        
        // Skip transparent colors.
        if (CGColorGetAlpha(tintColor.CGColor) == 0.0) {
            continue;
        }
                
        for (UIImage *image in imageLayer.images) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            
            imageView.tintColor = tintColor;
            
            [self.leadingImageView addSubview:imageView];
            
            [NSLayoutConstraint activateConstraints:@[
                [imageView.topAnchor constraintEqualToAnchor:self.leadingImageView.topAnchor],
                [imageView.leftAnchor constraintEqualToAnchor:self.leadingImageView.leftAnchor],
                [imageView.bottomAnchor constraintEqualToAnchor:self.leadingImageView.bottomAnchor],
                [imageView.rightAnchor constraintEqualToAnchor:self.leadingImageView.rightAnchor],
            ]];
        }
        
        // Added at least one non-transparent image layer.
        addedLayers = YES;
    }
    
    return addedLayers;
}

#pragma mark - Tint colors

- (UIColor *)primaryTintColorForStyle:(PTAnnotStyle *)style
{
    // Find the first style color with a non-zero alpha.
    for (PTAnnotStyleKey styleKey in style.availableStyleKeys) {
        UIColor *proposedColor = nil;
        
        if ([styleKey isEqualToString:PTAnnotStyleKeyColor]) {
            proposedColor = self.style.color;
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyFillColor]) {
            proposedColor = self.style.fillColor;
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyStrokeColor]) {
            proposedColor = self.style.strokeColor;
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyTextColor]) {
            proposedColor = self.style.textColor;
        }
        
        if (proposedColor && CGColorGetAlpha(proposedColor.CGColor) > 0) {
            return proposedColor;
        }
    }
    // Use default (gray) color.
    return [self defaultTintColor];
}

- (UIColor *)tintColorForStyleKey:(PTAnnotStyleKey)styleKey style:(PTAnnotStyle *)style
{
    if (!styleKey) {
        return [self defaultTintColor];
    } else {
        if ([styleKey isEqualToString:PTAnnotStyleKeyColor]) {
            return self.style.color;
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyFillColor]) {
            return self.style.fillColor;
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyStrokeColor]) {
            return self.style.strokeColor;
        }
        else if ([styleKey isEqualToString:PTAnnotStyleKeyTextColor]) {
            return self.style.textColor;
        }
    }
    return [self defaultTintColor];
}

- (UIColor *)defaultTintColor
{
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            switch (traitCollection.userInterfaceStyle) {
                case UIUserInterfaceStyleDark:
                    return UIColor.whiteColor;
                case UIUserInterfaceStyleLight:
                default:
                    return UIColor.darkGrayColor;
            }
        }];
    } else {
        return UIColor.darkGrayColor;
    }
}

#pragma mark - Disclosure indicator

- (void)setDisclosureIndicatorEnabled:(BOOL)enabled
{
    _disclosureIndicatorEnabled = enabled;
    
    self.disclosureIndicatorView.hidden = !enabled;
}

- (void)setDisclosureIndicatorHidden:(BOOL)hidden
{
    [self setDisclosureIndicatorHidden:hidden animated:YES];
}

- (void)setDisclosureIndicatorHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (hidden == _disclosureIndicatorHidden) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_SELF_KEY(disclosureIndicatorHidden)];
    
    if (self.activeDisclosureIndicatorAnimationCount == 0) {
        if (hidden) {
            
        } else {
            self.disclosureIndicatorImageView.hidden = NO;
        }
    }
    
    _disclosureIndicatorHidden = hidden;
    
    const NSTimeInterval duration = (animated) ? PT_ANIMATION_DURATION : 0;
    
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.disclosureIndicatorImageView.alpha = (hidden) ? 0.0 : 1.0;
    } completion:^(BOOL finished) {
        self.activeDisclosureIndicatorAnimationCount--;
        
        if (self.activeDisclosureIndicatorAnimationCount == 0) {
            if ([self isDisclosureIndicatorHidden]) {
                self.disclosureIndicatorImageView.hidden = YES;
            } else {
                
            }
        }
    }];
    self.activeDisclosureIndicatorAnimationCount++;

    [self didChangeValueForKey:PT_SELF_KEY(disclosureIndicatorHidden)];
}

+ (BOOL)automaticallyNotifiesObserversOfDisclosureIndicatorHidden
{
    return NO;
}

@end
