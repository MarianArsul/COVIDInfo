//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCanvasView.h"

@interface PTCanvasView () <UIGestureRecognizerDelegate>
@property (nonatomic,strong) UIView *hitView;
@end

@implementation PTCanvasView
#if !TARGET_OS_MACCATALYST
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    /**
     * The canvas has been moved to a new page and now must immediately begin drawing.
     * This is done by allowing the canvas itself to receive the touches and forward them
     * to its drawingGestureRecognizer.
     * See `PTPencilDrawingCreate` implementation of `pdfViewCtrl:touchesShouldBegin:withEvent:inContentView:` for details.
     */
    if ([self.hitView isKindOfClass:[PKCanvasView class]]) {
        [self.drawingGestureRecognizer touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.hitView isKindOfClass:[PKCanvasView class]]) {
        [self.drawingGestureRecognizer touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.hitView isKindOfClass:[PKCanvasView class]]) {
        [self.drawingGestureRecognizer touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.hitView isKindOfClass:[PKCanvasView class]]) {
        [self.drawingGestureRecognizer touchesCancelled:touches withEvent:event];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    self.hitView = [super hitTest:point withEvent:event];
    return self.hitView;
}
#endif
@end
