//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDocumentSliderViewController.h"

#import "PTKeyValueObserving.h"
#import "PTPassthroughView.h"
#import "PTTimer.h"

#include <tgmath.h>

// Default UIScrollView scroll indicator animation duration.
#define PT_SLIDER_ANIMATION_DURATION (0.25)

NS_ASSUME_NONNULL_BEGIN

@interface PTDocumentSliderViewController () <UIGestureRecognizerDelegate>
{
    BOOL _needsUpdateSliderConstraints;
}

@property (nonatomic, readwrite) PTDocumentSlider *slider;
@property (nonatomic, copy, nullable) NSArray<NSLayoutConstraint *> *sliderConstraints;
@property (nonatomic) NSUInteger activeSliderAnimationCount;

@property (nonatomic, nullable) UILayoutGuide *sliderInsetsLayoutGuide;

@property (nonatomic, nullable) PTTimer *sliderHidingTimer;

@end

NS_ASSUME_NONNULL_END

@implementation PTDocumentSliderViewController

- (void)PTDocumentSliderViewController_commonInit
{
    _sliderHidden = YES;
    
    _horizontalSliderInsets = UIEdgeInsetsMake(2, 4, 2, 4);
    _verticalSliderInsets = UIEdgeInsetsMake(4, 2, 4, 2);
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self PTDocumentSliderViewController_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PTDocumentSliderViewController_commonInit];
    }
    return self;
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super init];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
    }
    return self;
}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

- (void)loadView
{
    // Use a passthrough view for this view controller to allow "unhandled" touches (not on any
    // subview) to be passed to the views behind this view (controller).
    self.view = [[PTPassthroughView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.slider = [[PTDocumentSlider alloc] init];
    self.slider.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.slider addTarget:self
                    action:@selector(sliderValueChanged:)
          forControlEvents:(UIControlEventValueChanged)];
    
    [self.slider addTarget:self
                    action:@selector(sliderDidEndTracking:)
          forControlEvents:(UIControlEventTouchUpInside |
                            UIControlEventTouchUpOutside)];
    
    self.slider.accessibilityIdentifier = PT_SELF_KEY(slider);
        
    [self.view addSubview:self.slider];
    
    self.slider.alpha = ([self isSliderHidden]) ? 0.0 : 1.0;
    self.slider.hidden = [self isSliderHidden];
    
    [self setNeedsUpdateSliderConstraints];
}

#pragma mark - Constraints

- (void)setNeedsUpdateSliderConstraints
{
    _needsUpdateSliderConstraints = YES;
    [self.view setNeedsUpdateConstraints];
}

- (void)loadSliderInsetsLayoutGuide
{
    UILayoutGuide *layoutGuide = [[UILayoutGuide alloc] init];
    layoutGuide.identifier = PT_SELF_KEY(sliderInsetsLayoutGuide);
    
    [self.view addLayoutGuide:layoutGuide];
    
    id<PTLayoutAnchorContainer> anchorContainer = nil;
    if (@available(iOS 11.0, *)) {
        anchorContainer = self.view.safeAreaLayoutGuide;
    } else {
        anchorContainer = self.view;
    }
    
    if ([self.pdfViewCtrl pagePresentationModeIsContinuous]) {
        const UIEdgeInsets insets = self.verticalSliderInsets;
        
        [NSLayoutConstraint activateConstraints:@[
            [layoutGuide.topAnchor constraintEqualToAnchor:anchorContainer.topAnchor
                                                  constant:insets.top],
            [layoutGuide.trailingAnchor constraintEqualToAnchor:anchorContainer.trailingAnchor
                                                       constant:-insets.right],
            [layoutGuide.bottomAnchor constraintEqualToAnchor:anchorContainer.bottomAnchor
                                                     constant:-insets.bottom],
        ]];
    } else {
        const UIEdgeInsets insets = self.horizontalSliderInsets;
        
        [NSLayoutConstraint activateConstraints:@[
            [layoutGuide.leadingAnchor constraintEqualToAnchor:anchorContainer.leadingAnchor
                                                      constant:insets.left],
            [layoutGuide.bottomAnchor constraintEqualToAnchor:anchorContainer.bottomAnchor
                                                     constant:insets.bottom],
            [layoutGuide.trailingAnchor constraintEqualToAnchor:anchorContainer.trailingAnchor constant:-insets.right],
        ]];
    }
    
    self.sliderInsetsLayoutGuide = layoutGuide;
}

- (void)updateSliderConstraints
{
    if (self.sliderConstraints) {
        [NSLayoutConstraint deactivateConstraints:self.sliderConstraints];
        self.sliderConstraints = nil;
    }
    
    if (self.sliderInsetsLayoutGuide) {
        [self.view removeLayoutGuide:self.sliderInsetsLayoutGuide];
        self.sliderInsetsLayoutGuide = nil;
    }
    
    [self loadSliderInsetsLayoutGuide];
    
    UILayoutGuide *layoutGuide = self.sliderInsetsLayoutGuide;
    
    if ([self.pdfViewCtrl pagePresentationModeIsContinuous]) {
        self.sliderConstraints = @[
            [self.slider.topAnchor constraintEqualToAnchor:layoutGuide.topAnchor],
            [self.slider.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor],
            [self.slider.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor],
        ];
    } else {
        self.sliderConstraints = @[
            [self.slider.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor],
            [self.slider.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor],
            [self.slider.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor],
        ];
    }
    
    if (self.sliderConstraints) {
        [NSLayoutConstraint activateConstraints:self.sliderConstraints];
    }
}

- (void)updateViewConstraints
{
    if (_needsUpdateSliderConstraints) {
        [self updateSliderConstraints];
        
        _needsUpdateSliderConstraints = NO;
    }
    // Call super implementation as final step.
    [super updateViewConstraints];
}

#pragma mark - View controller containment

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if (!parent) {
        self.pdfViewCtrl.contentScrollView.showsVerticalScrollIndicator = YES;
        self.pdfViewCtrl.pagingScrollView.showsHorizontalScrollIndicator = YES;
    }
}

