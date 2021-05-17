//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextMarkupCreate.h"

#import "PTPanTool.h"
#import "PTColorDefaults.h"
#import "PTAnnotEditTool.h"
#import "PTTextMarkupEditTool.h"
#import "PTFormFillTool.h"
#import "PTMagnifierView.h"

@interface PTTextMarkupCreate ()
{
    CGPoint selectionStart;
    CGPoint selectionEnd;
    
    BOOL shouldCancel;
    
    int pageNumber;
    
    NSMutableArray* currentSelection;
    
    PTMagnifierView* loupe;
    
    NSMutableArray* selectionLayers;
    
    BOOL selectionOnScreen;
    
    BOOL tapOK;
    
    PTColorPt* _colorPt;
    double _thickness;
    int _compNums;
}

@property (nonatomic, assign) BOOL isPencilTouch;

@end

@implementation PTTextMarkupCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = YES;
        selectionLayers = [[NSMutableArray alloc] init];
        self.allowZoom = YES;
        shouldCancel = false;
		_thickness = -1;
        _isPencilTouch = YES;
    }
    
    return self;
}

-(void)setToolManager:(PTToolManager *)toolManager
{
    [super setToolManager:toolManager];
    
    self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.toolManager.annotationsCreatedWithPencilOnly;
}


+ (BOOL)canEditStyle
{
    return YES;
}

+(BOOL)createsAnnotation
{
	return YES;
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if( newSuperview == nil )
    {
        [self ClearSelectionOnly];

        [loupe removeFromSuperview];
    }
    else
    {

    }
    
    [super willMoveToSuperview:newSuperview];
}


-(void)pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
	
	TrnPagePresentationMode mode = [self.pdfViewCtrl GetPagePresentationMode];
	
	if( mode == e_ptsingle_page || mode == e_ptfacing || mode == e_ptfacing_cover )
    {
	
		[self ClearSelectionOnly];
		
		[self hideMenu];
		
		selectionOnScreen = NO;
		
		// this stops old markup annot from being selected
		// by the onTouchesEnded: event of MarkupEditTool
		self.currentAnnotation = nil;
			
	}
	
	[super pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:oldPageNumber To:newPageNumber];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
    // don't create a tiny annotation
    if( self.backToPanToolAfterUse)
    {
        self.nextToolType = [PTPanTool class];
        return NO;
    }
    else
    {
		// user has tapped on the screen, and we want to edit it
		// with the approriate tool. Fake a tap using the PTPanTool
		// to figure out which.
		
		PTTool* editTool = [[PTPanTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
        editTool.toolManager = self.toolManager;
		
		while(![editTool pdfViewCtrl:pdfViewCtrl handleTap:sender])
		{
			editTool = (PTTool *)[editTool getNewTool];
			
			if( [editTool isKindOfClass:[PTFormFillTool class]] )
				break;
		}
		
		if([editTool isKindOfClass:[PTAnnotEditTool class]] || [editTool isKindOfClass:[PTTextMarkupEditTool class]])
		{
			self.nextToolType = [editTool class];
			self.defaultClass = [self class];
			return NO;
		}
		
		[self ClearSelectionOnly];
		
		[self hideMenu];
		
		selectionOnScreen = NO;
		
		// this stops old markup annot from being selected
		// by the onTouchesEnded: event of MarkupEditTool
		self.currentAnnotation = nil;
		
        return YES;
    }
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
    
    if( !self.allowScrolling )
	{
		if( event.allTouches.count  > 1 )
			shouldCancel = true;
		else
			shouldCancel = false;
		
		UITouch *touch = touches.allObjects[0];
		
		selectionStart = selectionEnd = [touch locationInView:self.pdfViewCtrl];
		
		pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:selectionStart.x y:selectionStart.y];
		
		[self ConvertScreenPtToPagePtX:&selectionStart.x Y:&selectionStart.y PageNumber:pageNumber];
		
		[self ConvertScreenPtToPagePtX:&selectionEnd.x Y:&selectionEnd.y PageNumber:pageNumber];
		
		self.backgroundColor = [UIColor clearColor];
		
		self.frame = self.pdfViewCtrl.bounds;
				
		CGPoint down = [touch locationInView:self.pdfViewCtrl];
		
		down.y += self.pdfViewCtrl.frame.origin.y;
		down.x += self.pdfViewCtrl.frame.origin.x;

	}
    
    return YES;
}


