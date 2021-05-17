//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTThumbnailSliderViewController.h"

#import "ToolsDefines.h"
#import "PTResizingToolbar.h"
#import "PTToolsUtil.h"

#import "NSLayoutConstraint+PTPriority.h"

#import <tgmath.h>

static const NSTimeInterval PTThumbnailSliderViewController_thumbViewHideDuration = 0.2;

static const CGFloat PTThumbnailSliderViewController_shadowExtent = 64.0;

// View that adjusts its shadow path for its bounds.
@interface PTThumbnailShadowView : UIView
@end

@implementation PTThumbnailShadowView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Update shadow path for bounds.
    CGRect shadowRect = CGRectInset(self.bounds,
                                    -PTThumbnailSliderViewController_shadowExtent,
                                    -PTThumbnailSliderViewController_shadowExtent);
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = shadowPath.CGPath;
}

@end

@interface PTThumbnailSliderViewController () <UIToolbarDelegate>

// Re-declare as readwrite internally.
@property (nonatomic, readwrite, strong) UIToolbar *toolbar;
@property (nonatomic, readwrite, strong) UISlider *slider;
@property (nonatomic, readwrite, strong) PTThumbnailSliderView *thumbnailSliderView;

@property (nonatomic, strong) PTResizingToolbar *resizingToolbar;

@property (nonatomic, assign) NSUInteger activeSliderTransitionCount;

@property (nonatomic, strong) PTThumbnailShadowView *thumbnailContainer;

@property (nonatomic, strong) UIView *labelBackgroundView;
@property (nonatomic, strong) UILabel *pageLabel;

@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *thumbnailViewAspectRatioConstraint;

@property (nonatomic, assign) int pageNumber;

@property (nonatomic, readonly, strong) UIColor *pageBackgroundColor;

@end

@implementation PTThumbnailSliderViewController

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pdfViewCtrl = pdfViewCtrl;
    }
    return self;
}

- (instancetype)initWithToolManager:(PTToolManager *)toolManager
{
    self = [self initWithPDFViewCtrl:toolManager.pdfViewCtrl];
    if (self) {
        _toolManager = toolManager;
    }
    return self;
}

- (UIImage *)GetThumbnailImageWithProperRotation:(UIImage *)thumbnail
{
	PTRotate rotation = [self.pdfViewCtrl GetRotation];
	UIImageOrientation orientation = UIImageOrientationUp;
	UIImageOrientation originalOrientation = thumbnail.imageOrientation;
	
	switch (rotation) {
		case e_pt0:
			orientation = UIImageOrientationUp;
			break;
		case e_pt90:
			orientation = UIImageOrientationRight;
			break;
		case e_pt180:
			orientation = UIImageOrientationDown;
			break;
		case e_pt270:
			orientation = UIImageOrientationLeft;
			break;
			
		default:
			break;
	}
	
	if (orientation != originalOrientation) {
		return [UIImage imageWithCGImage:thumbnail.CGImage scale:1.0 orientation:orientation];
	} else {
		return thumbnail;
	}
}

- (UIImage *)imageWithColor:(UIColor *)color rect:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIColor *)pageBackgroundColor
{
    PTColorPostProcessMode mode = [self.pdfViewCtrl GetColorPostProcessMode];
    if (mode == e_ptpostprocess_night_mode) {
        return UIColor.blackColor;
    }
    return UIColor.whiteColor;
}

- (void)setSliderValue:(int)pageNumber
{
    int pageCount = [self.pdfViewCtrl GetPageCount];
	if (pageNumber > 0 && pageCount > 1 && ![self.slider isTracking]) {
        self.slider.value = ((float)(pageNumber - 1)) / ((float)(pageCount - 1));
    }
}

- (void)setPage:(int)pageNumber
{
	[self setSliderValue:pageNumber];
	
	if ([self.pdfViewCtrl GetDoc] && ![self.slider isTracking]) {
        [self.pdfViewCtrl SetCurrentPage:pageNumber];
        [self.pdfViewCtrl hideSelectedTextHighlights];
    }
}

- (BOOL)requestThumbnailForPageNumber:(int)pageNumber
{
    @try {
        [self.pdfViewCtrl GetThumbAsync:pageNumber completion:^(UIImage *image) {
            [self setThumbnail:image forPage:pageNumber];
        }];
    } @catch (NSException *exception) {
        return NO;
    }
    
    return YES;
}

