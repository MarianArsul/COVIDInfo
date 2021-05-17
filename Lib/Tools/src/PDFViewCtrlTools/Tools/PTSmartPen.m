//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSmartPen.h"

#import "PTAnnotationStyleManager.h"
#import "PTAnnotStyle.h"
#import "PTAnnotStyleViewController.h"
#import "PTMultiAnnotStyleViewController.h"
#import "PTPopoverNavigationController.h"
#import "PTTextHighlightCreate.h"
#import "PTToolsUtil.h"

#import "PTKeyValueObserving.h"
#import "UIView+PTAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTSmartPen () <PTAnnotStyleViewControllerDelegate>

@property (nonatomic, assign, getter=isSecondaryOverText) BOOL secondaryOverText;
@property (nonatomic, weak) PTTool *activeTool;

@property (nonatomic, strong) PTAnnotationStylePresetsGroup *primaryPresets;
@property (nonatomic, strong) PTAnnotationStylePresetsGroup *secondaryPresets;

@property (nonatomic, weak, nullable) PTMultiAnnotStyleViewController *annotationStyleViewController;

@end

NS_ASSUME_NONNULL_END

@implementation PTSmartPen

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        _secondaryToolClass = [self class].defaultSecondaryToolClass;
        
        
        self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = YES;
        self.allowZoom = YES;
        
        _primaryTool = [[PTFreeHandCreate alloc] initWithPDFViewCtrl:pdfViewCtrl];
        _secondaryTool = [[_secondaryToolClass alloc] initWithPDFViewCtrl:pdfViewCtrl];
        
        _activeTool = _primaryTool;
        _primaryTool.multistrokeMode = NO;
        
        _primaryTool.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                         UIViewAutoresizingFlexibleHeight);
        
        self.backToPanToolAfterUse = NO;
        _secondaryTool.backToPanToolAfterUse = NO;
        _primaryTool.backToPanToolAfterUse = NO;
        self.defaultClass = [self class];
        
        _primaryTool.pageIndicatorIsVisible = NO;
        _secondaryTool.pageIndicatorIsVisible = NO;
        
        [self updateAnnotationStylePresets];
    }
    return self;
}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

#pragma mark - Secondary tool

- (void)setSecondaryTool:(PTTextMarkupCreate *)secondaryTool
{
    if (secondaryTool.pdfViewCtrl != self.pdfViewCtrl) {
        NSString * const reason = [NSString stringWithFormat:@"Secondary tool's PDFViewCtrl %@ does not match this tool's, %@",
                                   secondaryTool.pdfViewCtrl,
                                   self.pdfViewCtrl];
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:reason
                                                       userInfo:nil];
        @throw exception;
        return;
    }
    
    // Remove previous secondary tool.
    PTTextMarkupCreate * const previousSecondaryTool = _secondaryTool;
    if (previousSecondaryTool) {
        [previousSecondaryTool removeFromSuperview];
    }
    
    _secondaryTool = secondaryTool;
    
    [self PT_setupSubtool:secondaryTool];
    
    [self updateAnnotationStylePresets];
    
}

- (void)PT_setupSubtool:(PTTool *)subtool
{
    subtool.backToPanToolAfterUse = NO;
    subtool.pageIndicatorIsVisible = NO;
    
    subtool.toolManager = self.toolManager;
    subtool.annotationAuthor = self.annotationAuthor;
    subtool.identifier = self.identifier;
}

#pragma mark - Secondary tool class

@synthesize secondaryToolClass = _secondaryToolClass;

- (Class)secondaryToolClass
{
    if (!_secondaryToolClass) {
        _secondaryToolClass = [self class].defaultSecondaryToolClass;
    }
    return _secondaryToolClass;
}

