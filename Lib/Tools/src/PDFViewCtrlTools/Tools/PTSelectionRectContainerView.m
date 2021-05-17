//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

// NOTE: This file should be compiled without optimizations or the selection rectangle will not
//       be visible on devices with an A5. In Build Phases, add -O0 in this file's compiler flags.

#import "ToolsConfig.h"
#import "PTToolsUtil.h"
#import "PTSelectionRectContainerView.h"
#import "PTFreeTextInputAccessoryView.h"
#import "PTResizeWidgetView.h"
#import "PTColorDefaults.h"
#import "PTFreeTextCreate.h"

#if TARGET_OS_MACCATALYST
#import <AppKit/AppKit.h>
#endif

@interface PTSelectionRectContainerView ()
{
    PTResizeWidgetView* rwvNW;
    PTResizeWidgetView* rwvN;
    PTResizeWidgetView* rwvNE;
    PTResizeWidgetView* rwvE;
    PTResizeWidgetView* rwvSE;
    PTResizeWidgetView* rwvS;
    PTResizeWidgetView* rwvSW;
    PTResizeWidgetView* rwvW;
//    UITextView* tv;
    
    CGPoint startPoint, endPoint;
}

@property (nonatomic, weak) PTAnnotEditTool* tool;
@end

@implementation PTSelectionRectContainerView

@synthesize textView = tv;

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl forAnnot:(PTAnnot*)annot withAnnotEditTool:(PTAnnotEditTool*)tool
{
	CGRect frame = CGRectZero;
    const int length = PTResizeWidgetView.length;
    frame.origin.x -= length/2;
    frame.origin.y -= length/2;
    frame.size.width += length;
    frame.size.height += length;
    
    _tool = tool;
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

        
        frame.origin.x = length/2;
        frame.origin.y = length/2;
        frame.size.width -= length;
        frame.size.height -= length;

        _selectionRectView = [[PTSelectionRectView alloc] initWithFrame:frame forAnnot:annot withAnnotEditTool:self.tool withPDFViewCtrl:pdfViewCtrl];
        
        [self addSubview:self.selectionRectView];
        
        _pdfViewCtrl = pdfViewCtrl;

        rwvNW = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(0, 0) WithLocation:PTResizeHandleLocationTopLeft];
        rwvN = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(self.frame.size.width/2-length/2, 0) WithLocation:PTResizeHandleLocationTop];
        rwvNE = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(self.frame.size.width-length, 0) WithLocation:PTResizeHandleLocationTopRight];
        rwvE = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(self.frame.size.width-length, self.frame.size.height/2-length/2) WithLocation:PTResizeHandleLocationRight];
        rwvSE = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(self.frame.size.width-length, self.frame.size.height-length) WithLocation:PTResizeHandleLocationBottomRight];
        rwvS = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(self.frame.size.width/2-length/2, self.frame.size.height-length) WithLocation:PTResizeHandleLocationBottom];
        rwvSW = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(0, self.frame.size.height-length) WithLocation:PTResizeHandleLocationBottomLeft];
        rwvW = [[PTResizeWidgetView alloc] initAtPoint:CGPointMake(0, self.frame.size.height/2-length/2) WithLocation:PTResizeHandleLocationLeft];
        
        _groupSelectionRectView = [[UIView alloc] init];
        [self addSubview:self.groupSelectionRectView];
        _borderView = [[UIView alloc] init];
        _borderView.layer.borderColor = self.tintColor.CGColor;
        _borderView.layer.borderWidth = 1;
        _borderView.layer.opacity = 0.8;
        _borderView.userInteractionEnabled = NO;
        [self addSubview:_borderView];

        // corners
        [self addSubview:rwvNW];
        [self addSubview:rwvNE];
        [self addSubview:rwvSE];
        [self addSubview:rwvSW];
        
        // egdes
        [self addSubview:rwvN];
        [self addSubview:rwvE];
        [self addSubview:rwvS];
        [self addSubview:rwvW];

        #if TARGET_OS_MACCATALYST
        UIHoverGestureRecognizer *hover = [[UIHoverGestureRecognizer alloc] initWithTarget:self action:@selector(handleHover:)];
        [self addGestureRecognizer:hover];
        #endif

    }
    return self;
}