- (void)touchMove:(CGPoint)touch
{
	if( !self.allowScrolling )
	{
		selectionEnd = touch;
		
		[self ConvertScreenPtToPagePtX:&selectionEnd.x Y:&selectionEnd.y PageNumber:pageNumber];
		
		[self.pdfViewCtrl SelectX1:selectionStart.x Y1:selectionStart.y PageNumber1:pageNumber X2:selectionEnd.x Y2:selectionEnd.y PageNumber2:pageNumber];
		
		currentSelection = [self GetQuadsFromPage:pageNumber];
		
		[self DrawSelectionQuads:currentSelection];
	}
	else
	{
		if( loupe.superview != nil )
            [loupe removeFromSuperview];
		[self ClearSelectionOnly];
	}
}

-(void)addLoupeAtMagnifyPoint:(CGPoint)magnifyPoint touchPoint:(CGPoint)touchPoint
{
    if(loupe == nil){
        loupe = [[PTMagnifierView alloc] initWithViewToMagnify:self.pdfViewCtrl];
    }
    if(loupe.superview == nil)
        [self.pdfViewCtrl.superview addSubview:loupe];

    [loupe setMagnifyPoint:magnifyPoint TouchPoint:touchPoint];
    [loupe setNeedsDisplay];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if( gestureRecognizer.state == UIGestureRecognizerStateChanged )
    {
        CGPoint touch = [gestureRecognizer locationInView:self.pdfViewCtrl];
        
        [self touchMove:touch];
    }
    else if( gestureRecognizer.state == UIGestureRecognizerStateEnded )
    {
        // same as onTouchesEnded
        [self ClearSelectionOnly];
        
        [self createAnnotation];
        
        if( loupe.superview != nil )
            [loupe removeFromSuperview];
        
        if( self.backToPanToolAfterUse )
        {
            self.nextToolType = [PTPanTool class];
            return NO;
        }
        else
            return YES;
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( event.allTouches.count >= 2 )
    {
        return YES;
    }
    
    if( event.allTouches.count >1 )
        shouldCancel = true;
    else
        shouldCancel = false;
    
    UITouch *touch = touches.allObjects[0];
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
    down.y += self.pdfViewCtrl.frame.origin.y;
    down.x += self.pdfViewCtrl.frame.origin.x;
    if (touch.type != UITouchTypePencil && self.toolManager.annotationsCreatedWithPencilOnly == NO) {
        [self addLoupeAtMagnifyPoint:down touchPoint:down];
    }
    [self touchMove:[touch locationInView:self.pdfViewCtrl]];
    
    return YES;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( event.allTouches.count >= 2 )
    {
        return YES;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        BOOL isPencil = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
        self.isPencilTouch = isPencil;
        if( isPencil == NO )
        {
            return YES;
        }
    }
    
    // same as handleLongPress ended
    [self ClearSelectionOnly];
    [self createAnnotation];

    if( loupe.superview != nil )
        [loupe removeFromSuperview];
    
    // Reset selection color.
    _colorPt = nil;
	
    if( self.backToPanToolAfterUse ) {
		self.defaultClass = [PTPanTool class];
    } else {
		self.defaultClass = [self class];
    }
    
    self.isPencilTouch = NO;
    
    if (self.toolManager.selectAnnotationAfterCreation) {
        // edit this annotaiton immediately, providing instant access
        // to the note button, properties, etc.
        self.nextToolType = [PTTextMarkupEditTool class];
    } else {
        // Switch to the default class.
        self.nextToolType = self.defaultClass;
        
        // Deselect current annotation so that the next tool doesn't think
        // that there is a selected annotation.
        self.currentAnnotation = nil;
    }
    
	return NO;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	return [self pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
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
        ret = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
        self.isPencilTouch = ret;
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

-(void)ClearSelectionOnly
{
    
    [selectionLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [selectionLayers removeAllObjects];
    
}

-(void)DrawSelectionQuads:(NSMutableArray*)quads
{
	if( !self.allowScrolling )
	{
		int drawnQuads = 0;
		
		[self ClearSelectionOnly];
		
		PTColorPostProcessMode mode = [self.pdfViewCtrl GetColorPostProcessMode];
		
		for (NSValue* quad in quads) 
		{
			CALayer* selectionLayer = [[CALayer alloc] init];
			
			CGRect selectionRect = quad.CGRectValue;
			
			if( self.annotType == PTExtendedAnnotTypeHighlight || self.annotType == PTExtendedAnnotTypeRedact )
			{
				selectionLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos], selectionRect.origin.y+[self.pdfViewCtrl GetVScrollPos], selectionRect.size.width, selectionRect.size.height);
				
				if( !_colorPt )
					_colorPt = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:mode];//[m_default_text_annotation GetColorAsRGB];
				
				UIColor* defaultTextAnnotColor = [UIColor colorWithRed:[_colorPt Get:0] green:[_colorPt Get:1] blue:[_colorPt Get:2] alpha:0.20];
				
				CGColorRef cgDefaultTextAnnotColorr = defaultTextAnnotColor.CGColor;
				
				selectionLayer.backgroundColor = cgDefaultTextAnnotColorr;
			}
			else if( self.annotType == PTExtendedAnnotTypeUnderline || self.annotType == PTExtendedAnnotTypeSquiggly)
			{
				//BorderStyle* bs = [m_default_text_annotation GetBorderStyle];
				if( _thickness < 0 )
					_thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];//[bs GetWidth];
				
				selectionLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos], selectionRect.origin.y+selectionRect.size.height+[self.pdfViewCtrl GetVScrollPos] - _thickness, selectionRect.size.width, _thickness);
				
				if( !_colorPt )
					_colorPt = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:mode];//[m_default_text_annotation GetColorAsRGB];
				
				UIColor* defaultTextAnnotColor = [UIColor colorWithRed:[_colorPt Get:0] green:[_colorPt Get:1] blue:[_colorPt Get:2] alpha:1.0];
				
				CGColorRef cgDefaultTextAnnotColorr = defaultTextAnnotColor.CGColor;
				
				selectionLayer.backgroundColor = cgDefaultTextAnnotColorr;

			}
			else if( self.annotType == PTExtendedAnnotTypeStrikeOut )
			{
				//BorderStyle* bs = [m_default_text_annotation GetBorderStyle];
				
				if ( _thickness < 0 )
					_thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];//[bs GetWidth];
				
				selectionLayer.frame = CGRectMake(selectionRect.origin.x+[self.pdfViewCtrl GetHScrollPos], selectionRect.origin.y+selectionRect.size.height/2+[self.pdfViewCtrl GetVScrollPos] - _thickness/2, selectionRect.size.width, _thickness);
				
				if( !_colorPt )
					_colorPt = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:mode];//[m_default_text_annotation GetColorAsRGB];
				
				UIColor* defaultTextAnnotColor = [UIColor colorWithRed:[_colorPt Get:0] green:[_colorPt Get:1] blue:[_colorPt Get:2] alpha:1.0];
				
				CGColorRef cgDefaultTextAnnotColorr = defaultTextAnnotColor.CGColor;
				
				selectionLayer.backgroundColor = cgDefaultTextAnnotColorr;
			}
			else
			{
				// http://stackoverflow.com/questions/5693297/how-to-draw-wavy-line-on-ios-device
				// squiggly not yet implemented - uses underline
				
				
			}
			
			[self.pdfViewCtrl.toolOverlayView.layer addSublayer:selectionLayer];
			
			[selectionLayers addObject:selectionLayer];
			
			
			drawnQuads++;
		}
	}
	else
	{
		[self ClearSelectionOnly];
	}
    
}