- (void)setThumbnail:(UIImage *)image forPage:(int)pageNum
{
    if (self.pageNumber == pageNum && (self.thumbnailView && self.thumbnailView.tag != self.pageNumber)) {
        if (!image) {
            // Show white placeholder image.
            image = [self imageWithColor:self.pageBackgroundColor rect:CGRectMake(0, 0, self.thumbnailView.frame.size.width, self.thumbnailView.frame.size.height)];
        }

        UIImage* rotatedImage = [self GetThumbnailImageWithProperRotation:image];

        self.thumbnailView.image = rotatedImage; // Don't call -(void)sizeToFit.
        self.thumbnailView.tag = pageNum;
        
        [self updateAspectRatioConstraintWithImage:rotatedImage];
    }
}

#pragma mark - UISlider events

- (void)sliderTouchDown:(UISlider *)slider
{
    // Notify delegate.
    if ([self.delegate respondsToSelector:@selector(thumbnailSliderViewInUse:)]) {
        [self.delegate thumbnailSliderViewInUse:self];
    }
    
    if (!self.thumbnailContainer) {
        [self loadThumbView];
    } else {
        // Remove from PDFViewCtrl to break constraints. Otherwise, the constraints will be added
        // more than once.
        [self.thumbnailContainer removeFromSuperview];
    }
    
    if (![self requestThumbnailForPageNumber:self.pageNumber]) {
        return;
    }
    
    self.thumbnailContainer.alpha = 1;
    self.thumbnailContainer.backgroundColor = self.pageBackgroundColor;
    
    self.pageLabel.text = [NSString stringWithFormat:@"%d", self.pageNumber];
    
    self.thumbnailView.image = nil;
    self.thumbnailView.tag = 0; // No thumbnail loaded.
    
    // Add thumb view to PDFViewCtrl.
    [self.pdfViewCtrl addSubview:self.thumbnailContainer];
    
    // Create and activate constraints between thumb view, PDFViewCtrl, and the view controller's views.
    CGFloat scale = (UIScreen.mainScreen.scale / 8.0);
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.thumbnailContainer.centerXAnchor constraintEqualToAnchor:self.pdfViewCtrl.centerXAnchor],
       [self.thumbnailContainer.bottomAnchor constraintEqualToAnchor:self.view.topAnchor constant:-8],
       [self.thumbnailContainer.widthAnchor constraintLessThanOrEqualToAnchor:self.pdfViewCtrl.widthAnchor multiplier:scale],
       [self.thumbnailContainer.heightAnchor constraintLessThanOrEqualToAnchor:self.pdfViewCtrl.heightAnchor multiplier:scale],
       ]];
    
    [NSLayoutConstraint pt_activateConstraints:
     @[
       [self.thumbnailContainer.widthAnchor constraintEqualToAnchor:self.pdfViewCtrl.widthAnchor multiplier:scale],
       [self.thumbnailContainer.heightAnchor constraintEqualToAnchor:self.pdfViewCtrl.heightAnchor multiplier:scale],
       ] withPriority:UILayoutPriorityDefaultHigh];
}

- (void)sliderValueChanged:(UISlider *)slider
{
	int pageNumber = 1 + roundf(([self.pdfViewCtrl GetPageCount] - 1) * self.slider.value);
	if( pageNumber != self.pageNumber )
	{
        if (![self requestThumbnailForPageNumber:pageNumber]) {
            return;
        }
        
		self.pageNumber = pageNumber;
        
		self.pageLabel.text = [NSString stringWithFormat:@"%d", self.pageNumber];
        
        self.thumbnailView.image = nil;
        self.thumbnailView.tag = 0; // No thumbnail loaded.
	}
}

- (void)sliderTouchUp:(UISlider *)slider
{
	[self.pdfViewCtrl CancelAllThumbRequests];
	
	int pageNumber = 1 + roundf(([self.pdfViewCtrl GetPageCount] - 1) * self.slider.value);
	[self setPage:pageNumber];
    
    [UIView animateWithDuration:PTThumbnailSliderViewController_thumbViewHideDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // Animate alpha: requires UIViewAnimationOptionBeginFromCurrentState.
        self.thumbnailContainer.alpha = 0;
    } completion:^(BOOL finished) {
        self.activeSliderTransitionCount--;
        
        // Animation post-amble.
        if (self.activeSliderTransitionCount == 0) {
            if (![self.slider isTracking]) {
                // Hide and reset thumb view.
                [self.thumbnailContainer removeFromSuperview];
                self.thumbnailContainer.alpha = 1;
            }
        }
    }];
    
    self.activeSliderTransitionCount++;
    
    // Notify delegate.
    if ([self.delegate respondsToSelector:@selector(thumbnailSliderViewInUse:)]) {
		[self.delegate thumbnailSliderViewNotInUse:self];
    }
}

#pragma mark - Layout

- (void)updateAspectRatioConstraintWithImage:(UIImage *)image
{
    self.thumbnailViewAspectRatioConstraint.active = NO;
    
    CGSize size = image.size;
    CGFloat aspectRatio = (size.height != 0.0) ? fabs(size.width / size.height) : 0.0;
    
    self.thumbnailViewAspectRatioConstraint =
    [self.thumbnailView.widthAnchor constraintEqualToAnchor:self.thumbnailView.heightAnchor multiplier:aspectRatio];
    
    self.thumbnailViewAspectRatioConstraint.active = YES;
}

