//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTLineEditTool.h"

#import "PTAnnotEditToolSubclass.h"
#import "PTSelectionRectContainerView.h"

#import "CGGeometry+PTAdditions.h"

typedef NS_ENUM(NSUInteger, PTLinePointDirection) {
    PTLinePointDirectionTopLeft,
    PTLinePointDirectionTopRight,
    PTLinePointDirectionBottomLeft,
    PTLinePointDirectionBottomRight,
};

@interface PTLineEditTool()
{
    CGPoint m_touchPoint;
    PTLineAnnot* m_lineAnnot;
    PTPDFPoint* m_ptToDrawTo;
    BOOL movedEndPt;
    BOOL m_resizing;
    BOOL m_isDragging;
    CGPoint _touchStartPoint;
    CGPoint _touchEndPoint;
    
    PTLinePointDirection m_pointing;
}
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation PTLineEditTool
#pragma clang diagnostic pop

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void) setSelectionRectDelta: (CGRect) deltaRect
{
	self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height );
    
    
    // make sure you can't drag the end of the line off the page
    m_touchPoint = [self boundPointToPage:m_touchPoint];
    
    // position the resize widget correctly
    CGPoint newLocation = [self.pdfViewCtrl convertPoint:m_touchPoint toView:[self.touchedSelectWidget superview]];
    
    CGRect resizeWidgetFrame;
    const int length = PTResizeWidgetView.length;
    resizeWidgetFrame.origin.x = newLocation.x-length/2;
    resizeWidgetFrame.origin.y = newLocation.y-length/2;
    resizeWidgetFrame.size.width = self.touchedSelectWidget.frame.size.width;
    resizeWidgetFrame.size.height = self.touchedSelectWidget.frame.size.height;
    
    self.touchedSelectWidget.frame = resizeWidgetFrame;
    
	m_resizing = YES;

}

-(void)selectCurrentAnnotation
{
	PTPDFPoint *basePoint, *endPoint;
	PTPDFRect *tightRect;
	@try
	{
		[self.pdfViewCtrl DocLockRead];
		m_lineAnnot = [[PTLineAnnot alloc] initWithAnn:self.currentAnnotation];
		
		basePoint = [m_lineAnnot GetStartPoint];
		endPoint = [m_lineAnnot GetEndPoint];
		tightRect = [[PTPDFRect alloc] initWithX1:[basePoint getX] y1:[basePoint getY] x2:[endPoint getX] y2:[endPoint getY]];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@: %@",exception.name, exception.reason);
	}
	@finally {
		[self.pdfViewCtrl DocUnlockRead];
	}
	
	PTPDFPoint* sp = [self.pdfViewCtrl ConvPagePtToScreenPt:basePoint page_num:self.annotationPageNumber];

	CGPoint head = CGPointMake([sp getX], [sp getY]);
	
	self.annotRect = [self PDFRectPage2CGRectScreen:tightRect PageNumber:self.annotationPageNumber];
	
	if( [self PointsAreEqualA:head	B:self.annotRect.origin] )
	{
		// arrow points up, left
		m_pointing = PTLinePointDirectionTopLeft;
	}
	else if( [self PointsAreEqualA:head	B:CGPointMake(self.annotRect.origin.x, self.annotRect.origin.y+self.annotRect.size.height)] )
	{
		m_pointing = PTLinePointDirectionBottomLeft;
	}
	else if( [self PointsAreEqualA:head	B:CGPointMake(self.annotRect.origin.x+self.annotRect.size.width, self.annotRect.origin.y)] )
	{
		m_pointing = PTLinePointDirectionTopRight;
	}
	else
	{
		m_pointing = PTLinePointDirectionBottomRight;
	}
	
	self.annotationPageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.annotRect.origin.x+self.annotRect.size.width/2 y:self.annotRect.origin.y+self.annotRect.size.height/2];
	
    self.annotRect = CGRectOffset(self.annotRect, [self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos]);
    
	[self.selectionRectContainerView setFrameFromAnnot:self.annotRect];
    
    self.selectionRectContainerView.hidden = NO;
    self.selectionRectContainerView.borderView.hidden = YES;
	
    if ([self annotIsResizable:self.currentAnnotation]) {
        PTPDFPoint* pagePoint1 = [self.pdfViewCtrl ConvPagePtToScreenPt:basePoint page_num:self.annotationPageNumber];
        PTPDFPoint* pagePoint2 = [self.pdfViewCtrl ConvPagePtToScreenPt:endPoint page_num:self.annotationPageNumber];
        
        double slope = ([pagePoint2 getY] - [pagePoint1 getY])/([pagePoint2 getX] - [pagePoint1 getX]);
        
        if( slope > 0 )
        {
            [self.selectionRectContainerView showNWSEWidgetViews];
        }
        else
        {
            [self.selectionRectContainerView showNESWWidgetViews];
        }
    } else {
        [self.selectionRectContainerView hideResizeWidgetViews];
    }
	
	[self.selectionRectContainerView setAnnot:self.currentAnnotation];
	
	if( [self.selectionRectContainerView superview] != self.pdfViewCtrl.toolOverlayView)
	{
		[self.pdfViewCtrl.toolOverlayView addSubview:self.selectionRectContainerView];
	}
	
    self.annotRect = CGRectOffset(self.annotRect, - [self.pdfViewCtrl GetHScrollPos], - [self.pdfViewCtrl GetVScrollPos]);
    
	[self hideMenu];
	[self showSelectionMenu: self.annotRect];

}

