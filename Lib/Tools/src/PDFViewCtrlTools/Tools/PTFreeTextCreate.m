//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTFreeTextCreate.h"

#import "PTPanTool.h"
#import "PTColorDefaults.h"
#import "CGGeometry+PTAdditions.h"
#import "PTFreeTextInputAccessoryView.h"

#import "PTToolsUtil.h"

static const CGFloat PTFreeTextDragThreshold = 10.0;

@interface PTVectorLabel : UILabel
{
    
}

@property (nonatomic) int layersDrawn;

@end

@implementation PTVectorLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _layersDrawn = 0;
    }
    return self;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if( self.layersDrawn == 1 )
    {
        BOOL isPDF = !CGRectIsEmpty(UIGraphicsGetPDFContextBounds());
        if (!layer.shouldRasterize && isPDF)
            [self drawRect:self.bounds]; // draw unrasterized
        else
            [super drawLayer:layer inContext:ctx];
    }

    self.layersDrawn++;
}

@end

@interface PTFreeTextCreate () <UIGestureRecognizerDelegate>
{
    CGPoint firstTouchPoint;
    CGPoint startPoint;
    CGPoint endPoint;
    UITextView* _textView;
    UIScrollView* sv;
    BOOL wroteAnnot;
    BOOL created;
    BOOL keyboardOnScreen;
}

@property (assign, nonatomic) BOOL isDrag;

@property (strong, nonatomic) NSDate* touchesEndedTime;

@property (nonatomic, strong) PTPDFRect* writeRect;
@property (nonatomic, strong) PTPage* writePage;
/**
 * Defines if the text box should orient itself for right-to-left language input.
 * Switches based on language that is first used when creating the annotation
 */
@property (assign, nonatomic) BOOL isRTL;

@property (nonatomic, assign) BOOL isPencilTouch;

+(void)refreshAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc;

// path 2, creation: look at page and viewer rotation, set annot rotate flag
+(void)createAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc withViewerRotation:(PTRotate)rotation;


+(void)createAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc withViewerRotation:(PTRotate)rotation newAnnot:(BOOL)newAnnot;

@end

@implementation PTFreeTextCreate


- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl*)in_pdfViewCtrl
{
    
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
		self.backgroundColor = [UIColor clearColor];
        
        self.isRTL = false;
        
        _isPencilTouch = YES;
        
        // use a temporary textView to see if the user is about to write in a RTL or LTR language
        UITextView* textView = [[UITextView alloc] initWithFrame:CGRectZero];
        [in_pdfViewCtrl addSubview:textView];
        [textView becomeFirstResponder];


        if( [NSLocale characterDirectionForLanguage:[textView textInputMode].primaryLanguage] == NSLocaleLanguageDirectionRightToLeft)
        {
            self.isRTL = true;
        }
        
        [textView resignFirstResponder];
        
        [textView removeFromSuperview];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector (UITextInputCurrentInputModeDidChangeNotification:)
                                                     name: UITextInputCurrentInputModeDidChangeNotification object:nil];
        
    }
    
    return self;
}

-(void)setToolManager:(PTToolManager *)toolManager
{
    [super setToolManager:toolManager];
    
    self.pdfViewCtrl.minimumTwoFingersToScrollEnabled = !self.toolManager.annotationsCreatedWithPencilOnly;
}

-(Class)annotClass
{
    return [PTFreeText class];
}

+(PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypeFreeText;
}

+ (BOOL)canEditStyle
{
    return YES;
}

+(BOOL)createsAnnotation
{
	return YES;
}

- (NSUndoManager *)undoManager
{
    return self.textView.undoManager;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)UITextInputCurrentInputModeDidChangeNotification:(NSNotification*)notification
{
    if( self.textView.text.length == 0 )
    {
        
        bool prior = self.isRTL;
        
        if( [NSLocale characterDirectionForLanguage:[self.textView textInputMode].primaryLanguage] == NSLocaleLanguageDirectionRightToLeft)
        {
            self.isRTL = true;
        }
        else
        {
            self.isRTL = false;
        }
        
        if( prior != self.isRTL )
        {
            [self setTextAreaFrame];
        }
    }
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
    }
    return _textView;
}

