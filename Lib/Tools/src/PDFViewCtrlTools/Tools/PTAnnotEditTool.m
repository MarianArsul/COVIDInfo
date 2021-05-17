//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotEditTool.h"
#import "PTAnnotEditToolSubclass.h"

#import "PTAnnotationPasteboard.h"
#import "PTAnnotSelectTool.h"
#import "PTAnnotStyleDraw.h"
#import "PTChoiceFormViewController.h"
#import "PTColorDefaults.h"
#import "PTColorPickerViewController.h"
#import "PTDigitalSignatureTool.h"
#import "PTFormFillTool.h"
#import "PTFreeTextCreate.h"
#import "PTImageCropTool.h"
#import "PTMeasurementUtil.h"
#import "PTNoteEditController.h"
#import "PTPanTool.h"
#import "PTPencilDrawingCreate.h"
#import "PTPolylineEditTool.h"
#import "PTPopoverNavigationController.h"
#import "PTResizeWidgetView.h"
#import "PTRotateWidgetView.h"
#import "PTSelectionRectContainerView.h"
#import "PTTimer.h"
#import "PTToolsUtil.h"

#import "CGGeometry+PTAdditions.h"
#import "PTAnnot+PTAdditions.h"
#import "PTLineAnnot+PTAdditions.h"
#import "PTPDFRect+PTAdditions.h"
#import "UIView+PTAdditions.h"

#include <tgmath.h>

static const CGFloat PTAspectRatioSnappingThreshold = 0.05f;

@interface PTAnnotEditTool () <PTColorPickerViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>
{
    BOOL m_fill_color;
    BOOL m_external_colorpicker;

    CGPoint firstTouchPoint;
    CGPoint mostRecentTouchPoint;
    CGRect firstSelectionRect;

    NSMutableArray* baseMenuOptions;

    BOOL keyboardOnScreen;


    BOOL moveOccuredPreTap;

    NSMutableArray* choices;

    BOOL rotatingAnnot;
    BOOL movingAnnot;

    CGPoint rotationCenter;
    UIView* stampRectView;
    CGFloat startingAngle;

    UITextField *calibrationScaleTextField;
    UITextField *calibrationUnitTextField;
    UISelectionFeedbackGenerator* feedbackGenerator;
    BOOL shouldTriggerHaptic;

    CGPoint aspectSnapPoint;
    CAShapeLayer *aspectRatioGuideLayer;
}

// Redeclare property as readwrite internally.
@property (nonatomic, readwrite, weak) UIView *touchedSelectWidget;

@property (nonatomic) PTAnnotStyleViewController *stylePicker;

@property (nonatomic) UIAlertController *calibrationAlertController;

@property (nonatomic, readonly) int numGroupsSelected;

@property (nonatomic) CGFloat menuOffset;

@property (nonatomic) CGPoint maintainAspectRatioTouchOffset;

@property (nonatomic,) CGRect startingAnnotationRect;

// causes a slight stick when finger comes to a rest to make precisely
// positioning annotations easier
@property (nonatomic, strong) PTTimer *stickyTimer;
@property (nonatomic) CGPoint stickyPoint;
@property (nonatomic) BOOL stickyBlocked;

@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTAnnotEditTool

@synthesize selectedAnnotations = _selectedAnnotations;

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        
        _selectionRectContainerView = [[PTSelectionRectContainerView alloc] initWithPDFViewCtrl:in_pdfViewCtrl forAnnot:self.currentAnnotation withAnnotEditTool:self];

        _selectionRectContainerView.displaysOnlyCornerResizeHandles = self.maintainAspectRatio;
        _minimumAnnotationSize = 0.0;
        _maximumAnnotationSize = CGFLOAT_MAX;

        baseMenuOptions = [[NSMutableArray alloc] initWithCapacity:10];
        [_selectionRectContainerView addGestureRecognizer:[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationGesture:)]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector (keyboardWillShow:)
                                                     name: UIKeyboardWillShowNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector (keyboardWillHide:)
                                                     name: UIKeyboardWillHideNotification object:nil];

        _menuOffset = 26;
        
        _aspectRatioGuideEnabled = YES;
        
        _isPencilTouch = YES;
    }

    return self;
}

-(void)setCurrentAnnotation:(PTAnnot *)currentAnnotation
{
    if( self.currentAnnotation && [self.currentAnnotation IsValid] && currentAnnotation != self.currentAnnotation )
    {
        BOOL shouldShowAnnot = YES;
        if (@available(iOS 13.1, *)) {
            // If we're editing a PencilKit drawing then we don't want to show the annot until editing is complete (in PTPencilDrawingCreate)
            shouldShowAnnot = self.nextToolType != [PTPencilDrawingCreate class];
        }
        if (shouldShowAnnot) {
            [self.pdfViewCtrl ShowAnnotation:self.currentAnnotation];
            BOOL shouldUnlock = NO;
            @try {
                [self.pdfViewCtrl DocLockRead];
                shouldUnlock = YES;
                [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
            } @catch (NSException *exception) {
                NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            } @finally {
                if (shouldUnlock) {
                    [self.pdfViewCtrl DocUnlockRead];
                }
            }
        }
    }
    
    if( currentAnnotation == nil)
    {
        [self.selectionRectContainerView setAnnot:nil];
    }
    
    [super setCurrentAnnotation:currentAnnotation];


}

-(void)willMoveToSuperview:(UIView*)newSuperview
{
	if( newSuperview == nil )
	{
        if( [self.currentAnnotation IsValid] )
        {
            // just in case...
            [self.pdfViewCtrl ShowAnnotation:self.currentAnnotation];
            BOOL shouldUnlock = NO;
            @try {
                [self.pdfViewCtrl DocLockRead];
                shouldUnlock = YES;
                [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
            } @catch (NSException *exception) {
                NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            } @finally {
                if (shouldUnlock) {
                    [self.pdfViewCtrl DocUnlockRead];
                }
            }
        }
        
        const CGRect appearanceFrame = [self.superview convertRect:self.selectionRectContainerView.selectionRectView.frame fromView:self.selectionRectContainerView];
        
        // Create a snapshot of the selectedRectView.
        // NOTE: When the frame is empty (zero width & height), the call to
        // UIGraphicsBeginImageContextWithOptions() will fail and then UIGraphicsGetCurrentContext()
        // will return null.
        if (!CGRectIsEmpty(appearanceFrame)) {
            UIImageView* contentView = [[UIImageView alloc] init];
            contentView.frame = appearanceFrame;
            
            UIGraphicsBeginImageContextWithOptions(appearanceFrame.size, false, 0);
            const CGContextRef context = UIGraphicsGetCurrentContext();
            
            [self.selectionRectContainerView.selectionRectView.layer renderInContext:context];
            
            UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            
            contentView.image = viewImage;
            
            UIGraphicsEndImageContext();
            
            [self keepToolAppearanceOnScreenWithImageView:contentView];
        }
        
		[self deselectAnnotation];
		if( [self.selectionRectContainerView superview] == self.pdfViewCtrl.toolOverlayView  )
        {
			[self.selectionRectContainerView removeFromSuperview];
        }

        [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
	}
    else
    {
        if( [self.currentAnnotation IsValid] )
        {
            NSError* error;
            [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
                [self.pdfViewCtrl HideAnnotation:self.currentAnnotation];
                [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
            } error:&error];
            
            if( error )
            {
                NSAssert(error == Nil, @"Error hiding annot / updating control.");
            }

        }
    }

	[super willMoveToSuperview:newSuperview];
}

-(void)setMaintainAspectRatio:(BOOL)maintainAspectRatio
{
    _selectionRectContainerView.displaysOnlyCornerResizeHandles = maintainAspectRatio;
    _maintainAspectRatio = maintainAspectRatio;
}

- (void)dealloc
{
	if( [self.selectionRectContainerView superview] == self.pdfViewCtrl.toolOverlayView )
		[self.selectionRectContainerView removeFromSuperview];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    // Check if the keyboard notification is for the current app.
    BOOL isLocal = ((NSNumber *)notification.userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue;
    if (!isLocal) {
        return;
    }

    // Check if the FreeText text view is on screen.
    if (!self.selectionRectContainerView.textView) {
        return;
    }

    CGRect cursorRect = [self.selectionRectContainerView.textView caretRectForPosition:self.selectionRectContainerView.textView.selectedTextRange.start];

    CGRect textRect = self.selectionRectContainerView.frame;
    CGRect rect = CGRectMake(textRect.origin.x, textRect.origin.y + cursorRect.origin.y, textRect.size.width, cursorRect.size.height);

    CGFloat topEdge = 0.0;
    if (@available(iOS 11.0, *)) {
        topEdge = self.pdfViewCtrl.safeAreaInsets.top;
    }

    [self.pdfViewCtrl keyboardWillShow:notification rectToNotOverlapWith:rect topEdge:topEdge];
    keyboardOnScreen = true;
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    // Check if the keyboard notification is for the current app.
    BOOL isLocal = ((NSNumber *)notification.userInfo[UIKeyboardIsLocalUserInfoKey]).boolValue;
    if (!isLocal) {
        return;
    }

    [self.pdfViewCtrl keyboardWillHide:notification];

    keyboardOnScreen = false;
}

- (void)deleteSelectedAnnotation
{
    NSError *error = nil;
    [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
        CGRect rectToUpdate = CGRectZero;
        PTPage *page = [doc GetPage:self.annotationPageNumber];
        if (![page IsValid]) {
            return;
        }
        
        for (PTAnnot *annot in self.selectedAnnotations) {
            // special case if deleting a signature stamp that's associated with a signature field
            // via toolManager.signatureAnnotationOptions.signSignatureFieldsWithStamps
            if ([annot IsValid]) {
                
                if( [annot GetType] == e_ptStamp  && self.toolManager.signatureAnnotationOptions.signSignatureFieldsWithStamps == YES )
                {
                    NSString* fieldID = [annot GetCustomData:PT_SIGNATURE_FIELD_ID];
                    if (fieldID.length != 0)
                    {
                        NSArray* annotsOnPage = [self.pdfViewCtrl GetAnnotationsOnPage:self.annotationPageNumber];
                        
                        for(PTAnnot* ann in annotsOnPage)
                        {
                            if( [ann IsValid] && [ann GetType] == e_ptWidget )
                            {
                                PTWidget* widget = [[PTWidget alloc] initWithAnn:ann];
                                
                                PTField* field = [widget GetField];
                                
                                if( [field IsValid] && [field GetType] == e_ptsignature && [fieldID isEqualToString:[field GetName]])
                                {
                                    [self.toolManager willModifyAnnotation:ann onPageNumber:self.annotationPageNumber];
                                    [ann SetFlag:e_pthidden value:NO];
                                    [self.toolManager annotationModified:ann onPageNumber:self.annotationPageNumber];
                                    [self.pdfViewCtrl UpdateWithAnnot:ann page_num:self.annotationPageNumber];
                                }
                                                                                            
                            }
                        }
                    }
                }
                CGRect annotScreenRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:[annot GetRect] PageNumber:self.annotationPageNumber];
                rectToUpdate = CGRectIsEmpty(rectToUpdate) ? annotScreenRect : CGRectUnion(rectToUpdate, annotScreenRect);
                [self willRemoveAnnotation:annot onPageNumber:self.annotationPageNumber];
                [page AnnotRemoveWithAnnot:annot];
                [self annotationRemoved:annot onPageNumber:self.annotationPageNumber];
            }
        }
        [self.pdfViewCtrl UpdateWithRect:[PTPDFRect rectFromCGRect:rectToUpdate]];
    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    self.currentAnnotation = nil;
    self.annotationPageNumber = 0;
    [self cancelMenu];
    [self.selectionRectContainerView setHidden:YES];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL ret = [super pdfViewCtrl:pdfViewCtrl touchesShouldBegin:touches withEvent:event inContentView:view];
    
    if( [view isKindOfClass:[PTSelectionRectContainerView class]] || [view isKindOfClass:[PTResizeWidgetView class]] || [view isKindOfClass:[PTRotateWidgetView class]])
    {
        return YES;
    }
    
    if(self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }
    
    return ret;
    
    
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{

    if( [view isKindOfClass:[PTSelectionRectContainerView class]] || [view isKindOfClass:[PTResizeWidgetView class]] || [view isKindOfClass:[PTRotateWidgetView class]])
	{
        return NO;
	}
    else
	{
        return YES;
	}
}

- (int)numGroupsSelected
{
    NSMutableSet *groupIDs = [NSMutableSet set];
    int ungroupedAnnots = 0;
    for (PTAnnot *annot in self.selectedAnnotations) {
        if (annot.annotationsInGroup.count > 1) {
            [groupIDs addObject:annot.annotationsInGroup.firstObject.uniqueID];
        }else{
            // An ungrouped annotation counts as its own group
            ungroupedAnnots++;
        }
    }
    return ungroupedAnnots + (int)groupIDs.count;
}

- (void) moveAnnotation: (CGPoint) down
{
    CGRect selectionRectContainerFrame = self.selectionRectContainerView.frame;
    CGRect selectionRectFrame = self.selectionRectContainerView.selectionRectView.frame;

    self.annotRect = CGRectOffset(selectionRectFrame,
                                    CGRectGetMinX(selectionRectContainerFrame) - [self.pdfViewCtrl GetHScrollPos],
                                    CGRectGetMinY(selectionRectContainerFrame) - [self.pdfViewCtrl GetVScrollPos]);

    CGRect groupRect = self.selectionRectContainerView.groupSelectionRectView.frame;
    groupRect = [self.selectionRectContainerView convertRect:groupRect toView:self.pdfViewCtrl];
    CGAffineTransform transform = [PTAnnotEditTool transformFromRect:firstSelectionRect toRect:groupRect];
    for (PTAnnot *annot in self.selectedAnnotations) {
        if ([annot IsValid])
        {
            CGRect annotScreenCGRect;
            if( [annot GetType] == e_ptSquare )
            {
                PTSquare* sq = [[PTSquare alloc] initWithAnn:annot];
                annotScreenCGRect = [self contentRectInScreenCoordinatesForAnnot:sq];
                annotScreenCGRect = CGRectApplyAffineTransform(annotScreenCGRect, transform);
            }
            else
            {
                annotScreenCGRect = [self tightScreenBoundingBoxForAnnot:annot];
                annotScreenCGRect = CGRectApplyAffineTransform(annotScreenCGRect, transform);
            }
            [self willModifyAnnotation:annot onPageNumber:self.annotationPageNumber];
            [self SetAnnotationRect:annot Rect:annotScreenCGRect OnPage:self.annotationPageNumber];
            [self annotationModified:annot onPageNumber:self.annotationPageNumber];
        }
    }
        
    if( PT_ToolsMacCatalyst == NO )
    {
        [self showSelectionMenu: groupRect];
    }
    
}

- (void) setAnnotationRectDelta: (CGRect) deltaRect
{

    if ([self.currentAnnotation IsValid])
    {
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            for (int i = 0; i < self.selectedAnnotations.count; i++) {
                PTAnnot *annot = [self.selectedAnnotations objectAtIndex:i];
                if (![annot IsValid]) {
                    return;
                }
                UIView *annotView = [self.selectionRectContainerView.groupSelectionRectView.subviews objectAtIndex:i];

                CGRect viewFrame = annotView.frame;
                CGRect annotViewScreen = [annotView.superview convertRect:viewFrame toView:self.pdfViewCtrl];

                
                [self willModifyAnnotation:annot onPageNumber:self.annotationPageNumber];
                
                [self SetAnnotationRect:annot Rect:annotViewScreen OnPage:self.annotationPageNumber];

                PTExtendedAnnotType annotType = [annot extendedAnnotType];

                switch( annotType )
                {
                    case PTExtendedAnnotTypeStamp:
                    case PTExtendedAnnotTypeImageStamp:
                    case PTExtendedAnnotTypePencilDrawing:
                    case PTExtendedAnnotTypeSignature:
                    case PTExtendedAnnotTypeText:
                    case PTExtendedAnnotTypeSound:
                    case PTExtendedAnnotTypeFileAttachment:
                        break;
                    case PTExtendedAnnotTypeFreeText:
                    {
                        PTFreeText* ft = [[PTFreeText alloc] initWithAnn:annot];
                        [PTFreeTextCreate refreshAppearanceForAnnot:ft onDoc:[self.pdfViewCtrl GetDoc]];
                        
                        break;
                    }
                    default:
                        [annot RefreshAppearance];
                        break;
                }

                [self annotationModified:annot onPageNumber:self.annotationPageNumber];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
            [self reSelectAnnotation];
        }
    }
}

+ (CGAffineTransform) transformFromRect:(CGRect)sourceRect toRect:(CGRect)finalRect {
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(finalRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(finalRect)));
    transform = CGAffineTransformScale(transform, finalRect.size.width/sourceRect.size.width, finalRect.size.height/sourceRect.size.height);

    return transform;
}

- (void) setSelectionRectDelta: (CGRect) deltaRect
{

    if ([self.currentAnnotation IsValid])
    {

        CGRect selRect = firstSelectionRect;

        CGFloat minimumSize = [PTResizeWidgetView length];

        if( self.maintainAspectRatio )
        {
            minimumSize /= 2;
        }

        minimumSize = MAX(minimumSize, self.minimumAnnotationSize * [self.pdfViewCtrl GetZoom]);

        CGFloat maximumSize = self.maximumAnnotationSize * [self.pdfViewCtrl GetZoom];

        BOOL capOriginX = NO;
        BOOL capOriginY = NO;
        BOOL capWidth = NO;
        BOOL capHeight = NO;
        CGFloat capSize = minimumSize;

        // Update horizontal axis, subject to size constraints.
        BOOL widthAboveMin = (selRect.size.width + deltaRect.size.width) >= minimumSize;
        BOOL widthBelowMax = (selRect.size.width + deltaRect.size.width) <= maximumSize;

        if( widthAboveMin && widthBelowMax)
        {
            selRect.origin.x += deltaRect.origin.x;
            selRect.size.width += deltaRect.size.width;
        }
        else if (!widthAboveMin)
        {
            // Below minimum width.
            if( deltaRect.origin.x != 0 )
            {
                // Adjust origin by (any) remaining allowable amount.
                selRect.origin.x += selRect.size.width - minimumSize;
                selRect.size.width = minimumSize;
                capOriginX = YES;
                capWidth = YES;
            }
            else
            {
                selRect.size.width = minimumSize;
                capWidth = YES;
            }
        }
        else
        {
            // Above maximum width.
            if (deltaRect.origin.x != 0)
            {
                // Adjust origin by (any) remaining allowable amount.
                selRect.origin.x += selRect.size.width - maximumSize;
                selRect.size.width = maximumSize;
                capOriginX = YES;
                capWidth = YES;
                capSize = maximumSize;
            }
            else
            {
                selRect.size.width = maximumSize;
                capWidth = YES;
                capSize = maximumSize;
            }
        }

        // Update vertical axis, subject to size constraints.
        BOOL heightAboveMin = (selRect.size.height + deltaRect.size.height) >= minimumSize;
        BOOL heightBelowMax = (selRect.size.height + deltaRect.size.height) <= maximumSize;

        if(heightAboveMin && heightBelowMax)
        {
            selRect.origin.y += deltaRect.origin.y;
            selRect.size.height += deltaRect.size.height;
        }
        else if (!heightAboveMin)
        {
            // Below minimum height.
            if( deltaRect.origin.y != 0 )
            {
                // Adjust origin by (any) remaining allowable amount.
                selRect.origin.y += selRect.size.height - minimumSize;
                selRect.size.height = minimumSize;
                capOriginY = YES;
                capHeight = YES;
            }
            else
            {
                selRect.size.height = minimumSize;
                capHeight = YES;
            }
        }
        else
        {
            // Above maximum height.
            if( deltaRect.origin.y != 0 )
            {
                // Adjust origin by (any) remaining allowable amount.
                selRect.origin.y += selRect.size.height - maximumSize;
                selRect.size.height = maximumSize;
                capOriginY = YES;
                capHeight = YES;
                capSize = maximumSize;
            }
            else
            {
                selRect.size.height = maximumSize;
                capHeight = YES;
                capSize = maximumSize;
            }
        }

        if( self.maintainAspectRatio  )
        {
            CGFloat originalRatio = firstSelectionRect.size.width/firstSelectionRect.size.height;

            if( capWidth && firstSelectionRect.size.height > firstSelectionRect.size.width)
            {
                selRect.size.height = capSize/originalRatio;

                if( capOriginX )
                    selRect.origin.x = firstSelectionRect.origin.x + firstSelectionRect.size.width - selRect.size.width;

                if( selRect.origin.y != firstSelectionRect.origin.y)
                    selRect.origin.y = firstSelectionRect.origin.y + firstSelectionRect.size.height - selRect.size.height;

            }

            if( capHeight && firstSelectionRect.size.height < firstSelectionRect.size.width)
            {
                selRect.size.width = capSize*originalRatio;

                if( capOriginY )
                    selRect.origin.y = firstSelectionRect.origin.y + firstSelectionRect.size.height - selRect.size.height;

                if( selRect.origin.x != firstSelectionRect.origin.x)
                    selRect.origin.x = firstSelectionRect.origin.x + firstSelectionRect.size.width - selRect.size.width;

            }

            selRect = [self boundRectToPage:selRect isResizing:YES];

            CGFloat newAspectRatio = selRect.size.width/selRect.size.height;

            if( newAspectRatio < originalRatio )
                selRect.size.height = selRect.size.width/originalRatio;
            else
                selRect.size.width = selRect.size.height*originalRatio;

            if( selRect.origin.x != firstSelectionRect.origin.x)
                selRect.origin.x = firstSelectionRect.origin.x + firstSelectionRect.size.width - selRect.size.width;
            if( selRect.origin.y != firstSelectionRect.origin.y)
                selRect.origin.y = firstSelectionRect.origin.y + firstSelectionRect.size.height - selRect.size.height;

        }
        else
        {
            selRect = [self boundRectToPage:selRect isResizing:YES];
        }
        // Get transform from initial rect to new rect
        CGAffineTransform transform = [PTAnnotEditTool transformFromRect:firstSelectionRect toRect:selRect];

        // Get initial origin of groupSelectionRectView
        CGPoint origin = self.selectionRectContainerView.groupSelectionRectView.frame.origin;
        // Apply the transform to groupSelectionRectView and then correct for any change in origin
        self.selectionRectContainerView.groupSelectionRectView.transform = transform;
        self.selectionRectContainerView.groupSelectionRectView.frame = CGRectMake(origin.x, origin.y, self.selectionRectContainerView.groupSelectionRectView.frame.size.width, self.selectionRectContainerView.groupSelectionRectView.frame.size.height);

        [self.selectionRectContainerView setFrameFromAnnot:selRect];

        [self hideMenu];

    }
}

-(CGRect)contentRectInScreenCoordinatesForAnnot:(PTMarkup*)annot
{
    NSError* error;
    
    __block CGRect cgScreenRect;

    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
 
        PTPDFRect* contentRect = [annot GetContentRect];
        
        PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
        PTRotate pageRotation = [[doc GetPage:self.annotationPageNumber] GetRotation];
        PTRotate annotRotation = ((pageRotation + ctrlRotation) % 4);
        
        CGFloat crx1 = [contentRect GetX1];
        CGFloat cry1 = [contentRect GetY1];
        
        CGFloat crx2 = [contentRect GetX2];
        CGFloat cry2 = [contentRect GetY2];
        
        if( annotRotation == e_pt90 )
        {
            [contentRect Set:crx1 y1:cry2 x2:crx2 y2:cry1];
        }
        else if( annotRotation == e_pt270 )
        {
            [contentRect Set:crx2 y1:cry1 x2:crx1 y2:cry2];
        }
        else if( annotRotation == e_pt180 )
        {
            CGFloat crx1 = [contentRect GetX1];
            CGFloat cry1 = [contentRect GetY1];
            
            CGFloat crx2 = [contentRect GetX2];
            CGFloat cry2 = [contentRect GetY2];
            
            [contentRect Set:crx2 y1:cry2 x2:crx1 y2:cry1];
            
        }
        
        cgScreenRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:contentRect PageNumber:self.annotationPageNumber];
        
    } error:&error];
    
    if( error )
    {
        NSLog(@"Error determining annot rect.");
    }
    
    return cgScreenRect;
}

-(CGRect)tightScreenBoundingBoxForAnnot:(PTAnnot*)annot
{
    CGRect cgScreenRect;

    PTPDFRect* screenRect = [self.pdfViewCtrl GetScreenRectForAnnot:annot page_num:self.annotationPageNumber];
    cgScreenRect = [self PDFRectScreen2CGRectScreen:screenRect PageNumber:self.annotationPageNumber];
    
    return cgScreenRect;
}

-(PTPDFRect*)tightPageBoundingBoxFromAnnot:(PTAnnot*)annot
{
    return [annot GetRect];
}

- (CGPoint)boundPointToPage:(CGPoint)point
{
    if (![self.currentAnnotation IsValid]) {
        return point;
    }

    PTPDFRect *pageScreenRect = [self pageBoxInScreenPtsForPageNumber:self.annotationPageNumber];
    if (!pageScreenRect) {
        return point;
    }

    CGFloat minX = [pageScreenRect GetX1];
    CGFloat maxX = [pageScreenRect GetX2];
    CGFloat minY = [pageScreenRect GetY1];
    CGFloat maxY = [pageScreenRect GetY2];

    point.x = fmax(minX, fmin(point.x, maxX));
    point.y = fmax(minY, fmin(point.y, maxY));

    return point;
}

- (PTPDFRect *)boundPageRect:(PTPDFRect *)pageRect toPage:(int)pageNumber
{
    if (![self.currentAnnotation IsValid]) {
        return nil;
    }

    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    PTPDFRect *cropBox = nil;

    @try {
        [self.pdfViewCtrl DocLockRead];

        PTPage *page = [doc GetPage:pageNumber];
        cropBox = [page GetCropBox];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", [exception name], [exception reason]);

        cropBox = nil;
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }

    if (!cropBox) {
        return nil;
    }

    double x1 = [pageRect GetX1];
    double y1 = [pageRect GetY1];
    double x2 = [pageRect GetX2];
    double y2 = [pageRect GetY2];

    double minX = [cropBox GetX1];
    double minY = [cropBox GetY1];
    double maxX = [cropBox GetX2];
    double maxY = [cropBox GetY2];

    if (x1 < minX) {
        double diff = minX - x1;
        x1 += diff;
        x2 += diff;
    }

    if (y1 < minY) {
        double diff = minY - y1;
        y1 += diff;
        y2 += diff;
    }

    if (x2 > maxX) {
        double diff = maxX - x2;
        x1 += diff;
        x2 += diff;
    }

    if (y2 > maxY) {
        double diff = maxY - y2;
        y1 += diff;
        y2 += diff;
    }

    PTPDFRect *boundedRect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
    [boundedRect Normalize];

    return boundedRect;
}

- (CGRect) boundRectToPage:(CGRect)annotRect isResizing:(BOOL)resizing
{
	if( ![self.currentAnnotation IsValid] )
		return CGRectNull;


	PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];

	CGFloat x1, y1;
	PTRotate rotation;
	PTPage* page;

	@try
	{
		[self.pdfViewCtrl DocLockRead];

		x1 = annotRect.origin.x - [self.pdfViewCtrl GetHScrollPos];
		y1 = annotRect.origin.y - [self.pdfViewCtrl GetVScrollPos];

		page = [doc GetPage:self.annotationPageNumber];

		rotation = [page GetRotation];

	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",[exception name], [exception reason]);
	}
	@finally {
		[self.pdfViewCtrl DocUnlockRead];
	}

	// build page box start

    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.annotationPageNumber];


	CGFloat minX = [page_rect GetX1];
	CGFloat maxX = [page_rect GetX2];
	CGFloat minY = [page_rect GetY1];
	CGFloat maxY = [page_rect GetY2];

	// build page box end

	if( x1 < minX )
	{
		CGFloat diff = annotRect.origin.x;
		annotRect.origin.x = minX + [self.pdfViewCtrl GetHScrollPos];
		diff -= annotRect.origin.x;
		if( resizing )
		{
			annotRect.size.width -= ABS(diff);
		}
	}

	if( y1 < minY )
	{
		CGFloat diff = annotRect.origin.y;
		annotRect.origin.y = minY + [self.pdfViewCtrl GetVScrollPos];
		diff -= annotRect.origin.y;
		if( resizing )
		{
			annotRect.size.height -= ABS(diff);
		}
	}

    CGFloat x2 = annotRect.origin.x - [self.pdfViewCtrl GetHScrollPos] + annotRect.size.width;
	CGFloat y2 = annotRect.origin.y - [self.pdfViewCtrl GetVScrollPos] + annotRect.size.height;

	if( y2 > maxY )
	{
		CGFloat diff = annotRect.origin.y;
		annotRect.origin.y = maxY + [self.pdfViewCtrl GetVScrollPos] - annotRect.size.height;
		if( resizing )
		{
			diff -= annotRect.origin.y;
			annotRect.size.height -= ABS(diff);
			annotRect.origin.y += ABS(diff);
		}
	}

	if( x2 > maxX )
	{
		CGFloat diff = annotRect.origin.x;
		annotRect.origin.x = maxX + [self.pdfViewCtrl GetHScrollPos] -annotRect.size.width;
		if( resizing )
		{
			diff -= annotRect.origin.x;
			annotRect.size.width -= ABS(diff);
			annotRect.origin.x += ABS(diff);
		}
	}

    return annotRect;
}