- (BOOL)selectAnnotation:(PTAnnot *)annotation onPageNumber:(unsigned int)pageNumber
{
    BOOL selected = [super selectAnnotation:annotation onPageNumber:pageNumber];
    if (selected) {
        [self selectCurrentAnnotation];
    }
    return selected;
}

-(void)deleteSelectedAnnotation
{
    [super deleteSelectedAnnotation];
    m_lineAnnot = nil;
}

- (void)moveAnnotation:(CGPoint)down
{
    [self.selectionRectContainerView hideSelectionRect];
    
    if (![self.currentAnnotation IsValid]) {
        return;
    }
    
    @try {
        [self.pdfViewCtrl DocLock:YES];
        
        PTPDFPoint *touchStartPointPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:_touchStartPoint.x py:_touchStartPoint.y] page_num:self.annotationPageNumber];
        
        PTPDFPoint *touchEndPointPage = [self.pdfViewCtrl ConvScreenPtToPagePt:[[PTPDFPoint alloc] initWithPx:_touchEndPoint.x py:_touchEndPoint.y] page_num:self.annotationPageNumber];
        
        // Calculate the annotation displacement.
        CGFloat diffX = [touchEndPointPage getX] - [touchStartPointPage getX];
        CGFloat diffY = [touchEndPointPage getY] - [touchStartPointPage getY];
        
        PTPDFPoint *oldStartPointPage = [m_lineAnnot GetStartPoint];
        PTPDFPoint *oldEndPointPage = [m_lineAnnot GetEndPoint];
        
        CGFloat width = fabs([oldEndPointPage getX] - [oldStartPointPage getX]);
        CGFloat height = fabs([oldEndPointPage getY] - [oldStartPointPage getY]);
        
        // Calculate new start and end points.
        PTPDFPoint *startPointPage = [[PTPDFPoint alloc] initWithPx:([oldStartPointPage getX] + diffX) py:([oldStartPointPage getY] + diffY)];
        PTPDFPoint *endPointPage = [[PTPDFPoint alloc] initWithPx:([oldEndPointPage getX] + diffX) py:([oldEndPointPage getY] + diffY)];
        
        PTPDFRect *cropBox = [[self.currentAnnotation GetPage] GetCropBox];
        
        // Bound the start and end points to the page's crop box.
        if ([startPointPage getY] < [cropBox GetY1] || [endPointPage getY] < [cropBox GetY1]) {
            if ([startPointPage getY] < [endPointPage getY]) {
                [startPointPage setY:[cropBox GetY1]];
                [endPointPage setY:[cropBox GetY1] + height];
            }
            else {
                [endPointPage setY:[cropBox GetY1]];
                [startPointPage setY:[cropBox GetY1] + height];
            }
        }
        
        if ([startPointPage getY] > [cropBox GetY2] || [endPointPage getY] > [cropBox GetY2]) {
            if ([startPointPage getY] > [endPointPage getY]) {
                [startPointPage setY:cropBox.GetY2];
                [endPointPage setY:cropBox.GetY2 - height];
            }
            else {
                [endPointPage setY:[cropBox GetY2]];
                [startPointPage setY:[cropBox GetY2] - height];
            }
        }

        if ([startPointPage getX] > [cropBox GetX2] || [endPointPage getX] > [cropBox GetX2]) {
            if ([startPointPage getX] > [endPointPage getX]) {
                [startPointPage setX:[cropBox GetX2]];
                [endPointPage setX:[cropBox GetX2] - width];
            } else {
                [endPointPage setX:[cropBox GetX2]];
                [startPointPage setX:[cropBox GetX2] - width];
            }
        }
        
        if ([startPointPage getX] < [cropBox GetX1] || [endPointPage getX] < [cropBox GetX1]) {
            if ([startPointPage getX] < [endPointPage getX]) {
                [startPointPage setX:[cropBox GetX1]];
                [endPointPage setX:[cropBox GetX1] + width];
            }
            else {
                [endPointPage setX:[cropBox GetX1]];
                [startPointPage setX:[cropBox GetX1] + width];
            }
        }

        // Calculate the new annotation bounding box.
        double x1 = fmin([startPointPage getX], [endPointPage getX]);
        double y1 = fmin([startPointPage getY], [endPointPage getY]);
        double x2 = fmax([startPointPage getX], [endPointPage getX]);
        double y2 = fmax([startPointPage getY], [endPointPage getY]);
        
        PTPDFRect *newRect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
        [newRect Normalize];
        
        [self willModifyAnnotation:m_lineAnnot onPageNumber:self.annotationPageNumber];
        
        [m_lineAnnot Resize:newRect];
        [m_lineAnnot SetStartPoint:startPointPage];
        [m_lineAnnot SetEndPoint:endPointPage];
        
        [m_lineAnnot RefreshAppearance];
        
        self.annotRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:newRect PageNumber:self.annotationPageNumber];
        
        [self showSelectionMenu:self.annotRect];
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        
        [self.pdfViewCtrl Update];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
}