-(void)setUpTextEntry
{
	PTColorPostProcessMode mode = [self.pdfViewCtrl GetColorPostProcessMode];
        
    sv = [[UIScrollView alloc] init];
    
    self.textView.contentInset = UIEdgeInsetsMake(3, 0, 0, 0);
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = 0;
    
//  Border should hug text
//    textView.layer.borderWidth = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];
//    PTColorPt* strokeColor = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:e_ptpostprocess_none];
//    UIColor* borderColor = [PTColorDefaults uiColorFromColorPt:strokeColor compNum:[PTColorDefaults numCompsInColorPtForAnnotType:PTExtendedAnnotTypeFreeText attribute:ATTRIBUTE_STROKE_COLOR]];
//    textView.layer.borderColor = borderColor.CGColor;
    
    
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [sv addSubview:self.textView];
    [self addSubview:sv];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillShow:)
                                                 name: UIKeyboardWillShowNotification object:nil];
    
    sv.backgroundColor = [UIColor clearColor];
	
    self.userInteractionEnabled = YES;
    sv.userInteractionEnabled = YES;
    self.textView.userInteractionEnabled = YES;
    self.textView.delegate = self;
    self.textView.textColor = [PTColorDefaults defaultColorForAnnotType:self.annotType attribute:ATTRIBUTE_TEXT_COLOR colorPostProcessMode:mode];

    self.textView.font = [UIFont fontWithName:[PTColorDefaults defaultFreeTextFontName] size:[PTColorDefaults defaultFreeTextSize]*[self.pdfViewCtrl GetZoom]];
    self.textView.backgroundColor = [UIColor clearColor];

	// one day add background colour to live editing too?
	//http://stackoverflow.com/questions/15438869/uitextview-text-background-colour
	
    created = NO;
    
    wroteAnnot = NO;

    return;
}

+(void)setRectForFreeText:(PTFreeText*)freeText withRect:(PTPDFRect*)rect pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl isRTL:(BOOL)isRTL
{
    // Get the annotation's content stream
    PTObj* contentStream = [[[freeText GetSDFObj] FindObj:@"AP"] FindObj:@"N"];
    
    if( !contentStream )
    {
        // unexpected failure
        // bbox will not be tight
        return;
    }
    
    // use element reader to iterate through elements and union their bounding boxes
    PTElementReader* er = [[PTElementReader alloc] init];
    
    PTObj* dict = [[PTObj alloc] init];
    
    PTContext* context = [[PTContext alloc] init];
    
    [er ReaderBeginWithSDFObj:contentStream resource_dict:dict ocg_context:context];
    
    PTElement *element;
    
    PTPDFRect* unionRect = 0;
    
    for (element=[er Next]; element != NULL; element = [er Next])
    {
        PTPDFRect* elementRect = [element GetBBox];
        
        if([element GetType] == e_pttext_obj)
        {
            if( [elementRect Width] && [elementRect Height] )
            {
                if( unionRect == 0 )
                    unionRect = elementRect;
                unionRect = [PTTool GetRectUnion:unionRect Rect2:elementRect];
            }
        }
        
    }
    
    double width = fabs([unionRect GetX2] - [unionRect GetX1])+10;
    double height = fabs([unionRect GetY2] - [unionRect GetY1])+10;
    
    PTRotate ctrlRotation = [pdfViewCtrl GetRotation];
    PTRotate pageRotation = [[freeText GetPage] GetRotation];
    int annotRotation = ((pageRotation + ctrlRotation) % 4) * 90;

    if(  !isRTL )
    {
        if (ctrlRotation == e_pt90 || ctrlRotation == e_pt270) {
            // Swap width and height if pdfViewCtrl is rotated 90 or 270 degrees
            width = width + height;
            height = width - height;
            width = width - height;
        }

        [unionRect SetX1:[rect GetX1]];
        [unionRect SetY1:[rect GetY1]];
        
        if( annotRotation == 0 )
        {
            [unionRect SetX2:[rect GetX1]+width];
            [unionRect SetY2:[rect GetY1]-height];
        }
        else if( annotRotation == 90 )
        {
            [unionRect SetX2:[rect GetX1]+width];
            [unionRect SetY2:[rect GetY1]+height];
        }
        else if(annotRotation == 180)
        {
            [unionRect SetX2:[rect GetX1]-width];
            [unionRect SetY2:[rect GetY1]+height];
        }
        else if(annotRotation == 270)
        {
            [unionRect SetX2:[rect GetX1]-width];
            [unionRect SetY2:[rect GetY1]-height];
        }
        
        
        
    }
    else
    {
        const int rightAligned = 2;
        
        [freeText SetQuaddingFormat:rightAligned];
        if (pageRotation == e_pt90 || pageRotation == e_pt270) {
            // Swap width and height if page is rotated 90 or 270 degrees
            width = width + height;
            height = width - height;
            width = width - height;
        }

        if( annotRotation == 0 )
        {
            [unionRect SetX1:[rect GetX2]-width];
            [unionRect SetY1:[rect GetY1]-height];
            
            [unionRect SetX2:[rect GetX2]];
            [unionRect SetY2:[rect GetY1]];
        }
        else if( annotRotation == 90 )
        {
            
            [unionRect SetX1:[rect GetX1]];
            [unionRect SetY1:[rect GetY2]-width];
            
            [unionRect SetX2:[rect GetX1]+height];
            [unionRect SetY2:[rect GetY2]];
            
        }
        else if( annotRotation == 180 )
        {
            [unionRect SetX1:[rect GetX2]+width];
            [unionRect SetY1:[rect GetY1]+height];
            
            [unionRect SetX2:[rect GetX2]];
            [unionRect SetY2:[rect GetY1]];
        }
        else if( annotRotation == 270 )
        {
            [unionRect SetX1:[rect GetX1]-height];
            [unionRect SetY1:[rect GetY2]];
            
            [unionRect SetX2:[rect GetX1]];
            [unionRect SetY2:[rect GetY2]+width];
        }
        
        
    }
    
    if( unionRect )
    {
        [unionRect Normalize];
        [freeText Resize:unionRect];
    }else{
        [rect Normalize];
        [freeText Resize:rect];
    }
    
    [freeText SetRotation:annotRotation];
}

