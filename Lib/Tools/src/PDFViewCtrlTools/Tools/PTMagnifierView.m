//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTMagnifierView.h"

#import "PTToolsUtil.h"

#import <QuartzCore/QuartzCore.h>

@interface PTMagnifierView ()
{
    CGPoint _magnifyPoint;
}

@end

@implementation PTMagnifierView	

- (instancetype)initWithViewToMagnify:(UIView*)viewToMagnify {
    
    if ((self = [super initWithFrame:CGRectMake(0, 0, 120, 120)])) {
        
        _viewToMagnify = viewToMagnify;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 3;
        self.layer.cornerRadius = 60;
        self.layer.masksToBounds = YES;
        
        UIImageView *loupeImageView = [[UIImageView alloc] initWithFrame:CGRectOffset(CGRectInset(self.bounds, -5.0, -5.0), 0, 2)];
        loupeImageView.image = [PTToolsUtil toolImageNamed:@"loupe"];
        loupeImageView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:loupeImageView];
    }
    
    return self;
}


- (void)setMagnifyPoint:(CGPoint)magnifyPoint TouchPoint:(CGPoint)touchPoint{
	_magnifyPoint = magnifyPoint;
    _magnifyPoint.y -= 10;
	self.center = CGPointMake(touchPoint.x, touchPoint.y-60);
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context,1*(self.frame.size.width*0.5),1*(self.frame.size.height*0.5));
	CGContextScaleCTM(context, 1.8, 1.8);
	CGContextTranslateCTM(context,-1*(_magnifyPoint.x),-1*(_magnifyPoint.y));
	[self.viewToMagnify.layer renderInContext:context];
}

@end