- (bool) moveSelectionRect: (CGPoint) down
{
    
    if( CGRectEqualToRect(self.startingAnnotationRect, CGRectZero))
    {
        if( [self.currentAnnotation GetType] == e_ptSquare )
        {
            PTSquare* sq = [[PTSquare alloc] initWithAnn:self.currentAnnotation];
            self.startingAnnotationRect = [self contentRectInScreenCoordinatesForAnnot:sq];
        }
        else
        {
            self.startingAnnotationRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];
        }
    }
    
    CGRect annotRect = self.startingAnnotationRect;
    
    // Ensure that first selection rect is filled out.
    if (CGRectEqualToRect(firstSelectionRect, CGRectZero)) {
        firstSelectionRect = self.selectionRectContainerView.groupSelectionRectView.frame;
        // Convert to screen space
        firstSelectionRect = [self.selectionRectContainerView convertRect:firstSelectionRect toView:self.pdfViewCtrl];
        movingAnnot = YES;
    }
    
    if( self.stickyTimer.valid == NO && (
       fabs(self.stickyPoint.x - down.x) <= 2 &&
       fabs(self.stickyPoint.y - down.y) <= 2) )
    {
        self.stickyBlocked = YES;
        return false;
    }

    
    CGRect groupAnnotRect = firstSelectionRect;
    
    if( fabs(groupAnnotRect.origin.x - (down.x + self.touchOffset.x)) > 2 ||
        fabs(groupAnnotRect.origin.y - (down.y + self.touchOffset.y)) > 2)
    {
        if( self.stickyBlocked )
        {
            CGPoint touchOffset = self.touchOffset;
            touchOffset.x += (self.stickyPoint.x - down.x);
            touchOffset.y += (self.stickyPoint.y - down.y);
            self.touchOffset = touchOffset;
            
            self.stickyBlocked = NO;
        }
        groupAnnotRect.origin.x = down.x + self.touchOffset.x + PTResizeWidgetView.length*0.5;
        groupAnnotRect.origin.y = down.y + self.touchOffset.y + PTResizeWidgetView.length*0.5;

        groupAnnotRect = [self boundRectToPage:groupAnnotRect isResizing:NO];

        CGVector offset = PTCGPointOffsetFromPoint(groupAnnotRect.origin, firstSelectionRect.origin);
        annotRect.origin = PTCGVectorOffsetPoint(firstSelectionRect.origin, offset);

        
        [self.selectionRectContainerView setFrameFromAnnot:annotRect];
        
        [self.stickyTimer invalidate];
        self.stickyTimer = [PTTimer scheduledTimerWithTimeInterval:0.50f target:self selector:Nil userInfo:Nil repeats:NO];
        self.stickyPoint = down;

        [self hideMenu];

        return true;
    }
    else
        return false;
}


- (void) attachHighlightAnnotMenuItems: (NSMutableArray *) menuItems
{
    UIMenuItem* menuItem;

    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"Annotation style") action:@selector(editSelectedAnnotationStyle)];
        [menuItems addObject:menuItem];
    }

    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"Note tool name") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Color", @"Color") action:@selector(editSelectedAnnotationStrokeColor)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Opacity", @"Opacity") action:@selector(editSelectedAnnotationOpacity)];
//    [menuItems addObject:menuItem];
}

- (void) attachTextAnnotMenuItems: (NSMutableArray *) menuItems
{
    UIMenuItem* menuItem;

    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"Annotation style") action:@selector(editSelectedAnnotationStyle)];
        [menuItems addObject:menuItem];
    }

    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"Note tool name") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Color", @"Color") action:@selector(editSelectedAnnotationStrokeColor)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Thickness", @"Line Thickness") action:@selector(editSelectedAnnotationBorder)];
//    [menuItems addObject:menuItem];
//     menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Opacity", @"Opacity") action:@selector(editSelectedAnnotationOpacity)];
//    [menuItems addObject:menuItem];
}

- (void) attachFreeTextMenuItems: (NSMutableArray *) menuItems
{
    UIMenuItem* menuItem;

    // items commented out below are compatible with free text annotations, uncomment if desired.

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"Note tool name") action:@selector(editSelectedAnnotationNote)];
//    [menuItems addObject:menuItem];


    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"Annotation style") action:@selector(editSelectedAnnotationStyle)];
        [menuItems addObject:menuItem];

        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Edit", @"") action:@selector(editSelectedAnnotationFreeText)];
        [menuItems addObject:menuItem];
    }

//    [menuItems addObject:[[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Copy Text", @"Copy FreeText text menu item") action:@selector(copySelectedFreeText)]];

    // not available!
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Text Color", @"") action:@selector(editFreeTextColor)];
//    [menuItems addObject:menuItem];

    // not available!
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Text Size", @"") action:@selector(editFreeTextSize)];
//    [menuItems addObject:menuItem];

    // not available!
    //menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Text Size", @"") action:@selector(editFreeTextFont)];
    //[menuItems addObject:menuItem];

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Fill Color", @"Colour with which to fill a shape.") action:@selector(editSelectedAnnotationStrokeColor)];
//    [menuItems addObject:menuItem];

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Thickness", @"") action:@selector(editSelectedAnnotationBorder)];
//    [menuItems addObject:menuItem];
//    [menuItem release];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Opacity", @"") action:@selector(editSelectedAnnotationOpacity)];
//    [menuItems addObject:menuItem];
//    [menuItem release];
}

