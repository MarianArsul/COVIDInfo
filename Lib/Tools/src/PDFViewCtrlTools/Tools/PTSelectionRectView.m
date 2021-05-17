//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTSelectionRectView.h"

#import "PTAnnotStyleDraw.h"
#import "PTAnnotStyle.h"
#import "PTToolsUtil.h"
#import "PTAnnot+PTAdditions.h"

@interface PTNoFadeTiledLayer : CATiledLayer
@end

@implementation PTNoFadeTiledLayer

+ (CFTimeInterval)fadeDuration
{
    return 0.0;
}

@end


@interface PTSelectionRectView ()

@property (nonatomic, assign) int pageNumber;
@property (nonatomic, weak) PTAnnotEditTool* tool;
@property (nonatomic) CGSize lastRenderSize;

@end

@implementation PTSelectionRectView

- (instancetype)initWithFrame:(CGRect)frame forAnnot:(PTAnnot*)annot withAnnotEditTool:(PTAnnotEditTool*)tool withPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _annot = annot;
        _tool = tool;
        [_tool removeAppearanceViews];
        _rectOffset = 5.0;
        self.backgroundColor = UIColor.clearColor;
        self.layer.backgroundColor = UIColor.clearColor.CGColor;
        self.contentMode = UIViewContentModeRedraw;
        _pdfViewCtrl = pdfViewCtrl;
        _lastRenderSize = CGSizeZero;
        self.userInteractionEnabled = NO;

    }
    
    return self;
}


- (void)refreshVectorAppearanceViewWithAnnot:(PTAnnot * _Nullable)annot {
    
    UIView* view = [PTAnnotStyleDraw getAnnotationVectorAppearanceView:[self.pdfViewCtrl GetDoc] withAnnot:annot andPDFViewCtrl:self.pdfViewCtrl onPageNumber:self.tool.annotationPageNumber];
    
    view.frame = self.bounds;
    view.frame = CGRectInset(view.frame, -30, -30);
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSAssert(self.subviews.count <= 1, @"0 or 1 subviews expected");
    [self.subviews.firstObject removeFromSuperview];
    [self addSubview:view];

    if( self.tool.superview != Nil )
    {
        [self.pdfViewCtrl HideAnnotation:annot];
        [self.pdfViewCtrl UpdateWithAnnot:self.annot page_num:self.pageNumber];
    }

}

- (void)refreshBitmapAppearanceViewWithAnnot:(PTAnnot * _Nullable)annot {
    
    PTRotate rotation;
    
    if( [annot GetFlag:e_ptno_rotate] == YES )
    {
        PTPage *page = [annot GetPage];
        PTRotate pageRotation = [page GetRotation];
        rotation = (4 - ( pageRotation % 4));
    }
    else
    {
        rotation = self.pdfViewCtrl.rotation;
    }

    NSAssert(self.pageNumber > 0 , @"Page number must be > 0");
    
    // this should be called on a background thread
    UIImage* appearance = [PTAnnotStyleDraw getAnnotationAppearanceImage:[self.pdfViewCtrl GetDoc] withAnnot:annot onPageNumber:self.pageNumber withDPI:[self.pdfViewCtrl GetZoom]*72*[[UIScreen mainScreen] scale]  forViewerRotation:rotation];
    

    
    dispatch_async( dispatch_get_main_queue(), ^{
        
        if( [annot IsValid] && self.superview )
        {
            [self.pdfViewCtrl HideAnnotation:annot];
            [self.pdfViewCtrl UpdateWithAnnot:annot page_num:self.pageNumber];
            UIImageView* imageView = [[UIImageView alloc] initWithImage:appearance];
            
            imageView.frame = self.bounds;

            if ([annot IsMarkup]) {
                PTMarkup* markup = [[PTMarkup alloc] initWithAnn:annot];
                if ([markup GetBorderEffect] == e_ptCloudy) {
                    CGRect annotScreenRect = [self.pdfViewCtrl PDFRectPage2CGRectScreen:[markup GetRect] PageNumber:self.pageNumber];
                    imageView.frame = [self.pdfViewCtrl convertRect:annotScreenRect toView:self];
                }
            }

            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            if (annot.extendedAnnotType == PTExtendedAnnotTypeRuler) {
                // Ruler annot bounds don't include the label or leader lines so the image will be distorted with the default contentMode of UIViewContentModeScaleToFill
                imageView.contentMode = UIViewContentModeCenter;
            }
            else if( annot.extendedAnnotType == PTExtendedAnnotTypeFreeText &&
               UIApplication.sharedApplication.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight)
            {
                imageView.contentMode = UIViewContentModeTopLeft;
            }

            NSAssert(self.subviews.count <= 1, @"0 or 1 subviews expected");
            [self.subviews.firstObject removeFromSuperview];
            [self addSubview:imageView];
        }
    });
}

