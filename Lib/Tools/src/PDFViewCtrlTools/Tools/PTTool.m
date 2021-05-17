//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTool.h"

#import "PTAnnotationStyleManager.h"
#import "PTCreateToolBase.h"
#import "PTFreeHandCreate.h"
#import "PTFreeTextCreate.h"
#import "PTNoteEditController.h"
#import "PTOverrides.h"
#import "PTPanTool.h"
#import "PTTextMarkupCreate.h"
#import "PTToolImages.h"
#import "PTToolsUtil.h"

#import "NSObject+PTAdditions.h"
#import "PTAnnot+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"
#import "UIView+PTAdditions.h"

#include <tgmath.h>

/**
 * The PTToolView is used to temporarily keep the tool's appearance
 * on screen after the tool itself has been destroyed.
 */
@interface PTToolView : UIImageView
@end

@implementation PTToolView
@end

@interface PTTool ()
{
    UILabel* m_pageNumberLabel;
    NSLayoutConstraint* m_pageNumberWidthConstraint;
    PTPDFPoint* m_screenPt;
    PTPDFPoint* m_pagePt;
    
    BOOL _needsLoadAnnotationStyle;
}

@property (nonatomic, strong, nullable) UIPanGestureRecognizer *panScaleGestureRecognizer;
@property (nonatomic, assign) CGPoint previousPanScaleTranslation;
@property (nonatomic, assign) BOOL multistrokeMode;

@end

@implementation PTTool

// Synthesize PTToolSwitching protocol properties.
@synthesize toolManager = _toolManager;
@synthesize annotationAuthor = _annotationAuthor;
@synthesize pdfViewCtrl = _pdfViewCtrl;

-(void)setPageIndicatorIsVisible:(BOOL)pageIndicatorIsVisibleValue
{
    m_pageNumberLabel.hidden = !pageIndicatorIsVisibleValue;
    _pageIndicatorIsVisible = pageIndicatorIsVisibleValue;
}

-(void)executeAction:(PTActionParameter*)action_param
{
    PTAction* action = [action_param GetAction];
    if([action IsValid])
    {
        PTActionType actionType = [action GetType];
        if(actionType == e_ptURI)
        {
            PTObj* sdfObj = [action GetSDFObj];
            if([sdfObj IsValid])
            {
                PTObj* uriObj = [sdfObj FindObj:@"URI"];
                if(uriObj != nil)
                {
                    NSString* uriDestination = [uriObj GetAsPDFText];
                    uriDestination = [PTLink GetNormalizedUrl:uriDestination];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [UIApplication.sharedApplication openURL:[NSURL URLWithString: uriDestination] options:@{} completionHandler:Nil];
                    });
                }
            }
        }
        else if(actionType == e_ptSubmitForm)
        {
            PTObj* filespec = [[action GetSDFObj] FindObj:@"F"];
            
            if( [filespec IsValid] )
            {
                PTObj* fsEntry = [filespec FindObj:@"FS"];
                if( [fsEntry IsValid] && [[fsEntry GetName] isEqualToString:@"URL"] )
                {
                    PTObj* urlObj = [filespec FindObj:@"F"];
                    if( [urlObj IsValid])
                    {
                        NSString* urlStr = [urlObj GetAsPDFText];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            [UIApplication.sharedApplication openURL:[NSURL URLWithString: urlStr] options:@{} completionHandler:Nil];
                        });
                    }
                }
            }

        }
        else if(actionType == e_ptGoTo)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                @try {
                    [self.pdfViewCtrl ExecuteActionWithActionParameter:action_param];
                } @catch (NSException *exception) {
                    
                }
            });
        }
        else
        {
            // Check if we can open a linked PDF.
            BOOL handled = NO;
            if (actionType == e_ptGoToR) {
                PTObj *obj = [[action GetSDFObj] FindObj:@"F"];
                if ([obj IsValid]) {
                    PTFileSpec *fileSpec = [[PTFileSpec alloc] initWithF:obj];
                    if ([fileSpec IsValid]) {
                        NSString *filePath = [fileSpec GetFilePath];
                        if (filePath.length > 0) {
                            handled = [self handleFileSelected:filePath];
                        }
                    }
                }
            }
            
            if (!handled) {
                [self.pdfViewCtrl ExecuteActionWithActionParameter:action_param];
            }
        }
    }
}

#pragma mark - <PTOverridable>

+ (instancetype)allocOverridden
{
    return [self alloc];
}