- (void) attachFreeHandMenuItems: (NSMutableArray *) menuItems
{
    UIMenuItem* menuItem;

    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"Annotation style") action:@selector(editSelectedAnnotationStyle)];
        [menuItems addObject:menuItem];
    }

    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Color", @"") action:@selector(editSelectedAnnotationStrokeColor)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Thickness", @"Line thickness") action:@selector(editSelectedAnnotationBorder)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Opacity", @"") action:@selector(editSelectedAnnotationOpacity)];
//    [menuItems addObject:menuItem];
}

- (void)attachFileAttachmentMenuItems:(NSMutableArray *)menuItems
{
    UIMenuItem *menuItem = nil;

    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];

    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Open", @"Open file attachment annotation") action:@selector(openFileAttachmentAnnotation)];
    [menuItems addObject:menuItem];
}

- (void) attachMarkupMenuItems: (NSMutableArray *) menuItems
{
    UIMenuItem* menuItem;

    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"Annotation style") action:@selector(editSelectedAnnotationStyle)];
        [menuItems addObject:menuItem];
    }

    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];

//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Stroke Color", @"Line Color") action:@selector(editSelectedAnnotationStrokeColor)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Fill Color", @"Colour with which to fill a shape.") action:@selector(editSelectedAnnotationFillColor)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Thickness", @"Line thickness") action:@selector(editSelectedAnnotationBorder)];
//    [menuItems addObject:menuItem];
//    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Opacity", @"") action:@selector(editSelectedAnnotationOpacity)];
//    [menuItems addObject:menuItem];
}

- (void) attachMeasurementMenuItems: (NSMutableArray *) menuItems
{
    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        UIMenuItem* menuItem;
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Calibrate", @"") action:@selector(showMeasurementCalibrationAlert)];
        [menuItems addObject:menuItem];
    }
}

- (void)attachRedactionMenuItems:(NSMutableArray<UIMenuItem *> *)menuItems
{
    UIMenuItem* menuItem;

    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Redact", @"") action:@selector(redact)];
        [menuItems addObject:menuItem];

        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Style", @"Annotation style") action:@selector(editSelectedAnnotationStyle)];
        [menuItems addObject:menuItem];
    }
}

- (void)attachSignatureMenuItems:(NSMutableArray<UIMenuItem *> *)menuItems
{
    UIMenuItem* menuItem;
    
    menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];
    
    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]
        && self.toolManager.signatureAnnotationOptions.canEditAppearance) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Edit", @"") action:@selector(editSelectedAnnotationSignature)];
        [menuItems addObject:menuItem];
    }
}

- (void)attachImageStampMenuItems:(NSMutableArray<UIMenuItem *> *)menuItems
{
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];

    // Only show "Crop" menu item if the annotation can be edited and crop is enabled.
    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]
        && [self.toolManager.imageStampAnnotationOptions isCropEnabled]) {
        
        // Check the image stamp's (arbitrary) rotation.
        PTObj *stampObj = [self.currentAnnotation GetSDFObj];
        PTObj *rotationObj = [stampObj FindObj:PTImageStampAnnotationRotationDegreeIdentifier];

        double rotation = 0;
        if ([rotationObj IsValid] && [rotationObj IsNumber]) {
            rotation = [rotationObj GetNumber];
        }
        rotation = fmod(rotation, 360);
        
        // Only show "Crop" menu item if image is *NOT* rotated at all.
        if (rotation == 0) {
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Crop", @"Crop image stamp menu item") action:@selector(cropSelectedImageStamp)];
            [menuItems addObject:menuItem];
        }
    }
}

- (void)attachPencilDrawingMenuItems:(NSMutableArray<UIMenuItem *> *)menuItems
{
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
    [menuItems addObject:menuItem];
    
    if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Edit", @"") action:@selector(editSelectedAnnotationPencilDrawing)];
        [menuItems addObject:menuItem];
    }
}

-(void)attachFreeTextFontSizeMenuItems
{
	NSMutableArray* menuItems = [[NSMutableArray alloc] initWithCapacity:2];

    UIMenuItem* menuItem;

	menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"8") action:@selector(setFreeTextSize8)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"11") action:@selector(setFreeTextSize11)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"16") action:@selector(setFreeTextSize16)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"24") action:@selector(setFreeTextSize24)];
    [menuItems addObject:menuItem];
	menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"36") action:@selector(setFreeTextSize36)];
    [menuItems addObject:menuItem];

	UIMenuController *theMenu = [UIMenuController sharedMenuController];
    theMenu.menuItems = menuItems;

}

- (void) attachBorderThicknessMenuItems
{
    NSMutableArray* menuItems = [[NSMutableArray alloc] initWithCapacity:2];

    UIMenuItem* menuItem;

	NSString* pt = PTLocalizedString(@"pt", @"Abbreviation for point, as in font point size.");

    menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"0.5 %@", pt] action:@selector(setAnnotBorder05)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"1 %@", pt] action:@selector(setAnnotBorder10)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"1.5 %@", pt] action:@selector(setAnnotBorder15)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"3 %@", pt] action:@selector(setAnnotBorder30)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"5 %@", pt] action:@selector(setAnnotBorder50)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"9 %@", pt] action:@selector(setAnnotBorder90)];
    [menuItems addObject:menuItem];

    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    theMenu.menuItems = menuItems;

}

- (void) attachOpacityMenuItems
{

    NSMutableArray* menuItems = [[NSMutableArray alloc] initWithCapacity:2];

    UIMenuItem* menuItem;

    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"25%") action:@selector(setAnnotOpacity25)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"50%") action:@selector(setAnnotOpacity50)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"75%") action:@selector(setAnnotOpacity75)];
    [menuItems addObject:menuItem];
    menuItem = [[UIMenuItem alloc] initWithTitle:PT_LocalizationNotNeeded(@"100%") action:@selector(setAnnotOpacity10)];
    [menuItems addObject:menuItem];

    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    theMenu.menuItems = menuItems;

}