-(BOOL)setTextAreaFrame
{
    startPoint = self.longPressPoint;
    
    int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:startPoint.x y:startPoint.y];
	
    if (pageNumber < 1 )
      return NO;

    assert(startPoint.x > 0);
    assert(startPoint.y > 0);
	
    PTPDFRect* testRect = [[[self.pdfViewCtrl GetDoc] GetPage:pageNumber] GetCropBox];
	
    CGFloat cbx1 = [testRect GetX1];
    CGFloat cbx2 = [testRect GetX2];
    CGFloat cby1 = [testRect GetY1];
    CGFloat cby2 = [testRect GetY2];
	
    CGFloat pageLeft;
    CGFloat pageTop;
	
    [self ConvertPagePtToScreenPtX:&cbx1 Y:&cby1 PageNumber:pageNumber];
    [self ConvertPagePtToScreenPtX:&cbx2 Y:&cby2 PageNumber:pageNumber];
    
    //double thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];
    double offset;// = thickness * [self.pdfViewCtrl GetZoom];
    offset = 0;
    
    if( self.isRTL == false )
    {
        pageLeft = MIN(cbx1, cbx2);
        pageTop =  MIN(cby1, cby2);
        endPoint.x = MAX(cbx1, cbx2);
        endPoint.y = MAX(cby1, cby2);
        
        startPoint.x = MAX(pageLeft, startPoint.x-offset);
        startPoint.y = MAX(pageTop, startPoint.y-offset);
    }
    else
    {
        pageLeft = MIN(cbx1, cbx2);
        pageTop =  MIN(cby1, cby2);
        
        endPoint.x = startPoint.x+offset;
        endPoint.y = MAX(cby1, cby2);
        
        startPoint.x = pageLeft;
        startPoint.y = MAX(pageTop, startPoint.y+offset);
        
    }
	
	
	self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos]+startPoint.x, [self.pdfViewCtrl GetVScrollPos]+startPoint.y, fabs(endPoint.x-startPoint.x), fabs(endPoint.y-startPoint.y));

	return YES;
}

