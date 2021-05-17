//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFreeHandCreate.h"

#import "PTPanTool.h"
#import "PTColorDefaults.h"
#import "PTTimer.h"
#import "PTToolsUtil.h"
#import "PTAnnotEditTool.h"
#import "PTTextMarkupEditTool.h"

#import "PTKeyValueObserving.h"

static const NSTimeInterval PTFreeHandCreateStylusAppendInterval = 2.0; // seconds
static const CGFloat PTFreeHandCreateStylusAppendDistance = 200; // points in page space

@interface PTFreeHandCreate ()
{
	int m_startPageNum;
    NSMutableArray* m_redo_strokes;
    NSMutableArray<NSMutableArray*>* m_free_hand_strokes;
    NSMutableArray* m_free_hand_points;
    
    NSMutableArray* m_page_space_redo_strokes;
    NSMutableArray* m_page_space_free_hand_strokes;
    NSMutableArray* m_page_space_free_hand_points;
    
    PTTimer *stylusAppendTimeout;
}

@property (nonatomic, readwrite, assign) int pageNumber;

@property (nonatomic, assign) int pendingStrokes;

@property (nonatomic, assign) BOOL isPencilTouch;

@property (nonatomic, assign) BOOL commitAnnotationOnToolChange;

@end

@implementation PTFreeHandCreate

@dynamic multistrokeMode;
@synthesize pencilMode;
@dynamic isPencilTouch;


-(BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
	// ignore
	return YES;
}

static CGPoint midPoint(CGPoint p1, CGPoint p2)
{
	
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
	
}


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {

        self.opaque = NO;
        
		m_startPageNum = 0; // non-existant page in PDF
        
        _pendingStrokes = 0;
        
        self.multistrokeMode = NO;
        
        self.isPencilTouch = YES;
        
        _commitAnnotationOnToolChange = YES;

        self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
    }

    return self;
}

- (void)dealloc
{
    [self pt_removeAllObservations];
}

-(Class)annotClass
{
    return [PTInk class];
}

+(PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeInk;
}

+ (BOOL)canEditStyle
{
    return YES;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        PTExtendedAnnotName annotName = PTExtendedAnnotNameFromType(self.annotType);
        
        // Observe changes to the stroke color, thickness, and opacity attributes.
        NSArray<NSString *> *attributes = @[
            ATTRIBUTE_STROKE_COLOR,
            ATTRIBUTE_BORDER_THICKNESS,
            ATTRIBUTE_OPACITY,
        ];
        
        for (NSString *attribute in attributes) {
            // User defaults keys are of the form "<annot-name><attribute>".
            NSString *key = [annotName stringByAppendingString:attribute];
            
            // Observe changes to the specified user defaults key.
            [self pt_observeObject:NSUserDefaults.standardUserDefaults
                        forKeyPath:key
                          selector:@selector(userDefaultsChanged)];
        }
    } else {
        // Remove all user defaults observers.
        for (PTKeyValueObservation *observation in self.pt_observations) {
            [observation invalidate];
        }
    }
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == nil && self.commitAnnotationOnToolChange) {
        [self commitAnnotation];
    }
    else if (newSuperview != nil)
    {
        [self reset];
    }
    [super willMoveToSuperview:newSuperview];
}

- (void)userDefaultsChanged
{
    [self setNeedsDisplay];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    [super pdfViewCtrl:pdfViewCtrl pageNumberChangedFrom:oldPageNumber To:newPageNumber];
    
    [self restorePointsInScreenSpace];
    
    [self commitAnnotation];
    [self reset];
    
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
    
    BOOL ret = [super pdfViewCtrl:pdfViewCtrl touchesShouldCancelInContentView:view];
    if( ret == YES )
    {
        while( m_free_hand_strokes.count > self.pendingStrokes )
        {
            [m_free_hand_strokes removeLastObject];
        }
    }
    
    return ret;
    
//    if( self.multistrokeMode == YES )
//		return NO;
//	else
//		return [super pdfViewCtrl:pdfViewCtrl touchesShouldCancelInContentView:view];
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self commitAnnotation];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl pdfScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self commitAnnotation];
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self reset];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self reset];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self reset];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self reset];
}

