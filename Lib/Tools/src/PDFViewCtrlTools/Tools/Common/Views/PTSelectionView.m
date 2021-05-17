//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSelectionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTSelectionView ()

@property (nonatomic, copy) NSDictionary<NSNumber *, PTResizeWidgetView *> *resizeWidgets;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTSelectionView

- (void)PTSelectionView_commonInit
{
    NSMutableDictionary<NSNumber *, PTResizeWidgetView *> *resizeWidgets = [NSMutableDictionary dictionary];
    
    const PTResizeHandleLocation locations[] = {
        PTResizeHandleLocationTop,
        PTResizeHandleLocationTopLeft,
        PTResizeHandleLocationLeft,
        PTResizeHandleLocationBottomLeft,
        PTResizeHandleLocationBottom,
        PTResizeHandleLocationBottomRight,
        PTResizeHandleLocationRight,
        PTResizeHandleLocationTopRight,
    };
    const size_t locationCount = PT_C_ARRAY_SIZE(locations);
    for (int i = 0; i < locationCount; i++) {
        const PTResizeHandleLocation location = locations[i];
        
        PTResizeWidgetView *resizeWidget = [[PTResizeWidgetView alloc] init];
        resizeWidget.location = location;
        
        resizeWidget.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:resizeWidget];
        
        resizeWidgets[@(location)] = resizeWidget;
    }
    
    _resizeWidgets = [resizeWidgets copy];
    
    // Schedule constraints load.
    [self setNeedsUpdateConstraints];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PTSelectionView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTSelectionView_commonInit];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    NSMutableArray<NSLayoutConstraint *> *resizeWidgetConstraints = [NSMutableArray array];
    for (PTResizeWidgetView *resizeWidget in self.resizeWidgets.allValues) {
        NSArray<NSLayoutConstraint *> *constraints = [self constraintsForResizeWidget:resizeWidget];
        if (constraints.count > 0) {
            [resizeWidgetConstraints addObjectsFromArray:constraints];
        }
    }
    
    if (resizeWidgetConstraints.count > 0) {
        [NSLayoutConstraint activateConstraints:resizeWidgetConstraints];
    }
}

- (NSArray<NSLayoutConstraint *> *)constraintsForResizeWidget:(PTResizeWidgetView *)resizeWidget
{
    switch (resizeWidget.location) {
        case PTResizeHandleLocationTop:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.topAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            ];
        case PTResizeHandleLocationTopLeft:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.topAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.leftAnchor],
            ];
        case PTResizeHandleLocationLeft:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.leftAnchor],
            ];
        case PTResizeHandleLocationBottomLeft:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.bottomAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.leftAnchor],
            ];
        case PTResizeHandleLocationBottom:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.bottomAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            ];
        case PTResizeHandleLocationBottomRight:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.bottomAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.rightAnchor],
            ];
        case PTResizeHandleLocationRight:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.rightAnchor],
            ];
        case PTResizeHandleLocationTopRight:
            return @[
                [resizeWidget.centerYAnchor constraintEqualToAnchor:self.topAnchor],
                [resizeWidget.centerXAnchor constraintEqualToAnchor:self.rightAnchor],
            ];
        case PTResizeHandleLocationNone:
            return nil;
    }
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

- (PTResizeWidgetView *)resizeWidgetForLocation:(PTResizeHandleLocation)location
{
    return self.resizeWidgets[@(location)];
}

#pragma mark - Touches

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    const CGRect touchRect = CGRectInset(self.bounds,
                                         -(PTResizeWidgetView.length),
                                         -(PTResizeWidgetView.length));
    
    return CGRectContainsPoint(touchRect, point);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        // Don't handle touches in "empty" space of the selection view.
        return nil;
    }
    return view;
}

@end