- (bool) moveSelectionRect: (CGPoint) down
{
    PTPDFPoint *basePoint, *endPoint;
    PTPDFRect *tightRect;
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
        m_lineAnnot = [[PTLineAnnot alloc] initWithAnn:self.currentAnnotation];
        
        basePoint = [m_lineAnnot GetStartPoint];
        endPoint = [m_lineAnnot GetEndPoint];
        tightRect = [[PTPDFRect alloc] initWithX1:[basePoint getX] y1:[basePoint getY] x2:[endPoint getX] y2:[endPoint getY]];
    
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    CGRect annotRect = [self PDFRectPage2CGRectScreen:tightRect PageNumber:self.annotationPageNumber];
    
    if( m_isDragging || fabs(annotRect.origin.x - (down.x + self.touchOffset.x)) - self.selectionRectContainerView.selectionRectView.rectOffset > 3 ||
       fabs(annotRect.origin.y - (down.y + self.touchOffset.y)) - self.selectionRectContainerView.selectionRectView.rectOffset > 3)
    {
        m_isDragging = YES;
        annotRect.origin.x = down.x + self.touchOffset.x;
        annotRect.origin.y = down.y + self.touchOffset.y;
        
        annotRect = [self boundRectToPage:annotRect isResizing:NO];
        
        [self.selectionRectContainerView setFrameFromAnnot:annotRect];
        
		
		[self.selectionRectContainerView showSelectionRect];
        
		
        [self hideMenu];
        
        return true;
    }
    else
        return false;
}



-(void)SetAnnotationRect:(PTAnnot*)annot Rect:(CGRect)rect OnPage:(int)pageNumber
{
	return;
}