-(void)reset
{
    m_startPageNum = 0;
    
    m_redo_strokes = Nil;;
    m_free_hand_strokes = Nil;;
    m_free_hand_points = Nil;;
    
    m_page_space_redo_strokes = Nil;;
    m_page_space_free_hand_strokes = Nil;;
    m_page_space_free_hand_points = Nil;;
        
    self.pendingStrokes = 0;
        
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
    
    self.hidden = NO;
}


+(BOOL)createsAnnotation
{
	return YES;
}

- (void)drawRect:(CGRect)rect
{
    if( (m_free_hand_points.count > 1 || m_free_hand_strokes.count > 0) && (self.multistrokeMode == YES || !self.allowScrolling))
    {
        CGPoint previousPoint1 = CGPointZero;
        CGPoint previousPoint2 = CGPointZero;
        CGPoint currentPoint;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
		if( ! context )
			return;
		
        [super setupContext:context];
        
        CGContextSetLineJoin(context, kCGLineJoinRound);
        
		for (NSArray<NSValue*>* point_array in m_free_hand_strokes)
		{
            previousPoint1 = CGPointZero;
            previousPoint2 = CGPointZero;
            
            CGContextBeginPath(context);
			
			for (NSValue* val in point_array)
			{
				currentPoint = val.CGPointValue;
				
				if( CGPointEqualToPoint(previousPoint1, CGPointZero))
					previousPoint1 = currentPoint;
				
				if( CGPointEqualToPoint(previousPoint2, CGPointZero))
					previousPoint2 = currentPoint;
				
				CGPoint mid1 = midPoint(previousPoint1, previousPoint2);
				CGPoint	mid2 = midPoint(currentPoint, previousPoint1);
				
				CGContextMoveToPoint(context, mid1.x, mid1.y);
				
				CGContextAddQuadCurveToPoint(context, previousPoint1.x, previousPoint1.y, mid2.x, mid2.y);
			
				previousPoint2 = previousPoint1;
				previousPoint1 = currentPoint;
			}
            
            CGContextStrokePath(context);
		}
    }
}