#if TARGET_OS_MACCATALYST
-(void)handleHover:(UIHoverGestureRecognizer*)gestureRecognizer{
    CGPoint hoverPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    if (CGRectContainsPoint(self.groupSelectionRectView.frame, hoverPoint) ||
        CGPointEqualToPoint(CGPointZero, hoverPoint)) { // The point will be (0,0) after showing the style picker
        [[NSCursor pointingHandCursor] set];
        return;
    }
    for (PTResizeWidgetView *resizeWidgetView in @[rwvNW, rwvN, rwvNE, rwvE, rwvSE, rwvS, rwvSW, rwvW]){
        PTResizeHandleLocation location = resizeWidgetView.location;
        if (CGRectContainsPoint(resizeWidgetView.frame, hoverPoint)) {
            if ([self.selectionRectView.annot GetType] == e_ptLine && self.groupSelectionRectView.subviews.count < 2) {
                
                /*
                UIImage* cursorImage = [PTToolsUtil toolImageNamed:@"ic_pan_black_24dp"];
                NSCursor *cross = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(cursorImage.size.width*0.5, cursorImage.size.height*0.5)];
                [cross set];
                 */
                [[NSCursor crosshairCursor] set];
                return;
            }

            switch (location) {
                case PTResizeHandleLocationTop:
                case PTResizeHandleLocationBottom:
                    [[NSCursor resizeUpDownCursor] set];
                    break;
                case PTResizeHandleLocationLeft:
                case PTResizeHandleLocationRight:
                    [[NSCursor resizeLeftRightCursor] set];
                    break;
                case PTResizeHandleLocationTopLeft:
                case PTResizeHandleLocationBottomRight:
                {
                    UIImage *image = [NSCursor resizeLeftRightCursor].image;
                    image = [self rotateImage:image byDegrees:45];
                    NSCursor *angledResize = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(image.size.width*0.5, image.size.height*0.5)];
                    [angledResize set];
                    break;
                }
                case PTResizeHandleLocationTopRight:
                case PTResizeHandleLocationBottomLeft:
                {
                    UIImage *image = [NSCursor resizeUpDownCursor].image;
                    image = [self rotateImage:image byDegrees:45];
                    NSCursor *angledResize = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(image.size.width*0.5, image.size.height*0.5)];
                    [angledResize set];
                    break;
                }
                default:
                    break;
            }
        }
    }
}

- (UIImage *)rotateImage:(UIImage*)image byDegrees:(CGFloat)degrees {
    CGFloat radians = degrees*M_PI/180.0;

    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0, image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;

    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, [[UIScreen mainScreen] scale]);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);

    CGContextRotateCTM(bitmap, radians);

    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2 , image.size.width, image.size.height), image.CGImage );

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    CGPoint location = [touches.allObjects.firstObject locationInView:self];
    if (CGRectContainsPoint(self.groupSelectionRectView.frame, location)) {
        [[NSCursor closedHandCursor] set];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [[NSCursor pointingHandCursor] set];
}
#endif

-(void)didMoveToWindow
{
    [super didMoveToWindow];
    self.borderView.layer.borderColor = self.tintColor.CGColor;
}

-(void)hideResizeWidgetViews
{
    [rwvNW setHidden:YES];
    [rwvN setHidden:YES];
    [rwvNE setHidden:YES];
    [rwvE setHidden:YES];
    [rwvSE setHidden:YES];
    [rwvS setHidden:YES];
    [rwvSW setHidden:YES];
    [rwvW setHidden:YES];
}

-(void)setAnnot:(PTAnnot*)annot
{
    [self.selectionRectView setAnnot:annot];
    if ([annot extendedAnnotType] == PTExtendedAnnotTypeImageStamp) {
        if(self.rotationHandle == nil){
            CGPoint point = CGPointMake(self.frame.size.width / 2 - PTRotateWidgetView.diameter / 2,
                                        self.frame.size.height + PTRotateWidgetView.diameter * 0.5);
            self.rotationHandle = [[PTRotateWidgetView alloc] initAtPoint:point];
            [self addSubview:self.rotationHandle];
        }
    }
}

