//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTLineCreate.h"
#import "PTColorDefaults.h"
#import "PTRulerCreate.h"
#import "PTMagnifierView.h"
#import "CGGeometry+PTAdditions.h"

@class PTPDFViewCtrl;

@interface PTLineCreate()
{
    double _width;
    PTMagnifierView* loupe;
}
@end

@implementation PTLineCreate


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {

		_width = -1;
    }
    
    return self;
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
    CGPoint touchPoint = [touch locationInView:self.pdfViewCtrl];
	
	self.endPoint = [super boundToPageScreenPoint:touchPoint withThicknessCorrection:0];
    
    if (self.toolManager.snapToDocumentGeometry && [self isKindOfClass:[PTRulerCreate class]]) {
        PTPDFPoint* snapPoint = [self.pdfViewCtrl SnapToNearestInDoc:[[PTPDFPoint alloc] initWithPx:self.endPoint.x py:self.endPoint.y]];
        self.endPoint = PTCGPointSnapToPoint(self.endPoint, CGPointMake(snapPoint.getX, snapPoint.getY));
    }
    double thickness;
    
    if ([self isKindOfClass:[PTRulerCreate class]]) {
        [self addLoupeAtMagnifyPoint:self.endPoint touchPoint:self.endPoint];
    }

    @try {
        [self.pdfViewCtrl DocLock:YES];
		if( _width < 0 )
			_width = [PTColorDefaults defaultBorderThicknessForAnnotType:PTExtendedAnnotTypeLine];
		
        thickness = _width*[self.pdfViewCtrl GetZoom];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }

    // max size of control in both directions
    double width = self.pdfViewCtrl.frame.size.width;
    double height = self.pdfViewCtrl.frame.size.height;
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], width, height);
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [loupe removeFromSuperview];
    return [super pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [loupe removeFromSuperview];
    return [super pdfViewCtrl:pdfViewCtrl onTouchesCancelled:touches withEvent:event];
}

-(void)addLoupeAtMagnifyPoint:(CGPoint)magnifyPoint touchPoint:(CGPoint)touchPoint
{
    if(loupe == nil){
        loupe = [[PTMagnifierView alloc] initWithViewToMagnify:self.pdfViewCtrl];
    }

    [self.pdfViewCtrl.superview addSubview:loupe];

    [loupe setMagnifyPoint:magnifyPoint TouchPoint:touchPoint];
    [loupe setNeedsDisplay];
}

-(Class)annotClass
{
    return [PTLineAnnot class];
}

+(PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeLine;
}

+ (BOOL)canEditStyle
{
    return YES;
}

- (void)drawRect:(CGRect)rect
{
    if( self.pageNumber >= 1 && !self.allowScrolling)
    {
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        
        [super setupContext:currentContext];
        
        CGContextBeginPath (currentContext);
        
        CGContextMoveToPoint(currentContext, self.startPoint.x, self.startPoint.y);
        CGContextAddLineToPoint(currentContext, self.endPoint.x, self.endPoint.y);

        CGContextStrokePath(currentContext);
    }

}

@end