-(NSMutableArray*)GetQuadsFromPage:(int)page
{
    NSMutableArray* quadsToReturn = [[NSMutableArray alloc] init];
    
    PTSelection* selection = [self.pdfViewCtrl GetSelection:page];
    
    PTVectorQuadPoint* quads = [selection GetQuads];
    
    NSUInteger numberOfQuads = [quads size];
    
    if( numberOfQuads == 0 )
        return nil;
    
    int selectionPageNumber = [selection GetPageNum];
    
    
    for(int ii = 0; ii < numberOfQuads; ii++)
    {
        PTQuadPoint* aQuad = [quads get:ii];
        
        TRN_point* t_point1 = [aQuad getP1];
        TRN_point* t_point2 = [aQuad getP2];
        TRN_point* t_point3 = [aQuad getP3];
        TRN_point* t_point4 = [aQuad getP4];
        
        CGPoint point1 = CGPointMake([t_point1 getX], [t_point1 getY]);
        CGPoint point2 = CGPointMake([t_point2 getX], [t_point2 getY]);
        CGPoint point3 = CGPointMake([t_point3 getX], [t_point3 getY]);
        CGPoint point4 = CGPointMake([t_point4 getX], [t_point4 getY]);
        
        @try
        { 
            [self ConvertPagePtToScreenPtX:&point1.x Y:&point1.y PageNumber:selectionPageNumber];
            [self ConvertPagePtToScreenPtX:&point2.x Y:&point2.y PageNumber:selectionPageNumber];
            [self ConvertPagePtToScreenPtX:&point3.x Y:&point3.y PageNumber:selectionPageNumber];
            [self ConvertPagePtToScreenPtX:&point4.x Y:&point4.y PageNumber:selectionPageNumber];
            
        }
        @catch(NSException *exception)
        {
            continue;
        }
        
        float left = MIN(point1.x, MIN(point2.x, MIN(point3.x, point4.x)));
        float right = MAX(point1.x, MAX(point2.x, MAX(point3.x, point4.x)));
        
        float top = MIN(point1.y, MIN(point2.y, MIN(point3.y, point4.y)));
        float bottom = MAX(point1.y, MAX(point2.y, MAX(point3.y, point4.y)));
        
        
        
        [quadsToReturn addObject:[NSValue valueWithCGRect:CGRectMake(left, top, (right-left), (bottom-top))]];
    }
    
    return quadsToReturn;
}

