//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTouchForwardingView.h"

@implementation PTTouchForwardingView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    
    if (hitView != self) {
        return hitView;
    }
    
    for (UIView *passthroughView in self.passthroughViews) {
        UIView *passthroughHitView = [passthroughView hitTest:[self convertPoint:point toView:passthroughView] withEvent:event];
        
        if (passthroughHitView) {
            return passthroughHitView;
        }
    }
    
    return self;
}

@end
