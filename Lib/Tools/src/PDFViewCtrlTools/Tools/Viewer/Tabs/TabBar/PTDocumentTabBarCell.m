//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentTabBarCell.h"

#import "PTDocumentTabBar.h"
#import "PTKeyValueObserving.h"
#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

@interface PTDocumentTabBarCell ()

@property (nonatomic) UIView *containerView;

@property (nonatomic) BOOL constraintsLoaded;

@end

@implementation PTDocumentTabBarCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _containerView = ({
            UIView *view = [[UIView alloc] initWithFrame:self.contentView.bounds];
            view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
            
            view.layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
            if (@available(iOS 11, *)) {
                view.insetsLayoutMarginsFromSafeArea = NO;
            }

            (view);
        });
        [self.contentView addSubview:_containerView];
        
        // Set up label.
        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _label.textAlignment = NSTextAlignmentCenter;
        _label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        _label.font = [UIFont systemFontOfSize:UIFont.smallSystemFontSize
                                        weight:UIFontWeightSemibold];
        
        // Compress (and truncate) label if necessary.
        [_label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                forAxis:UILayoutConstraintAxisHorizontal];
        
        [_containerView addSubview:_label];
        
        // Set up button.
        _button = [UIButton buttonWithType:UIButtonTypeSystem];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIImage *buttonImage = nil;
        if (@available(iOS 13.0, *)) {
            UIImageConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:16];
            buttonImage = [UIImage systemImageNamed:@"xmark.square.fill"
                                  withConfiguration:configuration];
        } else {
            buttonImage = [PTToolsUtil toolImageNamed:@"ic_ios_cancel_black_16px"];
        }
        [_button setImage:buttonImage forState:UIControlStateNormal];
        
        _button.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        _button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        // Hide by default.
        _button.hidden = YES;
        
        // Resist being made larger than intrinsic content size.
        [_button setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                   forAxis:UILayoutConstraintAxisHorizontal];
        
        [_containerView addSubview:_button];
        
        self.selectedBackgroundView = [[UIToolbar alloc] initWithFrame:self.bounds];
        
        [self resetState];
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
    UILayoutGuide *layoutMarginsGuide = self.containerView.layoutMarginsGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        // Center button vertically and align to leading edge of view.
        [self.button.centerYAnchor constraintEqualToAnchor:layoutMarginsGuide.centerYAnchor],
        [self.button.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
        [self.button.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
        
        // Center label vertically and constrain horizontally to the area trailing the button.
        [self.label.centerYAnchor constraintEqualToAnchor:layoutMarginsGuide.centerYAnchor],
        [self.label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.button.trailingAnchor],
        [self.label.trailingAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.trailingAnchor],
    ]];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // Button must fit vertically within the margins.
        [self.button.topAnchor constraintGreaterThanOrEqualToAnchor:layoutMarginsGuide.topAnchor],
        [self.button.bottomAnchor constraintLessThanOrEqualToAnchor:layoutMarginsGuide.bottomAnchor],
    ] withPriority:(UILayoutPriorityRequired - 1) /* Pressure relief valve for compressed layout */];
    
    [NSLayoutConstraint pt_activateConstraints:@[
        // At least 4pts spacing between button and label.
        [self.label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.button.trailingAnchor
                                                              constant:4],
        // Prefer to keep the label centered in the view.
        [self.label.centerXAnchor constraintEqualToAnchor:layoutMarginsGuide.centerXAnchor],
    ] withPriority:UILayoutPriorityDefaultHigh /* Optional constraints */];
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

#pragma mark - Configuration

- (void)updateTitle
{
    self.label.text = [self titleForTab:self.tab];
}

- (NSString *)titleForTab:(PTDocumentTabItem *)tab
{
    NSString *displayName = tab.displayName;
    if (displayName) {
        return displayName;
    }
    
    NSURL *url = tab.documentURL ?: tab.sourceURL;
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *cachesURL = [fileManager URLsForDirectory:NSCachesDirectory
                                           inDomains:NSUserDomainMask].firstObject;
    
    // Only use the documentURL when *not* inside the Caches folder.
    if (tab.documentURL
        && ![tab.documentURL isEqual:tab.sourceURL]
        && ![tab.documentURL.absoluteString hasPrefix:cachesURL.absoluteString]) {
        url = tab.documentURL;
    }
    else if (tab.sourceURL) {
        url = tab.sourceURL;
    }
    
    if (url) {
        // Get file name.
        NSString *filename = url.lastPathComponent;
        
        // Strip file extension.
        return filename.stringByDeletingPathExtension;
    } else {
        return PTLocalizedString(@"Untitled",
                                 @"Untitled document name");
    }
}

#pragma mark - Tab

- (void)setTab:(PTDocumentTabItem *)tab
{
    PTDocumentTabItem *previousTab = _tab;
    _tab = tab;
    
    if (previousTab) {
        [self pt_removeObservationsForObject:previousTab
                                     keyPath:PT_KEY(previousTab, sourceURL)];
        [self pt_removeObservationsForObject:previousTab
                                     keyPath:PT_KEY(previousTab, documentURL)];
        [self pt_removeObservationsForObject:previousTab
                                     keyPath:PT_KEY(previousTab, displayName)];
    }
    if (tab) {
        [self pt_observeObject:tab
                    forKeyPath:PT_KEY(tab, sourceURL)
                      selector:@selector(tabDidChange:)];
        [self pt_observeObject:tab
                    forKeyPath:PT_KEY(tab, documentURL)
                      selector:@selector(tabDidChange:)];
        [self pt_observeObject:tab
                    forKeyPath:PT_KEY(tab, displayName)
                      selector:@selector(tabDidChange:)];
    }
    
    [self updateTitle];
}

- (void)tabDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.tab) {
        return;
    }
    
    // Update the title when the display name or either of the tab's URLs change.
    [self updateTitle];
}

- (void)resetState
{
    self.label.text = nil;
    self.label.enabled = NO;
    self.button.hidden = YES;
}

- (void)updateState
{
    BOOL selected = self.selected;
    
    self.label.enabled = selected;
    self.button.hidden = !selected;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self resetState];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self updateState];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view) {
        CGPoint contentViewPoint = [self convertPoint:point toView:self.contentView];
        
        CGFloat touchTargetDimension = fmin(CGRectGetHeight(self.contentView.bounds), 44.0);
        
        CGRect fakeButtonFrame = CGRectMake(0, 0,
                                            touchTargetDimension, touchTargetDimension);
        
        if (CGRectContainsPoint(fakeButtonFrame, contentViewPoint)) {
            return self.button;
        }
    }
    return view;
}

@end