- (void) attachInitialMenuItemsForAnnotType: (PTExtendedAnnotType) annotType
{
    NSMutableArray* menuItems = [[NSMutableArray alloc] init];

    UIMenuItem* menuItem;
    
    BOOL flattenEnabled = YES;

    switch (annotType) {
        case PTExtendedAnnotTypeText:
             menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
            [menuItems addObject:menuItem];
            break;
        case PTExtendedAnnotTypeLink:
            flattenEnabled = NO;
            break;
        case PTExtendedAnnotTypeFreeText:
        case PTExtendedAnnotTypeCallout:
            [self attachFreeTextMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypeArrow:
            [self attachFreeHandMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeRuler:
            [self attachMarkupMenuItems: menuItems];
            [self attachMeasurementMenuItems:menuItems];
            break;
        case PTExtendedAnnotTypePerimeter:
        case PTExtendedAnnotTypeArea:
            [self attachMarkupMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeSquare:
            [self attachMarkupMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeCircle:
            [self attachMarkupMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypeCloudy:
            [self attachMarkupMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypePolyline:
            [self attachMarkupMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeHighlight:
            [self attachHighlightAnnotMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeUnderline:
            [self attachTextAnnotMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeSquiggly:
            [self attachTextAnnotMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeStrikeOut:
            [self attachTextAnnotMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypeStamp:
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Note", @"") action:@selector(editSelectedAnnotationNote)];
            [menuItems addObject:menuItem];
            break;
        case PTExtendedAnnotTypeImageStamp:
            [self attachImageStampMenuItems:menuItems];
            break;
        case PTExtendedAnnotTypeSignature:
            [self attachSignatureMenuItems:menuItems];
            break;
        case PTExtendedAnnotTypePencilDrawing:
            [self attachPencilDrawingMenuItems:menuItems];
            break;
        case PTExtendedAnnotTypeCaret:
            break;
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypeFreehandHighlight:
            [self attachFreeHandMenuItems: menuItems];
            break;
        case PTExtendedAnnotTypePopup:
            break;
        case PTExtendedAnnotTypeFileAttachment:
            [self attachFileAttachmentMenuItems:menuItems];
            break;
        case PTExtendedAnnotTypeSound:
            flattenEnabled = NO;
            break;
        case PTExtendedAnnotTypeMovie:
            flattenEnabled = NO;
            break;
        case PTExtendedAnnotTypeWidget:
            break;
        case PTExtendedAnnotTypeScreen:
            break;
        case PTExtendedAnnotTypePrinterMark:
            break;
        case PTExtendedAnnotTypeTrapNet:
            break;
        case PTExtendedAnnotTypeWatermark:
            break;
        case PTExtendedAnnotType3D:
            break;
        case PTExtendedAnnotTypeRedact:
            flattenEnabled = NO;
            [self attachRedactionMenuItems:menuItems];
            break;
        case PTExtendedAnnotTypeProjection:
            break;
        case PTExtendedAnnotTypeRichMedia:
            flattenEnabled = NO;
            break;
        case PTExtendedAnnotTypeUnknown:
            break;
        default:
            break;
    }

     BOOL hasEditPermission = [self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation];
    
    if( hasEditPermission == NO )
    {
        flattenEnabled = NO;
    }

    if (self.numGroupsSelected > 1 && hasEditPermission){
        menuItems = [NSMutableArray array];
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Group", @"Group selected annotations menu item") action:@selector(groupSelectedAnnots)];
        [menuItems addObject:menuItem];
    }
    if (self.numGroupsSelected < self.selectedAnnotations.count && hasEditPermission) {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Ungroup", @"Ungroup selected annotations menu item") action:@selector(ungroupSelectedAnnots)];
        [menuItems addObject:menuItem];
    }
    
    if( flattenEnabled )
    {
        menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Flatten", @"") action:@selector(flattenSelectedAnnotations)];
        [menuItems addObject:menuItem];
    }


    // Add menu items common to all annotations EXCEPT movies.
    if( annotType != PTExtendedAnnotTypeRichMedia )
    {
        // Don't show "Copy" menu item for text markup annotations.
        BOOL shouldShowCopyItem = YES;
        for (PTAnnot *annot in self.selectedAnnotations) {
            switch (annot.extendedAnnotType) {
                case PTExtendedAnnotTypeHighlight:
                case PTExtendedAnnotTypeStrikeOut:
                case PTExtendedAnnotTypeSquiggly:
                case PTExtendedAnnotTypeUnderline:
                    shouldShowCopyItem = NO;
                    break;
                default:
                    break;
            }
            if (!shouldShowCopyItem) {
                break;
            }
        }
        if (shouldShowCopyItem) {
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Copy",
                                                                           @"Copy selected annotations")
                                                  action:@selector(copySelectedAnnotations)];
            [menuItems addObject:menuItem];
        }
        
        CGRect annotRect = self.annotRect;
        CGRect pdfViewCtrlBounds = self.pdfViewCtrl.bounds;

        // Add "Done" item for very large annotations that could be hard to tap outside to deselect.
        // An annotation is considered to be "large" if there is less than the standard tappable area
        // (44 pts) around any edge.
        // This assumes that all annotations are centered in the PDFViewCtrl's viewport, but this will
        // only add the "Done" item more often than if only the annotation's onscreen was considered.
        if (CGRectGetWidth(annotRect) > CGRectGetWidth(pdfViewCtrlBounds) - (44.0 * 2)
            && CGRectGetHeight(annotRect) > CGRectGetHeight(pdfViewCtrlBounds) - (44.0 * 2)) {
            // Add "Done" item to allow deselecting the annotation.
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Done", @"") action:@selector(deselectAnnotationAndExit)];
            [menuItems addObject:menuItem];
        }

        if ([self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
            menuItem = [[UIMenuItem alloc] initWithTitle:PTLocalizedString(@"Delete", @"") action:@selector(deleteSelectedAnnotation)];
            [menuItems addObject:menuItem];
        }
    }

    UIMenuController *theMenu = UIMenuController.sharedMenuController;

    theMenu.menuItems = menuItems;
}

-(void)flattenSelectedAnnotations
{
    [self flattenAnnotations:self.selectedAnnotations];
    
    [self deselectAnnotationAndExit];
}

- (void)deselectAnnotationAndExit
{
    [self deselectAnnotation];
    
    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:@"BackToPan"];
}

- (void)copySelectedAnnotations
{
    NSArray<PTAnnot *> *annotations = self.selectedAnnotations;
    if (annotations.count == 0) {
        return;
    }
    
    [PTAnnotationPasteboard.defaultPasteboard copyAnnotations:annotations
                                              withPDFViewCtrl:self.pdfViewCtrl
                                               fromPageNumber:self.annotationPageNumber
                                                   completion:^{
        NSLog(@"Annotations were copied");
    }];
}

- (void)editSelectedAnnotationSignature
{
    self.nextToolType = [PTDigitalSignatureTool class];
    [self.toolManager createSwitchToolEvent:[PTDigitalSignatureTool class]];
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    if (userData && [userData isEqual:[PTDigitalSignatureTool class]]) {
        self.nextToolType = [PTDigitalSignatureTool class];
        return NO;
    }else if (userData && [userData isEqual:@"EditPencilDrawing"]) {
        if (@available(iOS 13.1, *)) {
            self.nextToolType = [PTPencilDrawingCreate class];
            return NO;
        }
    } else if (userData && [userData isEqual:@"CropImageStamp"]) {
        self.nextToolType = [PTImageCropTool class];
        return NO;
    } else if (userData && [userData isEqual:@"BackToPan"]) {
        self.nextToolType = self.defaultClass;
        return NO;
    }
    else if( userData && [userData isEqual:@"Back to creation tool"] )
    {
        self.nextToolType = self.defaultClass;
        return NO;
    }
    
    return [super onSwitchToolEvent:userData];
}

- (PTPDFRect *)rectFromQuadPoint:(PTQuadPoint *)quadPoint
{
    PTPDFPoint *p1 = [quadPoint getP1];
    PTPDFPoint *p2 = [quadPoint getP2];
    PTPDFPoint *p3 = [quadPoint getP3];
    PTPDFPoint *p4 = [quadPoint getP4];

    double x1 = [p1 getX];
    double y1 = [p1 getY];
    double x2 = [p2 getX];
    double y2 = [p2 getY];
    double x3 = [p3 getX];
    double y3 = [p3 getY];
    double x4 = [p4 getX];
    double y4 = [p4 getY];

    double minX = fmin(x1, fmin(x2, fmin(x3, x4)));
    double minY = fmin(y1, fmin(y2, fmin(y3, y4)));
    double maxX = fmax(x1, fmax(x2, fmax(x3, x4)));
    double maxY = fmax(y1, fmax(y2, fmax(y3, y4)));

    PTPDFRect *rect = [[PTPDFRect alloc] initWithX1:minX y1:minY x2:maxX y2:maxY];
    [rect Normalize];

    return rect;
}

- (void)redact
{
    BOOL hasReadLock = NO;
    @try {
        [self.pdfViewCtrl DocLockRead];
        hasReadLock = YES;

        // Check if the current annotation and page number are valid.
        if (![self.currentAnnotation IsValid] || (self.annotationPageNumber == 0)) {
            return;
        }

        // Check that the current annotation is actually a redaction annotation.
        if (self.currentAnnotation.extendedAnnotType != PTExtendedAnnotTypeRedact) {
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        if (hasReadLock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }

    BOOL hasWriteLock = NO;
    @try {
        // we will be modifying the document, so obtain a write lock.
        // yes cancels any rendering that may be occuring
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;

        // Extract information out of the redaction annotation.
        PTRedactionAnnot *redactAnnot = [[PTRedactionAnnot alloc] initWithAnn:self.currentAnnotation];
        PTColorPt *fillColorPt = [redactAnnot GetInteriorColor];
        NSString *overlayText = [redactAnnot GetOverlayText];
        if (!overlayText) {
            overlayText = @"";
        }
        int quadPointCount = [redactAnnot GetQuadPointCount];
        PTVectorRedaction *vec = [[PTVectorRedaction alloc] init];

        // Create a redaction for each quadpoint in the redaction annotation.
        for (int i = 0; i < quadPointCount; i++) {
            PTQuadPoint *quadPoint = [redactAnnot GetQuadPoint:i];
            PTPDFRect *quadRect = [self rectFromQuadPoint:quadPoint];

            PTRedaction *redaction = [[PTRedaction alloc] initWithPage_num:self.annotationPageNumber bbox:quadRect negative:NO text:overlayText];
            [vec add:redaction];
        }

        // define the appearance of the redacted area
        PTAppearance *app = [[PTAppearance alloc] init];
        [app setUseOverlayText:YES];
        [app setPositiveOverlayColor:fillColorPt];
        [app setRedactionOverlay:YES];
        [app setBorder:NO];

        // redact the area
        [PTRedactor Redact:[self.pdfViewCtrl GetDoc] red_arr:vec app:app ext_neg_mode:NO page_coord_sys:NO];

        // delete the PTRedactAnnot
        [self deleteSelectedAnnotation];

        [self.pdfViewCtrl Update:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        if (hasWriteLock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
}

-(void)pdfViewCtrlOnSetDoc:(PTPDFViewCtrl *)pdfViewCtrl
{
    self.currentAnnotation = nil;

    [super pdfViewCtrlOnSetDoc:pdfViewCtrl];
}

-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    TrnPagePresentationMode mode = [self.pdfViewCtrl GetPagePresentationMode];

    int page = [self.pdfViewCtrl GetCurrentPage];


    if( self.annotationPageNumber != page && (mode == e_ptsingle_page || mode == e_ptfacing || mode == e_ptfacing_cover) )
    {
        self.currentAnnotation = nil;
        [self.selectionRectContainerView setHidden:YES];
        return;
    }
    else if( self.currentAnnotation )
    {
        // Prevent "implicit" UIView animations on the selection rect(s) during a layout change.
        // Without this, the selection rect(s) will slide into place over the PDF content during a
        // interface orientation change.
        [UIView performWithoutAnimation:^{
            [self reSelectAnnotation];
        }];
        if (!CGRectEqualToRect(CGRectZero, firstSelectionRect) && movingAnnot) {
            // Correct first selection rect if the layout changes while dragging
            firstSelectionRect = self.selectionRectContainerView.groupSelectionRectView.frame;
            // Convert to screen space
            firstSelectionRect = [self.selectionRectContainerView convertRect:firstSelectionRect toView:self.pdfViewCtrl];
        }
        if ([self.currentAnnotation IsMarkup]) {
            PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.currentAnnotation];
            self.startingAnnotationRect = [self contentRectInScreenCoordinatesForAnnot:markup];
        }
    }

    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
}

- (BOOL)annotIsMovable:(PTAnnot *)annot
{
    if (![annot IsValid]) {
        return NO;
    }

    if (self.selectedAnnotations.count > 1) {
        for (PTAnnot *groupAnnot in self.selectedAnnotations) {
            PTExtendedAnnotType groupAnnotType = groupAnnot.extendedAnnotType;
            switch (groupAnnotType) {
                    // No-moveable annotation types.
                case PTExtendedAnnotTypeLink:
                case PTExtendedAnnotTypeHighlight:
                case PTExtendedAnnotTypeUnderline:
                case PTExtendedAnnotTypeStrikeOut:
                case PTExtendedAnnotTypeSquiggly:
                case PTExtendedAnnotTypeRichMedia:
                case PTExtendedAnnotTypeRedact:
                    return NO;
                default:
                    break;
            }


            // Check with the tool manager.
            if (![self.toolManager tool:self hasEditPermissionForAnnot:groupAnnot]) {
                return NO;
            }
        }
    }

    PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;
    switch (annotType) {
        // No-moveable annotation types.
        case PTExtendedAnnotTypeLink:
        case PTExtendedAnnotTypeHighlight:
        case PTExtendedAnnotTypeUnderline:
        case PTExtendedAnnotTypeStrikeOut:
        case PTExtendedAnnotTypeSquiggly:
        case PTExtendedAnnotTypeRichMedia:
        case PTExtendedAnnotTypeRedact:
            return NO;
        default:
            break;
    }


    // Check with the tool manager.
    if (![self.toolManager tool:self hasEditPermissionForAnnot:annot]) {
        return NO;
    }

    return YES;
}

-(BOOL)annotIsResizable:(PTAnnot*)annot
{
    if (![annot IsValid]) {
        return YES;
    }

    if (self.selectedAnnotations.count > 1) {
        for (PTAnnot *groupAnnot in self.selectedAnnotations) {
            PTExtendedAnnotType groupAnnotType = groupAnnot.extendedAnnotType;
            switch (groupAnnotType) {
                    // Non-resizeable annotation types.
                case PTExtendedAnnotTypeLink:
                case PTExtendedAnnotTypeText:
                case PTExtendedAnnotTypeHighlight:
                case PTExtendedAnnotTypeUnderline:
                case PTExtendedAnnotTypeStrikeOut:
                case PTExtendedAnnotTypeSquiggly:
                case PTExtendedAnnotTypeRichMedia:
                case PTExtendedAnnotTypeFileAttachment:
                case PTExtendedAnnotTypeImageStamp:
                case PTExtendedAnnotTypeRedact:
                    return NO;
                default:
                    break;
            }


            // Check with the tool manager.
            if (![self.toolManager tool:self hasEditPermissionForAnnot:groupAnnot]) {
                return NO;
            }
        }
    }

    PTExtendedAnnotType annotType = annot.extendedAnnotType;
    switch (annotType) {
        // Non-resizeable annotation types.
        case PTExtendedAnnotTypeLink:
        case PTExtendedAnnotTypeText:
        case PTExtendedAnnotTypeHighlight:
        case PTExtendedAnnotTypeUnderline:
        case PTExtendedAnnotTypeStrikeOut:
        case PTExtendedAnnotTypeSquiggly:
        case PTExtendedAnnotTypeRichMedia:
        case PTExtendedAnnotTypeFileAttachment:
        case PTExtendedAnnotTypeRedact:
            return NO;
        default:
            break;
    }


    // Check with the tool manager.
    if (![self.toolManager tool:self hasEditPermissionForAnnot:annot]) {
        return NO;
    }

    return YES;
}

-(void)setRectForGroupAnnot:(PTAnnot *)annotation
{
    for (UIView *subView in self.selectionRectContainerView.groupSelectionRectView.subviews) {
        [subView removeFromSuperview];
    }

    self.selectionRectContainerView.groupSelectionRectView.transform = CGAffineTransformIdentity;

    CGRect unionCGRect = CGRectNull;
    CGRect mainAnnotRect = CGRectNull;

    @try {
        [self.pdfViewCtrl DocLockRead];
        if (![annotation IsValid]) {
            return;
        }
        BOOL annotRectSet = NO;
        for (PTAnnot *annot in self.selectedAnnotations) {
            PTPDFRect *annotScreenRect = [self.pdfViewCtrl GetScreenRectForAnnot:annot page_num:self.annotationPageNumber];
            
            CGRect annotCGRect = [self PDFRectScreen2CGRectScreen:annotScreenRect PageNumber:self.annotationPageNumber];
            
            if( [annot GetType] == e_ptSquare )
            {
                PTSquare* sq = [[PTSquare alloc] initWithAnn:annot];
                annotCGRect = [self contentRectInScreenCoordinatesForAnnot:sq];
            }
            else
            {
                annotCGRect = [self tightScreenBoundingBoxForAnnot:annot];
            }
            
            annotCGRect = CGRectOffset(annotCGRect, [self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos]);

            if (!annotRectSet) {
                // First annot in the group will always be the main annot
                mainAnnotRect = annotCGRect;
                self.currentAnnotation = annot;
                annotRectSet = YES;
            }

//            if (!annot.hasReplyTypeGroup) {
//                mainAnnotRect = annotCGRect;
//                self.currentAnnotation = annot;
//            }

            unionCGRect = CGRectUnion(unionCGRect,annotCGRect);

            UIView *subAnnotView = [[UIView alloc] initWithFrame:annotCGRect];
            subAnnotView.userInteractionEnabled = NO;
            subAnnotView.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:1.0 alpha:0.2];
            [self.selectionRectContainerView.groupSelectionRectView addSubview:subAnnotView];
        }

        for (UIView *subView in self.selectionRectContainerView.groupSelectionRectView.subviews) {
            CGRect frame = subView.frame;
            CGVector offsetFromMainAnnot = PTCGPointOffsetFromPoint(frame.origin, unionCGRect.origin);
            CGPoint newOrigin = PTCGVectorOffsetPoint(CGPointZero, offsetFromMainAnnot);
            frame.origin = newOrigin;
            subView.frame = frame;
        }
        CGRect originalUnionRect = unionCGRect;
        unionCGRect.origin = CGPointZero;

        const int length = PTResizeWidgetView.length*0.5;
        CGVector resizeHandleOffset = CGVectorMake(length, length);
        unionCGRect.origin = PTCGVectorOffsetPoint(unionCGRect.origin, resizeHandleOffset);

        self.selectionRectContainerView.groupSelectionRectView.frame = unionCGRect;
        self.annotRect = originalUnionRect;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", [exception name], [exception reason]);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
}

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber
{
    return [self selectAnnotation:annotation onPageNumber:pageNumber showMenu:!PT_ToolsMacCatalyst];
}

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber showMenu:(BOOL)showMenu
{
    CGRect menuRect;
    @try {
        [self.pdfViewCtrl DocLockRead];

        if (![annotation IsValid] || pageNumber == 0) {
            return NO;
        }

        PTExtendedAnnotType annotType = [annotation extendedAnnotType];
        if (annotType == PTExtendedAnnotTypeLink) {
            return NO;
        }

        if (![self.toolManager tool:self canEditAnnotation:annotation]) {
            // Cannot select/edit annotation.
            return NO;
        }

        // if the delegate wants to do something other than selecting the annotation, allow it to
        // interrupt here.
        if( ![self shouldSelectAnnotation:annotation onPageNumber:pageNumber] )
        {
            return NO;
        }
        
        self.annotationPageNumber = pageNumber;
        self.currentAnnotation = annotation;
        
        [self.selectionRectContainerView setAnnot:self.currentAnnotation];
        
        NSArray *groupAnnotations;
        groupAnnotations = self.currentAnnotation.annotationsInGroup;

        self.annotRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];

        if (self.selectedAnnotations.count == 0) {
            self.selectedAnnotations = groupAnnotations;
        }
        feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [feedbackGenerator prepare];
        self.annotRect = CGRectOffset(self.annotRect, [self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos]);
        [self setRectForGroupAnnot:self.currentAnnotation];
        [self.selectionRectContainerView setFrameFromAnnot:self.annotRect];
        self.selectionRectContainerView.displaysOnlyCornerResizeHandles = self.maintainAspectRatio;
        //self.selectionRectContainerView.frame = self.annotRect;
        [self.selectionRectContainerView setHidden:NO];

        if( ![self annotIsResizable:self.currentAnnotation]) {
            [self.selectionRectContainerView hideResizeWidgetViews];
        } else {
            [self.selectionRectContainerView showResizeWidgetViews];
        }

        if( [self.selectionRectContainerView superview] != self.pdfViewCtrl.toolOverlayView )
        {
            [self.pdfViewCtrl.toolOverlayView addSubview:self.selectionRectContainerView];
        }
        annotType = [self.currentAnnotation extendedAnnotType];
        [self attachInitialMenuItemsForAnnotType:annotType];

        self.annotRect = CGRectOffset(self.annotRect, - [self.pdfViewCtrl GetHScrollPos], - [self.pdfViewCtrl GetVScrollPos]);

        menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);

        if (annotType == PTExtendedAnnotTypeImageStamp) {
            [self setRotationHandlePosition];
        }

        [self didSelectAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];

        // Successfully selected annotation.
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    } @finally {
        [self.pdfViewCtrl DocUnlockRead];
        if( showMenu )
        {
            [self showSelectionMenu:menuRect];
        }
    }

    return NO;
}

-(void)setRotationHandlePosition
{
    UIMenuController *theMenu = [UIMenuController sharedMenuController];
    CGRect windowRect = self.pt_viewController.view.window.frame;
    CGRect annotRect = [self.selectionRectContainerView.superview convertRect:self.selectionRectContainerView.frame toView:self.pt_viewController.view];

    CGFloat leftMargin = annotRect.origin.x - windowRect.origin.x;
    CGFloat rightMargin = (windowRect.origin.x + windowRect.size.width) - (annotRect.origin.x+annotRect.size.width);
    CGFloat topMargin = annotRect.origin.y - windowRect.origin.y;
    CGFloat bottomMargin = (windowRect.origin.y + windowRect.size.height) - (annotRect.origin.y+annotRect.size.height);

    NSDictionary<NSNumber*, NSNumber*> *locationDistanceDict;
    locationDistanceDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithDouble:topMargin], [NSNumber numberWithInt:PTRotateHandleLocationTop],
                            [NSNumber numberWithDouble:leftMargin], [NSNumber numberWithInt:PTRotateHandleLocationLeft],
                            [NSNumber numberWithDouble:bottomMargin], [NSNumber numberWithInt:PTRotateHandleLocationBottom],
                            [NSNumber numberWithDouble:rightMargin], [NSNumber numberWithInt:PTRotateHandleLocationRight],
                            nil];

    NSArray *locationsByDistance = [locationDistanceDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
        if ([obj1 doubleValue] > [obj2 doubleValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        if ([obj1 integerValue] < [obj2 integerValue]) {

            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    // Place the handle on the side furthest from the edge of the window
    PTRotateHandleLocation handleLocation = [locationsByDistance.firstObject intValue];

    // If the menu controller is on the same side as the handle, place it on the next furthest side
    switch (handleLocation) {
        case PTRotateHandleLocationTop:
            if (theMenu.menuFrame.origin.y < annotRect.origin.y) {
                handleLocation = [locationsByDistance[1] intValue];
            }
            break;
        case PTRotateHandleLocationLeft:
            if (theMenu.menuFrame.origin.x < annotRect.origin.x) {
                handleLocation = [locationsByDistance[1] intValue];
            }
            break;
        case PTRotateHandleLocationBottom:
            if (theMenu.menuFrame.origin.y + theMenu.menuFrame.size.height > annotRect.origin.y + annotRect.size.height) {
                handleLocation = [locationsByDistance[1] intValue];
            }
            break;
        case PTRotateHandleLocationRight:
            if (theMenu.menuFrame.origin.x + theMenu.menuFrame.size.width > annotRect.origin.x + annotRect.size.width) {
                handleLocation = [locationsByDistance[1] intValue];
            }
            break;
        default:
            break;
    }
    [self.selectionRectContainerView setRotationHandleLocation:handleLocation];
}


- (void) reSelectAnnotation
{
    PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];

    if( (![self.currentAnnotation IsValid] || self.selectionRectContainerView.hidden) && annotType != PTExtendedAnnotTypeWidget )
        return;
    
    if ([self selectAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber]) {
        // Successfully selected annotation.
        if (annotType == PTExtendedAnnotTypeFreeText ||
            annotType == PTExtendedAnnotTypeCallout) {
            @try {
                [self.pdfViewCtrl DocLockRead];

                PTFreeText *ft = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];

                [self.selectionRectContainerView setEditTextSizeForZoom:[self.pdfViewCtrl GetZoom] forFontSize:[ft GetFontSize]];
            } @catch (NSException *exception) {
                NSLog(@"Exception: %@: %@", exception.name, exception.reason);
            } @finally {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    }

    // Demonstrates how to extract text under an annotation.
//    TextExtractor *textExtractor = [[TextExtractor alloc] init];
//    [textExtractor Begin:[self.currentAnnotation GetPage]
//                clip_ptr:0
//                   flags:e_no_ligature_exp];
//
//    NSString* annotationText = [textExtractor GetTextUnderAnnot:self.currentAnnotation];
//
//    NSLog(@"Text under annot is %@", annotationText);
}

- (BOOL) makeNewAnnotationSelection: (UIGestureRecognizer *) gestureRecognizer{
    CGPoint location = [gestureRecognizer locationInView:self.pdfViewCtrl];
    return [self makeNewAnnotationSelectionAtLocation:location];
}

- (BOOL) makeNewAnnotationSelectionAtLocation:(CGPoint)location
{
    unsigned int newOBJNum = [[[self.pdfViewCtrl GetAnnotationAt:location.x y:location.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT] GetSDFObj] GetObjNum];
    unsigned int oldOBJNum = [[self.currentAnnotation GetSDFObj] GetObjNum];
    if( newOBJNum == oldOBJNum && !CGSizeEqualToSize(self.selectionRectContainerView.selectionRectView.bounds.size, CGSizeZero) )
    {
        return YES;
    }
    
    [self deselectAnnotation];
    [self.selectionRectContainerView setNeedsDisplay];
    if( self.currentAnnotation )
    {
        [self deselectAnnotation];
        [self.pdfViewCtrl setNeedsDisplay];
    }
    BOOL hasReadLock = NO;
    BOOL hasWriteLock = NO;
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        hasReadLock = YES;
        
        self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:location.x y:location.y];

		self.currentAnnotation = [self.pdfViewCtrl GetAnnotationAt:location.x y:location.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];

        


        PTLinkInfo* linkInfo = 0;

        // checks if there is text that looks like a link but is missing a link annot
        // note that [pdfViewCtrl SetUrlExtraction:YES]; must be called
        if( ![self.currentAnnotation IsValid] )
            linkInfo = [self.pdfViewCtrl GetLinkAt:location.x y:location.y];


        if( [self.currentAnnotation IsValid] || (linkInfo.getUrl).length > 0)
        {

            if( [self.currentAnnotation IsValid] && ([self.currentAnnotation extendedAnnotType] == PTExtendedAnnotTypeStamp ||
                                                     [self.currentAnnotation extendedAnnotType] == PTExtendedAnnotTypeImageStamp ||
                                                     [self.currentAnnotation extendedAnnotType] == PTExtendedAnnotTypeSignature) ) {
                self.maintainAspectRatio = YES;
            } else {
                self.maintainAspectRatio = NO;
            }

            PTExtendedAnnotType annotType= -1;

            if( [self.currentAnnotation IsValid] )
            {
                annotType = [self.currentAnnotation extendedAnnotType];
                self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:location.x y:location.y];
            }

            // IF IT IS HYPERLINK, FOLLOW HYPERLINK INSTEAD
            if((annotType == PTExtendedAnnotTypeLink || (linkInfo.getUrl).length > 0) )
            {
                // external links

                if (![self.toolManager isLinkFollowingEnabledForTool:self]) {
                    // Link following is disabled.
                    return YES;
                }

                CGRect screenRect;
                PTActionType actionType = e_pta_Unknown;
                PTAction* action;
                PTLink* myLink;

                if( annotType == PTExtendedAnnotTypeLink )
                {
                    myLink = [[PTLink alloc] initWithAnn:self.currentAnnotation];

                    action = [myLink GetAction];

                    actionType = [action GetType];

					PTPDFRect* screen_rect = [self.pdfViewCtrl GetScreenRectForAnnot: self.currentAnnotation page_num: self.annotationPageNumber];

					screenRect = [self PDFRectScreen2CGRectScreen:screen_rect PageNumber:self.annotationPageNumber];
                    screenRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];
                    linkInfo = nil;

                }
                else // extracted link
                {
                    PTPDFRect* rect = [linkInfo getRect];
                    [rect setSwigCMemOwn:NO];
                    int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:location.x y:location.y];
                    screenRect = [self PDFRectPage2CGRectScreen:rect PageNumber:pageNumber];
                    self.currentAnnotation = nil;
                }

                screenRect.origin.x += [self.pdfViewCtrl GetHScrollPos];
                screenRect.origin.y += [self.pdfViewCtrl GetVScrollPos];

                if(![self shouldHandleLinkAnnotation:self.currentAnnotation orLinkInfo:linkInfo onPageNumber:[self.pdfViewCtrl GetPageNumberFromScreenPt:location.x y:location.y]])
                {
                    // delegate wants to handle the link, so return now.
                    return YES;
                }

                UIView* flashLink = [[UIView alloc] initWithFrame:screenRect];

                flashLink.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];

                [self.pdfViewCtrl.toolOverlayView addSubview:flashLink];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [flashLink removeFromSuperview];
                });

                if( [linkInfo.getUrl length] > 0 )
                {
                    // extracted link
                    NSString* uriDestination = [linkInfo getUrl];

                    // prepends http if no scheme is present, otherwise links with text such as www.pdftron.com won't open
                    uriDestination = [PTLink GetNormalizedUrl:uriDestination];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [UIApplication.sharedApplication openURL:[NSURL URLWithString: uriDestination] options:@{} completionHandler:Nil];
                    });

                    self.currentAnnotation = nil;
                    self.annotationPageNumber = 0;
                    return YES;
                }
                else if([action IsValid])
                {

                    if([action NeedsWriteLock])
                    {
                        hasReadLock = NO;
                        [self.pdfViewCtrl DocUnlockRead];
                        [self.pdfViewCtrl DocLock:true];
                        hasWriteLock = YES;
                    }
                    PTActionParameter* action_parameter = [[PTActionParameter alloc]initWithAction:action annot:self.currentAnnotation];
                    [self executeAction:action_parameter];
                    return YES;
                }
            }

            return [self selectAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        }
        else
        {
            self.currentAnnotation = nil;
        }

        self.nextToolType = self.defaultClass;
        return NO;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if(hasReadLock)
        {
            [self.pdfViewCtrl DocUnlockRead];
        }
        if(hasWriteLock)
        {
            [self.pdfViewCtrl DocUnlock];
        }
    }

}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( [scrollView isKindOfClass:[UITextView class]] )
    {
        // scrolling PDF form widget
    }
    else
    {
        // sent from outside
    }
}

#pragma mark - Handle Touches

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    moveOccuredPreTap = YES;
    
    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
    
    unsigned int newOBJNum = [[[self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT] GetSDFObj] GetObjNum];
    unsigned int oldOBJNum = [[self.currentAnnotation GetSDFObj] GetObjNum];
    
    if( newOBJNum == oldOBJNum && !CGSizeEqualToSize(self.selectionRectContainerView.selectionRectView.bounds.size, CGSizeZero))
    {
        if ([self.currentAnnotation IsValid] &&
            self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeFreeText &&
            [self.toolManager tool:self hasEditPermissionForAnnot:self.currentAnnotation]) {
            [self editSelectedAnnotationFreeText];
        }
        return YES;
    }
    
    [self deselectAnnotation];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        if (self.selectionRectContainerView.superview == nil)
        {
            if( [self makeNewAnnotationSelection: gestureRecognizer] )
            {
                //remove appearance views
                [self removeAppearanceViews];

                if( [self.currentAnnotation IsValid] )
                {
                    PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];

					// check for self.superview to prevent two popovers from being created
					// in while loops in PTCreateToolBase handleTap: and PTTextMarkupCreate
					// handleTap:
                    if( annotType == PTExtendedAnnotTypeText &&
                       (self.superview || [self isKindOfClass:[PTPanTool class]]) &&
                       self.toolManager.textAnnotationOptions.opensPopupOnTap)
                    {
                        [self hideMenu];
                        [self.stylePicker selectStyle];
                        [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
                        [self editSelectedAnnotationNote];
                    }
                }

                return  YES;
            }
        }

        CGPoint touchPoint = [gestureRecognizer locationInView:self.selectionRectContainerView];

        if( !CGRectContainsPoint(self.selectionRectContainerView.bounds, touchPoint) || self.currentAnnotation == nil)
        {
            self.nextToolType = self.defaultClass;

            return  NO;
        }

    }

    //[self.selectionRectContainerView setHidden:NO];

    [self reSelectAnnotation];

    //[self showSelectionMenu:self.annotRect];

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if( [self.pdfViewCtrl GetDoc] == nil )
    {
        return YES;
    }

    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }
    
    moveOccuredPreTap = YES;

	if (self.selectionRectContainerView.hidden)
    {
        [self deselectAnnotation];
        self.nextToolType = self.defaultClass;
        return NO;
    }

    if (![self.currentAnnotation IsValid] ) {
        return YES;
    }

    UITouch *touch = touches.allObjects[0];

    CGPoint down = [touch locationInView:touch.view];

    self.touchOffset = CGPointMake(-down.x, -down.y);

    switch (self.currentAnnotation.extendedAnnotType) {
        case PTExtendedAnnotTypeStamp:
        case PTExtendedAnnotTypeImageStamp:
        case PTExtendedAnnotTypeSignature:
            self.maintainAspectRatio = YES;
            break;
        default:
            self.maintainAspectRatio = NO;
            break;
    }
    
    if(![touch.view isKindOfClass:[PTRotateWidgetView class]])
    {
        [self.selectionRectContainerView.rotationHandle setHidden:YES];
    }

    if ([touch.view isKindOfClass:[PTSelectionRectContainerView class]])
    {
        down = [touch locationInView:self.pdfViewCtrl];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

        if( movingAnnot == NO )
        {
            firstSelectionRect = self.selectionRectContainerView.groupSelectionRectView.frame;
            // Convert to screen space
            firstSelectionRect = [self.selectionRectContainerView convertRect:firstSelectionRect toView:self.pdfViewCtrl];
        }
        movingAnnot = YES;
        

        
        [self.stickyTimer invalidate];
        self.stickyTimer = [PTTimer scheduledTimerWithTimeInterval:0.50f target:self selector:Nil userInfo:Nil repeats:NO];
        self.stickyBlocked = YES;
        self.stickyPoint = down;
        
        return YES;
    }
    else if([touch.view isKindOfClass:[PTResizeWidgetView class]])
    {

        UITouch *touch = touches.allObjects[0];

        CGPoint down = [touch locationInView:self.pdfViewCtrl];
//        CGPoint downInWidget = [touch locationInView:touch.view];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

        shouldTriggerHaptic = NO;
        firstSelectionRect = self.selectionRectContainerView.groupSelectionRectView.frame;
        // Convert to screen space
        firstSelectionRect.origin.x += self.selectionRectContainerView.frame.origin.x;
        firstSelectionRect.origin.y += self.selectionRectContainerView.frame.origin.y;

        if ([self isAspectRatioGuideEnabled] &&
            [self.selectionRectContainerView.subviews containsObject:touch.view]) {
            aspectRatioGuideLayer = [CAShapeLayer layer];
            aspectRatioGuideLayer.strokeColor = self.tintColor.CGColor;
            aspectRatioGuideLayer.lineWidth = 2;
            aspectRatioGuideLayer.lineDashPattern = @[@4];
            
            NSArray *points = PTVerticesFromRect(self.selectionRectContainerView.groupSelectionRectView.frame);
            NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(NSValue *first, NSValue *second) {
                CGPoint firstPt = [first CGPointValue];
                CGPoint secondPt = [second CGPointValue];
                CGFloat xDist1 = (firstPt.x - touch.view.center.x);
                CGFloat yDist1 = (firstPt.y - touch.view.center.y);
                CGFloat distance1 = sqrt(xDist1 * xDist1 + yDist1 * yDist1);
                CGFloat xDist2 = (secondPt.x - touch.view.center.x);
                CGFloat yDist2 = (secondPt.y - touch.view.center.y);
                CGFloat distance2 = sqrt(xDist2 * xDist2 + yDist2 * yDist2);
                return (distance1 > distance2);
            }];
            
            CGPoint nearestPoint = [sortedPoints.firstObject CGPointValue];
            CGPoint oppositePoint = [sortedPoints.lastObject CGPointValue];
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:nearestPoint];
            [path addLineToPoint:oppositePoint];
            aspectRatioGuideLayer.path = path.CGPath;
            [self.selectionRectContainerView.layer addSublayer:aspectRatioGuideLayer];
            aspectRatioGuideLayer.hidden = YES;
        }

        firstTouchPoint = down;
        mostRecentTouchPoint = down;

        self.touchedSelectWidget = touch.view;
        
        [self animateHandle:self.touchedSelectWidget];

        return YES;
    }
    else if([touch.view isKindOfClass:[PTRotateWidgetView class]])
    {
        down = [touch locationInView:self.pdfViewCtrl];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];
        firstTouchPoint = down;
        mostRecentTouchPoint = down;
