//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTArrowCreate.h"

#import "PTColorDefaults.h"

@interface PTArrowCreate()
{
    double mCos, mSin, mArrowLength;
}
@end

@implementation PTArrowCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        mCos = cos(3.1415926/6);
        mSin = sin(3.1415926/6);
        mArrowLength = 10;
    }
    return self;
}

- (Class)annotClass
{
    return [PTLineAnnot class];
}

+ (PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeArrow;
}

+ (BOOL)canEditStyle
{
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
	CGPoint touchPoint = [touch locationInView:self.pdfViewCtrl];
	
	self.endPoint = [super boundToPageScreenPoint:touchPoint withThicknessCorrection:0];
	
	if( _thickness < -1 )
	{
		_thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:PTExtendedAnnotTypeArrow];
		_thickness = _thickness*[self.pdfViewCtrl GetZoom];
	}
    
    mArrowLength = 10*_thickness/2;
    
    // max size of control in both directions
    double width = self.pdfViewCtrl.frame.size.width;
    double height = self.pdfViewCtrl.frame.size.height;
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], width, height);
    
    return YES;
}

- (void)drawRect:(CGRect)rect
{
    if( self.pageNumber >= 1 && !self.allowScrolling )
    {
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        
        [super setupContext:currentContext];
        
        CGRect myRect = CGContextGetClipBoundingBox(currentContext);
        
        CGPoint firstSmall, secondSmall;
        
        CGContextBeginPath (currentContext);

        double dx = self.startPoint.x - self.endPoint.x;
        double dy = self.startPoint.y - self.endPoint.y;
        double len = dx*dx+dy*dy;
        
        if( len > 0 )
        {
            len = sqrt(len);
            dx /= len;
            dy /= len;
            
            double dx1 = dx * mCos - dy * mSin;
            double dy1 = dy * mCos + dx * mSin;
            
            firstSmall = CGPointMake(self.startPoint.x - mArrowLength*dx1, self.startPoint.y - mArrowLength*dy1);
            
            double dx2 = dx * mCos + dy * mSin;
            double dy2 = dy * mCos - dx * mSin;
            
            secondSmall = CGPointMake(self.startPoint.x - mArrowLength*dx2, self.startPoint.y - mArrowLength*dy2);

            // end of small line
            CGContextMoveToPoint(currentContext, firstSmall.x, firstSmall.y);
            
            // tip of arrow
            CGContextAddLineToPoint(currentContext, self.startPoint.x, self.startPoint.y);
            
            // end of second small line
            CGContextAddLineToPoint(currentContext, secondSmall.x, secondSmall.y);
            
            // tip of arrow
            CGContextMoveToPoint(currentContext, self.startPoint.x, self.startPoint.y);
            
            // base of long arrow line
            CGContextAddLineToPoint(currentContext, self.endPoint.x, self.endPoint.y);
        }

        CGContextStrokePath(currentContext);
        
        CGContextClipToRect(currentContext, myRect);
    }
    
    [super drawRect:rect];
}

@end
