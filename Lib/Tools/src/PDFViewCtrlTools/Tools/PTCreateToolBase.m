//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCreateToolBase.h"
#import "PTPanTool.h"
#import "PTArrowCreate.h"
#import "PTPolygonCreate.h"
#import "PTLineCreate.h"
#import "PTRulerCreate.h"
#import "PTMeasurementUtil.h"
#import "PTMeasurement.h"
#import "PTMeasurementScale.h"
#import "PTColorDefaults.h"
#import "PTAnnotEditTool.h"
#import "PTTextMarkupEditTool.h"
#import "PTStickyNoteCreate.h"
#import "PTPolylineEditTool.h"
#import "PTToolsUtil.h"

@interface PTCreateToolBase ()
{

    NSUInteger m_num_touches;
    UIColor* _strokeColor;
    UIColor* _fillColor;
    double _opacity;

}

@property (nonatomic, readonly, strong) NSUndoManager *undoManager;
@property (nonatomic, assign) BOOL createdAnnot;
@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTCreateToolBase


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        self.allowZoom = YES;
        self.endPoint = self.startPoint = CGPointMake(-1, -1);
        _createdAnnot = NO;
        _isPencilTouch = YES;
    }
    
    return self;
}

-(void)setToolManager:(PTToolManager *)toolManager
{
    [super setToolManager:toolManager];
    
    self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.toolManager.annotationsCreatedWithPencilOnly;
}

+(BOOL)createsAnnotation
{
	return YES;
}

- (BOOL)requiresEditSupport
{
    return NO;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
 

    PTTool* editTool = [[PTPanTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
    editTool.toolManager = self.toolManager;
    while (![editTool pdfViewCtrl:pdfViewCtrl handleTap:sender]) {
        editTool = (PTTool *)[editTool getNewTool];
    }
    
    if([editTool isKindOfClass:[PTAnnotEditTool class]] || [editTool isKindOfClass:[PTTextMarkupEditTool class]])
    {
        self.nextToolType = [editTool class];
        self.defaultClass = [self class];
        return NO;
    }
    
    // Allow creation without dragging
    if( [self annotationToCreate] && (self.previousToolType != [PTAnnotEditTool class] || self.createdAnnot == YES))
    {
        [self createAnnotation];
        
//        if( self.toolManager.selectAnnotationAfterCreation )
//        {
//            self.defaultClass = [self class];
//            [self.toolManager selectAnnotation:self.currentAnnotation onPageNumber:self.pageNumber];
//            self.toolManager.tool.defaultClass = [self class];
//            return YES;
//        }
        
        BOOL returnValue = [self setupNextTool];

        self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.toolManager.annotationsCreatedWithPencilOnly;

        return returnValue;
        
    }
    else
    {
        self.createdAnnot = YES;
    }
		

    self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.toolManager.annotationsCreatedWithPencilOnly;

    return YES;

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }
    
    if( event.allTouches.count >= 2 )
    {
        return YES;
    }
    
	// keeps tool on top after a two-finger page change in
	// non-continous page view modes.
    [self.superview bringSubviewToFront:self];
	
    UITouch *touch = touches.allObjects[0];
    
    m_num_touches = touches.count;
    
    self.endPoint = self.startPoint = [touch locationInView:self.pdfViewCtrl];
    
    _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x y:self.startPoint.y];
    
    if (self.toolManager.snapToDocumentGeometry && [self isKindOfClass:[PTRulerCreate class]]) {
        PTPDFPoint* snapPtStart = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:self.startPoint.x py:self.startPoint.y]];
        self.startPoint = CGPointMake(snapPtStart.getX, snapPtStart.getY);
        
        PTPDFPoint* snapPtEnd = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:self.endPoint.x py:self.endPoint.y]];
        self.endPoint = CGPointMake(snapPtEnd.getX, snapPtEnd.getY);
    }

    if( self.pageNumber <= 0 )
    {
        return YES;
    }
    
    self.hidden = NO;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], 0, 0);
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
    
        PTPage* pg = [doc GetPage:self.pageNumber];
        
        PTPDFRect* pageRect = [pg GetCropBox];
        
        CGRect cropBox = [self PDFRectPage2CGRectScreen:pageRect PageNumber:self.pageNumber];
        
        CGRect cropBoxContainer = CGRectMake(cropBox.origin.x+[self.pdfViewCtrl GetHScrollPos], cropBox.origin.y+[self.pdfViewCtrl GetVScrollPos], cropBox.size.width, cropBox.size.height);
        
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		if( context )
			CGContextClipToRect(context, cropBoxContainer);
    
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    
    return YES;
}



- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{

    if( event.allTouches.count >= 2 )
    {
        return YES;
    }
    
    
    if( self.isPencilTouch == YES || self.toolManager.annotationsCreatedWithPencilOnly == NO )
    {
    
        UITouch *touch = touches.allObjects[0];
        
        m_num_touches = touches.count;
        
        self.endPoint = [touch locationInView:self.pdfViewCtrl];
        
        CGPoint touchPoint = [touch locationInView:self.pdfViewCtrl];
        
        self.endPoint = [self boundToPageScreenPoint:touchPoint withThicknessCorrection:0];
        
        CGPoint origin = CGPointMake(MIN(self.startPoint.x, self.endPoint.x), MIN(self.startPoint.y, self.endPoint.y));
        
        double drawWidth = MAX(0,fabs(self.endPoint.x-self.startPoint.x));
        double drawHeight = MAX(0,fabs(self.endPoint.y-self.startPoint.y));

        // used by rectangle and ellipse
        _drawArea = CGRectMake(origin.x, origin.y, drawWidth, drawHeight);
        
        double width = self.pdfViewCtrl.frame.size.width;
        double height = self.pdfViewCtrl.frame.size.height;
        
        self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], width, height);
    }

    return YES;
}

-(BOOL)annotationToCreate
{
    CGPoint noPoint = CGPointMake(-1, -1);
    
    if( CGPointEqualToPoint(self.startPoint, noPoint) && CGPointEqualToPoint(self.endPoint, noPoint))
    {
        return NO;
    }
    
    return YES;
}