+ (instancetype)alloc
{
    // Get the overridden subclass for this class.
    Class overriddenClass = [PTOverrides overriddenClassForClass:self];
    if (overriddenClass) {
        return [overriddenClass alloc];
    }
    
    // Create an instance of this class normally.
    return [super alloc];
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _pdfViewCtrl = in_pdfViewCtrl;
        
        m_pagePt = [[PTPDFPoint alloc] init];
        m_screenPt = [[PTPDFPoint alloc] init];
        
        _needsLoadAnnotationStyle = YES;

        [self setUserInteractionEnabled:NO];
        
        [self setBackToPanToolAfterUse:YES];
		
        self.pageIndicatorIsVisible = YES;
        
        _allowZoom = YES;
		
		m_pageNumberLabel = [[UILabel alloc] init];
        m_pageNumberLabel.translatesAutoresizingMaskIntoConstraints = NO;
        m_pageNumberLabel.alpha = 0.0f;
        m_pageNumberLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        m_pageNumberLabel.backgroundColor = [UIColor blackColor];
        //m_pageNumberLabel.clipsToBounds = YES;
        //m_pageNumberLabel.layer.cornerRadius = 15.0f;
        m_pageNumberLabel.textAlignment = NSTextAlignmentCenter;
        m_pageNumberLabel.textColor = [UIColor whiteColor];
        m_pageNumberLabel.text = [NSString stringWithFormat:@"%d/%d", [self.pdfViewCtrl GetCurrentPage], [self.pdfViewCtrl GetPageCount]];
        
        // no longer used in sample app due to page slider
        // uncomment lines to add a page indicator in thex
        // upper left corner.
         [self.pdfViewCtrl addSubview:m_pageNumberLabel];
		
		[self positionPageNumberLabel];
		
		self.textMarkupAdobeHack = YES;
        
		self.defaultClass = [PTPanTool class];
		
        // Pan-scale gesture.
        self.panScaleGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        self.panScaleGestureRecognizer.maximumNumberOfTouches = 1;
        self.panScaleGestureRecognizer.delegate = self;
        
        [self.panScaleGestureRecognizer addTarget:self
                                           action:@selector(handlePanScaleGesture:)];
                
        self.previousPanScaleTranslation = CGPointZero;
    }
    return self;
}

- (void)positionPageNumberLabel
{

	CGSize size = [UIScreen mainScreen].bounds.size;
	if( UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) )
	{
		double width = size.width;
		size.width = size.height;
		size.height = width;
	}
    
    
    if( m_pageNumberLabel.superview )
    {
        CGSize textSize = [m_pageNumberLabel.text boundingRectWithSize:CGSizeMake(10000, 100) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:18] } context:nil].size;
    
        if( m_pageNumberWidthConstraint )
        {
            // get rid of old, possibly incorrect width constraint
            [m_pageNumberLabel removeConstraint:m_pageNumberWidthConstraint];
        }
        else
        {
            // first time we're adding constraints
            [m_pageNumberLabel.heightAnchor constraintEqualToConstant:textSize.height+m_pageNumberLabel.layer.cornerRadius+5].active = true;
            
            if (@available(iOS 11, *))
            {
                UILayoutGuide* guide = m_pageNumberLabel.superview.safeAreaLayoutGuide;
                [m_pageNumberLabel.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-50].active = true;
                [m_pageNumberLabel.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:10].active = true;
            }
            else
            {
                
                [m_pageNumberLabel.bottomAnchor constraintEqualToAnchor:m_pageNumberLabel.superview.bottomAnchor constant:-50].active = true;
                [m_pageNumberLabel.leadingAnchor constraintEqualToAnchor:m_pageNumberLabel.superview.leadingAnchor constant:5].active = true;
            }
        }
    
        // add new width constraint
        m_pageNumberWidthConstraint = [m_pageNumberLabel.widthAnchor constraintEqualToConstant:textSize.width+m_pageNumberLabel.layer.cornerRadius+20];
        
        if (!m_pageNumberWidthConstraint.active) {
            m_pageNumberWidthConstraint.active = YES;
        }
    }
}


-(void)keepToolAppearanceOnScreenWithImageView:(UIImageView*)imageView
{
    PTToolView* contentView = [[PTToolView alloc] initWithFrame:imageView.frame];
    
    contentView.image = imageView.image;
    
    [self.superview addSubview:contentView];
    
}