-(void)refreshLiveAppearance
{
    [self.selectionRectView refreshLiveAppearance];
}

-(void)removeLiveAppearance
{
    [self.selectionRectView removeLiveAppearance];
}

-(void)showSelectionRect
{
    if( self.selectionRectView.hidden == YES)
    {
        [self.selectionRectView setHidden:NO];
        [self.selectionRectView setNeedsDisplay];
    }
}

-(void)hideSelectionRect
{
    if( self.selectionRectView.hidden == NO)
    {
		// ensure we don't get a stale view
		// flash on screen next time
		{
			PTAnnot* theAnnot = self.selectionRectView.annot;
			CGRect theFrame = self.selectionRectView.frame;
            PTSelectionRectViewDrawingMode drawingMode = self.selectionRectView.drawingMode;
			[self.selectionRectView removeFromSuperview];
            
			_selectionRectView = [[PTSelectionRectView alloc] initWithFrame:theFrame forAnnot:theAnnot withAnnotEditTool:self.tool withPDFViewCtrl:self.pdfViewCtrl];
            self.selectionRectView.drawingMode = drawingMode;
			self.selectionRectView.pdfViewCtrl = self.pdfViewCtrl;
			[self insertSubview:self.selectionRectView atIndex:0];
		}
		
        [self.selectionRectView setHidden:YES];
        [self.selectionRectView setNeedsDisplay];
    }
}

// for lines and arrows, show only the NE and SW
// resize dots
-(void)showNESWWidgetViews
{
    
    if( rwvNW == nil )
    {
        return;
    }
    
    self.selectionRectView.drawingMode = PTSelectionRectViewDrawingModeLineNEStart;
    [self hideResizeWidgetViews];
    [rwvNE setHidden:NO];
    [rwvSW setHidden:NO];
}

// for lines and arrows, show only the NW and SE
// resize dots
-(void)showNWSEWidgetViews
{

    if( rwvNW == nil )
    {
        return;
    }
    
    self.selectionRectView.drawingMode = PTSelectionRectViewDrawingModeLineNWStart;
    [self hideResizeWidgetViews];
    [rwvNW setHidden:NO];
    [rwvSE setHidden:NO];
}


-(void)showResizeWidgetViews
{
    if( rwvNW == nil )
        return;

    [rwvNW setHidden:NO];
    [rwvNE setHidden:NO];
    [rwvSE setHidden:NO];
    [rwvSW setHidden:NO];
    
    if( self.displaysOnlyCornerResizeHandles == false)
    {
        [rwvW setHidden:NO];
        [rwvE setHidden:NO];
        [rwvS setHidden:NO];
        [rwvN setHidden:NO];
    }
    else
    {
        [rwvW setHidden:YES];
        [rwvE setHidden:YES];
        [rwvS setHidden:YES];
        [rwvN setHidden:YES];
    }
}

-(void)setAnnotationContents:(PTAnnot*)annot
{
    if( tv != nil)
    {
        [annot SetContents:tv.text];
        PTExtendedAnnotType type = [annot extendedAnnotType];
        if( type == PTExtendedAnnotTypeFreeText )
        {
            PTFreeText* ft = [[PTFreeText alloc] initWithAnn:annot];
            [PTFreeTextCreate refreshAppearanceForAnnot:ft onDoc:[self.pdfViewCtrl GetDoc]];
        }
        else if( type == PTExtendedAnnotTypeCallout )
        {
            [annot RefreshAppearance];
        }
        
        [tv resignFirstResponder];
    }
}

-(void)setEditTextSizeForZoom:(double)zoom forFontSize:(int)size
{
    if (!tv) {
        return;
    }
    NSString* name = tv.font.fontName;
    tv.font = [UIFont fontWithName:name size:size*zoom];
}