-(void)removeLiveAppearance
{
    [self.subviews.firstObject removeFromSuperview];
}

-(void)refreshLiveAppearance
{
    if( [self.annot IsValid] )
    {
        
        if( self.annot.extendedAnnotType == PTExtendedAnnotTypeHighlight ||
            self.annot.extendedAnnotType == PTExtendedAnnotTypeUnderline ||
           self.annot.extendedAnnotType == PTExtendedAnnotTypeSquiggly ||
           self.annot.extendedAnnotType == PTExtendedAnnotTypeStrikeOut )
        {
            return;
        }

        if( [PTAnnotStyleDraw canVectorDrawWithAnnotType:self.annot.extendedAnnotType])
        {
            BOOL renderAnnotationAsVector = YES;

            if ([self.tool.delegate respondsToSelector:@selector(annotEditTool:shouldRenderAnnotationAsVector:onPageNumber:)]) {
                renderAnnotationAsVector = [self.tool.delegate annotEditTool:self.tool shouldRenderAnnotationAsVector:self.annot onPageNumber:self.pageNumber];
            }

            if (renderAnnotationAsVector) {
                [self refreshVectorAppearanceViewWithAnnot:self.annot];
            }else{
                self.lastRenderSize = self.frame.size;

                self.pageNumber = self.tool.annotationPageNumber;
                NSAssert(self.pageNumber > 0 , @"Page number must be > 0");
                dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                    [self refreshBitmapAppearanceViewWithAnnot:self.annot];

                });
            }
        }
        else //bitmap from core
        {
            if( (CGSizeEqualToSize(self.lastRenderSize, self.frame.size) &&
                 !CGSizeEqualToSize(self.lastRenderSize, CGSizeZero) &&
                 self.annot.extendedAnnotType != PTExtendedAnnotTypeRuler &&
                 self.annot.extendedAnnotType != PTExtendedAnnotTypeFreeText &&
                 self.annot.extendedAnnotType != PTExtendedAnnotTypeCallout) || self.annot.extendedAnnotType == PTExtendedAnnotTypeLink )
            {
                // no need to over-render, but measurement may just have its label requiring an update
                return;
            }
            self.lastRenderSize = self.frame.size;
            
            self.pageNumber = self.tool.annotationPageNumber;
            NSAssert(self.pageNumber > 0 , @"Page number must be > 0");
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [self refreshBitmapAppearanceViewWithAnnot:self.annot];
                
            });
        }
    }
    else
    {
        [self.subviews.firstObject removeFromSuperview];
    }
}

-(void)setAnnot:(PTAnnot *)annot
{

    BOOL wasEqual = (annot == _annot);
    _annot = annot;
    
    // need to know here if part of group
    
    if( annot.isInGroup == NO &&
       self.tool.selectedAnnotations.count <= 1 &&
       ( [PTAnnotStyleDraw canVectorDrawWithAnnotType:self.annot.extendedAnnotType] == NO  || wasEqual == NO ))
    {
        [self refreshLiveAppearance];
    }
        
    
}

