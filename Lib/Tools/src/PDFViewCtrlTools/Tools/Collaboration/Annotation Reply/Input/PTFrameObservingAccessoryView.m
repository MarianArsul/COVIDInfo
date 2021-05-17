//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFrameObservingAccessoryView.h"

#import "PTKeyValueObserving.h"

@interface PTFrameObservingAccessoryView ()

@property (nonatomic, strong, nullable) PTKeyValueObservation *centerObservation;

@end

@implementation PTFrameObservingAccessoryView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

- (void)setHeight:(CGFloat)height
{
    _height = height;
    
    [self invalidateIntrinsicContentSize];
}

#pragma mark - View lifecycle

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    if (self.superview) {
        [self stopObservingView:self.superview];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        [self startObservingView:self.superview];
    }
}

#pragma mark - Observations

- (void)startObservingView:(UIView *)view
{
    // Observe all of the geometry-related properties on the view's layer.
    // NOTE: These properties are guaranteed to be KVO compliant by CALayer.h.
    NSArray<NSString *> *keyPaths =
    @[
      PT_KEY_PATH(view, layer.frame),
      PT_KEY_PATH(view, layer.bounds),
      PT_KEY_PATH(view, layer.transform),
      PT_KEY_PATH(view, layer.position),
      PT_KEY_PATH(view, layer.zPosition),
      PT_KEY_PATH(view, layer.anchorPoint),
      PT_KEY_PATH(view, layer.anchorPointZ),
      ];
    
    for (NSString *keyPath in keyPaths) {
        [self pt_observeObject:view
                    forKeyPath:keyPath
                      selector:@selector(viewGeometryDidChange:)];
    }
}

- (void)stopObservingView:(UIView *)view
{
    [view pt_removeObserver:self];
}

#pragma mark Geometry

- (void)viewGeometryDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.superview) {
        return;
    }
    
    // Convert view's frame to window coordinates.
    CGRect frame = [self.superview convertRect:self.frame toView:nil];
    
    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(frameObservingAccessoryView:frameDidChange:)]) {
        [self.delegate frameObservingAccessoryView:self frameDidChange:frame];
    }
}

@end