- (void)createAnnotation {
    
    if( [self annotationToCreate] == NO)
    {
        return;
    }
    
    if( ![self isKindOfClass:[PTStickyNoteCreate class]] )
        [self keepToolAppearanceOnScreen];
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    PTAnnot* annotation;
    
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        
        self.hidden = YES;
        
        @try
        {
            
            PTPage* pg = [doc GetPage:self.pageNumber];
            
            if( [pg IsValid] == false )
            {
                return;
            }
            
            // support tap creation
            if( CGPointEqualToPoint(self.startPoint, self.endPoint) )
            {

                if( ![self isKindOfClass:[PTStickyNoteCreate class]] )
                {
                    _startPoint.x -= 100;
                    _startPoint.y -= 100;
                    
                    _endPoint.x += 100;
                    _endPoint.y += 100;
                }
                
                self.startPoint = [self boundToPageScreenPoint:self.startPoint withPaddingLeft:0 right:0 bottom:0 top:0];
                
                self.endPoint = [self boundToPageScreenPoint:self.endPoint withPaddingLeft:0 right:0 bottom:0 top:0];
            }
            
            self.startPoint = [self convertScreenPtToPagePt:self.startPoint onPageNumber:self.pageNumber];
            
            self.endPoint = [self convertScreenPtToPagePt:self.endPoint onPageNumber:self.pageNumber];
            

            
            //[self ConvertScreenPtToPagePtX:&self.endPoint.x Y:&self.endPoint.y PageNumber:self.pageNumber];
            
            PTPDFRect* myRect;
            
            if( ![self isKindOfClass:[PTStickyNoteCreate class]] ) // everything other than sticky
            {
                myRect = [[PTPDFRect alloc] initWithX1:self.startPoint.x y1:self.startPoint.y x2:self.endPoint.x y2:self.endPoint.y];
                
                annotation = [[self annotClass] Create:(PTSDFDoc*)doc pos:myRect];
                
                if ([self isKindOfClass:[PTArrowCreate class]])
                {
                    PTObj* lineSdf = [annotation GetSDFObj];
                    PTObj* le = [lineSdf PutArray:@"LE"];
                    [le PushBackName:@"OpenArrow"];
                    [le PushBackName:@"None"];
                }
                if ([self isKindOfClass:[PTRulerCreate class]])
                {
                    [((PTLineAnnot*)annotation) SetShowCaption:YES];
                    [((PTLineAnnot*)annotation) SetCaptionPosition:e_ptTop];
                    [((PTLineAnnot*)annotation) SetEndStyle:e_ptButt];
                    [((PTLineAnnot*)annotation) SetStartStyle:e_ptButt];
                    PTObj *obj = [annotation GetSDFObj];
                    // This is needed so that PTExtendedAnnotType can be correctly inferred from here on out
                    [obj PutDict:@"Measure"];
                }
                
                [self setPropertiesFromAnnotation: annotation];
                
                self.currentAnnotation = annotation;
                self.annotationPageNumber = self.pageNumber;
                
            }
            else //sticky
            {
                NSString* str = [[NSString alloc] init];
                
                CGRect rect = self.frame;
                
                if( rect.size.width == 0 )
                    rect.size.width = 1;
                if( rect.size.height == 0 )
                    rect.size.height = 1;
                
                myRect = [[PTPDFRect alloc] initWithX1:self.endPoint.x y1:self.endPoint.y x2:self.endPoint.x+1 y2:self.endPoint.y+1];
                [myRect Normalize];
                
                annotation = [[self annotClass] CreateTextWithRect:(PTSDFDoc*)doc pos:myRect contents:str];
                
                [((PTText*)annotation) SetTextIconType: e_ptComment];
                PTColorPt* colorPoint = [[PTColorPt alloc] initWithX:1.0 y:1.0 z:0.0 w:0.0];
                [((PTText*)annotation) SetColor:colorPoint numcomp:3];
                
                //                // sample code for a custom sticky note icon. Also need to eliminate subsequent calls to RefreshAppearance
                //                // which will regenerate the standard icon
                //                PTElementWriter* writer = [[PTElementWriter alloc] init];
                //                PTElementBuilder* builder = [[PTElementBuilder alloc] init];
                //
                //                [writer WriterBeginWithSDFDoc:[doc GetSDFDoc] compress:YES];
                //                PTImage* img = [PTImage Create:[doc GetSDFDoc] filename:[[NSBundle mainBundle] pathForResource:@"butterfly" ofType:@"png"]];
                //                int w = [img GetImageWidth], h = [img GetImageHeight];
                //                PTElement* img_element = [builder CreateImageWithCornerAndScale:img x:0 y:0 hscale:w vscale:h];
                //                [writer WritePlacedElement:img_element];
                //
                //                PTObj* appearance_stream = [writer End];
                //
                //                [appearance_stream PutRect:@"BBox" x1:0 y1:0 x2:w y2:h];
                //
                //                annotation = [PTText CreateTextWithRect:(PTSDFDoc*)doc pos:myRect contents:@"Hello World"];
                //                [annotation SetAppearance:appearance_stream annot_state:e_ptnormal app_state:0];
                //                [pg AnnotPushBack:annotation];
                
                self.currentAnnotation = annotation;
                self.annotationPageNumber = self.pageNumber;
            }
            
            [annotation RefreshAppearance];
            
            if( self.annotationAuthor && self.annotationAuthor.length > 0 && [annotation isKindOfClass:[PTMarkup class]]    )
            {
                [(PTMarkup*)annotation SetTitle:self.annotationAuthor];
            }
            
            [pg AnnotPushBack:annotation];
            
            if ([self annotClass] == [PTText class] &&
                self.toolManager.textAnnotationOptions.opensPopupOnTap) {
                [self editSelectedAnnotationNote];
            }
        }
        @catch(NSException * e)
        {
            // continue
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    if( self.pageNumber > 0 )
        [self.pdfViewCtrl UpdateWithAnnot:annotation page_num:self.pageNumber];
    
    [self annotationAdded:annotation onPageNumber:self.pageNumber];
    
    if( [self isKindOfClass:[PTStickyNoteCreate class]] )
    {
        // required to make it appear upright in rotated documents
        [annotation RefreshAppearance];
    }
    
    self.currentAnnotation = annotation;
    self.createdAnnot = YES;
}

- (BOOL)setupNextTool {
    if ([self isKindOfClass:[PTStickyNoteCreate class]]) {
        self.nextToolType = [PTPanTool class]; // will pop up note edit window
        return YES;
    }
    else if (self.toolManager.selectAnnotationAfterCreation) {
        if ([self isKindOfClass:[PTLineCreate class]] ||
            [self isKindOfClass:[PTArrowCreate class]]) {
            self.nextToolType = [PTPolylineEditTool class];
        } else {
            self.nextToolType = [PTAnnotEditTool class];
        }
    } else if (!self.backToPanToolAfterUse) {
        self.nextToolType = [self class];
        
        // Deselect current annotation so that the next tool doesn't think
        // that there is a selected annotation.
        self.currentAnnotation = nil;
    }
    
    if (self.backToPanToolAfterUse && ![self isKindOfClass:[PTStickyNoteCreate class]]) {
        self.defaultClass  = [PTPanTool class];
    } else {
        self.defaultClass = [self class];
    }
    return NO;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if( event.allTouches.count >= 2 )
    {
        return YES;
    }
    
    if( self.allowScrolling || (fabs(self.startPoint.x-self.endPoint.x) <= 3 && fabs(self.startPoint.y-self.endPoint.y) <= 3 && ![self isKindOfClass:[PTStickyNoteCreate class]]) )
    {
        if( self.backToPanToolAfterUse)
        {
            self.nextToolType = [PTPanTool class];
            return NO;
        }
        else
        {
            return YES;
        }
    }
	
	
    
    
    m_num_touches = touches.count;
    
    if (self.pageNumber < 1)
    {
        self.nextToolType = self.defaultClass;
        
        return NO;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly == NO || self.isPencilTouch == YES   )
    {
        [self createAnnotation];
    }
    
    
    BOOL returnValue = [self setupNextTool];
    
	return returnValue;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL ret = [super pdfViewCtrl:pdfViewCtrl touchesShouldBegin:touches withEvent:event inContentView:view];

    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }

    return ret;

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{

    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        return !self.isPencilTouch;
    }
    
    return YES;
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidZoom:(nonnull UIScrollView *)scrollView
{
    self.hidden = YES;
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScroll:(nonnull UIScrollView *)scrollView
{
    self.hidden = YES;
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScroll:(UIScrollView *)scrollView
{
    self.hidden = YES;
}


-(CGPoint)boundToPageScreenPoint:(CGPoint)touchPoint
                         withPaddingLeft:(CGFloat)left
                                   right:(CGFloat)right
                                  bottom:(CGFloat)bottom
                                     top:(CGFloat)top
{
    PTPage* page;
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        
        page = [doc GetPage:self.pageNumber];
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",[exception name], [exception reason]);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
    
    CGFloat minX = [page_rect GetX1]+left;
    CGFloat maxX = [page_rect GetX2]-right;
    CGFloat minY = [page_rect GetY1]+top;
    CGFloat maxY = [page_rect GetY2]-bottom;
    
    
    if( touchPoint.x < minX )
    {
        touchPoint.x = minX;
    }
    else if( touchPoint.x > maxX )
    {
        touchPoint.x = maxX;
    }
    
    if( touchPoint.y < minY )
    {
        touchPoint.y = minY;
    }
    else if( touchPoint.y > maxY )
    {
        touchPoint.y = maxY;
    }
    
    return CGPointMake(touchPoint.x, touchPoint.y);
    
}


-(CGPoint)boundToPageScreenPoint:(CGPoint)touchPoint withThicknessCorrection:(CGFloat)thickness
{
    return [self boundToPageScreenPoint:touchPoint
                           withPaddingLeft:thickness
                                     right:thickness
                                    bottom:thickness
                                       top:thickness];
}

- (void) setPropertiesFromAnnotation:(PTAnnot *)annotation  {
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
		
		PTExtendedAnnotType annotType = [self annotType];

        // stroke colour
		PTColorPt* strokeColor = [PTColorDefaults defaultColorPtForAnnotType:annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:e_ptpostprocess_none];
		int compNums = [PTColorDefaults numCompsInColorPtForAnnotType:annotType attribute:ATTRIBUTE_STROKE_COLOR];
        [annotation SetColor:strokeColor numcomp:compNums];
        
        // thickness
		double width = [PTColorDefaults defaultBorderThicknessForAnnotType:annotType];
		PTBorderStyle* bs = [[PTBorderStyle alloc] initWithS:e_ptsolid b_width:width b_hr:0 b_vr:0];
		
        [annotation SetBorderStyle:bs oldStyleOnly:NO];
        
        if ([annotation isKindOfClass:[PTMarkup class]]) {
            
			PTColorPt* fillColor = [PTColorDefaults defaultColorPtForAnnotType:annotType attribute:ATTRIBUTE_FILL_COLOR colorPostProcessMode:e_ptpostprocess_none];
			int compNums = [PTColorDefaults numCompsInColorPtForAnnotType:annotType attribute:ATTRIBUTE_FILL_COLOR];
			[(PTMarkup*)annotation SetInteriorColor:fillColor CompNum:compNums];
            
            // opacity
			double opacity = [PTColorDefaults defaultOpacityForAnnotType:annotType];
            [(PTMarkup*)annotation SetOpacity:opacity];
        }
        if ( annotType == PTExtendedAnnotTypeRuler || annotType == PTExtendedAnnotTypePerimeter || annotType == PTExtendedAnnotTypeArea ){
            PTMeasurementScale* measurementScale = [PTColorDefaults defaultMeasurementScaleForAnnotType:annotType];

            [PTMeasurementUtil setAnnotMeasurementData:annotation fromMeasurementScale:measurementScale];
            [((PTLineAnnot*)annotation) SetTextVOffset:width/2.0f];
        }
    
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( event.allTouches.count >= 2 )
    {
        return YES;
    }

    return [self pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

-(void)setFrame:(CGRect)frame
{
    super.frame = frame;
    [self setNeedsDisplay];
}

-(double)setupContext:(CGContextRef)currentContext
{
    @try
    {
        
        [self.pdfViewCtrl DocLockRead];
        
		PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
		
		PTPage* pg = [doc GetPage:self.pageNumber];
		
		PTPDFRect* pageRect = [pg GetCropBox];
		
		CGRect cropBox = [self PDFRectPage2CGRectScreen:pageRect PageNumber:self.pageNumber];
		
		if( currentContext )
			CGContextClipToRect(currentContext, cropBox);

        
		PTColorPostProcessMode mode = [self.pdfViewCtrl GetColorPostProcessMode];
		
    
		PTExtendedAnnotType annotType = [self annotType];
        
        _strokeColor = [PTColorDefaults defaultColorForAnnotType:annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:mode];
        
        _fillColor = [PTColorDefaults defaultColorForAnnotType:annotType attribute:ATTRIBUTE_FILL_COLOR colorPostProcessMode:mode];
        
        _opacity = [PTColorDefaults defaultOpacityForAnnotType:annotType];
        
        // Decrease of freehand-highlight opacity slightly from 1.0, since doing a multiply blend
        // mode requires some hacks.
        if (annotType == PTExtendedAnnotTypeFreehandHighlight && _opacity == 1.0) {
            _opacity = 0.8;
        }
        
        _thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:annotType];
        
        _thickness *= [self.pdfViewCtrl GetZoom];
		
		CGContextSetLineWidth(currentContext, _thickness);
		CGContextSetLineCap(currentContext, kCGLineCapRound);
		CGContextSetLineJoin(currentContext, kCGLineJoinRound);
		CGContextSetStrokeColorWithColor(currentContext, _strokeColor.CGColor);
		CGContextSetFillColorWithColor(currentContext, _fillColor.CGColor);
		CGContextSetAlpha(currentContext, _opacity);
		
		
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    return _thickness;
}

-(void)swapA:(CGFloat*)a B:(CGFloat*)b
{
    CGFloat tmp;
    tmp = *a;
    *a = *b;
    *b = tmp;
}

#pragma mark - Undo manager

- (BOOL)isUndoManagerEnabled
{
    return NO;
}

@synthesize undoManager = _undoManager;

- (NSUndoManager *)undoManager
{
    if ([self isUndoManagerEnabled]) {
        if (!_undoManager) {
            _undoManager = [[NSUndoManager alloc] init];
        }
        return _undoManager;
    } else {
        return [super undoManager];
    }
}

@end