#pragma mark - Appearance

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.viewIfLoaded.window) {
        [self beginObservingPDFViewCtrl:self.pdfViewCtrl];
    }
    
    [self updateScrollingDirection];
    
    // Update slider value.
    if (self.pdfViewCtrl.currentPage > 0 &&
        self.pdfViewCtrl.pageCount > 0) {
        self.slider.value = (((CGFloat)self.pdfViewCtrl.currentPage - 1) / (self.pdfViewCtrl.pageCount - 1));
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self endObservingPDFViewCtrl:self.pdfViewCtrl];
}

#pragma mark - PDFViewCtrl

- (void)setPdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    [self endObservingPDFViewCtrl:_pdfViewCtrl];
    
    _pdfViewCtrl = pdfViewCtrl;
    
    [self updateScrollingDirection];
    
    if (self.viewIfLoaded.window) {
        [self beginObservingPDFViewCtrl:pdfViewCtrl];
    }
}

- (void)beginObservingPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    if (!pdfViewCtrl) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    // Start observing PDFViewCtrl notifications.
    [center addObserver:self
               selector:@selector(pdfViewCtrlPageDidChangeNotification:)
                   name:PTPDFViewCtrlPageDidChangeNotification
                 object:pdfViewCtrl];
    
    [center addObserver:self
               selector:@selector(pdfViewCtrlPageCountDidChangeNotification:)
                   name:PTPDFViewCtrlStreamingEventNotification
                 object:pdfViewCtrl];
    
    [center addObserver:self
               selector:@selector(pdfViewCtrlPagePresentationModeDidChange:)
                   name:PTPDFViewCtrlPagePresentationModeDidChangeNotification
                 object:pdfViewCtrl];
    
    [self pt_observeObject:pdfViewCtrl.contentScrollView
                forKeyPath:PT_KEY(pdfViewCtrl.contentScrollView, contentOffset)
                  selector:@selector(pdfViewCtrlContentOffsetDidChange:)];
    
    [self pt_observeObject:pdfViewCtrl.pagingScrollView
                forKeyPath:PT_KEY(pdfViewCtrl.pagingScrollView, contentOffset)
                  selector:@selector(pdfViewCtrlPagingOffsetDidChange:)];
    
}

- (void)endObservingPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    if (!pdfViewCtrl) {
        return;
    }
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    // Stop observing PDFViewCtrl notifications.
    [center removeObserver:self
                      name:PTPDFViewCtrlPageDidChangeNotification
                    object:pdfViewCtrl];
    
    [center removeObserver:self
                      name:PTPDFViewCtrlStreamingEventNotification
                    object:pdfViewCtrl];
    
    [center removeObserver:self
                      name:PTPDFViewCtrlPagePresentationModeDidChangeNotification
                    object:pdfViewCtrl];
    
    [self pt_removeObservationsForObject:pdfViewCtrl.contentScrollView
                                 keyPath:PT_KEY(pdfViewCtrl.contentScrollView, contentOffset)];
}