- (void)setSecondaryToolClass:(Class)toolClass
{
    if (toolClass) {
        if (![toolClass isSubclassOfClass:[PTTextMarkupCreate class]]) {
            // Throw invalid argument exception.
            NSString *reason = [NSString stringWithFormat:@"Class \"%@\" is not a subclass of \"%@\"",
                                NSStringFromClass(toolClass),
                                NSStringFromClass([PTTextMarkupCreate class])];
            
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
            return;
        }
        _secondaryToolClass = toolClass;
    } else {
        _secondaryToolClass = [self class].defaultSecondaryToolClass;
    }
    
    // Update the secondary tool instance.
    self.secondaryTool = [[_secondaryToolClass alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
}

#pragma mark Default

static Class PTComboTool_defaultSecondaryToolClass;

PT_PURE
static Class _Nonnull PTComboTool_restoreDefaultSecondaryToolClass(void)
{
    return [PTTextHighlightCreate class];
}

+ (Class)defaultSecondaryToolClass
{
    if (!PTComboTool_defaultSecondaryToolClass) {
        PTComboTool_defaultSecondaryToolClass = PTComboTool_restoreDefaultSecondaryToolClass();
    }
    return PTComboTool_defaultSecondaryToolClass;
}

+ (void)setDefaultSecondaryToolClass:(Class)toolClass
{
    if (toolClass) {
        if (![toolClass isSubclassOfClass:[PTTextMarkupCreate class]]) {
            // Throw invalid argument exception.
            NSString *reason = [NSString stringWithFormat:@"Class \"%@\" is not a subclass of \"%@\"",
                                NSStringFromClass(toolClass),
                                NSStringFromClass([PTTextMarkupCreate class])];
            
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
            return;
        }
        PTComboTool_defaultSecondaryToolClass = toolClass;
    } else {
        PTComboTool_defaultSecondaryToolClass = PTComboTool_restoreDefaultSecondaryToolClass();
    }
}

#pragma mark - Tool lifecycle

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (!newSuperview) {
        [self.primaryTool removeFromSuperview];
        [self.secondaryTool removeFromSuperview];
    }
    
    [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    UIView * const superview = self.superview;
    if (superview) {
        [superview addSubview:self.activeTool];
    } else {
        [self.activeTool removeFromSuperview];
    }
}

- (void)setToolManager:(PTToolManager *)toolManager
{
    [super setToolManager:toolManager];
    
    self.primaryTool.toolManager = toolManager;
    self.secondaryTool.toolManager = toolManager;
}

- (void)setAnnotationAuthor:(NSString *)annotationAuthor
{
    [super setAnnotationAuthor:annotationAuthor];
    
    self.primaryTool.annotationAuthor = annotationAuthor;
    self.secondaryTool.annotationAuthor = annotationAuthor;
}

+ (UIImage *)image
{
    return [PTToolsUtil toolImageNamed:@"Annotation/SmartPen/Icon"];
}

+ (NSString *)localizedName
{
    return PTLocalizedString(@"Combo tool",
                             @"Combo tool name");
}

- (void)setIdentifier:(NSString *)identifier
{
    [super setIdentifier:identifier];
    
    // Update the sub-tools' identifiers.
    self.primaryTool.identifier = identifier;
    self.secondaryTool.identifier = identifier;
    
    // Update style presets when the tool identifier changes.
    [self updateAnnotationStylePresets];
}

+ (BOOL)createsAnnotation
{
    return YES;
}

+ (BOOL)canEditStyle
{
    return YES;
}

#pragma mark - Annotation style presets

- (PTAnnotationStylePresetsGroup *)annotationStylePresets
{
    return self.primaryPresets;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAnnotationStylePresets
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTSmartPen, primaryPresets),
        PT_CLASS_KEY(PTSmartPen, secondaryPresets),
    ]];
}

