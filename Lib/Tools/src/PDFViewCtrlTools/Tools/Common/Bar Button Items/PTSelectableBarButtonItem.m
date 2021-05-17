//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSelectableBarButtonItem.h"
#import "PTSelectableBarButtonItemPrivate.h"

#import "PTButtonBarButtonView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTSelectableBarButtonItem ()

@end

NS_ASSUME_NONNULL_END

@implementation PTSelectableBarButtonItem

- (PTButtonBarButtonView *)PTSelectableBarButtonItem_createDefaultView
{
    PTButtonBarButtonView *view = [[PTButtonBarButtonView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [view.button addTarget:self
                    action:@selector(buttonTriggered:)
          forControlEvents:UIControlEventPrimaryActionTriggered];

    return view;
}

#pragma mark - Button action

- (void)buttonTriggered:(UIButton *)sender
{
    if (!self.action) {
        return;
    }
    
    [UIApplication.sharedApplication sendAction:self.action
                                             to:self.target
                                           from:self
                                       forEvent:nil];
}

#pragma mark - Init

- (instancetype)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
    self = [super initWithImage:image style:style target:target action:action];
    if (self) {
        PTButtonBarButtonView *view = [self PTSelectableBarButtonItem_createDefaultView];
        [view.button setImage:image forState:UIControlStateNormal];
        
        self.customView = view;
        
        _barButtonView = view;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
    self = [super initWithTitle:title style:style target:target action:action];
    if (self) {
        PTButtonBarButtonView *view = [self PTSelectableBarButtonItem_createDefaultView];
        [view.button setTitle:title forState:UIControlStateNormal];

        self.customView = view;
        
        _barButtonView = view;
    }
    return self;
}

- (instancetype)initWithCustomView:(UIView *)customView
{
    NSParameterAssert(customView != nil);
    
    PTBarButtonView *view = [[PTBarButtonView alloc] initWithView:customView];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self = [super initWithCustomView:view];
    if (self) {
        _barButtonView = view;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    if ([self.barButtonView isKindOfClass:[PTButtonBarButtonView class]]) {
        PTButtonBarButtonView *view = (PTButtonBarButtonView *)self.barButtonView;
        
        [self updateView:view];
    }
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    
    if ([self.barButtonView isKindOfClass:[PTButtonBarButtonView class]]) {
        PTButtonBarButtonView *view = (PTButtonBarButtonView *)self.barButtonView;
        
        [self updateView:view];
    }
}

- (void)updateView:(PTButtonBarButtonView *)view
{
    if (self.image) {
        [view.button setImage:self.image forState:UIControlStateNormal];
        
        // Use the title for the accessibility label(s).
        view.button.accessibilityLabel = self.title;
        if (@available(iOS 13.0, *)) {
            view.button.largeContentTitle = self.title;
        }
    } else {
        // Clear out the previously set image, if any.
        [view.button setImage:nil forState:UIControlStateNormal];
        [view.button setTitle:self.title forState:UIControlStateNormal];
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if ([self.barButtonView.view isKindOfClass:[UIControl class]]) {
        ((UIControl *)self.barButtonView.view).enabled = enabled;
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    // Pass custom tint color through to view.
    self.customView.tintColor = tintColor;
}

#pragma mark - Selected

@synthesize selected = _selected;

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    if ([self.barButtonView.view isKindOfClass:[UIControl class]]) {
        ((UIControl *)self.barButtonView.view).selected = selected;
    }
}

- (BOOL)isSelected
{
    if ([self.barButtonView.view isKindOfClass:[UIControl class]]) {
        return [((UIControl *)self.barButtonView.view) isSelected];
    }

    return _selected;
}

#pragma mark - Badge Hidden

- (BOOL)isBadgeHidden
{
    return [self.barButtonView.badgeIndicatorView isHidden];
}

- (void)setBadgeHidden:(BOOL)hidden
{
    self.barButtonView.badgeIndicatorView.hidden = hidden;
}

#pragma mark - badgeIndicatorView

- (PTBadgeIndicatorView *)badgeIndicatorView
{
    return self.barButtonView.badgeIndicatorView;
}

@end
