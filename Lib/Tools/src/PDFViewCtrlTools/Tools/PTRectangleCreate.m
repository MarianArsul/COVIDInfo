//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTRectangleCreate.h"

#import "PTAnnotStyleDraw.h"
#import "PTAnnotStyle.h"

@implementation PTRectangleCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {

    }
    return self;
}

+ (BOOL)createsAnnotation
{
	return YES;
}

- (Class)annotClass
{
    return [PTSquare class];
}

+ (PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeSquare;
}

+ (BOOL)canEditStyle
{
    return YES;
}

- (void)drawRect:(CGRect)rect
{
    if( self.pageNumber >= 1 && !self.allowScrolling)
    {
        
        PTAnnotStyle* myStyle = [[PTAnnotStyle allocOverridden] initWithAnnotType:PTExtendedAnnotTypeSquare];
        
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        
        [PTAnnotStyleDraw drawIntoContext:currentContext withStyle:myStyle withCrop:self.drawArea atZoom:[self.pdfViewCtrl GetZoom]];
        
    }
}

@end
