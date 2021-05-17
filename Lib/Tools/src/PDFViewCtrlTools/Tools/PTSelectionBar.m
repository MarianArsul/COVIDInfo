//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSelectionBar.h"

static const int circleDiameter = 12;

@implementation PTSelectionBar

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {

        [self setUserInteractionEnabled:YES];
        
        self.contentMode = UIViewContentModeCenter;
		
		self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
	CGRect myRect = CGRectMake(rect.size.width/2-circleDiameter/2, rect.size.height/2-circleDiameter/2, circleDiameter, circleDiameter);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, myRect);
    CGContextSetFillColorWithColor(ctx, self.tintColor.CGColor);
	CGContextFillEllipseInRect(ctx, myRect);
	CGContextStrokePath(ctx);
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