- (void)createAnnotation
{
    if ([self.annotClass isSubclassOfClass:[PTTextMarkup class]]) {
        [self createTextMarkupAnnot];
    }
    else if ([self.annotClass isSubclassOfClass:[PTRedactionAnnot class]]) {
        [self createRedactionAnnotation];
    }
    
    [self ClearSelectionOnly];
}

-(void)createTextMarkupAnnot
{
    NSUInteger num_quads;
	if( !self.allowScrolling && !CGPointEqualToPoint(selectionStart,selectionEnd) )
	{
		PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        BOOL hitException = NO;
		@try
		{
			[self.pdfViewCtrl DocLock:YES];
		
			[self.pdfViewCtrl SelectX1:selectionStart.x Y1:selectionStart.y PageNumber1:pageNumber X2:selectionEnd.x Y2:selectionEnd.y PageNumber2:pageNumber];
			
			[self GetQuadsFromPage:pageNumber];
			
			PTPage* p = [doc GetPage:pageNumber];
				
			if( ![p IsValid] )
				return;
			
			PTSelection* sel = [self.pdfViewCtrl GetSelection:pageNumber];
			PTVectorQuadPoint* quads = [sel GetQuads];
			num_quads = [quads size];
			
			if( num_quads > 0 )
			{
				PTQuadPoint* qp = [quads get:0];
				
				TRN_point* point = [qp getP1];
				
				double x1 = [point getX];
				double y1 = [point getY];
				
				point = [qp getP3];
				
				double x2 = [point getX];
				double y2 = [point getY];
				
				PTPDFRect* r = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
				
				
				PTTextMarkup* mktp;
				
				switch (self.annotType) {
					case PTExtendedAnnotTypeHighlight:
						mktp = [PTHighlightAnnot Create:(PTSDFDoc*)doc pos:r];
						break;
					case PTExtendedAnnotTypeUnderline:
						mktp = [PTUnderline Create:(PTSDFDoc*)doc pos:r];
						break;
					case PTExtendedAnnotTypeStrikeOut:
						mktp = [PTStrikeOut Create:(PTSDFDoc*)doc pos:r];
						break;
					case PTExtendedAnnotTypeSquiggly:
						mktp = [PTSquiggly Create:(PTSDFDoc*)doc pos:r];
						break;
					default:
						// not a supported text annotation type?
						assert(false);
						break;
				}

				for( int i=0; i < num_quads; ++i )
				{
					PTQuadPoint* quad = [quads get:i];

					if( self.textMarkupAdobeHack )
					{
						// Acrobat and Preview do not follow the PDF specification regarding
						// the ordering of quad points in a text markup annotation. Enable
						// this code for compatibility with those viewers.

						PTPDFPoint* point1 = [quad getP1];
						PTPDFPoint* point2 = [quad getP2];
						PTPDFPoint* point3 = [quad getP3];
						PTPDFPoint* point4 = [quad getP4];
					
						PTQuadPoint* newQuad = [[PTQuadPoint alloc] init];
					
						[newQuad setP1:point4];
						[newQuad setP2:point3];
						[newQuad setP3:point1];
						[newQuad setP4:point2];
					
						[mktp SetQuadPoint:i qp:newQuad];
					}
					else
					{
						[mktp SetQuadPoint:i qp:quad];
					}
				
				}
				
				if( self.annotationAuthor && self.annotationAuthor.length > 0 && [mktp isKindOfClass:[PTMarkup class]]	)
				{
					[(PTMarkup*)mktp SetTitle:self.annotationAuthor];
				}
                
                // Check if the annotated text should be copied to the annotation's contents.
                BOOL shouldCopyAnnotatedTextToContents = NO;
                PTAnnotationOptions *options = [self.toolManager annotationOptionsForAnnotType:self.annotType];
                if ([options isKindOfClass:[PTTextMarkupAnnotationOptions class]]) {
                    shouldCopyAnnotatedTextToContents = ((PTTextMarkupAnnotationOptions *)options).copiesAnnotatedTextToContents;
                }
                if (shouldCopyAnnotatedTextToContents) {
                    PTPopup *popup = [PTPopup Create:[doc GetSDFDoc] pos:[mktp GetRect]];
                    [popup SetParent:mktp];
                    [mktp SetPopup:popup];
                    [popup SetContents:[sel GetAsUnicode]];
                }
				
				[p AnnotPushBack:mktp];
				
				PTColorPt* cp = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:e_ptpostprocess_none];//[m_default_text_annotation GetColorAsRGB];
				int compNum = [PTColorDefaults numCompsInColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR];
				[mktp SetColor:cp numcomp:compNum];
				
				[mktp SetOpacity:[PTColorDefaults defaultOpacityForAnnotType:self.annotType]];
				
				//BorderStyle* bs = [m_default_text_annotation GetBorderStyle];
				if( _thickness < 0 )
					_thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];
				PTBorderStyle* bs = [[PTBorderStyle alloc] initWithS:e_ptsolid b_width:_thickness b_hr:0 b_vr:0];
				
				[mktp SetBorderStyle:bs oldStyleOnly:NO];

				[mktp RefreshAppearance];
				
				self.currentAnnotation = mktp;
				self.annotationPageNumber = pageNumber;
				
				[self.pdfViewCtrl UpdateWithAnnot:mktp page_num:pageNumber];

			}

		}
		@catch (NSException *exception) {
			NSLog(@"Exception: %@: %@",exception.name, exception.reason);
            hitException = YES;
		}
		@finally {
			[self.pdfViewCtrl DocUnlock];
		}
        
        if (!hitException && num_quads > 0)
            [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        
    }
}