-(void)activateTextEntry
{
    assert([NSThread isMainThread]);
    
    CGRect cursorRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];
    double thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType] * [self.pdfViewCtrl GetZoom];
    double inset = thickness*2;
    double topOffset = self.textView.font.lineHeight-self.textView.font.pointSize;
    self.textView.textContainerInset = UIEdgeInsetsMake(inset-topOffset, inset, inset, inset);
    //Move and resize the frame by the width of the border (and the additional padding inside the border)
    sv.frame = CGRectMake(-inset, -inset-cursorRect.size.height/2, self.frame.size.width-inset, self.frame.size.height-inset-cursorRect.size.height/2);
    self.textView.frame = CGRectMake(0, 0, sv.frame.size.width, sv.frame.size.height);
    if (self.toolManager.freeTextAnnotationOptions.inputAccessoryViewEnabled) {
        PTFreeTextInputAccessoryView *freeTextAccessory = [[PTFreeTextInputAccessoryView allocOverridden] initWithToolManager:self.toolManager textView:self.textView];
        self.textView.inputAccessoryView = freeTextAccessory;
    }
    
    if ([self.textView canBecomeFirstResponder]) {

        
        [self.textView becomeFirstResponder];

    }
    
    created = YES;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTap:)];
    tgr.delegate = self;
    
    NSUInteger numTaps = 1;
    
    tgr.numberOfTapsRequired = numTaps;
    
    [tgr setCancelsTouchesInView:YES];
    [tgr setDelaysTouchesEnded:NO];
    
    [self.textView addGestureRecognizer:tgr];
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    [self.pdfViewCtrl DocLock:YES];
    
    @try {
        int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:startPoint.x y:startPoint.y];
        
        if (pageNumber < 1)
            pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:endPoint.x y:endPoint.y];
        
        if (pageNumber < 1)
        {
            self.nextToolType = [PTPanTool class];
            
            return;
        }
        
        self.annotationPageNumber = pageNumber;
        
        self.writePage = [doc GetPage:pageNumber];

        
    }
    @catch (NSException *exception) {
        NSLog(@"activateTextEntry Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
}

- (PTFreeText *)createFreeText
{
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    return [PTFreeText Create:[doc GetSDFDoc] pos:self.writeRect];
}



// path 1, resize: only look at annot rotation flag
+(void)refreshAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc
{
    [PTFreeTextCreate createAppearanceForAnnot:freeText onDoc:doc withViewerRotation:0 newAnnot:NO];
}

// path 2, creation: look at page and viewer rotation, set annot rotate flag
+(void)createAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc withViewerRotation:(PTRotate)rotation
{
    [PTFreeTextCreate createAppearanceForAnnot:freeText onDoc:doc withViewerRotation:rotation newAnnot:YES];
}


+(void)createAppearanceForAnnot:(PTFreeText*)freeText onDoc:(PTPDFDoc*)doc withViewerRotation:(PTRotate)rotation newAnnot:(BOOL)newAnnot
{

   // needed for small (< 12pt) font sizes to be rendered properly
    const int magicNumberScale = 20;
    
    BOOL shouldUnlock = NO;
    @try {
        [doc Lock];
        shouldUnlock = YES;
        if (@available(iOS 12.0, *)) {
            CGRect tightTextSize;

            // this is the view that's the size of the text annot's rect
            UIView* containerView = [[UIView alloc] init];
            
            PTPDFRect* rect = [freeText GetRect];
            double width = [rect Width];
            double height = [rect Height];
            
            // will be zero if no page
            PTRotate pageRrotation = [[freeText GetPage] GetRotation];
            PTRotate viewerRotation = rotation;
            int annotationRotationDegrees = 0;
            
            if( !newAnnot )
            {
                annotationRotationDegrees = [freeText GetRotation];
            }
            
            if( annotationRotationDegrees % 90 != 0 )
            {
                annotationRotationDegrees = 0;
            }
            
            PTRotate annotationRotation;
            
            switch (annotationRotationDegrees) {
                case 90:
                    annotationRotation = e_pt90;
                    break;
                case 180:
                    annotationRotation = e_pt180;
                    break;
                case 270:
                    annotationRotation = e_pt270;
                    break;
                default:
                    annotationRotation = e_pt0;
                    break;
            }
            
            PTRotate effectiveRotation;
            
            if( newAnnot == YES )
            {
                effectiveRotation = (pageRrotation + viewerRotation + annotationRotation ) % 4;
            }
            else
            {
                effectiveRotation = annotationRotation;
            }
                
            if( effectiveRotation == e_pt90 || effectiveRotation == e_pt270 )
            {
                double temp = width;
                width = height;
                height = temp;
            }
            
            
            containerView.frame = CGRectMake(0, 0, width*magicNumberScale, height*magicNumberScale);
                    
            // This is the view that's the size of the actual text
            // UILabels and not UITextViews can render text as vector into a PDF context
            PTVectorLabel* vectorLabel;
            
            PTBorderStyle *borderStyle = [freeText GetBorderStyle];
            CGRect vectorLabelFrame = CGRectMake(0, 0, containerView.bounds.size.width-[borderStyle GetWidth]*magicNumberScale*2, containerView.bounds.size.height-[borderStyle GetWidth]*magicNumberScale*2);
            
            
            vectorLabel = [[PTVectorLabel alloc] initWithFrame:vectorLabelFrame];
            vectorLabel.numberOfLines = INT_MAX;
            vectorLabel.allowsDefaultTighteningForTruncation = NO;
            
            
            // copy over free text properties
            vectorLabel.alpha = [freeText GetOpacity];
            vectorLabel.text = [freeText GetContents];
            vectorLabel.textColor = [PTColorDefaults uiColorFromColorPt:[freeText GetTextColor]
                                                           compNum:[freeText GetTextColorCompNum]];
            int fontSize = [freeText GetFontSize]*magicNumberScale;
            NSString* fontName = [freeText getFontName];
            
            if( fontName == Nil )
            {
                fontName = @"Helvetica";
            }
            
            UIFont* font = [UIFont fontWithName:fontName size:fontSize];
            vectorLabel.font = font;
            
            int alignment = [freeText GetQuaddingFormat];
            
            if(alignment == 1 )
                vectorLabel.textAlignment = NSTextAlignmentCenter;
            else if(alignment == 2)
                vectorLabel.textAlignment = NSTextAlignmentRight;
            else
                vectorLabel.textAlignment = NSTextAlignmentLeft;

            NSDictionary *fontAttributes = @{
                NSFontAttributeName: vectorLabel.font
            };
            
            tightTextSize = [vectorLabel.text boundingRectWithSize:vectorLabel.frame.size
                 options:NSStringDrawingUsesLineFragmentOrigin
                 attributes:fontAttributes
                 context:nil];
            
            tightTextSize.size.width = MAX( tightTextSize.size.width, 30 );

            vectorLabel.frame = CGRectMake(0, 0, tightTextSize.size.width, tightTextSize.size.height);
            
            // copy free text border properties to the containing view
            UIColor* borderColor = [PTColorDefaults uiColorFromColorPt:[freeText GetLineColor]
                                                         compNum:[freeText GetLineColorCompNum]];

            
            containerView.layer.borderColor = [borderColor colorWithAlphaComponent:vectorLabel.alpha].CGColor;
            containerView.layer.borderWidth = [borderStyle GetWidth]*magicNumberScale;


            // add label to the enclosing rect
            [containerView addSubview:vectorLabel];
            
            UIColor* fillColor = [PTColorDefaults uiColorFromColorPt:[freeText GetColorAsRGB]
            compNum:[freeText GetColorCompNum]];
            
            containerView.backgroundColor = fillColor;
            
            // create separated PDFs from both
            PTPDFDoc* stampText = [PTToolsUtil createPTPDFDocFromFromUIView:vectorLabel];
            PTPDFDoc* fullAppearanceDoc = [PTToolsUtil createPTPDFDocFromFromUIView:containerView];
            
            // combine into a single PDF
            PTPage* pageOne = [stampText GetPage:1];
            PTStamper* stamper = [[PTStamper alloc] initWithSize_type:e_ptabsolute_size a:[pageOne GetPageWidth:e_ptmedia] b:[pageOne GetPageHeight:e_ptmedia]];
            
            [stamper SetAsAnnotation:NO];
            [stamper SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_top];
            [stamper SetPosition:[borderStyle GetWidth]*magicNumberScale vertical_distance:[borderStyle GetWidth]*magicNumberScale use_percentage:NO];
            
            PTPageSet* pageSet = [[PTPageSet alloc] initWithOne_page:1];
            
            [stamper StampPage:fullAppearanceDoc src_page:[stampText GetPage:1] dest_pages:pageSet];
            

            PTRotate rotate = effectiveRotation;
            
            if( rotate == e_pt90 )
            {
                rotate = e_pt270;
            }
            else if( rotate == e_pt270 )
            {
                rotate = e_pt90;
            }
            
            if( newAnnot )
            {
                [freeText SetRotation:effectiveRotation];
            }
            
            [[fullAppearanceDoc GetPage:1] SetRotation:rotate];
           
            
            PTPDFDoc* blankDoc = [[PTPDFDoc alloc] init];
            
            PTPage* blankPage = [blankDoc PageCreate:[[fullAppearanceDoc GetPage:1] GetVisibleContentBox]];
            
            
            [blankDoc PagePushBack:blankPage];
            
            PTStamper* stamper2 = [[PTStamper alloc] initWithSize_type:e_ptabsolute_size a:[blankPage GetPageWidth:e_ptmedia] b:[blankPage GetPageHeight:e_ptmedia]];
            [stamper2 SetAsAnnotation:YES];
            [stamper2 SetAlignment:e_pthorizontal_left vertical_alignment:e_ptvertical_top];
            
            [stamper2 StampPage:blankDoc src_page:[fullAppearanceDoc GetPage:1] dest_pages:pageSet];
            
            PTAnnot* annot = [[blankDoc GetPage:1] GetAnnot:0];
            
            PTObj* app = [annot GetAppearance:e_ptnormal app_state:0];
            
                    
            PTObj *destAnnotObj = [[doc GetSDFDoc] ImportObj:app deep_copy:YES];
            
            
            //Set the free text appearance to the combined PDFs
            [freeText SetAppearance:destAnnotObj annot_state:e_ptnormal app_state:0];
        }
        else
        {
            [freeText RefreshAppearance];
        }
        

        

    } @catch (NSException *exception) {
        
    } @finally {
        if (shouldUnlock) {
            [doc Unlock];
        }
    }
    
    
}

- (void)commitAnnotation
{
    if(wroteAnnot || !self.textView || [self.textView.text isEqualToString:@""])
        return;
    
    PTFreeText* annotation;
	    
    @try
    {
        [self.pdfViewCtrl DocLock:YES];
        
        
        CGRect tightTextSize = [self.textView.text boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, self.textView.frame.size.height)
           options:NSStringDrawingUsesLineFragmentOrigin
        attributes:self.textView.typingAttributes
           context:nil];
        
        CGRect screenRect = [self.pdfViewCtrl convertRect:self.textView.frame fromView:self.textView.superview];
        
        CGFloat x1 = screenRect.origin.x;
        CGFloat y1 = screenRect.origin.y;
        CGFloat x2 = screenRect.origin.x+tightTextSize.size.width+4;
        CGFloat y2 = screenRect.origin.y+tightTextSize.size.height;
        
        [self ConvertScreenPtToPagePtX:&x1 Y:&y1 PageNumber:self.annotationPageNumber];
        [self ConvertScreenPtToPagePtX:&x2 Y:&y2 PageNumber:self.annotationPageNumber];
        
        self.writeRect = [[PTPDFRect alloc] initWithX1:x1 y1:y1 x2:x2 y2:y2];

        // Create a new PTFreeText annotation.
        annotation = [self createFreeText];
		
		[annotation SetFontSize:[PTColorDefaults defaultFreeTextSize]];

        [annotation SetContents:self.textView.text];
        
        [annotation setFontWithName:[PTColorDefaults defaultFreeTextFontName] pdfDoc:[self.pdfViewCtrl GetDoc]];
		
		if (self.annotationAuthor.length > 0) {
			[annotation SetTitle:self.annotationAuthor];
		}
        
        // Apply annotation colors, border, etc.
        [self setPropertiesForFreeText:annotation];
        
        // push back annotation now in case of rotated page
        [self.writePage AnnotPushBack:annotation];
        
        
        if (self.annotType == PTExtendedAnnotTypeFreeText) {
            
            [PTFreeTextCreate createAppearanceForAnnot:annotation onDoc:[self.pdfViewCtrl GetDoc] withViewerRotation:[self.pdfViewCtrl GetRotation]];
        } else {
            // Callout, etc.
            [annotation RefreshAppearance];
            [self setRectForFreeText:annotation];
        }
        
        
        wroteAnnot = YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlock];
    }
    
    if( self.annotationPageNumber > 0 ) {
        [self.pdfViewCtrl UpdateWithAnnot:annotation page_num:self.annotationPageNumber];
    }
    
	[self annotationAdded:annotation onPageNumber:self.annotationPageNumber];
    
    [self.textView removeFromSuperview];
    self.textView = nil;
    [sv removeFromSuperview];
    sv = nil;
}