- (void)updateAnnotationStylePresets
{
    PTAnnotationStylePresetsGroup * const previousPrimaryPresets = self.primaryPresets;
    if (previousPrimaryPresets) {
        [previousPrimaryPresets pt_removeObserver:self
                                       forKeyPath:PT_CLASS_KEY(PTAnnotationStylePresetsGroup,
                                                               selectedStyle)];
    }
    
    self.primaryPresets = [[self class] presetsForTool:self.primaryTool];
    self.secondaryPresets = [[self class] presetsForTool:self.secondaryTool];
    
    [self synchronizeSelectedStyleIndexes];
    
    if (self.primaryPresets) {
        [self.primaryPresets pt_addObserver:self
                                   selector:@selector(selectedStyleDidChange:)
                                 forKeyPath:PT_CLASS_KEY(PTAnnotationStylePresetsGroup,
                                                         selectedStyle)
                                    options:(0)];
    }
}

- (void)synchronizeSelectedStyleIndexes
{
    // Synchronize selected style index between primary and secondary presets groups.
    const NSUInteger selectedStyleIndex = self.primaryPresets.selectedIndex;
    self.secondaryPresets.selectedIndex = selectedStyleIndex;
    
    [self.secondaryPresets.selectedStyle setCurrentValuesAsDefaults];
}

+ (PTAnnotationStylePresetsGroup *)presetsForTool:(PTTool *)tool
{
    const PTExtendedAnnotType annotationType = tool.annotType;
    NSAssert(annotationType != PTExtendedAnnotTypeUnknown,
             @"The active tool must have a valid annotation type");
    
    PTAnnotationStyleManager * const manager = PTAnnotationStyleManager.defaultManager;
    PTAnnotationStylePresetsGroup *presets = [manager stylePresetsForAnnotationType:annotationType
                                                                         identifier:tool.identifier];
    return presets;
}

- (void)selectedStyleDidChange:(PTKeyValueObservedChange *)change
{
    if (change.object != self.primaryPresets) {
        return;
    }
    
    [self synchronizeSelectedStyleIndexes];
}