-(void)keepToolAppearanceOnScreen
{
	if(!CGSizeEqualToSize(CGSizeZero,self.frame.size))
	{
		// keep tool's appearance on screen even after the tool is removed.
		PTToolView* contentView = [[PTToolView alloc] initWithFrame:self.frame];
		
		float screenScale = [UIScreen mainScreen].scale;
		UIGraphicsBeginImageContextWithOptions(self.frame.size, false, screenScale);
		
		[self.layer renderInContext:UIGraphicsGetCurrentContext()];
		
		UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
		
		contentView.image = viewImage;
		
		UIGraphicsEndImageContext();
		
		[self.superview addSubview:contentView];
	}
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
	if( self.pdfViewCtrl )
	{
		if( newSuperview == nil )
		{
            self.allowZoom = YES;
            
            [self hideMenu];
            
		}

	}
	
    [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    // Only add pan-scale gesture recognizer when tool is attached to a window.
    if (self.window) {
        [self.pdfViewCtrl addGestureRecognizer:self.panScaleGestureRecognizer];
    } else {
        [self.pdfViewCtrl removeGestureRecognizer:self.panScaleGestureRecognizer];
    }
}

- (void)dealloc
{
    [m_pageNumberLabel removeFromSuperview];
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@ touchesBegan, empty implementation.", [self class]);
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@ touchesMoved, empty implementation.", [self class]);
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@ touchesEnded, empty implementation.", [self class]);
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@ touchesCancelled, empty implementation.", [self class]);
    return YES;
}


- (BOOL)onSwitchToolEvent:(id)userData
{
    return YES;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    return YES;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    if( [self.pdfViewCtrl GetDoc] == nil ) {
        return YES;
    }
    
    if( self.pdfViewCtrl.zoomEnabled == NO || self.allowZoom == NO )
    {
        return YES;
    }
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];

        CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];

        PTAnnot* annot = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:22 minimumLineWeight:10];

        if( [annot IsValid] && [annot GetType] != e_ptLink )
        {
            return YES;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    // if statement here to only allow double tap after view has stabilized
    if( fabs([self.pdfViewCtrl zoomScale] - 1.0) < 0.01)
    {
        CGPoint down = [gestureRecognizer locationOfTouch:0 inView:self.pdfViewCtrl];
        
        double zoomBy = ([self.pdfViewCtrl GetCanvasWidth])/self.pdfViewCtrl.bounds.size.width;

        if( zoomBy < 1.01 || [self.pdfViewCtrl GetPageViewMode] == e_trn_fit_width )
        {
            
            BOOL didSmartZoom = [self.pdfViewCtrl SmartZoomX:down.x y:down.y animated:YES];

            if( didSmartZoom == false )
            {
                CGRect inRect = CGRectMake([self.pdfViewCtrl GetHScrollPos]+down.x/2, [self.pdfViewCtrl GetVScrollPos]+down.y/2, self.pdfViewCtrl.bounds.size.width/2, self.pdfViewCtrl.bounds.size.height/2);
                
                
                [self.pdfViewCtrl zoomToRect:inRect animated:YES];
            }
        }
        else
        {
            if( zoomBy > 1.0 )
            {
                
                double outZoom = self.pdfViewCtrl.toolOverlayView.frame.size.width/self.pdfViewCtrl.frame.size.width;
                
                CGRect outRect = CGRectMake([self.pdfViewCtrl GetHScrollPos]-down.x, [self.pdfViewCtrl GetVScrollPos]-down.y, self.pdfViewCtrl.bounds.size.width*outZoom, self.pdfViewCtrl.bounds.size.height*outZoom);
                
                [self.pdfViewCtrl zoomToRect:outRect animated:YES];
                
                
            }
            else
            {

                CGRect inRect = CGRectMake([self.pdfViewCtrl GetHScrollPos]+down.x/2, [self.pdfViewCtrl GetVScrollPos]+down.y/2, self.pdfViewCtrl.bounds.size.width/2, self.pdfViewCtrl.bounds.size.height/2);

                
                [self.pdfViewCtrl zoomToRect:inRect animated:YES];

            }
        }
    }
    return YES;
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
	
    if (sender.state == UIGestureRecognizerStateEnded )
    {   

        [self.pdfViewCtrl ClearSelection];
        [self.pdfViewCtrl becomeFirstResponder];
        
        self.nextToolType = [PTPanTool class];
        
        return NO;
    }
    
    return YES;
    
}

#if TARGET_OS_MACCATALYST
- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location configuration:(UIContextMenuConfiguration*_Nullable *_Nonnull)configuration
{
    return YES;
}
#endif

-(void)pdfViewCtrlOnSetDoc:(PTPDFViewCtrl *)pdfViewCtrl
{
    // Do nothing.
}

-(void)pdfViewCtrlOnRenderFinished:(PTPDFViewCtrl*)pdfViewCtrl
{
	[self removeAppearanceViews];
}

-(void)removeAppearanceViews
{
	for (__strong UIView* subView in self.superview.subviews) {
        if( [subView isKindOfClass:[PTToolView class]] )
        {
            [subView removeFromSuperview];
            subView = 0;
        }
    }
}

-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    // called in response to changes in the page layout to give the tool a chance to update itself it needs to.
    // see PTTextSelectTool for an example.
    
    [self.pdfViewCtrl bringSubviewToFront:m_pageNumberLabel];
	
	[self positionPageNumberLabel];
    
    [self removeAppearanceViews];
    
    [self.pdfViewCtrl bringSubviewToFront:self];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
	if( self.backToPanToolAfterUse == YES )
	{
		_allowScrolling = NO;
	}

	else if( event.allTouches.count > 1 && ( self.createsAnnotation || [self.defaultClass createsAnnotation] || (event.allTouches.count > 1 && self.defaultClass && ![self.defaultClass isSubclassOfClass:[PTPanTool class]])) )
	{
		// more than one touch, scroll the PDF
		_allowScrolling = YES;
	}
	else
	{
		// single touch, continue with tool touch handling
        self.allowZoom = YES;
		_allowScrolling = NO;
	}

	return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    // if this is not here scrollviewer could always will take over
    return self.allowScrolling;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL) canPerformAction:(SEL)selector withSender:(id)sender
{
    if ([NSStringFromSelector(selector) hasPrefix:@"_"]) {
        return NO;
    }
    
    
    if ([NSStringFromSelector(selector) isEqualToString:@"selectToHere:"]) {
        return NO;
    }
    return [self respondsToSelector:selector];
}