- (void)loadThumbView
{
    self.thumbnailContainer = [[PTThumbnailShadowView alloc] init];
    self.thumbnailContainer.backgroundColor = self.pageBackgroundColor;
    
    self.thumbnailContainer.layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
    
    // Show diffuse drop shadow under thumbnail.
    self.thumbnailContainer.layer.masksToBounds = NO;
    self.thumbnailContainer.layer.shadowColor = UIColor.blackColor.CGColor;
    self.thumbnailContainer.layer.shadowOffset = CGSizeMake(0.0, 0.0); // Center shadow under view.
    self.thumbnailContainer.layer.shadowOpacity = 0.1;
    self.thumbnailContainer.layer.shadowRadius = PTThumbnailSliderViewController_shadowExtent;
    
    self.thumbnailView = [[UIImageView alloc] init];
    self.thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnailView.tag = 0; // No thumbnail loaded.
    
    [self.thumbnailContainer addSubview:self.thumbnailView];
    
    self.labelBackgroundView = [[UIView alloc] init];
    self.labelBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.labelBackgroundView.layer.cornerRadius = 4.0;
    self.labelBackgroundView.layer.masksToBounds = YES;
    self.labelBackgroundView.layoutMargins = UIEdgeInsetsMake(2, 10, 2, 10);
    
    [self.thumbnailContainer addSubview:self.labelBackgroundView];
    
    self.pageLabel = [[UILabel alloc] init];
    self.pageLabel.textAlignment = NSTextAlignmentCenter;
    self.pageLabel.textColor = UIColor.whiteColor;
    self.pageLabel.adjustsFontSizeToFitWidth = YES;
    
    [self.labelBackgroundView addSubview:self.pageLabel];
    
    if (@available(iOS 11.0, *)) {
        self.thumbnailContainer.insetsLayoutMarginsFromSafeArea = NO;
        self.thumbnailView.insetsLayoutMarginsFromSafeArea = NO;
        self.labelBackgroundView.insetsLayoutMarginsFromSafeArea = NO;
    }
    
    self.thumbnailContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
    self.labelBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Aspect fit setup.
    self.thumbnailViewAspectRatioConstraint =
    [self.thumbnailView.widthAnchor constraintEqualToAnchor:self.thumbnailView.heightAnchor];
    
    [NSLayoutConstraint activateConstraints:
     @[
       (self.thumbnailViewAspectRatioConstraint),
       [self.thumbnailView.centerXAnchor constraintEqualToAnchor:self.thumbnailContainer.centerXAnchor],
       [self.thumbnailView.centerYAnchor constraintEqualToAnchor:self.thumbnailContainer.centerYAnchor],
       [self.thumbnailView.widthAnchor constraintLessThanOrEqualToAnchor:self.thumbnailContainer.widthAnchor],
       [self.thumbnailView.heightAnchor constraintLessThanOrEqualToAnchor:self.thumbnailContainer.heightAnchor],
       ]];
    
    // Priority for the optional aspect fit constraints. The +1 is required to prefer fitting the thumbnail
    // image view instead of the thumbnail container view's max size.
    UILayoutPriority priority = UILayoutPriorityDefaultHigh + 1;
    
    [NSLayoutConstraint pt_activateConstraints:
     @[
       [self.thumbnailView.widthAnchor constraintEqualToAnchor:self.thumbnailContainer.widthAnchor],
       [self.thumbnailView.heightAnchor constraintEqualToAnchor:self.thumbnailContainer.heightAnchor],
       ] withPriority:priority];
    
    [NSLayoutConstraint activateConstraints:
     @[
        [self.labelBackgroundView.centerXAnchor constraintEqualToAnchor:self.thumbnailContainer.centerXAnchor],
        [self.labelBackgroundView.bottomAnchor constraintEqualToAnchor:self.thumbnailView.layoutMarginsGuide.bottomAnchor],
        
        [self.pageLabel.centerXAnchor constraintEqualToAnchor:self.pageLabel.superview.layoutMarginsGuide.centerXAnchor],
        [self.pageLabel.centerYAnchor constraintEqualToAnchor:self.pageLabel.superview.centerYAnchor],
        [self.pageLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.pageLabel.superview.layoutMarginsGuide.widthAnchor],
        [self.pageLabel.heightAnchor constraintLessThanOrEqualToAnchor:self.pageLabel.superview.layoutMarginsGuide.heightAnchor],
       ]];
}

#pragma mark - Views