#pragma mark Notifications

- (void)pdfViewCtrlPageDidChangeNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    if ([self.slider isTracking]) {
        return;
    }
    
    NSNumber *pageNumberValue = ((NSNumber *)notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]);
    
    const int pageNumber = pageNumberValue.intValue;
    
    // Update slider value for non-continuous page presentation modes.
    // For continuous page presentation modes, the value is updated continuously while
    // scrolling.
    if (![self.pdfViewCtrl pagePresentationModeIsContinuous]
        || !([self.pdfViewCtrl.contentScrollView isDragging] &&
             [self.pdfViewCtrl.contentScrollView isDecelerating])) {
        self.slider.value = (((CGFloat)pageNumber - 1) / (self.pdfViewCtrl.pageCount - 1));
    }
    
    // Show slider on page change.
    [self setSliderHidden:NO animated:YES];
    
    if (![self.slider isTracking]) {
        [self restartSliderHidingTimer];
    }
}

- (void)pdfViewCtrlPageCountDidChangeNotification:(NSNotification *) notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }

    if ([self.slider isTracking]) {
        return;
    }

    
    self.slider.value = (((CGFloat)self.pdfViewCtrl.currentPage - 1) / (self.pdfViewCtrl.pageCount - 1));
}

- (void)pdfViewCtrlPagePresentationModeDidChange:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    [self updateScrollingDirection];
}

-(void)pdfViewCtrlPagingOffsetDidChange:(PTKeyValueObservedChange *)change
{
    [self adjustCompression];
}

- (void)pdfViewCtrlContentOffsetDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.pdfViewCtrl.contentScrollView) {
        return;
    }
    
    if (![self.pdfViewCtrl pagePresentationModeIsContinuous]) {
        return;
    }
    
    // The slider should not be updated while an interactive zoom (pinch or double-tap) is occurring.
    // The content scroll view's zoomScale will be > 1.0 (zooming in) or < 1.0 (zooming out) during
    // the zoom.
    if (self.pdfViewCtrl.contentScrollView.zoomScale != 1.0) {
        return;
    }
    
    if ([self.slider isTracking]) {
        return;
    }
    
    const double scrollPosition = [self.pdfViewCtrl GetVScrollPos];
    const double canvasHeight = self.pdfViewCtrl.canvasHeight;
    
    CGRect viewportRect = self.pdfViewCtrl.bounds;
    if (@available(iOS 11.0, *)) {
        viewportRect = UIEdgeInsetsInsetRect(viewportRect, self.pdfViewCtrl.safeAreaInsets);
    }
    const CGFloat viewportHeight = CGRectGetHeight(viewportRect);
    
    self.slider.value = scrollPosition / (canvasHeight - viewportHeight);
    
    
    [self adjustCompression];
    

    
    // Show slider *without* animation (default UIScrollView behavior).
    [self setSliderHidden:NO animated:NO];
    
    // Restart the timer so that it actually fires when scrolling stops.
    [self restartSliderHidingTimer];
}

#pragma mark - Slider

-(void)adjustCompression
{
    CGFloat maximumOffset;
    CGFloat currentOffset;
    
    if( self.slider.axis == UILayoutConstraintAxisVertical )
    {
        UIScrollView* scrollView = self.pdfViewCtrl.contentScrollView;
        // vertical
        maximumOffset = scrollView.contentSize.height - CGRectGetHeight(scrollView.frame);
        currentOffset = scrollView.contentOffset.y;
    }
    else
    {
        UIScrollView* scrollView = self.pdfViewCtrl.pagingScrollView;
    // horizontal
        maximumOffset = scrollView.contentSize.width - CGRectGetWidth(scrollView.frame);
        currentOffset = scrollView.contentOffset.x;
    }

    
    CGFloat compress = 1.0f;
    CGFloat amount = 1.0f;
    CGFloat maxCompress = 0.5;
    CGFloat maxScrollOffset = 400;
    
    
    if( currentOffset > maximumOffset || currentOffset < 0.0f )
    {
        if( currentOffset > maximumOffset )
        {
            amount = currentOffset - maximumOffset;
        }
        if( currentOffset < 0.0f )
        {
            amount = ABS(currentOffset);
        }
        
        compress = (1.0f-MIN(maxScrollOffset, amount)/maxScrollOffset);
        compress = MAX(compress, maxCompress);
    }
    
    self.slider.compress = compress;
}

