//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFreeHandHighlightCreate.h"

@implementation PTFreeHandHighlightCreate

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:pdfViewCtrl];
    if (self) {
        // Single-stroke mode by default.
        self.multistrokeMode = NO;
    }
    return self;
}

+ (PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeFreehandHighlight;
}

- (PTInk *)createAnnotation
{
    PTInk *annot = [super createAnnotation];
    [annot SetHighlightIntent:YES];
    return annot;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    [super drawRect:rect];
}

@end