- (UIToolbar *)toolbar
{
    if (!self.resizingToolbar) {
        [self loadViewIfNeeded];
        
        NSAssert(self.resizingToolbar != nil,
                 @"Failed to load %@", PT_CLASS_KEY(PTThumbnailSliderViewController, toolbar));
    }
    return self.resizingToolbar;
}

@synthesize slider = _slider;

- (UISlider *)slider
{
    if (!_slider) {
        [self loadViewIfNeeded];
        
        NSAssert(_slider != nil,
                 @"Failed to load %@", PT_CLASS_KEY(PTThumbnailSliderViewController, slider));
    }
    return _slider;
}

@synthesize thumbnailSliderView = _thumbnailSliderView;

- (PTThumbnailSliderView *)thumbnailSliderView
{
    if (!_thumbnailSliderView) {
        [self loadViewIfNeeded];
        
        NSAssert(_thumbnailSliderView != nil,
                 @"Failed to load %@", PT_CLASS_KEY(PTThumbnailSliderViewController, thumbnailSliderView));
    }
    return _thumbnailSliderView;
}

#pragma mark - View Controller lifecycle

// NOTE: Do *not* call super implementation.
- (void)loadView
{
    self.resizingToolbar = [[PTResizingToolbar alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.resizingToolbar.delegate = self;
        
    self.view = self.resizingToolbar;
    
    // Create and add subviews.
    self.slider = [[UISlider alloc] init];
    [self.slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:(UIControlEventTouchUpOutside | UIControlEventTouchUpInside)];
    [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        
    self.thumbnailSliderView = [[PTThumbnailSliderView allocOverridden] initWithToolManager:self.toolManager];

    self.resizingToolbar.contentView = self.thumbnailSliderView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setPage:[self.pdfViewCtrl GetCurrentPage]];
    
    // Start observing PDFViewCtrl notifications.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlPageDidChangeNotification:)
                                               name:PTPDFViewCtrlPageDidChangeNotification
                                             object:self.pdfViewCtrl];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(pdfViewCtrlPageCountDidChangeNotification:)
                                               name:PTPDFViewCtrlStreamingEventNotification
                                             object:self.pdfViewCtrl];

    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Stop observing PDFViewCtrl notifications.
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTPDFViewCtrlPageDidChangeNotification
                                                object:self.pdfViewCtrl];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:PTPDFViewCtrlStreamingEventNotification
                                                object:self.pdfViewCtrl];
}

#pragma mark - Content view

- (UIView *)contentView
{
    return self.resizingToolbar.contentView;
}

- (void)setContentView:(UIView *)contentView
{
    self.resizingToolbar.contentView = contentView;
}

#pragma mark - Tracking

- (BOOL)isTracking
{
    return [self.slider isTracking] || [self.thumbnailSliderView isTracking];
}

#pragma mark - Leading toolbar item(s)

- (UIBarButtonItem *)leadingToolbarItem
{
    return self.resizingToolbar.leadingItem;
}

- (void)setLeadingToolbarItem:(UIBarButtonItem *)leadingToolbarItem
{
    self.resizingToolbar.leadingItem = leadingToolbarItem;
}

- (NSArray<UIBarButtonItem *> *)leadingToolbarItems
{
    return self.resizingToolbar.leadingItems;
}

- (void)setLeadingToolbarItems:(NSArray<UIBarButtonItem *> *)leadingToolbarItems
{
    self.resizingToolbar.leadingItems = leadingToolbarItems;
}

#pragma mark - Trailing toolbar item(s)

- (UIBarButtonItem *)trailingToolbarItem
{
    return self.resizingToolbar.trailingItem;
}

- (void)setTrailingToolbarItem:(UIBarButtonItem *)trailingToolbarItem
{
    self.resizingToolbar.trailingItem = trailingToolbarItem;
}

- (NSArray<UIBarButtonItem *> *)trailingToolbarItems
{
    return self.resizingToolbar.trailingItems;
}

- (void)setTrailingToolbarItems:(NSArray<UIBarButtonItem *> *)trailingToolbarItems
{    
    self.resizingToolbar.trailingItems = trailingToolbarItems;
}

#pragma mark - Notification actions

- (void)pdfViewCtrlPageDidChangeNotification:(NSNotification *)notification
{
    if (notification.object != self.pdfViewCtrl) {
        return;
    }
    
    int currentPageNumber = ((NSNumber *) notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]).intValue;
    if (currentPageNumber == 0) {
        return;
    }
    
    [self setSliderValue:currentPageNumber];
}

-(void)pdfViewCtrlPageCountDidChangeNotification:(NSNotification *)notification
{
    [self setSliderValue:[self.pdfViewCtrl GetCurrentPage]];
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    // Extend toolbar background to its superview's bottom edge.
    return UIBarPositionBottom;
}

@end