- (PTTool *)getNewTool
{
    Class nextToolType = self.nextToolType;
    if (!nextToolType) {
        nextToolType = [PTPanTool class];
    }
    NSAssert(nextToolType != nil, @"Failed to get next tool type");
    
    PTTool* newTool = [[nextToolType alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
    
    newTool.identifier = self.identifier;
    newTool.previousToolType = [self class];
	newTool.annotationAuthor = self.annotationAuthor;
	newTool.longPressPoint = self.longPressPoint;
	newTool.backToPanToolAfterUse = self.backToPanToolAfterUse;
	newTool.defaultClass = self.defaultClass;
    newTool.longPressPoint = self.longPressPoint;
    newTool.annotationPageNumber = self.annotationPageNumber;
    newTool.multistrokeMode = self.multistrokeMode;
    
    if( [self.currentAnnotation IsValid] )
        newTool.currentAnnotation = self.currentAnnotation;

    newTool.toolManager = self.toolManager;
    
    if( [newTool isKindOfClass:[PTPanTool class]])
    {
        PTPanTool *panTool = (PTPanTool *)newTool;
        
        CGRect frame = UIMenuController.sharedMenuController.menuFrame;
        
        if (!CGRectIsEmpty(frame) || [self isKindOfClass:[PTFreeTextCreate class]] ) {
            panTool.showMenuNextTap = NO;
        } else {
            panTool.showMenuNextTap = YES;
        }
    }
    
    return newTool;
}

-(PTExtendedAnnotType)annotType
{
    return [[self class] annotType];
}

+ (PTExtendedAnnotType)annotType
{
    // defined in subclasses
    return PTExtendedAnnotTypeUnknown;
}

+ (UIImage *)image
{
    return [PTToolImages imageForAnnotationType:self.annotType];
}

+ (NSString *)localizedName
{
    return PTLocalizedAnnotationNameFromType(self.annotType);
}

-(Class)annotClass
{
    // defined in subclasses
    return (Class _Nonnull)nil; // suppress static analyzer warning.
}

-(BOOL)canEditStyle
{
    return [[self class] canEditStyle];
}

+ (BOOL)canEditStyle
{
    // Default is no, overridden in subclasses
    return NO;
}

-(BOOL)createsAnnotation
{
	// will return whatever the class method returns
	return [[self class] createsAnnotation];
}

+ (BOOL)createsAnnotation
{
	return NO;
}

#pragma mark - Selection menu

- (void) showSelectionMenu
{
    // do nothing
}

- (void) showSelectionMenu: (CGRect) targetRect animated:(BOOL)animated
{
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    
    
    int activePage = 0;
    if( self.annotationPageNumber < 1 )
    {
        activePage = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.longPressPoint.x y:self.longPressPoint.y];
    }
    else
    {
        activePage = self.annotationPageNumber;
    }
    
    
    if( ![self shouldShowMenu:theMenu forAnnotation:self.currentAnnotation onPageNumber:activePage])
    {
        // don't show menu if delegate says not to.
        return;
    }

	[self becomeFirstResponder];
	
	if( !CGRectEqualToRect(targetRect, CGRectZero))
	{
		[theMenu setTargetRect:targetRect inView:self.pdfViewCtrl];
	}
	

	[theMenu setMenuVisible:YES animated:animated];
}

- (void) showSelectionMenu: (CGRect) targetRect
{
    [self showSelectionMenu:targetRect animated:YES];
}

-(void)hideMenu
{
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    [theMenu setMenuVisible:NO animated:NO];
}

-(void)noteEditControllerDeleteSelectedAnnotation:(PTNoteEditController*)noteEditController
{
    [self deleteSelectedAnnotation];
    
    // Switch back to pan tool.
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:nil];
}

// in base class rather than PTAnnotEditTool in order to allow StickyCreateTool to delete annotation.
-(void)deleteSelectedAnnotation
{
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    PTPDFRect* annotRect;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
    
        PTPage* pg = [doc GetPage:self.annotationPageNumber];
        
        if ([pg IsValid] && [self.currentAnnotation IsValid]) {
            
            annotRect = [self.currentAnnotation GetRect];
            
            PTPDFPoint* pagePoint1 = [[PTPDFPoint alloc] initWithPx:[annotRect GetX1] py:[annotRect GetY1]];
            PTPDFPoint* pagePoint2 = [[PTPDFPoint alloc] initWithPx:[annotRect GetX2] py:[annotRect GetY2]];
            
            PTPDFPoint* screenPoint1 = [self.pdfViewCtrl ConvPagePtToScreenPt:pagePoint1 page_num:self.annotationPageNumber];
            PTPDFPoint* screenPoint2 = [self.pdfViewCtrl ConvPagePtToScreenPt:pagePoint2 page_num:self.annotationPageNumber];
            
            annotRect = [[PTPDFRect alloc] initWithX1:[screenPoint1 getX] y1:[screenPoint1 getY] x2:[screenPoint2 getX] y2:[screenPoint2 getY]];
            
            [self willRemoveAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            [pg AnnotRemoveWithAnnot:self.currentAnnotation];
        }
        
        @try
        {
            [self.pdfViewCtrl UpdateWithRect:annotRect];
        }
        @catch (NSException *exception) {
            [self.pdfViewCtrl Update:NO];
        }
    
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
	
	
	[self annotationRemoved:self.currentAnnotation onPageNumber:self.annotationPageNumber];
	
    self.currentAnnotation = 0;
    
    self.nextToolType = self.defaultClass;
}

#pragma mark - Pan-scale gesture

- (void)handlePanScaleGesture:(UIPanGestureRecognizer *)recognizer
{
    if( self.pdfViewCtrl.zoomEnabled == NO || self.allowZoom == NO ) {
        return;
    }
    UIScrollView *scrollView = nil;
    for (UIView *subview in self.pdfViewCtrl.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)subview;
            for (UIView *subview in scrollView.subviews) {
                if ([subview isKindOfClass:[UIScrollView class]]) {
                    scrollView = (UIScrollView *)subview;
                    break;
                }
            }
            break;
        }
    }
    if (!scrollView) {
        return;
    }
        
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.previousPanScaleTranslation = CGPointZero;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [recognizer translationInView:self.pdfViewCtrl];
            if (translation.y != self.previousPanScaleTranslation.y) {
                const CGFloat minZoom = [self.pdfViewCtrl GetZoomMinimumLimit];
                const CGFloat maxZoom = [self.pdfViewCtrl GetZoomMaximumLimit];
                const CGFloat zoomRange = maxZoom - minZoom;
                
                const CGFloat currentZoom = (self.pdfViewCtrl.zoom * self.pdfViewCtrl.zoomScale);
                
                CGFloat fullRangeDistance = 2500;
                if (currentZoom > 10) {
                    fullRangeDistance = 1000;
                }
                
                CGPoint translationDelta = PTCGPointSubtract(translation,
                                                             self.previousPanScaleTranslation);
                
                CGFloat normalizedZoom = -1 * fmax(-1, fmin(1, (translationDelta.y / fullRangeDistance)));
                
                CGFloat newZoom = currentZoom + (normalizedZoom * zoomRange);
                                
                CGFloat scrollViewZoomScale = newZoom / self.pdfViewCtrl.zoom;
                
                [scrollView setZoomScale:scrollViewZoomScale animated:YES];
            }
            self.previousPanScaleTranslation = translation;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            self.previousPanScaleTranslation = CGPointZero;
        }
            break;
        default:
            break;
    }

}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.panScaleGestureRecognizer) {
        return (touch.tapCount == 2 && [self isKindOfClass:[PTPanTool class]]);
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panScaleGestureRecognizer) {
        // Single-tap and double-tap gestures must fail *before* pan-scale gesture.
        if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)otherGestureRecognizer;
            if (tapGestureRecognizer.numberOfTapsRequired <= 2) {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - Live annotation moving

//-(double)setupContext:(CGContextRef)currentContext
//{
//
//}

#pragma mark - Scroll View Responses

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self showSelectionMenu];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self showSelectionMenu];
    [UIView animateWithDuration:0.5f delay:3.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->m_pageNumberLabel.alpha = 0;
    }
    completion:0];
}