- (void)editAnnotationStyle:(id)sender
{
    if (self.annotationStyleViewController.presentingViewController) {
        return;
    }
    
    const NSUInteger selectedStyleIndex = self.annotationStylePresets.selectedIndex;
    
    PTAnnotStyle *primaryStyle = self.primaryPresets.styles[selectedStyleIndex];
    PTAnnotStyle *secondaryStyle = self.secondaryPresets.styles[selectedStyleIndex];
    
    PTMultiAnnotStyleViewController *multiStyleViewController = [[PTMultiAnnotStyleViewController allocOverridden] initWithToolManager:self.toolManager styles:@[
        primaryStyle,
        secondaryStyle,
    ]];
    
    for (PTAnnotStyleViewController *styleViewController in multiStyleViewController.annotationStyleViewControllers) {
        styleViewController.delegate = self;
    }
    
    if (self.activeTool == self.primaryTool) {
        multiStyleViewController.selectedStyle = primaryStyle;
    } else {
        multiStyleViewController.selectedStyle = secondaryStyle;
    }
    
    self.annotationStyleViewController = multiStyleViewController;
        
    UIViewController *viewController = [self pt_viewController];
    
    PTPopoverNavigationController *navigationController = [[PTPopoverNavigationController allocOverridden] initWithRootViewController:multiStyleViewController];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
        navigationController.presentationManager.popoverBarButtonItem = barButtonItem;
    } else if ([sender isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)sender;
        navigationController.presentationManager.popoverSourceView = view;
    }
    
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - <PTAnnotStyleViewController>

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didChangeStyle:(PTAnnotStyle *)annotStyle
{
    [annotStyle setCurrentValuesAsDefaults];
}

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle
{
    [annotStyle setCurrentValuesAsDefaults];

    [annotStyleViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Tool selection

-(void)chooseTool:(CGPoint)touchPoint
{
    PTTool* newTool;
    
    BOOL nearNewPoint = [self.primaryTool inkPointPresentAtScreenPoint:touchPoint within:GET_ANNOT_AT_DISTANCE_THRESHOLD];
    
    if( nearNewPoint )
    {
        newTool = self.primaryTool;
    }
    
    if( !newTool )
    {
        PTAnnot* onAnnot = [self.pdfViewCtrl GetAnnotationAt:touchPoint.x y:touchPoint.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];
        
        if( [onAnnot IsValid] && onAnnot.extendedAnnotType == PTExtendedAnnotTypeInk )
        {
            newTool = self.primaryTool;
        }
    }
    
    

    if( !newTool )
    {
        [self.pdfViewCtrl SetTextSelectionMode:e_ptrectangular];
        [self.pdfViewCtrl SelectX1:touchPoint.x-5 Y1:touchPoint.y-2 X2:touchPoint.x+5 Y2:touchPoint.y+2];
        [self.pdfViewCtrl SetTextSelectionMode:e_ptstructural];

        PTSelection* selection = [self.pdfViewCtrl GetSelection:-1];
        
        if( selection == 0 || [[selection GetQuads] size] > 0 )
        {
            newTool = self.secondaryTool;
        }
    }
    
    if( !newTool )
    {
        newTool = self.primaryTool;
    }
    
    if( [[self.activeTool class] isEqual:[newTool class]] == NO && [self.activeTool respondsToSelector:@selector(commitAnnotation)])
    {
        [self.activeTool performSelector:@selector(commitAnnotation)];
    }
    
    self.activeTool = newTool;
}

- (void)setActiveTool:(PTTool *)activeTool
{
    if( [activeTool isEqual:_activeTool] == NO)
    {
        [_activeTool removeFromSuperview];
        _activeTool = activeTool;
        [self.superview addSubview:_activeTool];
    }
    
    [self updateAnnotationStylePresets];
}

#pragma mark - PTTool

-(BOOL)onSwitchToolEvent:(id)userData
{
    return [self.activeTool onSwitchToolEvent:userData];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    return [self.activeTool pdfViewCtrl:pdfViewCtrl touchesShouldBegin:touches withEvent:event inContentView:view];

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    return [self.activeTool pdfViewCtrl:pdfViewCtrl touchesShouldCancelInContentView:view];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.pdfViewCtrl];
    
    [self chooseTool:touchPoint];
    
    return [self.activeTool pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    return [self.activeTool pdfViewCtrl:pdfViewCtrl onTouchesMoved:touches withEvent:event];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl onTouchesCancelled:touches withEvent:event];
    return YES;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    return [self.activeTool pdfViewCtrl:pdfViewCtrl handleDoubleTap:gestureRecognizer];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    return [self.activeTool pdfViewCtrl:pdfViewCtrl handleTap:gestureRecognizer];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndZooming:scrollView withView:view atScale:scale];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndDecelerating:scrollView];
}

//-(void)outerScrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self.activeTool outerScrollViewDidEndDecelerating:scrollView];
//}



- (void)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl pdfScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if( [self.activeTool respondsToSelector:@selector(pdfViewCtrl:pdfScrollViewWillBeginDragging:)] )
    {
        [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewWillBeginDragging:scrollView];
    }
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:scrollView];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewDidScroll:scrollView];
    
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidZoom:(UIScrollView *)scrollView
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewDidZoom:scrollView];
}

- (BOOL)pdfViewCtrlShouldZoom:(PTPDFViewCtrl*)pdfViewCtrl
{
    return self.activeTool.allowZoom;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pdfScrollViewWillBeginZooming:scrollView withView:view];
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl outerScrollViewDidScroll:scrollView];
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    [self.activeTool pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:oldPageNumber To:newPageNumber];

}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([self.activeTool respondsToSelector:aSelector])
    {
        return [[self class] instanceMethodSignatureForSelector:aSelector];
    }
    else
    {
        return [super methodSignatureForSelector:aSelector];
    }
}

-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    @try {
        if ([self.activeTool respondsToSelector:[anInvocation selector]])
        {
            [anInvocation invokeWithTarget:self.activeTool];
        }
        else {
            [super forwardInvocation:anInvocation];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
}

@end
