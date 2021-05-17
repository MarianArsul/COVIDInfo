//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTEraser.h"

#import "PTPanTool.h"
#import "PTToolsUtil.h"

@interface PTAnnotCompare : NSObject

@property (nonatomic, strong) PTAnnot* annot;

@end

@implementation PTAnnotCompare

+(id)annot:(PTAnnot*)annot
{
    PTAnnotCompare* newAnnot = [[PTAnnotCompare alloc] init];
    
    newAnnot.annot = annot;
    
    return newAnnot;
}

- (BOOL)isEqual:(id)object
{
    if( ![object isKindOfClass:[PTAnnotCompare class]] )
    {
        return NO;
    }
    
    return [self.annot isEqualTo:((PTAnnotCompare*)object).annot];
}

-(NSUInteger)hash
{
    return 1;
}

@end

@interface PTEraser ()
{
	int m_startPageNum;
    NSMutableArray* m_free_hand_points;
    double m_eraser_half_width;
    CGPoint m_current_point;
    CGPoint m_prev_point;
    NSMutableArray* m_ink_list;
    UIColor* _strokeColor;
    UIColor* _fillColor;
    double _opacity;
}

@property (nonatomic, strong) NSMutableSet* annotsToErase;

@end

@implementation PTEraser

-(void)ignorePinch:(UIGestureRecognizer *)gestureRecognizer
{
    return;
}

-(CGPoint) midPoint:(CGPoint)p1 p2:(CGPoint)p2
{
	
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
	
}

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {

        self.opaque = NO;
        
		m_startPageNum = 0; // non-existant page in PDF
        
        m_eraser_half_width = 10.0/[in_pdfViewCtrl GetZoom];
		
		UIPinchGestureRecognizer* pgr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(ignorePinch:)];
		
        [self addGestureRecognizer:pgr];
        
        self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
        
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        
        _annotsToErase = [[NSMutableSet alloc] init];
        
    }
    
    return self;
}

-(Class)annotClass
{
    return [PTInk class];
}

+(PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeInk;
}

+ (UIImage *)image
{
    return [PTToolsUtil toolImageNamed:@"Tool/Eraser/Icon"];
}

+ (NSString *)localizedName
{
    return PTLocalizedString(@"Eraser",
                             @"Eraser tool name");
}