-(void)outerScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self showSelectionMenu];
    [UIView animateWithDuration:0.5f delay:3.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->m_pageNumberLabel.alpha = 0;
    }
                     completion:0];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if( decelerate == false )
    {
        [self showSelectionMenu];
    }
    
    if(!decelerate)
    {
        [UIView animateWithDuration:0.5f delay:3.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self->m_pageNumberLabel.alpha = 0;
        }
        completion:0];
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self showSelectionMenu];
    [UIView animateWithDuration:0.5f delay:3.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->m_pageNumberLabel.alpha = 0;
    }
    completion:0];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScroll:(UIScrollView *)scrollView
{
    m_pageNumberLabel.alpha = 0.7;
    
    [UIView animateWithDuration:0.5f delay:3.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->m_pageNumberLabel.alpha = 0;
    }
completion:0];
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidZoom:(UIScrollView *)scrollView
{

}

- (BOOL)pdfViewCtrlShouldZoom:(PTPDFViewCtrl*)pdfViewCtrl
{
    return self.allowZoom;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{

}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScroll:(UIScrollView *)scrollView
{

}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    if( [self.pdfViewCtrl GetDoc] == nil )
        return;
    
    m_pageNumberLabel.text = [NSString stringWithFormat:@"%d/%d", newPageNumber, [self.pdfViewCtrl GetPageCount]];
    
   [self positionPageNumberLabel];
    
    m_pageNumberLabel.alpha = 0.7;
    
    [UIView animateWithDuration:0.5f delay:3.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->m_pageNumberLabel.alpha = 0;
    }
    completion:0];

}

#pragma mark - Annotation flattening

-(void)flattenAnnotations:(NSArray<PTAnnot *>*)annotations
{
    if (annotations.count == 0) {
        return;
    }
    
    NSError* error;
    
    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        
        PTPage* page = [doc GetPage:self.annotationPageNumber];
        
        if( [page IsValid] )
        {
            for(PTAnnot* annot in annotations)
            {
                [self willRemoveAnnotation:annot onPageNumber:self.annotationPageNumber];
                [annot Flatten:page];
                [self annotationRemoved:annot onPageNumber:self.annotationPageNumber];
            }
        }
        
        [self.pdfViewCtrl Update:YES];
        
    } error:&error];
    
        
    if( error )
    {
        NSLog(@"Flatten error: %@: %@", error.localizedFailureReason, error.description);
    }
    

}

#pragma mark - Annotation note editing
// used by PTAnnotEditTool, PTStickyNoteCreate and PTDigitalSignatureTool