//        [self animateHandle:touch.view];

        rotationCenter = [self.selectionRectContainerView convertPoint:self.selectionRectContainerView.selectionRectView.center toView:self.selectionRectContainerView.superview];
        rotatingAnnot = YES;

        [self startRotation];
        return YES;
    }
    
    [self deselectAnnotation];
    self.nextToolType = self.toolManager.tool.defaultClass;

    if( [self.nextToolType createsAnnotation] )
    {
        [self.toolManager createSwitchToolEvent:@"Back to creation tool"];
    
        return YES;
    }
    
    return NO;
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    moveOccuredPreTap = NO;

    if( ![self.currentAnnotation IsValid] )
    {
        return YES;
    }

    PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];

    if (![self annotIsMovable:self.currentAnnotation]) {
        return YES;
    }

    UITouch *touch = touches.allObjects[0];

    if ([touch.view isKindOfClass:[PTSelectionRectContainerView class]] && [[event allTouches]count] == 1)
    {
        CGPoint down = [touch locationInView:self.pdfViewCtrl];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];


        [self moveSelectionRect:down];
        
        
        
    }
    else if([touch.view isKindOfClass:[PTResizeWidgetView class]] &&
            [self.selectionRectContainerView.subviews containsObject:touch.view])
    {

        if (annotType == PTExtendedAnnotTypeText ) {
            return YES;
        }

        CGPoint down = [touch locationInView:self.pdfViewCtrl];
        

        PTResizeWidgetView* resizeWidget = (PTResizeWidgetView*)touch.view;

        PTResizeHandleLocation location = resizeWidget.location;

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

        CGVector precisionCorrection = PTCGVectorZero;
        CGPoint downUnmodified = down;
        if( self.maintainAspectRatio)
        {
            CGPoint linePointA;
            CGPoint linePointB;

            if( location == PTResizeHandleLocationTopLeft || location == PTResizeHandleLocationBottomRight )
            {
                linePointA = CGPointMake(firstSelectionRect.origin.x, firstSelectionRect.origin.y);
                linePointB = CGPointMake(firstSelectionRect.origin.x + firstSelectionRect.size.width, firstSelectionRect.origin.y + firstSelectionRect.size.height);
            }
            else // e_topright || e_bottomleft
            {
                linePointA = CGPointMake(firstSelectionRect.origin.x + firstSelectionRect.size.width, firstSelectionRect.origin.y);
                linePointB = CGPointMake(firstSelectionRect.origin.x, firstSelectionRect.origin.y + firstSelectionRect.size.height);
            }

            double APx, APy, ABx, ABy;
             APx = down.x - linePointA.x;
             APy = down.y - linePointA.y;
             ABx = linePointB.x - linePointA.x;
             ABy = linePointB.y - linePointA.y;

            double magAB2 = ABx*ABx + ABy*ABy;
            double ABdotAP = ABx*APx + ABy*APy;
            double t = ABdotAP / magAB2;


            down.x = linePointA.x + ABx*t;
            down.y = linePointA.y + ABy*t;

            if( CGPointEqualToPoint(self.maintainAspectRatioTouchOffset, CGPointZero) )
            {
                self.maintainAspectRatioTouchOffset = CGPointMake(down.x - firstTouchPoint.x, down.y - firstTouchPoint.y);
            }
        }else if([self.currentAnnotation GetType] != e_ptLine &&
                 [self.currentAnnotation GetType] != e_ptPolyline &&
                 [self.currentAnnotation GetType] != e_ptPolygon &&
                 self.toolManager.annotationsSnapToAspectRatio){
            if (location == PTResizeHandleLocationTop ||
                location == PTResizeHandleLocationLeft ||
                location == PTResizeHandleLocationBottom ||
                location == PTResizeHandleLocationRight){
                [self snapToPerfectShape:&down];
            }else{
                [self snapToAspectRatio:&down];
            }
        }

        
        if(CGPointEqualToPoint(aspectSnapPoint, firstTouchPoint))
        {
            // In precision mode, apply offset correction
            precisionCorrection = PTCGPointOffsetFromPoint(down, downUnmodified);
        }
        CGPoint delta;
        delta.x = down.x - firstTouchPoint.x - self.maintainAspectRatioTouchOffset.x - precisionCorrection.dx;
        delta.y = down.y - firstTouchPoint.y - self.maintainAspectRatioTouchOffset.y - precisionCorrection.dy;
        mostRecentTouchPoint = down;

        if( location == PTResizeHandleLocationTopLeft )
            [self setSelectionRectDelta:CGRectMake(delta.x, delta.y, -delta.x, -delta.y)];
        else if( location == PTResizeHandleLocationTop )
            [self setSelectionRectDelta:CGRectMake(0, delta.y, 0, -delta.y)];
        else if( location == PTResizeHandleLocationTopRight )
            [self setSelectionRectDelta:CGRectMake(0, delta.y, delta.x, -delta.y)];
        else if( location == PTResizeHandleLocationRight )
            [self setSelectionRectDelta:CGRectMake(0, 0, delta.x, 0)];
        else if( location == PTResizeHandleLocationBottomRight )
            [self setSelectionRectDelta:CGRectMake(0, 0, delta.x, delta.y)];
        else if( location == PTResizeHandleLocationBottom )
            [self setSelectionRectDelta:CGRectMake(0, 0, 0, delta.y)];
        else if( location == PTResizeHandleLocationBottomLeft )
            [self setSelectionRectDelta:CGRectMake(delta.x, 0, -delta.x, delta.y)];
        else if( location == PTResizeHandleLocationLeft )
            [self setSelectionRectDelta:CGRectMake(delta.x, 0, -delta.x, 0)];


        self.selectionRectContainerView.rotationHandle.hidden = YES;
        
    }
    if (rotatingAnnot) {
        CGPoint down = [touch locationInView:self.pdfViewCtrl];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

        CGPoint delta;
        delta.x = down.x - firstTouchPoint.x;
        delta.y = down.y - firstTouchPoint.y;

        double dx = (down.x - rotationCenter.x);
        double dy = -(down.y - rotationCenter.y);
        double angle = atan2(dy, dx);
        double firstTouchAngle = atan2(rotationCenter.x-firstTouchPoint.x, (firstTouchPoint.y-rotationCenter.y));
        angle += firstTouchAngle + M_PI_2; // Account for direction
        angle = angle < 0 ? 2*M_PI + angle : angle;

        [self rotateAnnot:-angle];
    }
    return YES;
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

    moveOccuredPreTap = YES;
    
    if (aspectRatioGuideLayer) {
        [aspectRatioGuideLayer removeFromSuperlayer];
        aspectRatioGuideLayer = nil;
    }
    
    self.selectionRectContainerView.rotationHandle.hidden = NO;

    if( ![self.currentAnnotation IsValid] )
    {
        return YES;
    }
    movingAnnot = NO;
    PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];

    if (annotType == PTExtendedAnnotTypeImageStamp && rotatingAnnot) {
        [self resetHandleTransformsWithFeedback:YES];
        CGAffineTransform transform = self.selectionRectContainerView.transform;
        double angle = atan2(transform.b, transform.a);
        [self rotationFinishedWithAngle:angle];
        rotatingAnnot = NO;
        return YES;
    }

    if (![self annotIsMovable:self.currentAnnotation]) {

		UITouch *touch = touches.allObjects[0];

		CGPoint down = [touch locationInView:self.pdfViewCtrl];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

		PTAnnot* touchedAnnot = [self.pdfViewCtrl GetAnnotationAt:down.x y:down.y distanceThreshold:GET_ANNOT_AT_DISTANCE_THRESHOLD minimumLineWeight:GET_ANNOT_AT_MINIMUM_LINE_WEIGHT];

		if( ![touchedAnnot IsValid] )
		{
            CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
            
            [self showSelectionMenu:menuRect];

		}

        return YES;
    }

    UITouch *touch = touches.allObjects[0];

    if ([touch.view isKindOfClass:[PTSelectionRectContainerView class]])
    {

        [self moveAnnotation:self.stickyPoint];
        
        
        CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
        
        if( PT_ToolsMacCatalyst == NO)
        {
            [self showSelectionMenu:menuRect];
        }

    }
    else if([touch.view isKindOfClass:[PTResizeWidgetView class]])
    {
        [self resetHandleTransformsWithFeedback:YES];
        self.touchedSelectWidget = nil;
        if (annotType == PTExtendedAnnotTypeText ) {
            return YES;
        }

        CGPoint down = [touch locationInView:self.pdfViewCtrl];

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

        CGPoint delta;
        delta.x = down.x - firstTouchPoint.x;
        delta.y = down.y - firstTouchPoint.y;

        mostRecentTouchPoint = down;

        PTResizeWidgetView* resizeWidget = (PTResizeWidgetView*)touch.view;

        PTResizeHandleLocation location = resizeWidget.location;

        if ([self.selectionRectContainerView.subviews containsObject:resizeWidget]) {
            if( location == PTResizeHandleLocationTopLeft )
                [self setAnnotationRectDelta:CGRectMake(delta.x, delta.y, -delta.x, -delta.y)];
            else if( location == PTResizeHandleLocationTop )
                [self setAnnotationRectDelta:CGRectMake(0, delta.y, 0, -delta.y)];
            else if( location == PTResizeHandleLocationTopRight )
                [self setAnnotationRectDelta:CGRectMake(0, delta.y, delta.x, -delta.y)];
            else if( location == PTResizeHandleLocationRight )
                [self setAnnotationRectDelta:CGRectMake(0, 0, delta.x, 0)];
            else if( location == PTResizeHandleLocationBottomRight )
                [self setAnnotationRectDelta:CGRectMake(0, 0, delta.x, delta.y)];
            else if( location == PTResizeHandleLocationBottom )
                [self setAnnotationRectDelta:CGRectMake(0, 0, 0, delta.y)];
            else if( location == PTResizeHandleLocationBottomLeft )
                [self setAnnotationRectDelta:CGRectMake(delta.x, 0, -delta.x, delta.y)];
            else if( location == PTResizeHandleLocationLeft )
                [self setAnnotationRectDelta:CGRectMake(delta.x, 0, -delta.x, 0)];
        }
        

        if( [self.currentAnnotation GetType] == e_ptSquare )
        {
            PTSquare* sq = [[PTSquare alloc] initWithAnn:self.currentAnnotation];
            self.startingAnnotationRect = [self contentRectInScreenCoordinatesForAnnot:sq];
        }
        else
        {
            self.startingAnnotationRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];
        }
        
        
        if (annotType == PTExtendedAnnotTypeRuler || annotType == PTExtendedAnnotTypePerimeter || annotType == PTExtendedAnnotTypeArea ) {
            [PTMeasurementUtil setContentsForAnnot:self.currentAnnotation];
            [self.currentAnnotation RefreshAppearance];
            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        }

    }
	else
	{
		[self attachInitialMenuItemsForAnnotType:[self.currentAnnotation extendedAnnotType]];
		[self reSelectAnnotation];
	}
    [self setRotationHandlePosition];
    if (self.selectionRectContainerView.rotationHandle.hidden) {
        // show rotation handle if this is not part of a group annotation
        [self.selectionRectContainerView.rotationHandle setHidden:(self.selectionRectContainerView.groupSelectionRectView.subviews.count > 1)];
    }
    
    self.maintainAspectRatioTouchOffset = CGPointZero;
    aspectSnapPoint = CGPointZero;
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self resetHandleTransformsWithFeedback:NO];
    return YES;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint down = [gestureRecognizer locationInView:self.pdfViewCtrl];
    
    UIView* subview = [self.pdfViewCtrl hitTest:down withEvent:nil];
    
    if([ subview isKindOfClass:[PTResizeWidgetView class]] )
    {
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
        return YES;
    }

    if( gestureRecognizer.state == UIGestureRecognizerStateBegan )
    {

        if( [self makeNewAnnotationSelection: gestureRecognizer])
        {
            CGPoint off = [gestureRecognizer locationInView:self.selectionRectContainerView];

            self.touchOffset = CGPointMake(-off.x, -off.y);
            
            firstSelectionRect = self.selectionRectContainerView.groupSelectionRectView.frame;
            // Convert to screen space
            firstSelectionRect = [self.selectionRectContainerView convertRect:firstSelectionRect toView:self.pdfViewCtrl];

            return  YES;
        }
        else
        {
            self.currentAnnotation = 0;
            self.nextToolType = self.defaultClass;
            return NO;
        }
    }
    else if( gestureRecognizer.state == UIGestureRecognizerStateEnded )
    {

        if (![self.currentAnnotation IsValid]) {
            return YES;
        }

        if (![self annotIsMovable:self.currentAnnotation]) {
            return YES;
        }

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];


        [self moveAnnotation: self.stickyPoint];

        return  YES;
    }
    else // UIGestureRecognizerStateChanged
    {

        if (![self.currentAnnotation IsValid]) {
            return YES;
        }


        if (![self annotIsMovable:self.currentAnnotation]) {
            return YES;
        }

        down.x += [self.pdfViewCtrl GetHScrollPos];
        down.y += [self.pdfViewCtrl GetVScrollPos];

        [self moveSelectionRect: down];

        return  YES;
    }
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScroll:(UIScrollView *)scrollView
{
    [super pdfViewCtrl:pdfViewCtrl outerScrollViewDidScroll:scrollView];
    [self deselectAnnotation];
}