- (void)updateScrollingDirection
{
    // Update slider axis for page presentation mode.
    if ([self.pdfViewCtrl pagePresentationModeIsContinuous]) {
        self.slider.axis = UILayoutConstraintAxisVertical;
        
        self.pdfViewCtrl.contentScrollView.showsVerticalScrollIndicator = NO;
        self.pdfViewCtrl.pagingScrollView.showsHorizontalScrollIndicator = YES;
    } else {
        self.slider.axis = UILayoutConstraintAxisHorizontal;
        
        self.pdfViewCtrl.contentScrollView.showsVerticalScrollIndicator = YES;
        self.pdfViewCtrl.pagingScrollView.showsHorizontalScrollIndicator = NO;
    }
    
    [self setNeedsUpdateSliderConstraints];
}

- (void)sliderValueChanged:(id)sender
{
    if ([self.pdfViewCtrl pagePresentationModeIsContinuous]) {
        const double canvasHeight = self.pdfViewCtrl.canvasHeight;
        
        CGRect viewportRect = self.pdfViewCtrl.bounds;
        if (@available(iOS 11.0, *)) {
            viewportRect = UIEdgeInsetsInsetRect(viewportRect, self.pdfViewCtrl.safeAreaInsets);
        }
        const CGFloat viewportHeight = CGRectGetHeight(viewportRect);
                
        const double scrollRange = fmax(0, canvasHeight - viewportHeight);
        
        const double scrollPosition = scrollRange * self.slider.value;
        
        NSAssert(scrollPosition >= 0,
                 @"Scroll position must be >= 0");
        NSAssert(scrollPosition <= canvasHeight,
                 @"Scroll position must be <= canvas height");
        
        // Update vertical contentOffset.
        // NOTE: Animating the change results in a lot of scroll lag.
        CGPoint contentOffset = self.pdfViewCtrl.contentScrollView.contentOffset;
        contentOffset.y = scrollPosition;
        self.pdfViewCtrl.contentScrollView.contentOffset = contentOffset;
    } else {
        const int pageNumber = 1 + round((self.pdfViewCtrl.pageCount - 1) * self.slider.value);
        
        if (pageNumber != self.pdfViewCtrl.currentPage) {
            self.pdfViewCtrl.currentPage = pageNumber;
        }
    }
}

- (void)sliderDidEndTracking:(id)sender
{
    [self restartSliderHidingTimer];
}

#pragma mark Hidden

+ (BOOL)automaticallyNotifiesObserversOfSliderHidden
{
    NSAssert(PT_CLASS_KEY(PTDocumentSliderViewController, sliderHidden) != nil, NSUndefinedKeyException);
    return NO;
}

- (void)setSliderHidden:(BOOL)hidden
{
    [self setSliderHidden:hidden animated:NO];
}

- (void)setSliderHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_sliderHidden == hidden) {
        // No change.
        return;
    }
    
    [self willChangeValueForKey:PT_SELF_KEY(sliderHidden)];
    
    if (self.activeSliderAnimationCount == 0) {
        if (!hidden) {
            self.slider.hidden = NO;
        }
    }
    
    _sliderHidden = hidden;
    
    const NSTimeInterval duration = (animated) ? PT_SLIDER_ANIMATION_DURATION : 0.0;
    const UIViewAnimationOptions options = (UIViewAnimationOptionBeginFromCurrentState);
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.slider.alpha = (hidden) ? 0.0 : 1.0;
    } completion:^(BOOL finished) {
        self.activeSliderAnimationCount--;
        
        if (self.activeSliderAnimationCount == 0) {
            if ([self isSliderHidden]) {
                self.slider.hidden = YES;
            }
        }
    }];
    self.activeSliderAnimationCount++;
    
    [self didChangeValueForKey:PT_SELF_KEY(sliderHidden)];
}

#pragma mark Timer

- (void)restartSliderHidingTimer
{
    if (self.sliderHidingTimer) {
        [self stopSliderHidingTimer];
    }
    
    self.sliderHidingTimer = [PTTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(hideSliderFromTimer:)
                                                            userInfo:nil
                                                             repeats:NO];
}

- (void)hideSliderFromTimer:(NSTimer *)timer
{
    if (timer != self.sliderHidingTimer.timer) {
        return;
    }
    
    self.sliderHidingTimer = nil;

    if (![self.slider isTracking]) {
        [self setSliderHidden:YES animated:YES];
    }
}

- (void)stopSliderHidingTimer
{
    [self.sliderHidingTimer invalidate];
    self.sliderHidingTimer = nil;
}

@end