-(void)addFreehandPoint:(NSSet*)touches
{
    UITouch *touch = touches.allObjects[0];
    
    CGPoint touchPoint = [touch preciseLocationInView:self.pdfViewCtrl];
    
    self.endPoint = [super boundToPageScreenPoint:touchPoint withThicknessCorrection:_thickness/2];
    
    [m_free_hand_points addObject:[NSValue valueWithCGPoint:self.endPoint]];
    
    CGPoint pagePoint = [self convertScreenPtToPagePt:self.endPoint onPageNumber:self.pageNumber];
    [m_page_space_free_hand_points addObject:[NSValue valueWithCGPoint:pagePoint]];
    
    CGPoint lastDrawPoint = [[m_free_hand_points objectAtIndex:MAX(0,(int)[m_free_hand_points count]-3)] CGPointValue];

    [self setNeedsDisplayInRect:CGRectMake(MIN(self.endPoint.x,lastDrawPoint.x)-10-_thickness, MIN(self.endPoint.y,lastDrawPoint.y)-10-_thickness, ABS(self.endPoint.x-lastDrawPoint.x)+20+_thickness*2, ABS(self.endPoint.y-lastDrawPoint.y)+20+_thickness*2)];
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
    
    UITouch *touch = touches.allObjects[0];

    self.startPoint = [touch preciseLocationInView:self.pdfViewCtrl];
    CGPoint pageStartPoint = [self convertScreenPtToPagePt:self.startPoint onPageNumber:self.pageNumber];

    const int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x
                                                                     y:self.startPoint.y];
    
    if (pageNumber < 1 || (m_startPageNum > 0 && m_startPageNum != pageNumber))
    {
        [self commitAnnotation];
    }
    
    PTPDFRect *radiusRect = [self rectFromPoints];
    [radiusRect SetX1:radiusRect.GetX1 - PTFreeHandCreateStylusAppendDistance];
    [radiusRect SetX2:radiusRect.GetX2 + PTFreeHandCreateStylusAppendDistance];
    [radiusRect SetY1:radiusRect.GetY1 - PTFreeHandCreateStylusAppendDistance];
    [radiusRect SetY2:radiusRect.GetY2 + PTFreeHandCreateStylusAppendDistance];

    // If the touch point is within 200 page-points of the current rect, append to the drawing
    BOOL continueAnnotation = pageStartPoint.x > radiusRect.GetX1 && pageStartPoint.x < radiusRect.GetX2 && pageStartPoint.y > radiusRect.GetY1 && pageStartPoint.y < radiusRect.GetY2;

    if (touch.type == UITouchTypePencil && self.backToPanToolAfterUse) {
        pencilMode = YES;
        self.multistrokeMode = YES;
        [stylusAppendTimeout invalidate];
    }

    if (pencilMode && m_free_hand_points.count > 0) { // In pencil mode
        if (touch.type != UITouchTypePencil) {
            [self endDrawing];
            return YES;
        } else if (!continueAnnotation) {
            [self commitAnnotation];
            return NO;
        }
    }
    
    
    NSAssert(pageNumber > 0,
             @"Page number %d is invalid", pageNumber);

    self.pageNumber = pageNumber;
    m_startPageNum = pageNumber;
    
    CGPoint pagePoint = CGPointMake(self.startPoint.x, self.startPoint.y);
    
    if( self.toolManager.annotationsCreatedWithPencilOnly == NO || self.isPencilTouch == YES)
    {
        m_free_hand_points = [[NSMutableArray alloc] initWithCapacity:50];
        
        [m_free_hand_points addObject:[NSValue valueWithCGPoint:pagePoint]];

        if( !m_free_hand_strokes )
        {
            m_startPageNum = self.pageNumber;
            
            m_free_hand_strokes = [[NSMutableArray alloc] init];
            
            m_redo_strokes = [[NSMutableArray alloc] init];
            
            self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.bounds.size.width, self.pdfViewCtrl.bounds.size.height);
        }
        
        if( !m_page_space_redo_strokes )
        {
            m_page_space_redo_strokes = [[NSMutableArray alloc] init];
        }
        NSAssert(m_free_hand_strokes, @"can't be nil");
        NSAssert(m_free_hand_points, @"can't be nil");
        [m_free_hand_strokes addObject:m_free_hand_points];
        
        if( !m_page_space_free_hand_strokes )
            m_page_space_free_hand_strokes = [[NSMutableArray alloc] init];
        
        if( !m_page_space_free_hand_points )
            m_page_space_free_hand_points = [[NSMutableArray alloc] init];
        
        [m_page_space_free_hand_strokes addObject:m_page_space_free_hand_points];
    }
    else
    {
        [self commitAnnotation];
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
	if (self.pageNumber < 1 || m_startPageNum != self.pageNumber) {
        return YES;
    }
    
    if( self.isPencilTouch == YES || self.toolManager.annotationsCreatedWithPencilOnly == NO )
    {
    
        [self addFreehandPoint:touches];
        
    }
    
    return YES;
}

-(void)saveRedoStrokesInPageSpace
{

    m_page_space_free_hand_points = [[NSMutableArray alloc] init];

    NSArray<NSValue*>* point_array = m_redo_strokes.lastObject;

    for (NSValue* val in point_array)
    {
        CGPoint screenPoint = val.CGPointValue;
        CGPoint pagePoint = [self convertScreenPtToPagePt:screenPoint onPageNumber:self.pageNumber];
        [m_page_space_free_hand_points addObject:[NSValue valueWithCGPoint:pagePoint]];
    }
    
    [m_page_space_redo_strokes addObject:m_page_space_free_hand_points];
    
    m_page_space_free_hand_points = [[NSMutableArray alloc] init];
    
}