-(void)useTextViewWithText:(NSString*)text withAlignment:(int)alignment atZoom:(double)zoom forFontSize:(int)size withFontName:(NSString*)fontName withFrame:(CGRect)frame withDelegate:(nonnull id<UITextViewDelegate>)delegateView
{

    tv = [[UITextView alloc] initWithFrame:frame];
    
    tv.autoresizingMask = UIViewAutoresizingNone;
    
    tv.backgroundColor = [UIColor whiteColor];
    tv.textContainerInset = UIEdgeInsetsZero;
    tv.textContainer.lineFragmentPadding = 0;
    tv.contentInset = UIEdgeInsetsZero;
    
    

    // Get freetext annotation's text color.
    UIColor *textColor = nil;
    UIColor *borderColor = nil;
    double borderThickness = 0.0;
    if ([self.selectionRectView.annot IsValid] && [self.selectionRectView.annot extendedAnnotType] == PTExtendedAnnotTypeFreeText) {
        @try {
            PTFreeText *freeText = [[PTFreeText alloc] initWithAnn:self.selectionRectView.annot];
            
            textColor = [PTColorDefaults uiColorFromColorPt:[freeText GetTextColor]
                                                           compNum:[freeText GetTextColorCompNum]];
            
            borderColor = [PTColorDefaults uiColorFromColorPt:[freeText GetLineColor]
                                                    compNum:[freeText GetLineColorCompNum]];
            
            borderThickness = [[freeText GetBorderStyle] GetWidth] * [self.pdfViewCtrl GetZoom];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
        }
    }
    // Fallback color.
    if (!textColor) {
        textColor = UIColor.redColor;
    }
    tv.textColor = textColor;
    
    if (borderColor) {
        tv.layer.borderColor = borderColor.CGColor;
        tv.layer.borderWidth = borderThickness;
        tv.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    UIFont* font = [UIFont fontWithName:fontName size:size*zoom];

    NSAssert(font, @"Could not find font for given name.");
    
    tv.font = font ? font : [UIFont fontWithName:@"Helvetica" size:size*zoom];
    

    
    
    double inset = borderThickness;
    // Offset to account for the difference between font size in points and the actual line height.
    double topOffset = tv.font.lineHeight-tv.font.pointSize;
    tv.textContainerInset = UIEdgeInsetsMake(inset*2-topOffset, inset, inset, inset);
    
    tv.text = text;
    
    if(alignment == 1 )
        tv.textAlignment = NSTextAlignmentCenter;
    else if(alignment == 2)
        tv.textAlignment = NSTextAlignmentRight;
    else
        tv.textAlignment = NSTextAlignmentLeft;
    
    [self insertSubview:tv atIndex:1];

    if (self.tool.toolManager.freeTextAnnotationOptions.inputAccessoryViewEnabled) {
        PTFreeTextInputAccessoryView *freeTextAccessory = [[PTFreeTextInputAccessoryView allocOverridden] initWithToolManager:self.tool.toolManager textView:tv];
        tv.inputAccessoryView = freeTextAccessory;
    }

    [tv becomeFirstResponder];
    
    tv.delegate = delegateView;
    
}

-(void)setLineStartPoint:(CGPoint)sPoint EndPoint:(CGPoint)ePoint
{
    startPoint = sPoint;
    endPoint = ePoint;
}

-(void)setFrameFromAnnot:(CGRect)frame
{
    const int length = PTResizeWidgetView.length;
    
    // could avoid calculations by setting up struts and springs?
    frame.origin.x -= length/2;
    frame.origin.y -= length/2;
    frame.size.width += length;
    frame.size.height += length;
    
    super.frame = frame;
    
    frame.origin.x = length/2;
    frame.origin.y = length/2;
    frame.size.width -= length;
    frame.size.height -= length;

    self.selectionRectView.frame = frame;

    BOOL isGroup = (self.groupSelectionRectView.subviews.count > 1);

    self.groupSelectionRectView.hidden = !isGroup;
    self.rotationHandle.hidden = isGroup;
    self.selectionRectView.hidden = isGroup;

    // TO DO: Hack because the groupSelectionRectView frame is based on the ruler annot's screen rect which includes its caption rather than just the line itself
    if ([self.selectionRectView.annot extendedAnnotType] != PTExtendedAnnotTypeRuler) {
        frame = self.groupSelectionRectView.frame;
    }
    
    // aka `selectionBoxMargin` on Android
    double expansion = 20;
    
    double width = frame.size.width;
    double midX = width/2;
    double height = frame.size.height;
    double midY = height/2;
    
    if( [self.selectionRectView.annot IsValid] && [self.selectionRectView.annot GetType] == e_ptLine)
    {
        expansion = 0;
        self.borderView.frame = self.groupSelectionRectView.frame;
    }
    else
    {
        self.borderView.frame = CGRectInset(self.groupSelectionRectView.frame, -expansion-self.borderView.layer.borderWidth/2, -expansion-self.borderView.layer.borderWidth/2);
    }

    rwvNW.center = CGPointMake(frame.origin.x-expansion, frame.origin.y-expansion);
    rwvN.center = CGPointMake(frame.origin.x+midX, frame.origin.y - expansion);
    rwvNE.center = CGPointMake(frame.origin.x+width+expansion, frame.origin.y - expansion);
    rwvE.center = CGPointMake(frame.origin.x+width+expansion, frame.origin.y+midY);
    rwvSE.center = CGPointMake(frame.origin.x+width+expansion, frame.origin.y+height+expansion);
    rwvS.center = CGPointMake(frame.origin.x+midX, frame.origin.y+height+expansion);
    rwvSW.center = CGPointMake(frame.origin.x-expansion, frame.origin.y+height+expansion);
    rwvW.center = CGPointMake(frame.origin.x-expansion, frame.origin.y+midY);
}

- (void)setRotationHandleLocation:(PTRotateHandleLocation)location
{
    if (self.rotationHandle) {
        CGRect handleRect = self.rotationHandle.frame;
        CGSize handleSize = handleRect.size;
        switch (location) {
            case PTRotateHandleLocationTop:
                self.rotationHandle.center = CGPointMake(self.frame.size.width/2, -handleSize.height);
                break;
            case PTRotateHandleLocationRight:
                self.rotationHandle.center = CGPointMake(self.frame.size.width+handleSize.width, self.frame.size.height/2);
                break;
            case PTRotateHandleLocationBottom:
                self.rotationHandle.center = CGPointMake(self.frame.size.width/2, self.frame.size.height+handleSize.height);
                break;
            case PTRotateHandleLocationLeft:
                self.rotationHandle.center = CGPointMake(-handleSize.width, self.frame.size.height/2);
                break;
            default:
                break;
        }
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint pointForTargetView = [self.groupSelectionRectView convertPoint:point fromView:self];

    if (CGRectContainsPoint(self.groupSelectionRectView.bounds, pointForTargetView) && !self.groupSelectionRectView.hidden) {
        BOOL result = ([self.groupSelectionRectView hitTest:pointForTargetView withEvent:event] != nil);
        return result;
    }
    
    CGPoint pointForBorderView = [self.borderView convertPoint:point fromView:self];
    
    if(CGRectContainsPoint( CGRectInset(self.borderView.bounds, -PTResizeWidgetView.length/2, -PTResizeWidgetView.length/2) , pointForBorderView))
    {
        // borderView would return because its transparent
       return YES;
    }
    
    CGPoint pointForRotateHandle = [self convertPoint:point toView:self.rotationHandle];
    if( CGRectContainsPoint(self.rotationHandle.bounds, pointForRotateHandle) )
    {
        return YES;
    }

    return [super pointInside:point withEvent:event];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if ([hitView isKindOfClass:[PTSelectionRectView class]]) {
        /**
         * This can return true if tapping outside the PTSelectionRectView but still within the PTSelectionRectContainerView
         * as PTSelectionRectView's hitTest allows touches within a certain threshold.
         * To check if we're really touching the selection rect we can check if the touch point is within the rect.
         */
        if (!CGRectContainsPoint(self.selectionRectView.frame, point)) {
            return self;
        }
    }
    if (hitView == self.groupSelectionRectView) {
        return self;
//        return self.selectionRectView;
    }
    return hitView;
}

@end