- (void)setRectForFreeText:(PTFreeText *)freeText
{
    [PTFreeTextCreate setRectForFreeText:freeText
                                withRect:self.writeRect
                             pdfViewCtrl:self.pdfViewCtrl
                                   isRTL:self.isRTL];
}

- (void)setPropertiesForFreeText:(PTFreeText *)freeText
{
    // write text colour
    PTColorPt* cp = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_TEXT_COLOR  colorPostProcessMode:e_ptpostprocess_none];
    int numCompsText = [PTColorDefaults numCompsInColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_TEXT_COLOR];
    
    if( numCompsText > 0 ) {
        [freeText SetTextColor:cp col_comp:3];
    } else {
        [freeText SetTextColor:cp col_comp:0];
    }
    
    PTColorPt* strokeColor = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR colorPostProcessMode:e_ptpostprocess_none];
    int numCompsStroke = [PTColorDefaults numCompsInColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_STROKE_COLOR];
    [freeText SetLineColor:strokeColor col_comp:numCompsStroke];
    
    // write border colour
    double thickness = [PTColorDefaults defaultBorderThicknessForAnnotType:self.annotType];
    PTBorderStyle* bs = [freeText GetBorderStyle];
    
    
    if(numCompsStroke == 0){
        thickness = 0.0;
    }
    
    [bs SetWidth:thickness];
    [freeText SetBorderStyle:bs oldStyleOnly:NO];

    // write fill colour
    int numCompsFill = [PTColorDefaults numCompsInColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_FILL_COLOR];
    cp = [PTColorDefaults defaultColorPtForAnnotType:self.annotType attribute:ATTRIBUTE_FILL_COLOR colorPostProcessMode:e_ptpostprocess_none];
    
    if( numCompsFill > 0 ) {
        [freeText SetColor:cp numcomp:3];
    } else {
        [freeText SetColor:cp numcomp:0];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	self.isDrag = NO;
    [self commitAnnotation];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    CGRect cursorRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];
    CGRect cursorScreenRect = [self.pdfViewCtrl convertRect:cursorRect fromView:self.textView];
    cursorScreenRect.origin.x += [self.pdfViewCtrl GetHScrollPos];
    cursorScreenRect.origin.y += [self.pdfViewCtrl GetVScrollPos];

    CGFloat topEdge = 0.0;
    if (@available(iOS 11.0, *)) {
        topEdge = self.pdfViewCtrl.safeAreaInsets.top;
    }
    
    [self.pdfViewCtrl keyboardWillShow:notification rectToNotOverlapWith:cursorScreenRect topEdge:topEdge];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector (keyboardWillHide:)
                                                 name: UIKeyboardWillHideNotification object:nil];

    keyboardOnScreen = true;
}