- (void)drawRect:(CGRect)rect
{
    if( m_free_hand_points.count > 1 )
    {
        NSValue* val;
        CGPoint previousPoint1 = CGPointZero, previousPoint2 = CGPointZero, currentPoint;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
		if( ! context )
			return;
		
        [self setupContext:context];
        
        CGContextSetLineJoin(context, kCGLineJoinRound);
        
        CGPoint firstPoint = val.CGPointValue;
        CGContextMoveToPoint(context, firstPoint.x, firstPoint.y);
        previousPoint1 = CGPointZero;
        previousPoint2 = CGPointZero;
        
        for (NSValue* val in m_free_hand_points)
        {
            currentPoint = val.CGPointValue;
            
            if( CGPointEqualToPoint(previousPoint1, CGPointZero))
                previousPoint1 = currentPoint;
            
            if( CGPointEqualToPoint(previousPoint2, CGPointZero))
                previousPoint2 = currentPoint;
            
            CGPoint mid1 = [self midPoint:previousPoint1 p2:previousPoint2];
            CGPoint	mid2 = [self midPoint:currentPoint p2:previousPoint1];
            
            CGContextMoveToPoint(context, mid1.x, mid1.y);
            
            CGContextAddQuadCurveToPoint(context, previousPoint1.x, previousPoint1.y, mid2.x, mid2.y);
            
            previousPoint2 = previousPoint1;
            previousPoint1 = currentPoint;
        }
        
        CGContextStrokePath(context);
    }
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
    self.startPoint = [touch locationInView:self.pdfViewCtrl];
    
    _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x y:self.startPoint.y];
    
    if (self.pageNumber < 1) {
        return YES;
    }
    if (touch.type != UITouchTypePencil && self.acceptPencilTouchesOnly) {
        return NO;
    }
    
    CGPoint pagePoint = CGPointMake(self.startPoint.x, self.startPoint.y);
    
	
	m_free_hand_points = [[NSMutableArray alloc] initWithCapacity:50];
	
	[m_free_hand_points addObject:[NSValue valueWithCGPoint:pagePoint]];
    
    m_current_point = CGPointMake(pagePoint.x, pagePoint.y);
    m_prev_point = CGPointMake(pagePoint.x, pagePoint.y);

    m_startPageNum = self.pageNumber;
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.bounds.size.width, self.pdfViewCtrl.bounds.size.height);
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    CGPoint aPoint = [touch locationInView:self.pdfViewCtrl];
    _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:aPoint.x y:aPoint.y];
    
	if (self.pageNumber < 1 || m_startPageNum != self.pageNumber) {
        return YES;
    }
    
    CGPoint pagePoint = CGPointMake(aPoint.x, aPoint.y);
    
    [m_free_hand_points addObject:[NSValue valueWithCGPoint:pagePoint]];
    m_current_point.x = pagePoint.x;
    m_current_point.y = pagePoint.y;
    CGPoint _current = CGPointMake(m_current_point.x, m_current_point.y);
    CGPoint _prev = CGPointMake(m_prev_point.x, m_prev_point.y);
    
    NSArray<PTAnnot*>* annots = [self.pdfViewCtrl GetAnnotationListAt:m_current_point.x y1:m_current_point.y x2:m_prev_point.x y2:m_prev_point.y];
    
    for(PTAnnot* anAnnot in annots)
    {
        if ([anAnnot IsValid] && anAnnot.extendedAnnotType == PTExtendedAnnotTypeInk) {
            continue;
        }
        
        PTAnnotCompare* wrappedAnnot = [PTAnnotCompare annot:anAnnot];
        [self.annotsToErase addObject:wrappedAnnot];
    }
    
    [self setNeedsDisplay];
    
    // Erase
    PTPDFPoint* pdfPoint1 = [[PTPDFPoint alloc] init];
    PTPDFPoint* pdfPoint2 = [[PTPDFPoint alloc] init];
    
    [self ConvertScreenPtToPagePtX:&_prev.x Y:&_prev.y PageNumber:m_startPageNum];
    [self ConvertScreenPtToPagePtX:&_current.x Y:&_current.y PageNumber:m_startPageNum];
    
    [pdfPoint1 setX:_prev.x];
    [pdfPoint1 setY:_prev.y];
    [pdfPoint2 setX:_current.x];
    [pdfPoint2 setY:_current.y];
    
    @try {
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        [self.pdfViewCtrl DocLock:YES];
        PTPage* pg = [doc GetPage:m_startPageNum];
        if( [pg IsValid] )
        {
            int annot_num = [pg GetNumAnnots];
            for(int i=annot_num-1;i>=0;--i){
                PTAnnot *annot = [pg GetAnnot:i];
                if (![annot IsValid]) {
                    continue;
                };
                // Erase points in freehand ink annotations.
                if (annot.extendedAnnotType == PTExtendedAnnotTypeInk) {
                    PTInk *ink = [[PTInk alloc] initWithAnn:annot];
                    
                    if ([ink Erase:pdfPoint1 pt2:pdfPoint2 width:m_eraser_half_width]) {
                        if (!m_ink_list) {
                            m_ink_list = [[NSMutableArray alloc] initWithCapacity:10];
                        }
                        if ([self canAddObjectToInkList:ink]) {
                            [m_ink_list addObject:ink];
                        }
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
        m_prev_point.x = m_current_point.x;
        m_prev_point.y = m_current_point.y;
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (m_free_hand_points.count == 1) {
        // Erase
        CGPoint _prev = CGPointMake(m_prev_point.x, m_prev_point.y);
        PTPDFPoint* pdfPoint1 = [[PTPDFPoint alloc] init];
        
        [self ConvertScreenPtToPagePtX:&_prev.x Y:&_prev.y PageNumber:m_startPageNum];
        
        [pdfPoint1 setX:_prev.x];
        [pdfPoint1 setY:_prev.y];
        
        @try {
            PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
            [self.pdfViewCtrl DocLock:YES];
            PTPage* pg = [doc GetPage:m_startPageNum];
            if( [pg IsValid] )
            {
                int annot_num = [pg GetNumAnnots];
                for(int i=annot_num-1;i>=0;--i){
                    PTAnnot *annot = [pg GetAnnot:i];
                    if (![annot IsValid]) continue;
                    if([annot GetType] == e_ptInk) {
                        PTInk *ink = [[PTInk alloc]initWithAnn:annot];
                        
                        if ([ink Erase:pdfPoint1 pt2:pdfPoint1 width:m_eraser_half_width]) {
                            if (!m_ink_list) {
                                m_ink_list = [[NSMutableArray alloc] initWithCapacity:10];
                            }
                            if ([self canAddObjectToInkList:ink]) {
                                [m_ink_list addObject:ink];
                            }
                        }
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
        }
        @finally {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    
    [self commitAnnotation];
    
    if( self.backToPanToolAfterUse )
    {
        self.nextToolType = [PTPanTool class];
        return NO;
    }
    else
        return YES;
}

-(void)commitAnnotation
{
    if( m_startPageNum > 0 )
	{
        if (m_ink_list.count > 0) {
            [self keepToolAppearanceOnScreen];
        }
		
		PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
		
		@try
		{
			[self.pdfViewCtrl DocLock:YES];
            
            PTPage* pg = [doc GetPage:m_startPageNum];
            
            for(PTAnnotCompare* compareAnnot in self.annotsToErase)
            {
                PTAnnot* annotToErease = compareAnnot.annot;
                
                if ([pg IsValid] && [annotToErease IsValid]) {
                    [self willRemoveAnnotation:annotToErease onPageNumber:self.pageNumber];
                    
                    [pg AnnotRemoveWithAnnot:annotToErease];
                    [self annotationRemoved:annotToErease onPageNumber:m_startPageNum];
                    [self.pdfViewCtrl UpdateWithAnnot:annotToErease page_num:m_startPageNum];
                }
            }
            
            [self.annotsToErase removeAllObjects];
						
			if( [pg IsValid] )
			{
				for (PTInk* ink in m_ink_list) {
                    PTPDFRect* myRec = [ink GetRect];
                    [self willModifyAnnotation:ink onPageNumber:self.pageNumber];
                    
                    if ([ink GetPathCount] == 0) {
                        [self willRemoveAnnotation:ink onPageNumber:m_startPageNum];
                        [pg AnnotRemoveWithAnnot:ink];
						[self annotationRemoved:ink onPageNumber:m_startPageNum];
                    } else {
                        [ink RefreshAppearance];
						[self annotationModified:ink onPageNumber:m_startPageNum];
                    }
                    
                    CGPoint screenPt1 = CGPointMake([myRec GetX1], [myRec GetY1]);
                    CGPoint screenPt2 = CGPointMake([myRec GetX2], [myRec GetY2]);
                    
                    [self ConvertPagePtToScreenPtX:&screenPt1.x Y:&screenPt1.y PageNumber:m_startPageNum];
                    [self ConvertPagePtToScreenPtX:&screenPt2.x Y:&screenPt2.y PageNumber:m_startPageNum];
                    
                    PTPDFRect *screenRec = [[PTPDFRect alloc]init];
                    [screenRec SetX1:screenPt1.x];
                    [screenRec SetY1:screenPt1.y];
                    [screenRec SetX2:screenPt2.x];
                    [screenRec SetY2:screenPt2.y];
                    
                    [self.pdfViewCtrl UpdateWithRect:screenRec];
                }
            }
		}
		@catch (NSException *exception) {
            NSLog(@"Exception: %@: %@",exception.name, exception.reason);
		}
		@finally {
			[self.pdfViewCtrl DocUnlock];
		}
		
		m_free_hand_points = 0;
		[self.pdfViewCtrl RequestRendering];
	}
	
	[m_free_hand_points removeAllObjects];
    [m_ink_list removeAllObjects];
	[self setNeedsDisplay];
	
}

-(double)setupContext:(CGContextRef)currentContext
{
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    PTPage* pg = [doc GetPage:self.pageNumber];
    
    PTPDFRect* pageRect = [pg GetCropBox];
    
    CGRect cropBox = [self PDFRectPage2CGRectScreen:pageRect PageNumber:self.pageNumber];
    
	if( currentContext )
		CGContextClipToRect(currentContext, cropBox);
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
		if(! _strokeColor )
        {
            _strokeColor = [UIColor lightGrayColor];
            
            _opacity = 0.5;
        }
            
        _thickness = m_eraser_half_width * 2;
        
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

-(BOOL)canAddObjectToInkList:(PTInk*)ink
{
    if (!m_ink_list) {
        return NO;
    }
    for (PTInk *i in m_ink_list) {
        if ([[ink GetSDFObj] IsEqual:[i GetSDFObj]]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
    if (m_ink_list.count > 0) {
        return YES;
    }
	return [super pdfViewCtrl:pdfViewCtrl handleTap:sender];
}


-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndZooming:(nonnull UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(float)scale
{
    [super pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndZooming:scrollView withView:view atScale:scale];
    m_eraser_half_width /= scale;
    self.hidden = NO;
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [super pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndDecelerating:scrollView];
    self.hidden = NO;
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [super pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndScrollingAnimation:scrollView];
    self.hidden = NO;
}

-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [super pdfViewCtrl:pdfViewCtrl pdfScrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    self.hidden = NO;
}

@end