-(void)restorePointsInScreenSpace
{
    [m_free_hand_points removeAllObjects];
    [m_free_hand_strokes removeAllObjects];
    
    for (NSArray<NSValue*>* point_array in m_page_space_free_hand_strokes)
    {
        for (NSValue* val in point_array)
        {
            CGPoint pagePoint = val.CGPointValue;
            CGPoint screenPoint = [self convertPagePtToScreenPt:pagePoint onPageNumber:self.pageNumber];
            [m_free_hand_points addObject:[NSValue valueWithCGPoint:screenPoint]];
        }
        
        NSAssert(m_free_hand_strokes, @"can't be nil");
        NSAssert(m_free_hand_points, @"can't be nil");
        [m_free_hand_strokes addObject:m_free_hand_points];
        
        m_free_hand_points = [[NSMutableArray alloc] init];
    }
    
    [m_redo_strokes removeAllObjects];
    
    NSMutableArray* redoPointArray = [[NSMutableArray alloc] init];
    for (NSArray<NSValue*>* point_array in m_page_space_redo_strokes)
    {
        for (NSValue* val in point_array)
        {
            CGPoint pagePoint = val.CGPointValue;
            CGPoint screenPoint = [self convertPagePtToScreenPt:pagePoint onPageNumber:self.pageNumber];
            [redoPointArray addObject:[NSValue valueWithCGPoint:screenPoint]];
        }
        
        [m_redo_strokes addObject:redoPointArray];
        
        redoPointArray = [[NSMutableArray alloc] init];
    }
}