- (BOOL)onSwitchToolEvent:(id)userData
{
	NSString* start = (NSString*)userData;
    if( userData && ((![start isEqualToString:@"Start"] && self.backToPanToolAfterUse) || (self.backToPanToolAfterUse && [start isEqualToString:@"BackToPan"])))
    {
        self.nextToolType = [PTPanTool class];
        return NO;
    }
	else if( [start isEqualToString:@"BackToPan"] && !self.backToPanToolAfterUse )
	{
		self.nextToolType = [self class];
		return YES;
    }
    else if( [start isEqualToString:@"CloseAnnotationToolbar"] && !self.backToPanToolAfterUse )
    {
        return NO;
    }
    else
    {
        created = NO;

		startPoint = self.longPressPoint;

		[self setTextAreaFrame];
        [self setUpTextEntry];
		[self activateTextEntry];

        return YES;
    }
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    
    created = NO;
    
	[self.pdfViewCtrl keyboardWillHide:notification];
    
    keyboardOnScreen = false;

    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
	[self.toolManager createSwitchToolEvent:@"BackToPan"];
}

-(BOOL)createEntryAtPoint:(CGPoint)point
{
    assert([NSThread isMainThread]);
	[self.superview bringSubviewToFront:self];
	startPoint = point;
    self.longPressPoint = point;
	BOOL couldSetFrame = [self setTextAreaFrame];
	
	if( !couldSetFrame )
	{
		self.nextToolType = [PTPanTool class];
        return NO;
	}
	else
	{
		if( self.textView == 0 || sv == 0 )
			[self setUpTextEntry];
		
		[self activateTextEntry];
        
        return YES;
	}
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl handleTap:(UITapGestureRecognizer *)sender
{
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
    if( created == NO )
    {
        self.isDrag = NO;
        [self createEntryAtPoint:[sender locationOfTouch:0 inView:self.pdfViewCtrl]];
	
        return YES;
    }
    else
    {
        if( self.textView != nil )
		{
            // UI gesture recognizer may also come in after the touches ended. This is to prevent
            // one from firing after the other, causing the keyboard to popup and then immediately
            // dismiss.
            if( self.isDrag && [[NSDate date] timeIntervalSinceDate:self.touchesEndedTime] < 0.85 )
                return YES;

            [self.textView resignFirstResponder];
            self.frame = CGRectZero;
            
		}
		
		if( self.backToPanToolAfterUse )
		{
            self.nextToolType = [self.defaultClass class];
			return NO;
		}
		else
		{
			created = NO;
			return YES;
		}
    }
}


- (void)textTap:(UITapGestureRecognizer *)gestureRecognizer { 

	CGSize textSize = [self.textView.text boundingRectWithSize:self.textView.bounds.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{ NSFontAttributeName : [UIFont fontWithName:self.textView.font.fontName size:[PTColorDefaults defaultFreeTextSize]*[self.pdfViewCtrl GetZoom]] } context:nil].size;
	
    CGPoint down = [gestureRecognizer locationInView:self.textView];
    
    // 6 for textview inset
    if (down.x-6 < textSize.width && down.y-6 < textSize.height) {
        // tap was on text so ignore
    }
    else
    {
        // tap was outside of text, dismiss textview and commit annotation
        [self pdfViewCtrl:self.pdfViewCtrl handleTap:gestureRecognizer];
    }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // required for the textview gesture recognizer to fire
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        return !self.isPencilTouch;
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
    UITouch *touch = touches.allObjects[0];
    firstTouchPoint = [touch locationInView:self.pdfViewCtrl];
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
    UITouch *touch = touches.allObjects[0];
    CGPoint down = [touch locationInView:self.pdfViewCtrl];
    // Only classify touch as a drag if the touch point is over a certain distance threshold from the initial touch point
    self.isDrag = PTCGPointDistanceToPoint(down, firstTouchPoint) > PTFreeTextDragThreshold;
    self.touchesEndedTime = [NSDate date];
    return YES;
}


- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if( self.toolManager.annotationsCreatedWithPencilOnly && self.isPencilTouch == NO )
    {
        return YES;
    }
    
	if( !self.isDrag )
    {
		return YES;
    }
	
    UITouch *touch = touches.allObjects[0];

    
	if( created == NO )
    {
        [self createEntryAtPoint:[touch locationInView:self.pdfViewCtrl]];
    }

    created = YES;

    if( self.backToPanToolAfterUse )
    {
        self.nextToolType = [PTPanTool class];
        return NO;
    }
    else
        return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL ret = [super pdfViewCtrl:pdfViewCtrl touchesShouldBegin:touches withEvent:event inContentView:view];

    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }

    return ret;

}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        return !self.isPencilTouch;
    }
    
    return YES;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl pdfScrollViewWillBeginZooming:(nonnull UIScrollView *)scrollView withView:(nullable UIView *)view
{
    [self commitAnnotation];
}

@end