+(Class)layerClass
{
    // permits layer to become very big, for
    // when we have zoomed in close and selected
    // a large annotation.
    // otherwise consumes too much memory and sometimes crashes.
    return [PTNoFadeTiledLayer class];
}

- (void)setDrawingMode:(PTSelectionRectViewDrawingMode)drawingMode
{
    if (drawingMode != self.drawingMode
        && drawingMode != PTSelectionRectViewDrawingModeNone) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.hidden = YES;
        self.contentMode = UIViewContentModeRedraw;
    }
    
    _drawingMode = drawingMode;
}

-(void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if( self.window != nil )
    {
        CGPoint myPos = [self convertPoint:self.center toView:_pdfViewCtrl];
        self.pageNumber = [_pdfViewCtrl GetPageNumberFromScreenPt:myPos.x y:myPos.y];
    }
}

-(void)setFrame:(CGRect)frame
{
    if( self.drawingMode != PTSelectionRectViewDrawingModeNone )
    {
        CGFloat rectOffset = self.rectOffset;
        super.frame = CGRectInset(frame, -rectOffset, -rectOffset);
    }
    else
    {
        super.frame = frame;
    }
}

-(CGRect)frame
{
    if( self.drawingMode != PTSelectionRectViewDrawingModeNone )
    {
        CGFloat rectOffset = self.rectOffset;
        CGRect rectForResizeWidgets = CGRectInset(super.frame, rectOffset, rectOffset);
        rectForResizeWidgets.size.width = MAX(rectForResizeWidgets.size.width, 0);
        rectForResizeWidgets.size.height = MAX(rectForResizeWidgets.size.height, 0);
        return rectForResizeWidgets;
    }
    else
    {
        return super.frame;
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if( self.drawingMode != PTSelectionRectViewDrawingModeNone )
    {
        if( [self.annot IsValid] )
        {
            PTColorPt* strokePoint = [self.annot GetColorAsRGB];
            
            double r = [strokePoint Get:0];
            double g = [strokePoint Get:1];
            double b = [strokePoint Get:2];
            
            if( [self.pdfViewCtrl GetColorPostProcessMode] == e_ptpostprocess_invert )
            {
                r = 1.-r;
                g = 1.-g;
                b = 1.-b;
            }
            
            int strokeColorComps = [self.annot GetColorCompNum];
            
            UIColor* strokeColor = [UIColor colorWithRed:r green:g blue:b alpha:(strokeColorComps > 0 ? 1 : 0)];
            
            double thickness = [[self.annot GetBorderStyle] GetWidth];
            
            thickness *= [self.pdfViewCtrl GetZoom];
            
            CGContextSetLineWidth(ctx, thickness);
            CGContextSetLineCap(ctx, kCGLineCapButt);
            CGContextSetLineJoin(ctx, kCGLineJoinMiter);
            CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor);
            
            if ([self.annot IsMarkup]) {
                PTMarkup *markup = [[PTMarkup alloc] initWithAnn:self.annot];
                CGContextSetAlpha(ctx, [markup GetOpacity]);
            }
        }
        
        CGContextBeginPath (ctx);

        if( self.drawingMode == PTSelectionRectViewDrawingModeLineNEStart )
        {
            CGContextMoveToPoint(ctx, _rectOffset, MAX(layer.bounds.size.height-_rectOffset,0));
            CGContextAddLineToPoint(ctx, MAX(layer.bounds.size.width-_rectOffset,0), _rectOffset);
        }
        else
        {
            CGContextMoveToPoint(ctx, _rectOffset, _rectOffset);
            CGContextAddLineToPoint(ctx, MAX(layer.bounds.size.width-_rectOffset,0), MAX(layer.bounds.size.height-_rectOffset,0));
        }
        
        CGContextStrokePath(ctx);
    }
}

- (void)drawRect:(CGRect)rect
{
    // Although the drawing is done in `-drawLayer:inContext:` we still need to implement an empty `-drawRect:` method:
    // https://developer.apple.com/library/archive/qa/qa1637/_index.html
}

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return Nil;
}



@end