-(void)handleRotationGesture:(UIRotationGestureRecognizer*)gestureRecognizer {

    if ([self.currentAnnotation IsValid])
    {
        if ([self.currentAnnotation extendedAnnotType] == PTExtendedAnnotTypeImageStamp) {
            if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
                [self.selectionRectContainerView.rotationHandle setHidden:YES];
                [self startRotation];
            }
            [self rotateAnnot:gestureRecognizer.rotation];
            if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
                [self.selectionRectContainerView.rotationHandle setHidden:NO];
                CGAffineTransform transform = self.selectionRectContainerView.transform;
                double angle = atan2(transform.b, transform.a);
                [self rotationFinishedWithAngle:angle];
            }
        }
    }
}

-(void)handleTapGesture:(UITapGestureRecognizer*)gestureRecognizer
{
    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect animated:YES];
}

-(void)animateHandle:(UIView*)handle
{
    CGFloat endScaleLarge = [handle isKindOfClass:[PTRotateWidgetView class]] ? 2.0f : 3.0f;
    CGFloat endScaleSmall = 0.5f;

    [UIView animateWithDuration:0.2f delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self->feedbackGenerator selectionChanged];
        for (UIView *subview in self.selectionRectContainerView.subviews) {
            if ([subview isKindOfClass:[handle class]]) {
                CGFloat scale = subview == handle ? endScaleLarge : endScaleSmall;
                subview.transform = CGAffineTransformMakeScale(scale, scale);
            }
        }
    } completion:nil];
}

-(void)resetHandleTransformsWithFeedback:(BOOL)feedback
{
    [UIView animateWithDuration:0.1f
                          delay:0.0f
         usingSpringWithDamping:0.4f
          initialSpringVelocity:3.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        if( feedback )
        {
            [self->feedbackGenerator selectionChanged];
        }
        for (UIView *subview in self.selectionRectContainerView.subviews) {
            if ([subview isKindOfClass:[PTResizeWidgetView class]] || [subview isKindOfClass:[PTRotateWidgetView class]]) {
                subview.transform = CGAffineTransformIdentity;
            }
        }
    } completion:nil];
}

-(void)snapToAspectRatio:(CGPoint*)point
{
    if (![self isAspectRatioGuideEnabled]) {
        return;
    }
    
    CGPoint unmodifiedPoint = *point;
    NSArray *points = PTVerticesFromRect(self.selectionRectContainerView.groupSelectionRectView.frame);
    NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(NSValue *first, NSValue *second) {
        CGPoint firstPt = [first CGPointValue];
        CGPoint secondPt = [second CGPointValue];
        CGFloat xDist1 = (firstPt.x - self.touchedSelectWidget.center.x);
        CGFloat yDist1 = (firstPt.y - self.touchedSelectWidget.center.y);
        CGFloat distance1 = sqrt(xDist1 * xDist1 + yDist1 * yDist1);
        CGFloat xDist2 = (secondPt.x - self.touchedSelectWidget.center.x);
        CGFloat yDist2 = (secondPt.y - self.touchedSelectWidget.center.y);
        CGFloat distance2 = sqrt(xDist2 * xDist2 + yDist2 * yDist2);
        return (distance1 > distance2);
       }];

    CGPoint nearestPointPath = [sortedPoints.firstObject CGPointValue];
    CGPoint oppositePointPath = [sortedPoints.lastObject CGPointValue];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:nearestPointPath];
    [path addLineToPoint:oppositePointPath];
    aspectRatioGuideLayer.path = path.CGPath;

    CGPoint rectCenter = CGPointMake(firstSelectionRect.origin.x+firstSelectionRect.size.width*0.5, firstSelectionRect.origin.y+firstSelectionRect.size.height*0.5);
    CGPoint viewCenter = [self convertPoint:self.touchedSelectWidget.center fromView:self.touchedSelectWidget.superview];
    CGVector offsetFromCenter = PTCGPointOffsetFromPoint(viewCenter, rectCenter);
    int xNumerator = (int)offsetFromCenter.dx;
    int xDenominator = xNumerator == 0 ? 1 : abs(xNumerator);
    int yNumerator = (int)offsetFromCenter.dy;
    int yDenominator = yNumerator == 0 ? 1 : abs(yNumerator);
    CGVector offsetDirection = CGVectorMake(xNumerator/xDenominator, yNumerator/yDenominator);

    CGPoint nearestPoint = CGPointMake(rectCenter.x+(offsetDirection.dx*firstSelectionRect.size.width*0.5), rectCenter.y+(offsetDirection.dy*firstSelectionRect.size.height*0.5));
    CGPoint oppositePoint = CGPointMake(rectCenter.x-(offsetDirection.dx*firstSelectionRect.size.width*0.5), rectCenter.y-(offsetDirection.dy*firstSelectionRect.size.height*0.5));

    CGVector offset = PTCGPointOffsetFromPoint(nearestPoint,firstTouchPoint);
    CGVector offsetInverse = PTCGPointOffsetFromPoint(firstTouchPoint,nearestPoint);

    CGFloat firstAspectRatio = firstSelectionRect.size.height/firstSelectionRect.size.width;
    CGPoint offsetTouchPoint = PTCGVectorOffsetPoint(*point, offset);
    CGRect deltaRect = CGRectMake(oppositePoint.x, oppositePoint.y, offsetTouchPoint.x-oppositePoint.x, offsetTouchPoint.y-oppositePoint.y);
    deltaRect = CGRectStandardize(deltaRect);

    CGFloat projectedAspectRatio = deltaRect.size.height/deltaRect.size.width;

    if (fabs(firstAspectRatio-projectedAspectRatio)<PTAspectRatioSnappingThreshold) {
        if (CGPointEqualToPoint(aspectSnapPoint, CGPointZero)) {
            aspectSnapPoint = *point;
            // Don't trigger UISelectionFeedbackGenerator on the first touch
            if (!CGPointEqualToPoint(*point, firstTouchPoint) && shouldTriggerHaptic)
            {
                shouldTriggerHaptic = NO;
                [feedbackGenerator selectionChanged];
            }
        }
        // Offset points by difference between touched point and nearest annot rect corner
        *point = PTCGVectorOffsetPoint(*point, offset);
        CGPoint offsetFirstTouch = PTCGVectorOffsetPoint(firstTouchPoint, offset);

        double APx, APy, ABx, ABy;
         APx = (*point).x - oppositePoint.x;
         APy = (*point).y - oppositePoint.y;
         ABx = offsetFirstTouch.x - oppositePoint.x;
         ABy = offsetFirstTouch.y - oppositePoint.y;

        double magAB2 = ABx*ABx + ABy*ABy;
        double ABdotAP = ABx*APx + ABy*APy;
        double t = ABdotAP / magAB2;

        (*point).x = oppositePoint.x + ABx*t;
        (*point).y = oppositePoint.y + ABy*t;

        // Now revert the offset
        *point = PTCGVectorOffsetPoint(*point, offsetInverse);
    }else{
        shouldTriggerHaptic = YES;
        aspectSnapPoint = CGPointZero;
    }
    CGFloat distance = PTCGPointDistanceToPoint(*point, unmodifiedPoint);
    if (distance < 1 && !CGPointEqualToPoint(aspectSnapPoint, CGPointZero)) {
        
        // Enter precision mode if the touch is moved close to the snap point
        //aspectSnapPoint = firstTouchPoint;
    }

    [CATransaction setDisableActions:YES];
    aspectRatioGuideLayer.opacity = (CGPointEqualToPoint(aspectSnapPoint, CGPointZero) ||  CGPointEqualToPoint(aspectSnapPoint, firstTouchPoint)) ? 0.0 : 1.0;
    aspectRatioGuideLayer.hidden = CGPointEqualToPoint(aspectSnapPoint, CGPointZero) ||  CGPointEqualToPoint(aspectSnapPoint, firstTouchPoint);
    [CATransaction setDisableActions:NO];
}

-(void)snapToPerfectShape:(CGPoint*)point
{
    if (![self isAspectRatioGuideEnabled]) {
        return;
    }
    
//    CGPoint unmodifiedPoint = *point;
    CGPoint rectCenter = CGPointMake(firstSelectionRect.origin.x+firstSelectionRect.size.width*0.5, firstSelectionRect.origin.y+firstSelectionRect.size.height*0.5);
    CGPoint viewCenter = [self convertPoint:self.touchedSelectWidget.center fromView:self.touchedSelectWidget.superview];
    CGVector offsetFromCenter = PTCGPointOffsetFromPoint(viewCenter, rectCenter);
    int xNumerator = (int)offsetFromCenter.dx;
    int xDenominator = xNumerator == 0 ? 1 : abs(xNumerator);
    int yNumerator = (int)offsetFromCenter.dy;
    int yDenominator = yNumerator == 0 ? 1 : abs(yNumerator);
    CGVector offsetDirection = CGVectorMake(xNumerator/xDenominator, yNumerator/yDenominator);

    CGSize size = firstSelectionRect.size;
    CGVector rectOffset = CGVectorMake(size.width*0.5*offsetDirection.dx, size.height*0.5*offsetDirection.dy);

    CGPoint nearestPoint = PTCGVectorOffsetPoint(rectCenter,rectOffset);
    CGVector oppositeVector = PTCGPointOffsetFromPoint(rectCenter, nearestPoint);
    CGPoint oppositePoint = PTCGVectorOffsetPoint(rectCenter,oppositeVector);

    CGVector offset = PTCGPointOffsetFromPoint(nearestPoint,firstTouchPoint);
    CGVector offsetInverse = PTCGPointOffsetFromPoint(firstTouchPoint,nearestPoint);

    CGPoint offsetTouchPoint = PTCGVectorOffsetPoint(*point, offset);
    CGFloat deltaX = (offsetTouchPoint.x - nearestPoint.x)*offsetDirection.dx;
    CGFloat deltaY = (offsetTouchPoint.y - nearestPoint.y)*offsetDirection.dy;
    CGSize projectedSize = CGSizeMake(size.width+deltaX, size.height+deltaY);
    if ((fabs(projectedSize.height-projectedSize.width)<10)) {
        if (CGPointEqualToPoint(aspectSnapPoint, CGPointZero)) {
            aspectSnapPoint = *point;
            // Don't trigger UISelectionFeedbackGenerator on the first touch
            if (!CGPointEqualToPoint(*point, firstTouchPoint) && shouldTriggerHaptic) {
                shouldTriggerHaptic = NO;
                [feedbackGenerator selectionChanged];
            }
        }
        if (fabs(offsetDirection.dy) > fabs(offsetDirection.dx)) {
            projectedSize.height = projectedSize.width;
        }else{
            projectedSize.width = projectedSize.height;
        }
        
        (*point).x = oppositePoint.x+(projectedSize.width*offsetDirection.dx);
        (*point).y = oppositePoint.y+(projectedSize.height*offsetDirection.dy);
        *point = PTCGVectorOffsetPoint(*point, offsetInverse);
    }else{
        shouldTriggerHaptic = YES;
        aspectSnapPoint = CGPointZero;
    }

    /* Todo:
     * Precision mode implementation for snapping to perfect shape.
     * Below doesn't work
    CGFloat distance = PTCGPointDistanceToPoint(*point, unmodifiedPoint);
    if (distance < 1 && !CGPointEqualToPoint(aspectSnapPoint, CGPointZero)) {
        // Enter precision mode if the touch is moved close to the snap point
        aspectSnapPoint = firstTouchPoint;
    }
     */

    rectCenter = self.selectionRectContainerView.groupSelectionRectView.center;
    CGSize groupSize = self.selectionRectContainerView.groupSelectionRectView.frame.size;
    rectOffset = CGVectorMake(groupSize.width*0.5*offsetDirection.dy, groupSize.height*0.5*offsetDirection.dx);
    CGPoint point1 = PTCGVectorOffsetPoint(rectCenter,rectOffset);
    CGVector inverse = PTCGPointOffsetFromPoint(rectCenter, point1);
    CGPoint point2 = PTCGVectorOffsetPoint(rectCenter,inverse);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:point1];
    [path addLineToPoint:point2];
    aspectRatioGuideLayer.path = path.CGPath;

    
    [CATransaction setDisableActions:YES];
    aspectRatioGuideLayer.hidden = YES;//!(fabs(projectedSize.height-projectedSize.width)<PTAspectRatioSnappingThreshold);
    [CATransaction setDisableActions:NO];
}

#pragma mark - Annotation Rotation