- (void)createRedactionAnnotation
{
    NSUInteger num_quads;
    if( !self.allowScrolling && !CGPointEqualToPoint(selectionStart,selectionEnd) )
    {
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        BOOL hitException = NO;
        @try
        {
            [self.pdfViewCtrl DocLock:YES];
            
            [self.pdfViewCtrl SelectX1:selectionStart.x Y1:selectionStart.y PageNumber1:pageNumber X2:selectionEnd.x Y2:selectionEnd.y PageNumber2:pageNumber];
            
            [self GetQuadsFromPage:pageNumber];
            
            PTPage* p = [doc GetPage:pageNumber];
            
            if( ![p IsValid] )
                return;
            
            PTSelection* sel = [self.pdfViewCtrl GetSelection:pageNumber];
            PTVectorQuadPoint* quads = [sel GetQuads];
            num_quads = [quads size];
            
            if( num_quads > 0 )
            {
                PTQuadPoint* qp = [quads get:0];
                
                TRN_point* point = [qp getP1];
                
                double x1 = [point getX];
                double y1 = [point getY];
                
                point = [qp getP3];
                
                double x2 = [point getX];
                double y2 = [point getY];
                
                PTPDFRect* r = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
                
                PTRedactionAnnot *redactAnnot = [PTRedactionAnnot Create:[doc GetSDFDoc] pos:r];
                
                for( int i=0; i < num_quads; ++i ) {
                    PTQuadPoint* quad = [quads get:i];
                    [redactAnnot SetQuadPoint:i qp:quad];
                }
                
                if (self.annotationAuthor.length > 0 && [redactAnnot isKindOfClass:[PTMarkup class]]) {
                    [(PTMarkup*)redactAnnot SetTitle:self.annotationAuthor];
                }
                
                [p AnnotPushBack:redactAnnot];
                
                PTColorPt* cp = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:e_ptpostprocess_none];
                int compNum = [PTColorDefaults numCompsInColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR];
                [redactAnnot SetColor:cp numcomp:compNum];
                
                [redactAnnot SetOpacity:[PTColorDefaults defaultOpacityForAnnotType:self.annotType]];
                
                double width = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];
                
                PTBorderStyle *bs = [[PTBorderStyle alloc] initWithS:e_ptsolid b_width:width b_hr:0 b_vr:0];
                
                [redactAnnot SetBorderStyle:bs oldStyleOnly:NO];
                
                [redactAnnot RefreshAppearance];
                
                self.currentAnnotation = redactAnnot;
                self.annotationPageNumber = pageNumber;
                
                [self.pdfViewCtrl UpdateWithAnnot:redactAnnot page_num:pageNumber];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@", exception.name, exception.reason);
            hitException = YES;
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
        
        if (!hitException && num_quads > 0) {
            [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        }
    }
    
}

@end