-(void)editSelectedAnnotationNote
{
    if( ![self.currentAnnotation IsValid] ) {
        return;
    }
    
    PTNoteEditController* noteEditController = [[PTNoteEditController alloc] initWithDelegate:self annotType:[self.currentAnnotation extendedAnnotType]];
    [noteEditController setReadonly:![self.toolManager hasEditPermissionForAnnot:self.currentAnnotation]];

    UINavigationController* noteNavController = [[UINavigationController alloc] initWithRootViewController:noteEditController];
    
    PTMarkup* annot = [[PTMarkup alloc] initWithAnn:self.currentAnnotation];
    
    PTPopup* popup = [annot GetPopup];
    
    if( ![popup IsValid] )
    {
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        
        BOOL shouldUnlock = NO;
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            shouldUnlock = YES;
            
            PTPDFRect *rect = [annot GetRect];
            [rect Normalize];
            
            PTPDFRect* offsetRect = [[PTPDFRect alloc] initWithX1:[rect GetX2]+30 y1:[rect GetY2]+30 x2:[rect GetX2]+150 y2:[rect GetY2]+150];
            
            popup = [PTPopup Create:(PTSDFDoc*)doc pos:offsetRect];
            
            [popup SetParent:self.currentAnnotation];
            
            [annot SetPopup:popup];
            
            PTPage* page = [doc GetPage:self.annotationPageNumber];
            
            [page AnnotPushBack:popup];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
        }
        @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlock];
            }
        }
    }

    // Get contents of annot or its popup.
	NSString *contents = [self.currentAnnotation GetContents];
	if (contents.length == 0) {
		contents = [popup GetContents];
	}

    if (contents.length > 0) {
		noteEditController.noteString = contents;
    }
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        noteNavController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popController = noteNavController.popoverPresentationController;
        popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        PTPDFRect* screen_rect = [self.pdfViewCtrl GetScreenRectForAnnot:self.currentAnnotation page_num: self.annotationPageNumber];
        double x1 = [screen_rect GetX1];
        double x2 = [screen_rect GetX2];
        double y1 = [screen_rect GetY1];
        double y2 = [screen_rect GetY2];
        
        CGRect annotRect = CGRectMake(MIN(x1,x2), MIN(y1, y2), MAX(x1,x2) - MIN(x1,x2), MAX(y1, y2) - MIN(y1, y2));
        
        CGRect annotRectOnScreen = CGRectIntersection(annotRect, self.pdfViewCtrl.bounds);
        
        // use centre of rectangle to guarantee the control will appear on screen
        annotRectOnScreen = CGRectMake(annotRectOnScreen.origin.x+annotRectOnScreen.size.width/2,
                                       annotRectOnScreen.origin.y+annotRectOnScreen.size.height/2,
                                       1,
                                       1);
        
        popController.sourceRect = annotRectOnScreen;
        popController.sourceView = self.pdfViewCtrl;
        popController.delegate = self;
    }
    noteNavController.presentationController.delegate = self;
    
    [self.pt_viewController presentViewController:noteNavController animated:YES completion:nil];
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController
{
    if( [presentationController.presentedViewController isKindOfClass:[UINavigationController class]] )
    {
        UINavigationController *vc = (UINavigationController *)presentationController.presentedViewController;

        // Check for a note edit controller.
        if ([vc.topViewController isKindOfClass:[PTNoteEditController class]]) {
            PTNoteEditController *nec = (PTNoteEditController *)(vc.topViewController);

            NSString* newContentsOfNote = nec.noteString;

            [self noteEditController:nec saveNewNoteForMovingAnnotationWithString:newContentsOfNote];
        }
    }
    return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController{
    // if not dispatched, will disappear without reason
    dispatch_async(dispatch_get_main_queue(), ^() {
        if( self.currentAnnotation )
        {
            PTPDFRect* rect = [self.currentAnnotation GetRect];
            CGRect rectOnScreen = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
            [self showSelectionMenu:rectOnScreen];
        }
    });
}

-(void)noteEditController:(PTNoteEditController*)noteEditController cancelButtonPressed:(BOOL)showSelectionMenu
{
	[self.pt_viewController dismissViewControllerAnimated:YES completion:nil];
    
    if( showSelectionMenu )
	{
		PTPDFRect* rect = [self.currentAnnotation GetRect];
		CGRect annnot_rect = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
		
		// if not dispatched, will flash without reason
		dispatch_async(dispatch_get_main_queue(), ^() {
			[self showSelectionMenu:annnot_rect];
		});
	}

    // used by stickyNoteCreate so that it goes back to the pan tool when dismissed (rather than staying in sticky create)
    // annotEditTool does nothing in response to this event (implemented in base tool class)
    [self.toolManager createSwitchToolEvent:nil];

}

-(void)noteEditController:(PTNoteEditController *)noteEditController saveNewNoteForMovingAnnotationWithString:(NSString *)str
{
    BOOL modified = NO;
    @try
    {
       
        [self.pdfViewCtrl DocLock:YES];
    
        PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.currentAnnotation];
        PTPopup *popup = [markup GetPopup];
        
        NSString* oldStr = [popup GetContents];
        if (![oldStr isEqualToString:str]) { // if the two strings are different
            if (!(oldStr == nil && [str isEqualToString:@""])) { // case where contents is empty but str is returning = "". technically it is the same so we still ignore 
                
                [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
                
                // Set contents of popup and annotation.
                [popup SetContents:str];
                [self.currentAnnotation SetContents:str];
                modified = YES;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
	[self.pt_viewController dismissViewControllerAnimated:YES completion:nil];

    // if the document is not modified the annotation modified event is not fired
    if (modified) {
        [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    }
    
    // used by stickyNoteCreate so that it goes back to the pan tool when dismissed (rather than staying in sticky create)
    // annotEditTool does nothing in response to this event (implemented in base tool class)
    [self.toolManager createSwitchToolEvent:nil];
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
	if( [popoverPresentationController.presentedViewController isKindOfClass:[UINavigationController class]] )
    {
        UINavigationController *vc = (UINavigationController *)popoverPresentationController.presentedViewController;
        
        // Check for a note edit controller.
        if ([vc.topViewController isKindOfClass:[PTNoteEditController class]]) {
            PTNoteEditController *nec = (PTNoteEditController *)(vc.topViewController);
            
            NSString* newContentsOfNote = nec.noteString;
            
            [self noteEditController:nec saveNewNoteForMovingAnnotationWithString:newContentsOfNote];
        }
	}
    
	// else this is a colour swatch dismissal
	return YES;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
	// if not dispatched, will disappear without reason
	dispatch_async(dispatch_get_main_queue(), ^() {
		if( self.currentAnnotation )
		{
			PTPDFRect* rect = [self.currentAnnotation GetRect];
			CGRect rectOnScreen = [self PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];
			[self showSelectionMenu:rectOnScreen];
		}
	});
}


#pragma mark - Helpers


-(PTPDFRect *)pageBoxInScreenPtsForPageNumber:(int)pageNumber
{
    PTPDFRect* rect = nil;
    
    @try{
        [self.pdfViewCtrl DocLockRead];
        
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        PTPage* page = [doc GetPage:pageNumber];
        
        PTPDFRect* cropbox = [page GetCropBox];
        CGFloat x1 = [cropbox GetX1];
        CGFloat y1 = [cropbox GetY1];
        CGFloat x2 = [cropbox GetX2];
        CGFloat y2 = [cropbox GetY2];
        
        CGFloat x1t,y1t,x2t,y2t,x3t,y3t,x4t,y4t;
        
        CGFloat retx,rety;
        
        // Need to compute the transformed coordinates for the four corners
        // of the page bounding box, since a page can be rotated.
        retx = x1;rety = y1;
        [self ConvertPagePtToScreenPtX:&retx Y:&rety PageNumber:pageNumber];
        x1t = retx;y1t = rety;
        
        retx = x2;rety = y1;
        [self ConvertPagePtToScreenPtX:&retx Y:&rety PageNumber:pageNumber];
        x2t = retx;y2t = rety;
        
        retx = x2;rety = y2;
        [self ConvertPagePtToScreenPtX:&retx Y:&rety PageNumber:pageNumber];
        x3t = retx;y3t = rety;
        
        retx = x1;rety = y2;
        [self ConvertPagePtToScreenPtX:&retx Y:&rety PageNumber:pageNumber];
        x4t = retx;y4t = rety;
        
        CGFloat min_x = MIN(MIN(MIN(x1t,x2t),x3t),x4t);
        CGFloat max_x = MAX(MAX(MAX(x1t,x2t),x3t),x4t);
        CGFloat min_y = MIN(MIN(MIN(y1t,y2t),y3t),y4t);
        CGFloat max_y = MAX(MAX(MAX(y1t,y2t),y3t),y4t);
        
        rect = [[PTPDFRect alloc] init];
        
        [rect SetX1:min_x];
        [rect SetY1:min_y];
        [rect SetX2:max_x];
        [rect SetY2:max_y];
    }
    @catch(NSException *exception){
        NSLog(@"Exception: %@: %@",[exception name], [exception reason]);
        
    }
    @finally{
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    return rect;
}

//--------- text search/selection and annotations -------------//


-(CGPoint)convertScreenPtToPagePt:(CGPoint)screenPoint onPageNumber:(int)pageNumber
{
    [m_screenPt setX:screenPoint.x];
    [m_screenPt setY:screenPoint.y];
    
    m_pagePt = [self.pdfViewCtrl ConvScreenPtToPagePt:m_screenPt page_num:pageNumber];
    
    return CGPointMake((CGFloat)[m_pagePt getX], (CGFloat)[m_pagePt getY]);
}

-(void)ConvertScreenPtToPagePtX:(CGFloat*)x Y:(CGFloat*)y PageNumber:(int)pageNumber
{
    [m_screenPt setX:*x];
    [m_screenPt setY:*y];
    
    
    m_pagePt = [self.pdfViewCtrl ConvScreenPtToPagePt:m_screenPt page_num:pageNumber];
    
    *x = (float)[m_pagePt getX];
    *y = (float)[m_pagePt getY];
}

-(CGPoint)convertPagePtToScreenPt:(CGPoint)pagePoint onPageNumber:(int)pageNumber
{
    [m_pagePt setX:pagePoint.x];
    [m_pagePt setY:pagePoint.y];
    
    m_screenPt = [self.pdfViewCtrl ConvPagePtToScreenPt:m_pagePt page_num:pageNumber];
    
    return CGPointMake((CGFloat)[m_screenPt getX], (CGFloat)[m_screenPt getY]);
}

-(void)ConvertPagePtToScreenPtX:(CGFloat*)x Y:(CGFloat*)y PageNumber:(int)pageNumber
{
    [m_pagePt setX:*x];
    [m_pagePt setY:*y];
    
    m_screenPt = [self.pdfViewCtrl ConvPagePtToScreenPt:m_pagePt page_num:pageNumber];
    
    *x = (float)[m_screenPt getX];
    *y = (float)[m_screenPt getY];
}

-(CGRect)PDFRectScreen2CGRectScreen:(PTPDFRect*)screenRect PageNumber:(int)pageNumber
{
	double x1 = [screenRect GetX1];
	double x2 = [screenRect GetX2];
	double y1 = [screenRect GetY1];
	double y2 = [screenRect GetY2];
	
	CGRect cgScreenRect = CGRectMake(MIN(x1,x2), MIN(y1, y2), MAX(x1,x2) - MIN(x1,x2), MAX(y1, y2) - MIN(y1, y2));
	
	return cgScreenRect;
}

-(CGRect)PDFRectPage2CGRectScreen:(PTPDFRect*)r PageNumber:(int)pageNumber
{
    PTPDFPoint* pagePtA = [[PTPDFPoint alloc] init];
    PTPDFPoint* pagePtB = [[PTPDFPoint alloc] init];
    
    [pagePtA setX:[r GetX1]];
    [pagePtA setY:[r GetY2]];
    
    [pagePtB setX:[r GetX2]];
    [pagePtB setY:[r GetY1]];
    
    CGFloat paX = [pagePtA getX];
    CGFloat paY = [pagePtA getY];
    
    CGFloat pbX = [pagePtB getX];
    CGFloat pbY = [pagePtB getY];
    
    [self ConvertPagePtToScreenPtX:&paX Y:&paY PageNumber:pageNumber];
    [self ConvertPagePtToScreenPtX:&pbX Y:&pbY PageNumber:pageNumber];
    
    
    float x, y, width, height;
    x = MIN(paX, pbX);
    y = MIN(paY, pbY);
    width = MAX(paX, pbX)-x;
    height = MAX(paY, pbY)-y;
    
    return CGRectMake(x, y, width, height);
}

-(PTPDFRect*)CGRectScreen2PDFRectPage:(CGRect)cgRect PageNumber:(int)pageNumber
{
	CGPoint topLeft = cgRect.origin;
	CGPoint bottomRight = CGPointMake(CGRectGetMaxX(cgRect), CGRectGetMaxY(cgRect));
	
	[self ConvertScreenPtToPagePtX:&topLeft.x Y:&topLeft.y PageNumber:pageNumber];
	[self ConvertScreenPtToPagePtX:&bottomRight.x Y:&bottomRight.y PageNumber:pageNumber];
	
	PTPDFRect* ptRect = [[PTPDFRect alloc] initWithX1:topLeft.x y1:topLeft.y x2:bottomRight.x y2:bottomRight.y];
	
	[ptRect Normalize];
	
	return ptRect;
}

+(PTPDFRect*)GetRectUnion:(PTPDFRect*)rect1 Rect2:(PTPDFRect*)rect2
{
    PTPDFRect* rectUnion = [[PTPDFRect alloc] init];
    
    [rectUnion SetX1:MIN([rect1 GetX1], [rect2 GetX1])];
    [rectUnion SetY1:MIN([rect1 GetY1], [rect2 GetY1])];
    
    [rectUnion SetX2:MAX([rect1 GetX2], [rect2 GetX2])];
    [rectUnion SetY2:MAX([rect1 GetY2], [rect2 GetY2])];
    
    return rectUnion;
}

#pragma mark - events

-(BOOL)shouldShowMenu:(UIMenuController*)menuController forAnnotation:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    if( pageNumber > 0 )
    {

        return [self.toolManager tool:self shouldShowMenu:menuController forAnnotation:annotation onPageNumber:pageNumber];
    }
    
    return YES;
}

-(BOOL)shouldHandleLinkAnnotation:(PTAnnot*)annotation orLinkInfo:(PTLinkInfo*)linkInfo onPageNumber:(unsigned long)pageNumber
{
    if( annotation && pageNumber > 0)
    {
        
        return [self.toolManager tool:self shouldHandleLinkAnnotation:annotation orLinkInfo:(PTLinkInfo*)linkInfo onPageNumber:pageNumber];
    }
    
    return YES;
}

-(void)handleFileAttachment:(PTFileAttachment *)fileAttachment onPageNumber:(unsigned long)pageNumber
{
    if (fileAttachment && pageNumber > 0) {
        [self.toolManager tool:self handleFileAttachment:fileAttachment onPageNumber:pageNumber];
    }
}

- (BOOL)handleFileSelected:(NSString *)filePath
{
    if (filePath) {
        return [self.toolManager tool:self handleFileSelected:filePath];
    }
    return NO;
}

-(BOOL)shouldInteractWithForm:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    if( annotation && pageNumber > 0)
    {
        return [self.toolManager tool:self shouldInteractWithForm:annotation onPageNumber:pageNumber];
    }
    
    return YES;
}

-(BOOL)shouldSelectAnnotation:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
    if( annotation && pageNumber > 0)
    {

        return [self.toolManager tool:self shouldSelectAnnotation:annotation onPageNumber:pageNumber];
    }
    
    return YES;
}

-(void)didSelectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    if (annotation && pageNumber > 0)
    {
        [self.toolManager tool:self didSelectAnnotation:annotation onPageNumber:pageNumber];
    }
}

- (void)annotationAdded:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
	if( annotation && pageNumber > 0 )
	{
        [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
            
            NSString *annotID = annotation.uniqueID;
            
            if (annotID == nil) {
                annotID = [NSUUID UUID].UUIDString;
                int bytes = (int)[annotID lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
                [annotation SetUniqueID:annotID id_buf_sz:bytes];
            }
            
        } error:Nil];
        

		[self.toolManager tool:self annotationAdded:annotation onPageNumber:pageNumber];
	}
}

- (void)willModifyAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    [self.toolManager willModifyAnnotation:annotation onPageNumber:(int)pageNumber];
}

- (void)annotationModified:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
	if( annotation && pageNumber > 0 )
	{
		[self.toolManager tool:self annotationModified:annotation onPageNumber:pageNumber];
	}
}

- (void)willRemoveAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    if( annotation && pageNumber > 0)
    {
        [self.toolManager willRemoveAnnotation:annotation onPageNumber:(int)pageNumber];
    }
}

- (void)annotationRemoved:(PTAnnot*)annotation onPageNumber:(unsigned long)pageNumber
{
	if( annotation && pageNumber > 0)
	{
		[self.toolManager tool:self annotationRemoved:annotation onPageNumber:pageNumber];
	}
}



- (void)formFieldDataModified:(PTAnnot *)annotation onPageNumber:(unsigned long)pageNumber
{
    if( annotation && pageNumber > 0)
    {
        [self.toolManager tool:self formFieldDataModified:annotation onPageNumber:pageNumber];
    }
}



@end
