//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTEllipseCreate.h"
#import "PTAnnotStyleDraw.h"
#import "PTAnnotStyle.h"

@implementation PTEllipseCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {

    }
    return self;
}

-(Class)annotClass
{
    return [PTCircle class];
}

+(PTExtendedAnnotType)annotType
{
	return PTExtendedAnnotTypeCircle;
}

+ (BOOL)canEditStyle
{
    return YES;
}

- (void)drawRect:(CGRect)rect
{
    if( self.pageNumber >= 1 && !self.allowScrolling )
    {
        PTAnnotStyle* myStyle = [[PTAnnotStyle allocOverridden] initWithAnnotType:PTExtendedAnnotTypeCircle];
        
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        
        [PTAnnotStyleDraw drawIntoContext:currentContext withStyle:myStyle withCrop:self.drawArea atZoom:[self.pdfViewCtrl GetZoom]];
    }

}


@end