-(void)startRotation
{
    @try {
        [self.pdfViewCtrl DocLockRead];

        PTObj *stampObj = [self.currentAnnotation GetSDFObj];
        PTObj *rotationObj = [stampObj FindObj:@"pdftronImageStampRotationDegree"];
        double rotation = 0;
        if (rotationObj != nil && rotationObj.IsNumber) {
            rotation = [rotationObj GetNumber];
        }
        double rads = rotation * M_PI / 180;
        startingAngle = -rads;

        [self.selectionRectContainerView hideSelectionRect];
        [self.selectionRectContainerView hideResizeWidgetViews];

        // Get image from annotation
        PTObj *appearance = [self.currentAnnotation GetAppearance:e_ptnormal app_state:0];
        PTElementReader *reader = [[PTElementReader alloc] init];
        PTElement *element = [self getFirstElementUsingReader:reader fromObj:appearance ofType:e_ptimage];
        PTObj* xobj = [element GetXObject];
        PTImage *image = [[PTImage alloc] initWithImage_xobject: xobj];

        // Create template view with image dimensions
        CGRect stampRect = CGRectMake(0, 0, [image GetImageWidth], [image GetImageHeight]);
        stampRectView = [[UIView alloc] initWithFrame:stampRect];
        stampRectView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        stampRectView.center = self.selectionRectContainerView.selectionRectView.center;

        // Get bounding box for rotated rect
        CGRect rotatedRect = [self boundingRectAfterRotatingRect:stampRect toAngle:startingAngle];
        // Get the ratio between the rotated rect and the selection rect
        CGAffineTransform scaleTransform = CGAffineTransformScale(CGAffineTransformIdentity, self.selectionRectContainerView.selectionRectView.frame.size.width/rotatedRect.size.width, self.selectionRectContainerView.selectionRectView.frame.size.height/rotatedRect.size.height);
        CGAffineTransform rotateTransform = CGAffineTransformRotate(CGAffineTransformIdentity, startingAngle);

        // Scale the template view down to the actual size and rotate it to match the annotation rotation
        stampRectView.transform = CGAffineTransformConcat(scaleTransform, rotateTransform);
        [self.selectionRectContainerView addSubview:stampRectView];
    }
    @catch (NSException *exception) {

        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
}

-(void)rotateAnnot:(CGFloat)angle
{
    // Snap to nearest 45 degrees
    double combinedAngle = angle + startingAngle;
    combinedAngle = combinedAngle > 2*M_PI ? (2*M_PI)-combinedAngle : combinedAngle; // angle overflow past 360-degrees
    double snapRatio = combinedAngle / M_PI_4; // divide by 45 degrees (PI/4 rads)
    double numSegments = round(snapRatio); // get nearest 45-degree multiple
    double snapThreshold = (6.0 * M_PI / 180.0)/ M_PI_4;
    CGFloat transformAngle = angle;
    if (fabs(snapRatio-numSegments) <= snapThreshold) { // if current angle is within 6 degrees of a 45-degree multiple then snap to that multiple
        combinedAngle = numSegments*M_PI_4;
        transformAngle = combinedAngle - startingAngle;
    }

    CGAffineTransform initialTransform = self.selectionRectContainerView.transform;
    CGFloat initialAngle = atan2(initialTransform.b, initialTransform.a);
    CGAffineTransform nextTransform = CGAffineTransformMakeRotation(transformAngle);
    CGFloat nextAngle = atan2(nextTransform.b, nextTransform.a);

    CGFloat transformAngleDegrees = (transformAngle + startingAngle) * 180.0 / M_PI;

    if (transformAngle != angle) {
        if (initialAngle != nextAngle && fmodf(transformAngleDegrees, 45.0) == 0) {
            [feedbackGenerator selectionChanged];
        }
    }
    self.selectionRectContainerView.transform = CGAffineTransformMakeRotation(transformAngle);
}

-(void)rotationFinishedWithAngle:(CGFloat)angle
{
    if ([self.currentAnnotation IsValid])
    {
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            CGFloat degrees = -angle * 180.0 / M_PI;

            PTObj *stampObj = [self.currentAnnotation GetSDFObj];
            PTObj *rotationObj = [stampObj FindObj:@"pdftronImageStampRotationDegree"];
            double rotation = 0;
            if (rotationObj != nil && rotationObj.IsNumber) {
                rotation = (double) [rotationObj GetNumber];
            }
            rotation += degrees;

            if (rotation < 0) {
                rotation += 360.0;
            }
            if (rotation > 360.0) {
                rotation -= 360.0;
            }

            [stampObj PutNumber:PTImageStampAnnotationRotationDegreeIdentifier value:rotation];
            
            [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
            
            [self.currentAnnotation SetRotation:rotation];

            self.selectionRectContainerView.transform = CGAffineTransformIdentity;
            [self.selectionRectContainerView showSelectionRect];
            [self.selectionRectContainerView showResizeWidgetViews];

            [stampRectView removeFromSuperview];
            stampRectView = nil;
            feedbackGenerator = nil;
            [self.currentAnnotation RefreshAppearance];
            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
            [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
            [self reSelectAnnotation];
        }
    }
}

-(CGRect) boundingRectAfterRotatingRect: (CGRect) rect toAngle: (float) radians
{
    CGAffineTransform xfrm = CGAffineTransformMakeRotation(radians);
    return CGRectApplyAffineTransform (rect, xfrm);
}

-(PTElement *)getFirstElementUsingReader:(PTElementReader *)reader fromObj:(PTObj *)obj ofType:(PTElementType)type
{
    @try
    {
        [self.pdfViewCtrl DocLockRead];

        if (![obj IsValid]) {
            return nil;
        }

        [reader ReaderBeginWithSDFObj:obj resource_dict:nil ocg_context:nil];

        for( PTElement* element = [reader Next]; element != 0; element = [reader Next] )
        {
            if( [element GetType] == type )
            {
                return element;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    return nil;
}

#pragma mark - Annotation Menu Action Responses

-(void)cancelMenu
{
    [self hideMenu];
    [self.stylePicker selectStyle];
    [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    CGRect pageScreenRect = [self pageBoxInScreenPtsForPageNumber:self.annotationPageNumber].CGRectValue;
    CGFloat pageMaxXEdge = PTCGRectMaxXEdge(pageScreenRect);
    CGFloat pageMaxYEdge = PTCGRectMaxYEdge(pageScreenRect);

    CGRect textViewScreenRect = [self.pdfViewCtrl convertRect:textView.frame fromView:textView.superview];

    CGSize maxSize = CGSizeMake(pageMaxXEdge-textViewScreenRect.origin.x, pageMaxYEdge-textViewScreenRect.origin.y);

    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];

    BOOL textContainsNewLines = [newText rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound;
    if (textContainsNewLines)
    {
        maxSize.width = textViewScreenRect.size.width;
    }

    CGRect textRect = [textView.text boundingRectWithSize:maxSize
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:textView.typingAttributes
                                                  context:nil];

    CGRect newTextRect = [newText boundingRectWithSize:maxSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:textView.typingAttributes
                                               context:nil];

    if ((newTextRect.size.width > textRect.size.width && newTextRect.size.width < textView.frame.size.width) ||
        (newTextRect.size.height > textRect.size.height && newTextRect.size.height < textView.frame.size.height)) {
        // Don't expand the textView and selectionRect if the the text view is already big enough to contain the new text rect
        return YES;
    }

    CGRect frame = textView.frame;
    frame.size.width +=  newTextRect.size.width - textRect.size.width;
    frame.size.height += newTextRect.size.height - textRect.size.height;
    textView.frame = frame;

    // Resize the selection rect container view
    self.selectionRectContainerView.groupSelectionRectView.frame = textView.frame;
    frame.origin.x += self.pdfViewCtrl.GetHScrollPos;
    frame.origin.y += self.pdfViewCtrl.GetVScrollPos;
    textViewScreenRect = [self.pdfViewCtrl convertRect:frame fromView:textView.superview];
    [self.selectionRectContainerView setFrameFromAnnot:textViewScreenRect];
    return YES;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (!self.currentAnnotation) {
        return;
    }
    
    if (textView.text.length == 0) {
        [self deleteSelectedAnnotation];
        return;
    }

    NSError* error;
    
    __block NSString* annotTextContents;
    
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        annotTextContents = [self.currentAnnotation GetContents];
    } error:&error];
    
    if( error )
    {
        NSLog(@"Could not get annotation contents.");
    }
    
    NSString* theText = textView.text;
    
    if( [annotTextContents isEqualToString:theText] )
    {
        [self deselectAnnotationAndExit];
        return;
    }
    
    [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];

    
    [self.currentAnnotation SetContents:theText];
        
    PTFreeText* ft = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];
    
    // Set/re-set free text font. Whenever the text contents change the font must be
    // updated to ensure that the embedded font contains information for all characters.
    NSString* fontName = [ft getFontName];
    [ft setFontWithName:fontName pdfDoc:[self.pdfViewCtrl GetDoc]];
    
    if (ft.extendedAnnotType == PTExtendedAnnotTypeFreeText) {
        [PTFreeTextCreate refreshAppearanceForAnnot:ft onDoc:[self.pdfViewCtrl GetDoc]];
    } else {
        [ft RefreshAppearance];
    }
    
    [self.pdfViewCtrl UpdateWithAnnot:ft page_num:self.annotationPageNumber];
    

    if (self.toolManager.autoResizeFreeText) {
        PTFreeText* ft = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];

        CGRect screenRect = [self.pdfViewCtrl convertRect:textView.frame fromView:textView.superview];
        CGFloat x1 = screenRect.origin.x;
        CGFloat y1 = screenRect.origin.y;
        CGFloat x2 = screenRect.origin.x+screenRect.size.width;
        CGFloat y2 = screenRect.origin.y+screenRect.size.height;

        [self ConvertScreenPtToPagePtX:&x1 Y:&y1 PageNumber:self.annotationPageNumber];
        [self ConvertScreenPtToPagePtX:&x2 Y:&y2 PageNumber:self.annotationPageNumber];

        PTPDFRect *rect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];

        [PTFreeTextCreate setRectForFreeText:ft withRect:rect pdfViewCtrl:self.pdfViewCtrl isRTL:[NSLocale characterDirectionForLanguage:[textView textInputMode].primaryLanguage] == NSLocaleLanguageDirectionRightToLeft];

        @try
        {
            [self.pdfViewCtrl DocLock:YES];

            
            if (ft.extendedAnnotType == PTExtendedAnnotTypeFreeText) {
                [PTFreeTextCreate refreshAppearanceForAnnot:ft onDoc:[self.pdfViewCtrl GetDoc]];
            } else {
                [ft RefreshAppearance];
            }
            
            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    [self deselectAnnotationAndExit];
}

-(void)editSelectedAnnotationFreeText
{
    [self.selectionRectContainerView hideResizeWidgetViews];
    [self.selectionRectContainerView removeLiveAppearance];
    
    NSString* text = [self.currentAnnotation GetContents];
    PTFreeText* ft = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];
	int fontSize = [ft GetFontSize];
    int alignment = [ft GetQuaddingFormat];
        
    NSString* fontName = [ft getFontName];
    
    if( fontName == Nil )
    {
        fontName = @"Helvetica";
    }

    [self.selectionRectContainerView useTextViewWithText:text withAlignment:alignment atZoom:[self.pdfViewCtrl GetZoom] forFontSize:fontSize withFontName:(NSString*)fontName withFrame:[self frameForEditingFreeTextAnnotation] withDelegate:self];

    // Notify delegate.
    if ([self.delegate respondsToSelector:@selector(annotEditTool:didBeginEditingFreeText:withTextView:)]) {
        [self.delegate annotEditTool:self didBeginEditingFreeText:ft withTextView:self.selectionRectContainerView.textView];
    }
}

- (CGRect)frameForEditingFreeTextAnnotation
{
    CGRect rect = self.selectionRectContainerView.bounds;
    double thickness = 0;
    PTFreeText* freeText = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];
    UIColor* borderColor = [PTColorDefaults uiColorFromColorPt:[freeText GetLineColor]
                                            compNum:[freeText GetLineColorCompNum]];
    
    //double borderThickness = [[freeText GetBorderStyle] GetWidth];
    
    if( borderColor )
    {
        thickness = 12;
    }
    
    rect.origin.x += thickness;
    rect.origin.y += thickness;
    rect.size.width -= thickness*2;
    rect.size.height -= thickness*2;
    return rect;
}

-(void)copySelectedFreeText
{
    NSString *textToCopy = [self.currentAnnotation GetContents];
    if (textToCopy && textToCopy.length > 0) {
        [[UIPasteboard generalPasteboard] setString:textToCopy];
    }
}

-(void)editSelectedAnnotationBorder
{
    [self hideMenu];
    [self attachBorderThicknessMenuItems];
    
    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect];
}

-(void)setFreeTextSize:(double)size
{
	PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];
    [self attachInitialMenuItemsForAnnotType:annotType];

	@try
    {
        [self.pdfViewCtrl DocLock:YES];
		PTFreeText* ft = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
		[ft SetFontSize:size];
		[ft RefreshAppearance];

		[PTColorDefaults setDefaultFreeTextSize:size];

	}
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
	[self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

-(void)setAnnotationBorder:(float)thickness
{
    PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];
    [self attachInitialMenuItemsForAnnotType:annotType];

    @try
    {
        [self.pdfViewCtrl DocLock:YES];

        PTBorderStyle* bs = [self.currentAnnotation GetBorderStyle];
        [bs SetWidth:thickness];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        [self.currentAnnotation SetBorderStyle:bs oldStyleOnly:NO];
        [self.currentAnnotation RefreshAppearance];

        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];

        [PTColorDefaults setDefaultBorderThickness:thickness forAnnotType:annotType];

    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }

    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect];

	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

-(void)calibrateMeasurementScale
{
    PTLineAnnot *line = [[PTLineAnnot alloc] initWithAnn:self.currentAnnotation];
    PTMeasurement *measurement = [PTMeasurementUtil getAnnotMeasurementData:self.currentAnnotation];

    measurement.distance.unit = calibrationUnitTextField.text;
    measurement.area.unit = [@"sq " stringByAppendingString:calibrationUnitTextField.text];

    double length = line.length;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *calibrationDistance = [formatter numberFromString:calibrationScaleTextField.text];
    double factor = [calibrationDistance doubleValue]/length;
    measurement.axis.factor = factor;
    PTMeasurementScale *newScale = [PTMeasurementUtil getMeasurementScaleFromMeasurement:measurement];
    [PTColorDefaults setDefaultMeasurementScale:newScale forAnnotType:PTExtendedAnnotTypeRuler];
    [PTColorDefaults setDefaultMeasurementScale:newScale forAnnotType:PTExtendedAnnotTypePerimeter];

    // Prepend units with sq for area measurements
    PTMeasurementScale *newAreaScale = [PTMeasurementUtil getMeasurementScaleFromMeasurement:measurement];
    newAreaScale.baseUnit = [@"sq " stringByAppendingString:newAreaScale.baseUnit];
    newAreaScale.translateUnit = [@"sq " stringByAppendingString:calibrationUnitTextField.text];
    [PTColorDefaults setDefaultMeasurementScale:newAreaScale forAnnotType:PTExtendedAnnotTypeArea];

    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        [PTMeasurementUtil setAnnotMeasurementData:self.currentAnnotation fromMeasurementScale:newScale];
        [self.currentAnnotation RefreshAppearance];
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];

    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    
    [self deselectAnnotation];
    
    // back to default tool
    [self onSwitchToolEvent:Nil];
    
}

// gets us a popover on iPhone (iOS8+)
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void) showColorPicker
{
    if (![self.currentAnnotation IsValid]) {
        return;
    }

    PTColorPickerViewController *colorPicker = [[PTColorPickerViewController alloc] init];
    colorPicker.colorPickerDelegate = self;

	@try
	{
		[self.pdfViewCtrl DocLockRead];

		if (!self.selectionRectContainerView.selectionRectView.frame.size.width && !self.selectionRectContainerView.selectionRectView.frame.size.height) {
			CGRect annotRect;
			// coming from a text annot
			@try
			{
				[self.pdfViewCtrl DocLockRead];

				PTPDFRect* screen_rect = [self.pdfViewCtrl GetScreenRectForAnnot: self.currentAnnotation page_num: self.annotationPageNumber];

				self.annotRect = [self PDFRectScreen2CGRectScreen:screen_rect PageNumber:self.annotationPageNumber];
                
                self.annotRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];

			}
			@catch (NSException *exception) {
				NSLog(@"Exception: %@: %@",exception.name, exception.reason);
			}
			@finally {
				[self.pdfViewCtrl DocUnlockRead];
			}

			annotRect.origin.x = annotRect.origin.x + [self.pdfViewCtrl GetHScrollPos];
			annotRect.origin.y = annotRect.origin.y + [self.pdfViewCtrl GetVScrollPos];

			[self.selectionRectContainerView setHidden:YES];

			[self.pdfViewCtrl.toolOverlayView addSubview:self.selectionRectContainerView];

            [self.selectionRectContainerView setFrameFromAnnot:annotRect];
			//self.selectionRectContainerView.frame = annotRect;
		}

		colorPicker.modalPresentationStyle = UIModalPresentationPopover;
		colorPicker.popoverPresentationController.delegate = self;
		colorPicker.popoverPresentationController.sourceRect = [self.pt_viewController.view convertRect:self.annotRect fromView:self.pdfViewCtrl];
		colorPicker.popoverPresentationController.sourceView = self.pt_viewController.view;

        [self.pt_viewController presentViewController:colorPicker animated: YES completion: nil];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlockRead];
	}
}

-(void)editFreeTextSize
{
    [self hideMenu];
    [self attachFreeTextFontSizeMenuItems];

    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect];
}

-(void)editFreeTextColor
{
    m_fill_color = true;
    [self showColorPicker];
}

-(void)editSelectedAnnotationStrokeColor
{
    m_fill_color = false;
    [self showColorPicker];
}

-(void)editSelectedAnnotationFillColor
{
    m_fill_color = true;
    [self showColorPicker];
}

-(void)noteEditController:(PTNoteEditController*)noteEditController saveNewNoteForMovingAnnotationWithString:(NSString*)str
{
	[super noteEditController:noteEditController saveNewNoteForMovingAnnotationWithString:str];
	//[self showSelectionMenu:self.annotRect];
}