-(BOOL)PointsAreEqualA:(CGPoint)a B:(CGPoint)b
{
    return sqrt((b.x-a.x)*(b.x-a.x) + (b.y-a.y)*(b.y-a.y)) < 0.01;
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    m_isDragging = NO;
	self.backgroundColor = [UIColor clearColor];
	m_resizing = NO;
	UITouch *touch = touches.allObjects[0];
    
    m_touchPoint = [touch locationInView:self.pdfViewCtrl];

    if ([self snappingEnabled]) {
        PTPDFPoint* snapPt = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:m_touchPoint.x py:m_touchPoint.y]];
        m_touchPoint = PTCGPointSnapToPoint(m_touchPoint, CGPointMake(snapPt.getX, snapPt.getY));
    }
    
    _touchStartPoint = m_touchPoint;

	PTPDFPoint* sp = [self.pdfViewCtrl ConvPagePtToScreenPt:[m_lineAnnot GetStartPoint] page_num:self.annotationPageNumber];
	
	PTPDFPoint* ep = [self.pdfViewCtrl ConvPagePtToScreenPt:[m_lineAnnot GetEndPoint] page_num:self.annotationPageNumber];

	if( pow((m_touchPoint.x-[sp getX]),2)+pow((m_touchPoint.y-[sp getY]),2) > pow((m_touchPoint.x-[ep getX]),2)+pow((m_touchPoint.y-[ep getY]),2)  )
	{
		movedEndPt = NO;
		m_ptToDrawTo = sp;
	}
	else
	{
		m_ptToDrawTo = ep;
		movedEndPt = YES;
	}
	
	
	return [super pdfViewCtrl:pdfViewCtrl onTouchesBegan:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
    m_touchPoint = [touch locationInView:self.pdfViewCtrl];
    
    if ([self snappingEnabled]) {
        PTPDFPoint* snapPt = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:m_touchPoint.x py:m_touchPoint.y]];
        m_touchPoint = PTCGPointSnapToPoint(m_touchPoint, CGPointMake(snapPt.getX, snapPt.getY));
    }
    
	[self setNeedsDisplay];
	
	return [super pdfViewCtrl:pdfViewCtrl onTouchesMoved:touches withEvent:event];
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
    _touchEndPoint = [touch locationInView:self.pdfViewCtrl];
    
    if ([self snappingEnabled]) {
        PTPDFPoint* snapPt = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:_touchEndPoint.x py:_touchEndPoint.y]];
        _touchEndPoint = PTCGPointSnapToPoint(_touchEndPoint, CGPointMake(snapPt.getX, snapPt.getY));
    }
    
    if( m_resizing )
    {
        
        PTPDFRect *oldAnnotRect = nil;
        
        @try {
            [self.pdfViewCtrl DocLock:YES];
            
            PTPDFRect *r = [m_lineAnnot GetRect];
            
            // Convert old annot page rect to screen space.
            PTPDFPoint *rectCorner1Page = [[PTPDFPoint alloc] initWithPx:[r GetX1] py:[r GetY1]];
            PTPDFPoint *rectCorner2Page = [[PTPDFPoint alloc] initWithPx:[r GetX2] py:[r GetY2]];
            
            PTPDFPoint *rectCorner1Screen = [self.pdfViewCtrl ConvPagePtToScreenPt:rectCorner1Page page_num:self.annotationPageNumber];
            PTPDFPoint *rectCorner2Screen = [self.pdfViewCtrl ConvPagePtToScreenPt:rectCorner2Page page_num:self.annotationPageNumber];
            oldAnnotRect = [[PTPDFRect alloc] initWithX1:[rectCorner1Screen getX] y1:[rectCorner1Screen getY] x2:[rectCorner2Screen getX] y2:[rectCorner2Screen getY]];
            
            // Get current start and end points.
            PTPDFPoint *oldStartPoint = [m_lineAnnot GetStartPoint];
            PTPDFPoint *oldEndPoint = [m_lineAnnot GetEndPoint];
            
            PTPDFPoint *newStartPoint = oldStartPoint;
            PTPDFPoint *newEndPoint = oldEndPoint;
            
            PTPDFPoint *touchPointScreen = [[PTPDFPoint alloc] initWithPx:m_touchPoint.x py:m_touchPoint.y];
            PTPDFPoint *touchPointPage = [self.pdfViewCtrl ConvScreenPtToPagePt:touchPointScreen page_num:self.annotationPageNumber];
            
            // Update the appropriate (start, end) point.
            if( !movedEndPt )
            {
                newEndPoint = touchPointPage;
            }
            else
            {
                newStartPoint = touchPointPage;
            }
            
            // Compute the new annotation rect.
            double x1 = MIN([newStartPoint getX], [newEndPoint getX]);
            double y1 = MIN([newStartPoint getY], [newEndPoint getY]);
            double x2 = MAX([newStartPoint getX], [newEndPoint getX]);
            double y2 = MAX([newStartPoint getY], [newEndPoint getY]);
            
            PTPDFRect *newAnnotRect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];
            [newAnnotRect Normalize];
            
            [self willModifyAnnotation:m_lineAnnot onPageNumber:self.annotationPageNumber];
            
            // Update the annotation rect.
            [m_lineAnnot Resize:newAnnotRect];
            
            // Set new start and end points.
            // NOTE: Must be done *after* resizing the annotation.
            [m_lineAnnot SetStartPoint:newStartPoint];
            [m_lineAnnot SetEndPoint:newEndPoint];
            
            [m_lineAnnot RefreshAppearance];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
        
        if (oldAnnotRect) {
            [self.pdfViewCtrl UpdateWithRect:oldAnnotRect];
        }
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        
        [self annotationModified:self.currentAnnotation onPageNumber:self.annotationPageNumber];
        
        self.backgroundColor = [UIColor clearColor];
        self.currentAnnotation = m_lineAnnot;
        self.selectionRectContainerView.hidden = NO;
    }
    
    [self selectCurrentAnnotation];
    
    m_resizing = NO;
    
    [self setNeedsDisplay];
    
    [self showSelectionMenu: self.annotRect];
    
    return [super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

-(void)noteEditController:(PTNoteEditController*)noteEditController cancelButtonPressed:(BOOL)showSelectionMenu
{
    [super noteEditController:noteEditController cancelButtonPressed:showSelectionMenu];

    [self showSelectionMenu:self.annotRect];
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
	if( [m_lineAnnot IsValid] && m_resizing && !self.allowScrolling)
	{
		
		CGContextRef currentContext = UIGraphicsGetCurrentContext();
		
		PTColorPt* strokePoint = [m_lineAnnot GetColorAsRGB];
		
		double r = [strokePoint Get:0];
		double g = [strokePoint Get:1];
		double b = [strokePoint Get:2];
		
		if( [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_invert )
		{
			r = 1.-r;
			g = 1.-g;
			b = 1.-b;
		}
		
		int strokeColorComps = [m_lineAnnot GetColorCompNum];
		
		UIColor* strokeColor = [UIColor colorWithRed:r green:g blue:b alpha:(strokeColorComps > 0 ? 1 : 0)];
		
		double thickness = [[m_lineAnnot GetBorderStyle] GetWidth];
		
		thickness *= [self.pdfViewCtrl GetZoom];
		
		CGContextSetLineWidth(currentContext, thickness);
		CGContextSetLineCap(currentContext, kCGLineCapButt);
		CGContextSetLineJoin(currentContext, kCGLineJoinMiter);
        CGContextSetStrokeColorWithColor(currentContext, strokeColor.CGColor);
        CGContextSetAlpha(currentContext, [m_lineAnnot GetOpacity]);
        	
		CGContextBeginPath (currentContext);
		
		CGContextMoveToPoint(currentContext, m_touchPoint.x, m_touchPoint.y);
		CGContextAddLineToPoint(currentContext, [m_ptToDrawTo getX], [m_ptToDrawTo getY]);
		
		CGContextStrokePath(currentContext);
		
	}
}

#pragma mark - Convenience

- (BOOL)snappingEnabled
{
    return ( self.toolManager.snapToDocumentGeometry &&
            self.currentAnnotation.extendedAnnotType == PTExtendedAnnotTypeRuler );
}

@end