-(BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    return [super pdfViewCtrl:pdfViewCtrl onTouchesCancelled:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    self.pendingStrokes++;
    
    if (pencilMode) {
        [stylusAppendTimeout invalidate];
        stylusAppendTimeout = [PTTimer scheduledTimerWithTimeInterval:PTFreeHandCreateStylusAppendInterval target:self selector:@selector(endDrawing) userInfo:nil repeats:NO];
    }
	if (self.pageNumber < 1 || m_startPageNum != self.pageNumber) {
        return YES;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly == NO || self.isPencilTouch == YES)
    {
        if( m_free_hand_points.count == 1)
        {
            [self addFreehandPoint:touches];
        }
    }
    
    [self saveRedoStrokesInPageSpace];
    
	if( self.multistrokeMode == NO && pencilMode == NO)
	{
		[self commitAnnotation];
		
		if (self.backToPanToolAfterUse) {
			self.nextToolType = [PTPanTool class];
            return NO;
        } else {
            return YES;
        }
        
        
	}
	else
	{
		[m_redo_strokes removeAllObjects];
        [m_page_space_redo_strokes removeAllObjects];
		
		if( [self.delegate respondsToSelector:@selector(strokeAdded:)] )
		{
			[self.delegate strokeAdded:self];
		}
        
        if ([self isUndoManagerEnabled]) {
            // Undo support.
            [self.undoManager registerUndoWithTarget:self handler:^(PTFreeHandCreate *target) {
                [target undoStroke];
            }];
            if (![self.undoManager isUndoing]) {
                [self.undoManager setActionName:PTLocalizedString(@"Add stroke",
                                                                  @"Undo/redo action for multi-stroke inks")];
            }
        }

		return YES;
	}
}

-(PTPDFRect *)rectFromPoints
{
    PTPDFRect* myRect = [[PTPDFRect alloc] init];

    double minX = RAND_MAX, minY = RAND_MAX, maxX = -RAND_MAX, maxY = -RAND_MAX;

    int numStrokes = 0;

    for (NSMutableArray* point_array in m_free_hand_strokes)
    {

        for (NSValue* point in point_array)
        {
            CGPoint aPoint = point.CGPointValue;

            PTPDFPoint* pdfPoint = [[PTPDFPoint alloc] init];

            [self ConvertScreenPtToPagePtX:&aPoint.x Y:&aPoint.y PageNumber:m_startPageNum];

            [pdfPoint setX:aPoint.x];
            [pdfPoint setY:aPoint.y];

            minX = MIN(minX, aPoint.x);
            minY = MIN(minY, aPoint.y);

            maxX = MAX(maxX, aPoint.x);
            maxY = MAX(maxY, aPoint.y);
        }
        numStrokes++;
    }

    [myRect SetX1:minX];
    [myRect SetY1:minY];

    [myRect SetX2:maxX];
    [myRect SetY2:maxY];

    return myRect;
}

-(void)endDrawing
{
    [self commitAnnotation];

    if (self.backToPanToolAfterUse) {
        pencilMode = NO;
        self.multistrokeMode = NO;
        [self.toolManager changeTool:[PTPanTool class]];
    }
}

-(BOOL)inkPointPresentAtScreenPoint:(CGPoint)screenPoint within:(CGFloat)threshold
{
    for (NSMutableArray* point_array in m_free_hand_strokes)
    {

        for (NSValue* inkPointValue in point_array)
        {
            CGPoint inkPoint = inkPointValue.CGPointValue;
            
            CGFloat distance = sqrt(pow(screenPoint.x-inkPoint.x,2)+pow(screenPoint.y-inkPoint.y,2));
            if( distance <= threshold )
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (PTInk *)createAnnotation
{
    PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
    PTInk *annot = [PTInk Create:(PTSDFDoc*)doc pos:[[PTPDFRect alloc] init]];

    [super setPropertiesFromAnnotation:annot];

    return annot;
}

- (void)cancelEditingAnnotation
{
    self.commitAnnotationOnToolChange = NO;
}

-(void)commitAnnotation
{
    self.commitAnnotationOnToolChange = NO;
    if (m_free_hand_strokes.count < 1) {
        return;
    }

	if( self.pageNumber > 0 )
	{
        


        
		[self keepToolAppearanceOnScreen];

        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];

		PTInk* inkAnnot;
		
		@try
		{
			[self.pdfViewCtrl DocLock:YES];
			
			PTPage* pg = [doc GetPage:m_startPageNum];
			
			if( [pg IsValid] )
			{
				
				PTPDFRect* myRect = [[PTPDFRect alloc] init];
				
				inkAnnot = [self createAnnotation];
				
				int i = 0;
				
				double minX = RAND_MAX, minY = RAND_MAX, maxX = -RAND_MAX, maxY = -RAND_MAX;
				
				int numStrokes = 0;
				
				for (NSMutableArray* point_array in m_free_hand_strokes)
				{

					for (NSValue* point in point_array)
					{
						CGPoint aPoint = point.CGPointValue;
						
						PTPDFPoint* pdfPoint = [[PTPDFPoint alloc] init];
						
						[self ConvertScreenPtToPagePtX:&aPoint.x Y:&aPoint.y PageNumber:m_startPageNum];
						
						[pdfPoint setX:aPoint.x];
						[pdfPoint setY:aPoint.y];
						
						[inkAnnot SetPoint:numStrokes pointindex:i++ pt:pdfPoint];
						
						minX = MIN(minX, aPoint.x);
						minY = MIN(minY, aPoint.y);

						maxX = MAX(maxX, aPoint.x);
						maxY = MAX(maxY, aPoint.y);
					}
					numStrokes++;
					i = 0;
				}

				[myRect SetX1:minX];
				[myRect SetY1:minY];
				
				[myRect SetX2:maxX];
				[myRect SetY2:maxY];
				
				[inkAnnot SetRect:myRect];
				
				[inkAnnot RefreshAppearance];
				
				if( self.annotationAuthor && self.annotationAuthor.length > 0 && [inkAnnot isKindOfClass:[PTMarkup class]]	)
				{
					[(PTMarkup*)inkAnnot SetTitle:self.annotationAuthor];
				}
			
				[pg AnnotPushBack:inkAnnot];
			}
			
		}
		@catch (NSException *exception) {
			//NSLog(@"Exception: %@: %@",exception.name, exception.reason);
		}
		@finally {
			[self.pdfViewCtrl DocUnlock];
		}
		
		m_free_hand_points = 0;
        
		
		[self.pdfViewCtrl UpdateWithAnnot:inkAnnot page_num:m_startPageNum];
		[self.pdfViewCtrl RequestRendering];
		
		[self annotationAdded:inkAnnot onPageNumber:self.pageNumber];
		
	}
	
    [m_page_space_free_hand_strokes removeAllObjects];
	[m_free_hand_strokes removeAllObjects];
	[m_redo_strokes removeAllObjects];
	[m_free_hand_points removeAllObjects];
    
    // Clear local undo/redo stack for the now-committed annotation.
    if ([self isUndoManagerEnabled]) {
        [self.undoManager removeAllActions];
    }
    
	[self setNeedsDisplay];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
    
    BOOL annotHere = NO;
    
    // is there an annot here we might be trying to select?
    
    PTTool* editTool = [[PTPanTool alloc] initWithPDFViewCtrl:self.pdfViewCtrl];
    editTool.toolManager = self.toolManager;
    while (![editTool pdfViewCtrl:pdfViewCtrl handleTap:sender]) {
        editTool = (PTTool *)[editTool getNewTool];
    }
    
    if([editTool isKindOfClass:[PTAnnotEditTool class]] || [editTool isKindOfClass:[PTTextMarkupEditTool class]])
    {
        editTool.currentAnnotation = Nil;
        annotHere = YES;
    }

    if( annotHere == NO || m_free_hand_strokes.lastObject.count > 9 )
    {
        // carry on because it's an intentional draw or a dot
        
        return YES;
    }
    else
    {
        // get rid of the likely suprious ink stroke
        [m_free_hand_strokes removeLastObject];

        // save the ink stroke if there is one
        [self commitAnnotation];
        
        // select the annot that was tapped
        self.nextToolType = [editTool class];
        self.defaultClass = [self class];
        return NO;
    }

	return YES;
}

-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
    
    [self restorePointsInScreenSpace];
    
    if( !self.multistrokeMode )
    {
        [self commitAnnotation];
    }

    self.hidden = NO;
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);

    [self setNeedsDisplay];

}

@synthesize requiresEditSupport = _requiresEditSupport;

- (BOOL)isUndoManagerEnabled
{
    // Only require undo manager for multi-stroke mode.
    return self.multistrokeMode;
}

#pragma mark - multistroke undo/redo methods

-(void)undoStroke
{
	if( m_free_hand_strokes.count )
	{
		[m_redo_strokes addObject:m_free_hand_strokes.lastObject];
        [m_page_space_redo_strokes addObject:m_page_space_free_hand_strokes.lastObject];
		[m_free_hand_strokes removeLastObject];
        [m_page_space_free_hand_strokes removeLastObject];
		[self setNeedsDisplay];
	}
    
    if ([self isUndoManagerEnabled]) {
        // Undo support.
        [self.undoManager registerUndoWithTarget:self handler:^(PTFreeHandCreate *target) {
            [target redoStroke];
        }];
        if (![self.undoManager isUndoing]) {
            [self.undoManager setActionName:PTLocalizedString(@"Remove stroke",
                                                              @"Undo/redo action for removing ink stroke")];
        }
    }
}

-(void)redoStroke
{
	if( m_redo_strokes.count )
	{
        NSAssert(m_free_hand_strokes, @"can't be nil");
        NSAssert(m_redo_strokes, @"can't be nil");
		[m_free_hand_strokes addObject:m_redo_strokes.lastObject];
        [m_page_space_free_hand_strokes addObject:m_page_space_redo_strokes.lastObject];
		[m_redo_strokes removeLastObject];
        [m_page_space_redo_strokes removeLastObject];
		[self setNeedsDisplay];
	}
    
    if ([self isUndoManagerEnabled]) {
        // Undo support.
        [self.undoManager registerUndoWithTarget:self handler:^(PTFreeHandCreate *target) {
            [target undoStroke];
        }];
        if (![self.undoManager isUndoing]) {
            [self.undoManager setActionName:PTLocalizedString(@"Add stroke",
                                                              @"Undo/redo action for adding ink stroke")];
        }
    }
}

-(BOOL)canUndoStroke
{
	return m_free_hand_strokes.count > 0 ? YES : NO;
}

-(BOOL)canRedoStroke
{
	return m_redo_strokes.count > 0 ? YES : NO;
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    if( userData && [userData isEqual:@"Back to creation tool"] )
    {
        return YES;
    }
    else if (pencilMode && m_free_hand_points.count > 0) {
        [self endDrawing];
    }
    return YES;
}

#pragma mark - Page number

// Synthesized by subclass.
@dynamic pageNumber;

// Manually implement property accessor.
- (void)setPageNumber:(int)pageNumber
{
    _pageNumber = pageNumber;
}

@end