-(void)noteEditController:(PTNoteEditController*)noteEditController cancelButtonPressed:(BOOL)showSelectionMenu
{
	[self.pt_viewController dismissViewControllerAnimated:YES completion:nil];

    if (self.currentAnnotation) {
        CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
        if (!PT_ToolsMacCatalyst) {
            [self showSelectionMenu:menuRect];
        }
    }
}

- (void)colorPickerController:(PTColorPickerViewController *)colorPickerController didSelectColor:(UIColor *)color
{
    @try
    {
        [self.pdfViewCtrl DocLock:YES];

        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        if (!m_fill_color) {
            // Set stroke color.
            PTColorPt* cp = [PTColorDefaults colorPtFromUIColor:color];

            if (CGColorGetNumberOfComponents(color.CGColor) > 3 && ![color isEqual:[UIColor clearColor]]) {
                [self.currentAnnotation SetColor:cp numcomp:3];
            } else {
                [self.currentAnnotation SetColor:cp numcomp:0];
            }
        } else if (self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeFreeText ||
                   self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeCallout) {
            PTFreeText* ft = [[PTFreeText alloc] initWithAnn:self.currentAnnotation];

            PTColorPt* cp = [PTColorDefaults colorPtFromUIColor:color];

            if (CGColorGetNumberOfComponents(color.CGColor) > 3 && ![color isEqual:[UIColor clearColor]]) {
                [ft SetTextColor:cp col_comp:3];
            } else {
                [ft SetTextColor:cp col_comp:0];
            }
        } else {
            // Set fill color for non-free-text annotations.
            PTColorPt* cp = [PTColorDefaults colorPtFromUIColor:color];

            PTMarkup* markup = [[PTMarkup alloc] initWithAnn:self.currentAnnotation];

            if (CGColorGetNumberOfComponents(color.CGColor) > 3 && ![color isEqual:[UIColor clearColor]]) {
                [markup SetInteriorColor:cp CompNum:3];
            } else {
                [markup SetInteriorColor:cp CompNum:0];
            }
        }

        [self.currentAnnotation RefreshAppearance];

        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }

    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];

    [colorPickerController dismissViewControllerAnimated:YES completion:nil];

    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect];
}

-(void)groupSelectedAnnots
{
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        PTAnnot *mainAnnot = self.selectedAnnotations.firstObject;
        NSString *mainAnnotID = mainAnnot.uniqueID;
        if (mainAnnotID == nil) {
            mainAnnotID = [NSUUID UUID].UUIDString;
            int bytes = (int)[mainAnnotID lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            [mainAnnot SetUniqueID:mainAnnotID id_buf_sz:bytes];
        }
        for (PTAnnot *annot in self.selectedAnnotations) {
            [self willModifyAnnotation:annot onPageNumber:self.annotationPageNumber];
            PTObj *annotSDFObj = [annot GetSDFObj];
            [annotSDFObj EraseDictElementWithKey:@"RT"];
            [annotSDFObj EraseDictElementWithKey:@"IRT"];
            if (![annot isEqualTo:mainAnnot]) {
                [annotSDFObj PutName:@"RT" name:@"Group"];
                [annotSDFObj Put:@"IRT" obj:[mainAnnot GetSDFObj]];
            }
            [self annotationModified:annot onPageNumber:self.annotationPageNumber];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    [self reSelectAnnotation];
}

-(void)ungroupSelectedAnnots
{
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        for (PTAnnot *annot in self.selectedAnnotations) {
            PTObj *annotSDFObj = [annot GetSDFObj];
            
            [self willModifyAnnotation:annot onPageNumber:self.annotationPageNumber];
            
            [annotSDFObj EraseDictElementWithKey:@"RT"];
            [annotSDFObj EraseDictElementWithKey:@"IRT"];
            [self annotationModified:annot onPageNumber:self.annotationPageNumber];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    [self reSelectAnnotation];
}

-(void)deselectAnnotation
{
	BOOL modified = NO;
    if( [self.currentAnnotation IsValid] &&
        (self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeFreeText ||
         self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeCallout) )
    {
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            
            if( self.selectionRectContainerView.textView.text != Nil && [self.selectionRectContainerView.textView.text isEqualToString:[self.currentAnnotation GetContents]] == NO )
            {
                //requires a write lock for refresh appearance
                [self.selectionRectContainerView setAnnotationContents:self.currentAnnotation];

                modified = YES;
            }

            //[self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];

        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    
    self.currentAnnotation = nil;
    self.annotationPageNumber = 0;
    self.startingAnnotationRect = CGRectZero;
    
    feedbackGenerator = nil;
}

-(void)showMeasurementCalibrationAlert
{
    if (![self.currentAnnotation IsValid]) {
        return;
    }
    self.calibrationAlertController = [UIAlertController alertControllerWithTitle:PTLocalizedString(@"Calibrate Measurements", @"")
                                                                             message:PTLocalizedString(@"Enter the length of the measurement", @"")
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIPickerView *unitPickerView = [[UIPickerView alloc] init];
    unitPickerView.delegate = self;
    unitPickerView.dataSource = self;
    [unitPickerView selectRow:1 inComponent:0 animated:NO];

    calibrationUnitTextField = [[UITextField alloc] init];
    calibrationUnitTextField.delegate = self;
    calibrationUnitTextField.textAlignment = NSTextAlignmentCenter;
    calibrationUnitTextField.inputView = unitPickerView;
    calibrationUnitTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    calibrationUnitTextField.textColor = self.tintColor;
    calibrationUnitTextField.tintColor = [UIColor clearColor];

    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar sizeToFit];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissInput)];
    [toolbar setItems:@[flex, done]];

    calibrationUnitTextField.inputAccessoryView = toolbar;
    calibrationUnitTextField.frame = CGRectMake(0, 0, 44, 44);
    calibrationUnitTextField.text = [PTColorDefaults defaultMeasurementScaleForAnnotType:PTExtendedAnnotTypeRuler].translateUnit;

    __weak typeof(self) weakSelf = self;
    [weakSelf.calibrationAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.delegate = self;
        textField.borderStyle = UITextBorderStyleNone;
        textField.rightViewMode = UITextFieldViewModeAlways;
        [textField addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
        textField.rightView = self->calibrationUnitTextField;
        self->calibrationScaleTextField = textField;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"Cancel", @"")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:PTLocalizedString(@"OK", @"")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self calibrateMeasurementScale];
                                                         }];
    [okAction setEnabled:NO];
    [self.calibrationAlertController addAction:cancelAction];
    [self.calibrationAlertController addAction:okAction];
    UIViewController *viewController = [self pt_viewController];
    [viewController presentViewController:self.calibrationAlertController animated:YES completion:nil];
    [self.calibrationAlertController.textFields.firstObject becomeFirstResponder];
}

-(void)dismissInput {
    [calibrationUnitTextField endEditing:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [PTMeasurementUtil realWorldUnits].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[PTMeasurementUtil realWorldUnits] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    calibrationUnitTextField.text = [[PTMeasurementUtil realWorldUnits] objectAtIndex:row];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *entry = [textField.text stringByAppendingString:string];
    // Only allow numbers
    if (textField == calibrationScaleTextField) {
        NSNumber* value = nil;
        NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
        value  = [format numberFromString:entry];
        // NSNumberFormatter will return nil if it can't parse the string into a valid number
        if (value == nil && ![entry isEqualToString:@"."]){
            return NO;
        }
    }
    // Limit the scale to a maximum of 4 characters
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self.calibrationAlertController.actions.lastObject setEnabled:textField.text.length > 0];
}

-(void)editSelectedAnnotationStyle
{
    if (![self.currentAnnotation IsValid]) {
        return;
    }

    if (self.stylePicker.presentingViewController) {
        return;
    }

    PTAnnotStyle *annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnot:self.currentAnnotation onPDFDoc:[self.pdfViewCtrl GetDoc]];
    self.stylePicker = [[PTAnnotStyleViewController allocOverridden] initWithToolManager:self.toolManager annotStyle:annotStyle];
    self.stylePicker.delegate = self;

    PTPDFRect* rect = [self.currentAnnotation GetRect];
    CGRect annotRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:rect PageNumber:self.annotationPageNumber];

    UIViewController *viewController = [self pt_viewController];
    
    PTPopoverNavigationController *navigationController = [[PTPopoverNavigationController allocOverridden] initWithRootViewController:self.stylePicker];
    
    navigationController.presentationManager.popoverSourceView = self.pdfViewCtrl;
    navigationController.presentationManager.popoverSourceRect = annotRect;
    
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didChangeStyle:(PTAnnotStyle *)annotStyle
{
    if (self.currentAnnotation != annotStyle.annot || ![self.currentAnnotation IsValid]) {
        return;
    }

    @try
    {
        [self.pdfViewCtrl DocLock:YES];

        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        [annotStyle saveChanges];
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    if( self.selectedAnnotations.count <= 1 )
    {
        [self.selectionRectContainerView refreshLiveAppearance];
    }
    
    PTExtendedAnnotType annotType = self.currentAnnotation.extendedAnnotType;
    if( annotType == PTExtendedAnnotTypeHighlight || annotType == PTExtendedAnnotTypeUnderline ||
        annotType == PTExtendedAnnotTypeStrikeOut || annotType == PTExtendedAnnotTypeSquiggly ||
        annotType == PTExtendedAnnotTypeRuler)
    {
        [self.currentAnnotation RefreshAppearance];
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
    }

    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

- (void)annotStyleViewController:(PTAnnotStyleViewController *)annotStyleViewController didCommitStyle:(PTAnnotStyle *)annotStyle
{
    if (self.currentAnnotation != annotStyle.annot || ![self.currentAnnotation IsValid]) {
        return;
    }

    [self attachInitialMenuItemsForAnnotType:[self.currentAnnotation extendedAnnotType]];
    
    self.annotRect = [self tightScreenBoundingBoxForAnnot:self.currentAnnotation];
    
    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    if (!PT_ToolsMacCatalyst) {
        [self showSelectionMenu:menuRect];
    }

    // Dismiss style picker.
    [self.stylePicker dismissViewControllerAnimated:YES completion:nil];

    self.stylePicker = nil;
}

- (void)commitSelectedAnnotationStyle
{
    [self.stylePicker selectStyle];

    [self.stylePicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)editSelectedAnnotationOpacity
{
    [self hideMenu];
    [self attachOpacityMenuItems];
    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect];
}

-(void)editSelectedAnnotationPencilDrawing
{
    if (@available(iOS 13.1, *)) {
        self.toolManager.tool.backToPanToolAfterUse = NO;
        self.nextToolType = [PTPencilDrawingCreate class];
        [self.toolManager createSwitchToolEvent:@"EditPencilDrawing"];
    }
    return;
}

-(void)setAnnotationOpacity:(double)alpha
{

    [self attachInitialMenuItemsForAnnotType:[self.currentAnnotation extendedAnnotType]];

    @try
    {
        [self.pdfViewCtrl DocLock:YES];

        PTMarkup* annot = [[PTMarkup alloc] initWithAnn:self.currentAnnotation];
        
        [self willModifyAnnotation:self.currentAnnotation onPageNumber:self.annotationPageNumber];

        [annot SetOpacity:alpha];


        [self.currentAnnotation RefreshAppearance];

        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];

        PTExtendedAnnotType annotType = [self.currentAnnotation extendedAnnotType];

		[PTColorDefaults setDefaultOpacity:(double)alpha forAnnotType:annotType];

    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }

    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    
    [self showSelectionMenu:menuRect];

	[self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

- (void)openFileAttachmentAnnotation
{
    if (self.currentAnnotation.extendedAnnotType != PTExtendedAnnotTypeFileAttachment) {
        return;
    }

    PTFileAttachment *fileAttachment = [[PTFileAttachment alloc] initWithAnn:self.currentAnnotation];

    [self handleFileAttachment:fileAttachment onPageNumber:self.annotationPageNumber];
}

- (void)cropSelectedImageStamp
{
//    self.backToPanToolAfterUse = NO;
    self.nextToolType = [PTImageCropTool class];
    [self.toolManager createSwitchToolEvent:@"CropImageStamp"];
}

#pragma mark - Set Annot Appearance

-(void)SetAnnotationRect:(PTAnnot*)annot Rect:(CGRect)rect OnPage:(int)pageNumber
{
	// CGRect's origin is at the top-left corner
	PTPDFPoint* sceenUpperLeft = [[PTPDFPoint alloc] init];
	PTPDFPoint* sceenLowerRight = [[PTPDFPoint alloc] init];

	[sceenUpperLeft setX:rect.origin.x];
	[sceenUpperLeft setY:rect.origin.y];

	[sceenLowerRight setX:rect.origin.x+rect.size.width];
	[sceenLowerRight setY:rect.origin.y+rect.size.height];

	PTPDFPoint* pageUpperLeft = [self.pdfViewCtrl ConvScreenPtToPagePt:sceenUpperLeft page_num:pageNumber];
	PTPDFPoint* pageLowerRight = [self.pdfViewCtrl ConvScreenPtToPagePt:sceenLowerRight page_num:pageNumber];

	PTPDFRect* r = [[PTPDFRect alloc] init];
	PTPDFRect* startRect = [annot GetRect];
    startRect = [self tightPageBoundingBoxFromAnnot:annot];

	double startRectWidth = MAX([startRect GetX1],[startRect GetX2]) - MIN([startRect GetX1], [startRect GetX2]);
	double startRectHeight = MAX([startRect GetY1], [startRect GetY2]) - MIN([startRect GetY1], [startRect GetY2]);
	if ([annot GetFlag: e_ptno_zoom])
	{
		[r SetX1: [pageUpperLeft getX]];
		[r SetY1: [pageUpperLeft getY] - startRectHeight];
		[r SetX2: [pageUpperLeft getX] + startRectWidth];
		[r SetY2: [pageUpperLeft getY]];
	}
	else
	{
		[r SetX1:[pageUpperLeft getX]];
		[r SetY1:[pageUpperLeft getY]];
		[r SetX2:[pageLowerRight getX]];
		[r SetY2:[pageLowerRight getY]];
	}
	[r Normalize];

	@try
	{
		[self.pdfViewCtrl DocLock:YES];

		PTPDFRect* old_rect = [self.pdfViewCtrl GetScreenRectForAnnot:annot page_num:pageNumber];
		[old_rect Normalize];

        if( isnan([r GetX1]) || isnan([r GetX2]) || isnan([r GetY1]) || isnan([r GetY2]) )
        {
            NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot resize annotation to NaN" userInfo:Nil];
            @throw exception;
        }
        
        if( [annot GetType] == e_ptSquare )
        {
            PTSquare* sq = [[PTSquare alloc] initWithAnn:annot];

            [sq SetRect:r];
            [sq SetContentRect:r];
            [sq RefreshAppearance];
        }
        else
        {
            [annot Resize:r];
        }
        

        if( annot.isInGroup == YES || self.selectedAnnotations.count > 1 )
        {
            [self.pdfViewCtrl UpdateWithRect:old_rect];
            [self.pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumber];
        }

	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",[exception name], [exception reason]);
	}
	@finally {
		[self.pdfViewCtrl DocUnlock];
	}

}




-(void)setAnnotOpacity00
{
    [self setAnnotationOpacity:0.0];
}

-(void)setAnnotOpacity25
{
    [self setAnnotationOpacity:0.25];
}

-(void)setAnnotOpacity50
{
    [self setAnnotationOpacity:0.50];
}

-(void)setAnnotOpacity75
{
    [self setAnnotationOpacity:0.75];
}

-(void)setAnnotOpacity10
{
    [self setAnnotationOpacity:1.0];
}

-(void)setAnnotBorder05
{
    [self setAnnotationBorder:0.5];
}

-(void)setAnnotBorder10
{
    [self setAnnotationBorder:1.0];
}

-(void)setAnnotBorder15
{
    [self setAnnotationBorder:1.5];
}

-(void)setAnnotBorder30
{
    [self setAnnotationBorder:3.0];
}

-(void)setAnnotBorder50
{
    [self setAnnotationBorder:5.0];
}

-(void)setAnnotBorder90
{
    [self setAnnotationBorder:9.0];
}

-(void)setFreeTextSize8
{
	[self setFreeTextSize:8.0];
}

-(void)setFreeTextSize11
{
	[self setFreeTextSize:11.0];
}

-(void)setFreeTextSize16
{
	[self setFreeTextSize:16.0];
}

-(void)setFreeTextSize24
{
	[self setFreeTextSize:24.0];
}

-(void)setFreeTextSize36
{
	[self setFreeTextSize:36.0];
}

#pragma mark - UIContextMenuInteractionDelegate
#if TARGET_OS_MACCATALYST
- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location configuration:(UIContextMenuConfiguration * _Nullable __autoreleasing *)configuration
{
    moveOccuredPreTap = YES;

    if (self.selectionRectContainerView.superview == nil)
    {
        [self makeNewAnnotationSelectionAtLocation:location];
    }

    CGPoint touchPoint = [self.pdfViewCtrl convertPoint:location toView:self.selectionRectContainerView];

    if( !CGRectContainsPoint(self.selectionRectContainerView.bounds, touchPoint) || self.currentAnnotation == nil)
    {
        self.nextToolType = self.defaultClass;

        return  NO;
    }

    [self reSelectAnnotation];

    [self attachInitialMenuItemsForAnnotType:[self.currentAnnotation extendedAnnotType]];
    CGRect menuRect = CGRectInset(self.annotRect, -self.menuOffset, -self.menuOffset);
    [self showSelectionMenu:menuRect];
    *configuration = nil;
    return YES;
}
#endif

@end
