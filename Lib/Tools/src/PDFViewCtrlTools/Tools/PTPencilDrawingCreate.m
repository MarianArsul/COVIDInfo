//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPencilDrawingCreate.h"
#import "PTDocumentBaseViewController.h"
#import "PTPanTool.h"
#import "PTTimer.h"
#import "CGGeometry+PTAdditions.h"
#import "PTAnnotStyleDraw.h"
#import <PencilKit/PencilKit.h>
#import "PTCanvasView.h"

#import "UIView+PTAdditions.h"

static const NSTimeInterval PTPencilDrawingCreateStylusAppendInterval = 1.0; // seconds
static const CGFloat PTPencilDrawingCreateStylusAppendDistance = 200; // points in page space
static const CGFloat PTPencilDrawingCreateImageScale = 3.0;

@interface PTPencilDrawingCreate () <PKCanvasViewDelegate, PKToolPickerObserver, UIScreenshotServiceDelegate, UIGestureRecognizerDelegate>
{
    int m_startPageNum;
    double drawnZoom;
    PTTimer *stylusAppendTimeout;
    BOOL editing;
    PTAnnot *annotation;
    PTPDFRect *drawingPageRect;
    CGRect preZoomFrame;
    CGPoint canvasOffset;
    NSUInteger touchCount;
    BOOL canvasShouldReceiveTouches;
}

@property (nonatomic) PTCanvasView *canvasView;
@property (nonatomic) PKToolPicker *toolPicker;
@property (nonatomic) UIImageView *annotSnapshot;
@property (nonatomic, assign) BOOL isPencilTouch;
@property (nonatomic, assign) BOOL commitAnnotationOnToolChange;

@end
    
@implementation PTPencilDrawingCreate

@dynamic isPencilTouch;

- (instancetype)initWithPDFViewCtrl:(PTPDFViewCtrl *)in_pdfViewCtrl
{
    self = [super initWithPDFViewCtrl:in_pdfViewCtrl];
    if (self) {
        
        self.opaque = NO;
        _commitAnnotationOnToolChange = YES;
        m_startPageNum = 0; // non-existent page in PDF
        _pageNumber = self.pdfViewCtrl.GetCurrentPage;
        
        self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
        
        _canvasView = [[PTCanvasView alloc] initWithFrame:self.bounds];
        _canvasView.delegate = self;
        _canvasView.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        [self addSubview:_canvasView];

        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            m_startPageNum = _pageNumber;
            [self.canvasView setHidden:NO];
            PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:_pageNumber];
            CGFloat minX = [page_rect GetX1];
            CGFloat maxX = [page_rect GetX2];
            CGFloat minY = [page_rect GetY1];
            CGFloat maxY = [page_rect GetY2];
            CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);
            self.canvasView.contentSize = pageFrame.size;
            self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);
        }

        _toolPicker = [PKToolPicker sharedToolPickerForWindow:self.pt_viewController.view.window];
        _toolPicker.colorUserInterfaceStyle = UIUserInterfaceStyleLight;
        [_toolPicker setVisible:self.shouldShowToolPicker forFirstResponder:_canvasView];
        [_toolPicker addObserver:_canvasView];
        [_toolPicker addObserver:self];
        [_toolPicker setRulerActive:NO];
        if ([self.pdfViewCtrl.toolDelegate isKindOfClass:[PTToolManager class]]) {
            PTPencilInteractionMode mode = ((PTToolManager*)self.pdfViewCtrl.toolDelegate).pencilInteractionMode;
            if (@available(iOS 14.0, *)) {

                
                if (mode == PTPencilInteractionModeFingerAndPencil || self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                {
                    _canvasView.drawingPolicy = PKCanvasViewDrawingPolicyAnyInput;
                }
                else if(mode == PTPencilInteractionModePencilOnly)
                {
                    _canvasView.drawingPolicy = PKCanvasViewDrawingPolicyPencilOnly;
                }
                else
                {
                    _canvasView.drawingPolicy = UIPencilInteraction.prefersPencilOnlyDrawing ? PKCanvasViewDrawingPolicyPencilOnly : PKCanvasViewDrawingPolicyAnyInput;
                }

            }else{
                _canvasView.allowsFingerDrawing = !((PTToolManager*)self.pdfViewCtrl.toolDelegate).annotationsCreatedWithPencilOnly;
            }
        }else{
            _canvasView.allowsFingerDrawing = YES;
        }
        [_canvasView setOpaque:NO];
        [_canvasView becomeFirstResponder];
        _canvasView.scrollEnabled = NO;
        _canvasView.drawingGestureRecognizer.delegate = self;
        editing = NO;
    }
    return self;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Ignore
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // Ignore
    return YES;
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidScroll:(UIScrollView *)scrollView
{
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    self.canvasView.contentSize = pageFrame.size;
    self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    // Prevent the pdfViewCtrl zoom from moving the tool's frame by recording its frame initially
    preZoomFrame = self.frame;
    return [super pdfViewCtrl:pdfViewCtrl pdfScrollViewWillBeginZooming:scrollView withView:view];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pdfScrollViewDidZoom:(UIScrollView *)scrollView
{
    // do not call super
    // Set the tool's frame back to what it was before the zoom
    self.frame = preZoomFrame;
}

- (void)setShouldShowToolPicker:(BOOL)shouldShowToolPicker
{
    _shouldShowToolPicker = shouldShowToolPicker;
    [self.toolPicker setVisible:shouldShowToolPicker forFirstResponder:self.canvasView];
}

- (void)setBackToPanToolAfterUse:(BOOL)backToPanToolAfterUse
{
    [super setBackToPanToolAfterUse:backToPanToolAfterUse];
    [self setUserInteractionEnabled:!backToPanToolAfterUse];
}

-(Class)annotClass
{
    return [PTRubberStamp class];
}

+(PTExtendedAnnotType)annotType
{
    return PTExtendedAnnotTypePencilDrawing;
}

+(BOOL)createsAnnotation
{
    return YES;
}

- (BOOL)requiresEditSupport
{
    return editing || self.currentAnnotation;
}

- (BOOL)isUndoManagerEnabled
{
    return YES;
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == nil && self.commitAnnotationOnToolChange) {
        [self commitAnnotation];
    }
    [super willMoveToSuperview:newSuperview];
    self.allowZoom = YES;
    [self.pdfViewCtrl setScrollEnabled:YES];
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    
    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    if( self.toolManager.annotationsCreatedWithPencilOnly )
    {
        self.isPencilTouch = event.allTouches.allObjects.firstObject.type == UITouchTypePencil;
    }

    UITouch *touch = touches.allObjects[0];
    CGPoint touchPoint = [touch preciseLocationInView:self.pdfViewCtrl];
    int pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:touchPoint.x y:touchPoint.y];
    if (pageNumber != self.pageNumber && !editing) {
        // Move the canvas to touched page
        self.startPoint = touchPoint;
        [self commitAnnotation];
        _pageNumber = pageNumber;
        m_startPageNum = pageNumber;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.canvasView setDrawing:[[PKDrawing alloc] init]];
        });
        [self.canvasView setHidden:NO];
        PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:pageNumber];
        CGFloat minX = [page_rect GetX1];
        CGFloat maxX = [page_rect GetX2];
        CGFloat minY = [page_rect GetY1];
        CGFloat maxY = [page_rect GetY2];
        CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);
        self.canvasView.contentSize = pageFrame.size;
        self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);
        // Allow the canvas to receive the touches so that it can *immediately* start drawing.
        canvasShouldReceiveTouches = YES;
    }
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl touchesShouldCancelInContentView:(UIView *)view
{
    if( self.toolManager.annotationsCreatedWithPencilOnly && !self.isPencilTouch)
    {
        return YES;
    }
    if (canvasShouldReceiveTouches) {
        canvasShouldReceiveTouches = NO;
        return NO;
    }
    return (!self.backToPanToolAfterUse && !editing);
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( event.allTouches.allObjects.firstObject.type == UITouchTypePencil )
    {
        [self.toolManager promptForBluetoothPermission];
    }
    
    // Don't show tool picker if tool was activated by drawing on the doc
    [self.toolPicker setVisible:self.shouldShowToolPicker forFirstResponder:self.canvasView];
    if (self.annotSnapshot.superview) {
        [self.annotSnapshot removeFromSuperview];
        self.annotSnapshot = nil;
    }

    UITouch *touch = touches.allObjects[0];
    self.startPoint = [touch preciseLocationInView:self.pdfViewCtrl];
    _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x y:self.startPoint.y];
    CGPoint pageStartPoint = [self convertScreenPtToPagePt:self.startPoint onPageNumber:self.pageNumber];

    if (self.backToPanToolAfterUse) {
        if(touch.type == UITouchTypePencil){
            [stylusAppendTimeout invalidate];
        }else{
            if (!CGSizeEqualToSize(CGSizeZero, self.canvasView.drawing.bounds.size)) {
                [self commitAnnotation];
                return NO;
            }
        }
    }

    drawnZoom = pdfViewCtrl.zoom;
    if (self.pageNumber < 1){
        return YES;
    }

    if(CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)){
        m_startPageNum = self.pageNumber;
    }

    if (m_startPageNum > 0 && m_startPageNum != self.pageNumber ) {
        if (touch.type == UITouchTypePencil && self.backToPanToolAfterUse) { // If the pencil drawing is on another page, commit the existing annotation
            [self commitAnnotation];
            return NO;
        }
        return YES;
    }
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);

    self.canvasView.contentSize = pageFrame.size;
    self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);

    if (![self.canvasView.tool isKindOfClass:[PKInkingTool class]] && self.backToPanToolAfterUse && [[NSUserDefaults standardUserDefaults] valueForKey:@"pencilKitInkType"]) {
        PKInkingTool *inkingTool = [self loadInkToolFromUserDefaults];
        self.canvasView.tool = inkingTool;
    }

    // When activating tool with Pencil touch, group nearby (within 200 page points) strokes into one annotation. Otherwise make it a separate annotation.
    if (self.backToPanToolAfterUse && !CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)) {
        CGRect drawingScreenRect = [self convertRect:self.canvasView.drawing.bounds fromView:self.canvasView];
        PTPDFRect* radiusRect = [self.pdfViewCtrl CGRectScreen2PDFRectPage:drawingScreenRect PageNumber:self.pageNumber];
        [radiusRect SetX1:radiusRect.GetX1 - PTPencilDrawingCreateStylusAppendDistance];
        [radiusRect SetX2:radiusRect.GetX2 + PTPencilDrawingCreateStylusAppendDistance];
        [radiusRect SetY1:radiusRect.GetY1 - PTPencilDrawingCreateStylusAppendDistance];
        [radiusRect SetY2:radiusRect.GetY2 + PTPencilDrawingCreateStylusAppendDistance];
        BOOL continueAnnotation = pageStartPoint.x > radiusRect.GetX1 && pageStartPoint.x < radiusRect.GetX2 && pageStartPoint.y > radiusRect.GetY1 && pageStartPoint.y < radiusRect.GetY2;
        if (!continueAnnotation) {
            [self commitAnnotation];
            return NO;
        }
    }

    [self setUserInteractionEnabled:!self.backToPanToolAfterUse];
    [self.canvasView.drawingGestureRecognizer touchesBegan:touches withEvent:event];
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
   
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    
    UITouch *touch = touches.allObjects.firstObject;
    CGPoint location = [touch preciseLocationInView:self.pdfViewCtrl];

    CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    
    if (CGRectContainsPoint(pageFrame, location)) {
            [self.canvasView.drawingGestureRecognizer touchesMoved:touches withEvent:event];
    }
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.canvasView.drawingGestureRecognizer touchesEnded:touches withEvent:event];
    if (self.backToPanToolAfterUse) {
        [stylusAppendTimeout invalidate];
        stylusAppendTimeout = [PTTimer scheduledTimerWithTimeInterval:PTPencilDrawingCreateStylusAppendInterval target:self selector:@selector(endDrawing) userInfo:nil repeats:NO];
    }
    return YES;
}


-(void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl outerScrollViewDidScroll:(UIScrollView *)scrollView
{
    // do not call super.
}

-(void)saveInkToolToUserDefaults
{
    if ([self.canvasView.tool isKindOfClass:[PKInkingTool class]]) {
        PKInkingTool *inkTool = (PKInkingTool*)self.canvasView.tool;
        NSData *inkColor = [NSKeyedArchiver archivedDataWithRootObject:inkTool.color];
        [[NSUserDefaults standardUserDefaults] setObject:inkColor forKey:@"pencilKitInkColor"];
        [[NSUserDefaults standardUserDefaults] setValue:inkTool.inkType forKey:@"pencilKitInkType"];
        [[NSUserDefaults standardUserDefaults] setFloat:inkTool.width forKey:@"pencilKitInkWidth"];
    }
}

-(PKInkingTool*)loadInkToolFromUserDefaults
{
    NSString *inkType = [[NSUserDefaults standardUserDefaults] valueForKey:@"pencilKitInkType"];
    NSData *inkColorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"pencilKitInkColor"];
    UIColor *inkColor = [NSKeyedUnarchiver unarchiveObjectWithData:inkColorData];
    CGFloat inkWidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"pencilKitInkWidth"];
    return [[PKInkingTool alloc] initWithInkType:inkType color:inkColor width:inkWidth];
}

-(void)endDrawing
{
    [self commitAnnotation];
    [self.toolManager changeTool:[PTPanTool class]];
}

-(UIImage*)imageFromCanvas
{
    CGFloat scale = PTPencilDrawingCreateImageScale;
    
    return [self imageFromCanvasWithScale:scale];
}

-(UIImage*)imageFromCanvasWithScale:(CGFloat)scale
{
    __block UIImage *drawnImage;
    CGRect drawingRect = [self visibleDrawingRect];
    [self.canvasView.traitCollection performAsCurrentTraitCollection:^{
        drawnImage = [self.canvasView.drawing imageFromRect:drawingRect scale:scale];
    }];

    return drawnImage;
}

-(CGRect)visibleDrawingRect
{
    CGRect canvasScreen = CGRectMake(0, 0, self.canvasView.contentSize.width, self.canvasView.contentSize.height);
    if (CGRectIntersectsRect(canvasScreen, self.canvasView.drawing.bounds)) {
        return CGRectIntersection(canvasScreen, self.canvasView.drawing.bounds);
    }
    return self.canvasView.drawing.bounds;
}

-(PTImage*)ptImageFromUIImage:(UIImage*)image withDoc:(PTPDFDoc*)doc
{
    NSData *data = UIImagePNGRepresentation(image);
    PTObjSet* hintSet = [[PTObjSet alloc] init];
    PTObj* encoderHints = [hintSet CreateArray];

    NSString *compressionAlgorithm = @"Flate";
    NSInteger compressionQuality = 8;
    [encoderHints PushBackName:compressionAlgorithm];
    if ([compressionAlgorithm isEqualToString:@"Flate"]) {
        [encoderHints PushBackName:@"Level"];
        [encoderHints PushBackNumber:compressionQuality];
    }
    PTImage* stampImage = [PTImage CreateWithDataSimple:[doc GetSDFDoc] buf:data buf_size:data.length encoder_hints:encoderHints];
    return stampImage;
}

-(void)commitAnnotation
{
    self.commitAnnotationOnToolChange = NO;
    [stylusAppendTimeout invalidate];
    [self.toolPicker setRulerActive:NO];
    [self keepToolAppearanceOnScreen];
    if(editing){
        [self saveModifiedAnnotation];
        return;
    }

    if(CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)){
        return;
    }

    if( m_startPageNum > 0 )
    {
        if(!CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero))
        {
            [self.canvasView setHidden:YES]; // to prevent 'flash' due to blending with the PTToolView in [self keepToolAppearanceOnScreen]
            [self createStamp];
            return;
        }
    }
}

-(void)writeDrawingDataToAnnotation:(PTAnnot*)annot
{
    PTPage *page = [annot GetPage];
    PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
    PTRotate pageRotation = [page GetRotation];
    PTRotate stampRotation = ((pageRotation + ctrlRotation) % 4);

    NSData *drawingData = self.canvasView.drawing.dataRepresentation;
    NSString *dataString = [drawingData base64EncodedStringWithOptions:0];
    [annot SetCustomData:@"Zoom" value:[NSString stringWithFormat:@"%f",self.pdfViewCtrl.zoom]];
    [annot SetCustomData:@"StampRotation" value:[NSString stringWithFormat:@"%d",stampRotation]];
    [annot SetCustomData:PTPencilDrawingAnnotationIdentifier value:dataString];
}

-(void)setMultiplyBlendModeOnElement:(PTElement*)element API_AVAILABLE(ios(14.0)){
    BOOL isHighlight = YES;
    for (PKStroke *stroke in self.canvasView.drawing.strokes) {
        isHighlight = isHighlight && [stroke.ink.inkType isEqualToString:(NSString*)PKInkTypeMarker];
    }
    if (isHighlight) {
        [[element GetGState] SetBlendMode:e_ptbl_multiply];
    }
}

-(void)createStamp
{
    BOOL hasWriteLock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;

        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];

        PTPage* page = [doc GetPage:m_startPageNum];
        PTPDFRect *pageRect = drawingPageRect;
        PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
        PTRotate pageRotation = [page GetRotation];
        PTRotate stampRotation = ((pageRotation + ctrlRotation) % 4);

        UIImage *image = [self imageFromCanvas];
        PTImage* stampImage = [self ptImageFromUIImage:image withDoc:doc];

        PTMatrix2D* rotationMtx;
        CGSize size = CGSizeMake([stampImage GetImageWidth], [stampImage GetImageHeight]);
        if (stampRotation == e_pt90) {
            rotationMtx = [PTMatrix2D RotationMatrix:-M_PI_2];
            size = CGSizeMake(size.height, size.width);
        } else if (stampRotation == e_pt180) {
            size = CGSizeMake(size.height, size.width);
            rotationMtx = [PTMatrix2D RotationMatrix:M_PI];
        } else if (stampRotation == e_pt270) {
            size = CGSizeMake(size.height, size.width);
            rotationMtx = [PTMatrix2D RotationMatrix:M_PI_2];
        } else if (stampRotation == e_pt0) {
            rotationMtx = [PTMatrix2D IdentityMatrix];
        }

        PTElementWriter* writer = [[PTElementWriter alloc] init];
        PTElementBuilder* builder = [[PTElementBuilder alloc] init];

        [writer WriterBeginWithSDFDoc:[doc GetSDFDoc] compress:YES];
        PTElement* element = [builder CreateImageWithCornerAndScale:stampImage x:0 y:0 hscale:size.width vscale:size.height];
        PTMatrix2D *mtx = [[element GetGState] GetTransform];
        [mtx Multiply:rotationMtx];
        [[element GetGState] SetTransformWithMatrix:mtx];

        if (@available(iOS 14.0, *)) {
            if( self.toolManager.pencilHighlightMultiplyBlendModeEnabled ){
                [self setMultiplyBlendModeOnElement:element];
            }
        }

        [writer WritePlacedElement:element];

        PTObj *newApp = [writer End];
        PTPDFRect *bbox = [element GetBBox];
        [bbox Normalize];

        [newApp PutRect:@"BBox" x1:[bbox GetX1] y1:[bbox GetY1] x2:[bbox GetX2] y2:[bbox GetY2]];

        PTRubberStamp *annotation = [PTRubberStamp Create:[doc GetSDFDoc] pos:pageRect icon:e_ptr_Unknown];
        [annotation SetAppearance:newApp annot_state:e_ptnormal app_state:0];
        [super setPropertiesFromAnnotation: annotation];
        [page AnnotPushBack:annotation];
        [self writeDrawingDataToAnnotation:annotation];
        [annotation SetRect:pageRect];

        // Set up to transfer to PTAnnotEditTool
        self.currentAnnotation = annotation;
        self.annotationPageNumber = m_startPageNum;

        if( self.annotationAuthor && self.annotationAuthor.length > 0 )
        {
            [annotation SetTitle:self.annotationAuthor];
        }
        
        [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        [self.pdfViewCtrl RequestRendering];

    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (hasWriteLock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    if (self.currentAnnotation && self.annotationPageNumber > 0) {
        [self annotationAdded:self.currentAnnotation onPageNumber:self.annotationPageNumber];
    }
}

- (void)editAnnotation:(PTAnnot *)annot onPage:(int)pageNumber
{
    editing = YES;
    annotation = annot;
    self.currentAnnotation = annot;
    _pageNumber = pageNumber;
    self.annotationPageNumber = pageNumber;
    m_startPageNum = pageNumber;
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:pageNumber];
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    self.canvasView.contentSize = pageFrame.size;
    self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);

    PTObj* obj = [annot GetSDFObj];

    NSString *stringData = [annot GetCustomData:PTPencilDrawingAnnotationIdentifier];
    if (!stringData) {
        PTObj* drawingObj = [obj FindObj:PTPencilDrawingAnnotationIdentifier];
        stringData = [drawingObj GetAsPDFText];
    }
    NSData *drawingData = [[NSData alloc] initWithBase64EncodedString:stringData options:0];
    PKDrawing *drawing = [[PKDrawing alloc] initWithData:drawingData error:nil];

    CGRect annotScreenCGRect = [self PDFRectPage2CGRectScreen:[annot GetRect] PageNumber:pageNumber];
    CGVector offset = PTCGPointOffsetFromPoint(annotScreenCGRect.origin,pageFrame.origin);
    annotScreenCGRect.origin = PTCGVectorOffsetPoint(CGPointZero, offset);

    if (drawing != nil) {
        NSString *previousZoom = [annot GetCustomData:@"Zoom"];
        if (!previousZoom) {
            PTObj *zoomObj = [obj FindObj:@"Zoom"];
            previousZoom = [NSString stringWithFormat:@"%f",[zoomObj GetNumber]];
        }
        double zoom = [previousZoom doubleValue];
        double lastZoom = zoom;
        double currZoom = self.pdfViewCtrl.zoom;
        drawnZoom = currZoom;
        CGFloat scale = currZoom/lastZoom;
        CGAffineTransform transformToCanvas = CGAffineTransformMakeScale(scale, scale);

        drawing = [drawing drawingByApplyingTransform:transformToCanvas];
        PTPage *page = [annot GetPage];
        NSString *prevRotation = [annot GetCustomData:@"StampRotation"];
        if (!prevRotation) {
            PTObj *rotateObj = [obj FindObj:@"StampRotation"];
            prevRotation = [NSString stringWithFormat:@"%f",[rotateObj GetNumber]];
        }
        PTRotate prevStampRotation = (PTRotate)[prevRotation intValue];

        PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
        PTRotate pageRotation = [page GetRotation];
        PTRotate stampRotation = ((pageRotation + ctrlRotation) % 4);

        int diff = stampRotation-prevStampRotation;
        CGFloat rotation = diff*M_PI_2;
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(rotation);

        drawing = [drawing drawingByApplyingTransform:rotationTransform];
        self.canvasView.drawing = drawing;
        CGRect reconstructedRect = [self visibleDrawingRect];
        CGAffineTransform transformToAnnot = [PTPencilDrawingCreate transformFromRect:[self visibleDrawingRect] toRect:annotScreenCGRect];
        reconstructedRect = CGRectApplyAffineTransform(reconstructedRect, transformToAnnot);

        drawing = [drawing drawingByApplyingTransform:transformToAnnot];
        self.canvasView.drawing = drawing;
        
        CGAffineTransform transformToAnnotB = [PTPencilDrawingCreate transformFromRect:reconstructedRect toRect:annotScreenCGRect];
        drawing = [drawing drawingByApplyingTransform:transformToAnnotB];
        self.canvasView.drawing = drawing;

        //To prevent layer blending: take a snapshot of the annot's appearance and show it until the user starts drawing.
        float screenScale = [UIScreen mainScreen].scale;
        CGRect frame = [self convertRect:drawing.bounds fromView:self.canvasView];
        UIGraphicsBeginImageContextWithOptions(frame.size, false, screenScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-frame.origin.x, -frame.origin.y));
        [self.pdfViewCtrl.layer renderInContext:context];
        UIImage *annotImage = [PTAnnotStyleDraw getAnnotationAppearanceImage:[self.pdfViewCtrl GetDoc] withAnnot:annot onPageNumber:self.pageNumber withDPI:[self.pdfViewCtrl GetZoom]*72*[[UIScreen mainScreen] scale]  forViewerRotation:self.pdfViewCtrl.rotation];
        [annotImage drawInRect:frame];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        self.annotSnapshot = [[UIImageView alloc] initWithFrame:frame];
        self.annotSnapshot.image = viewImage;
        UIGraphicsEndImageContext();
        [self.canvasView setHidden:YES];
        [self addSubview:self.annotSnapshot];

        [self.pdfViewCtrl HideAnnotation:annot];
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            [self.pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumber];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        } @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }

        [self.canvasView becomeFirstResponder];
    }
}

- (void)saveModifiedAnnotation
{
    if (!editing) {
        return;
    }
    BOOL hasWriteLock = NO;
    @try {
        [self.pdfViewCtrl DocLock:YES];
        hasWriteLock = YES;
        PTPage* page = [annotation GetPage];
        if(CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)){
            if ([page IsValid] && [annotation IsValid]) {
                [self willRemoveAnnotation:annotation onPageNumber:m_startPageNum];
                [page AnnotRemoveWithAnnot:annotation];
                [self.pdfViewCtrl UpdateWithAnnot:annotation page_num:m_startPageNum];
                [self annotationRemoved:annotation onPageNumber:m_startPageNum];
            }
            return;
        }

        PTPDFDoc *doc = [self.pdfViewCtrl GetDoc];
        [self willModifyAnnotation:annotation onPageNumber:self.pageNumber];
        [self writeDrawingDataToAnnotation:annotation];

        PTObj *appearance = [annotation GetAppearance:e_ptnormal app_state:0];
        [self.canvasView setHidden:YES]; // to prevent 'flash' due to blending with the PTToolView in [self keepToolAppearanceOnScreen]
        UIImage *image = [self imageFromCanvas];
        PTImage* stampImage = [self ptImageFromUIImage:image withDoc:doc];

        PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
        PTRotate pageRotation = [page GetRotation];
        PTRotate stampRotation = ((pageRotation + ctrlRotation) % 4);
        PTMatrix2D* rotationMtx;
        CGSize size = CGSizeMake([stampImage GetImageWidth], [stampImage GetImageHeight]);
        if (stampRotation == e_pt90) {
            rotationMtx = [PTMatrix2D RotationMatrix:-M_PI_2];
            size = CGSizeMake(size.height, size.width);
        } else if (stampRotation == e_pt180) {
            size = CGSizeMake(size.height, size.width);
            rotationMtx = [PTMatrix2D RotationMatrix:M_PI];
        } else if (stampRotation == e_pt270) {
            size = CGSizeMake(size.height, size.width);
            rotationMtx = [PTMatrix2D RotationMatrix:M_PI_2];
        } else if (stampRotation == e_pt0) {
            rotationMtx = [PTMatrix2D IdentityMatrix];
        }

        PTElementBuilder* builder = [[PTElementBuilder alloc] init];
        PTElementReader *reader = [[PTElementReader alloc] init];
        PTElementWriter* writer = [[PTElementWriter alloc] init];
        PTElement *element = [self getFirstElementUsingReader:reader fromObj:appearance ofType:e_ptimage];
        [reader End];

        if( element != nil )
        {
            [writer WriterBeginWithSDFDoc:[doc GetSDFDoc] compress:YES];
            element = [builder CreateImageWithCornerAndScale:stampImage x:0 y:0 hscale:size.width vscale:size.height];
            PTMatrix2D *mtx = [[element GetGState] GetTransform];
            [mtx Multiply:rotationMtx];
            [[element GetGState] SetTransformWithMatrix:mtx];

            if (@available(iOS 14.0, *)) {
                if( self.toolManager.pencilHighlightMultiplyBlendModeEnabled ){
                    [self setMultiplyBlendModeOnElement:element];
                }
            }

            [writer WritePlacedElement:element];

            PTObj *newApp = [writer End];
            PTPDFRect *bbox = [element GetBBox];
            [bbox Normalize];

            [newApp PutRect:@"BBox" x1:[bbox GetX1] y1:[bbox GetY1] x2:[bbox GetX2] y2:[bbox GetY2]];

            [annotation SetAppearance:newApp annot_state:e_ptnormal app_state:0];
            [annotation SetRect:drawingPageRect];
            editing = NO;
            [self.pdfViewCtrl ShowAnnotation:annotation];
            [self.pdfViewCtrl UpdateWithAnnot:annotation page_num:m_startPageNum];
            [self.pdfViewCtrl RequestRendering];
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (hasWriteLock) {
            [self.pdfViewCtrl DocUnlock];
        }
    }
    [self annotationModified:annotation onPageNumber:self.annotationPageNumber];

    self.nextToolType = self.defaultClass;
    [self.toolManager createSwitchToolEvent:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer != self.canvasView.drawingGestureRecognizer) {
        return NO;
    }
    if (CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)) {
        self.startPoint = [touch preciseLocationInView:self.pdfViewCtrl];
        _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x y:self.startPoint.y];
        drawnZoom = self.pdfViewCtrl.zoom;
        m_startPageNum = self.pageNumber;

        PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
        CGFloat minX = [page_rect GetX1];
        CGFloat maxX = [page_rect GetX2];
        CGFloat minY = [page_rect GetY1];
        CGFloat maxY = [page_rect GetY2];
        CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);

        self.canvasView.contentSize = pageFrame.size;
        self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);

    }
    return YES;
}

- (void)canvasViewDidBeginUsingTool:(PKCanvasView *)canvasView
{
    [self saveInkToolToUserDefaults];
}

- (void)canvasViewDrawingDidChange:(PKCanvasView *)canvasView
{
    CGRect drawingFrame = [self.canvasView convertRect:[self visibleDrawingRect] toView:self.pdfViewCtrl];
    drawingPageRect = [self.pdfViewCtrl CGRectScreen2PDFRectPage:drawingFrame PageNumber:m_startPageNum];
}

- (void)canvasViewDidFinishRendering:(PKCanvasView *)canvasView
{
    [self.canvasView setHidden:NO];
    if (self.annotSnapshot.superview) {
        [self.annotSnapshot removeFromSuperview];
        self.annotSnapshot = nil;
    }
    CGRect drawingFrame = [self.canvasView convertRect:[self visibleDrawingRect] toView:self.pdfViewCtrl];
    drawingPageRect = [self.pdfViewCtrl CGRectScreen2PDFRectPage:drawingFrame PageNumber:m_startPageNum];
}

+ (CGAffineTransform) transformFromRect:(CGRect)sourceRect toRect:(CGRect)finalRect {
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(finalRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(finalRect)));
    transform = CGAffineTransformScale(transform, finalRect.size.width/sourceRect.size.width, finalRect.size.height/sourceRect.size.height);

    return transform;
}

-(void)pdfViewCtrlOnLayoutChanged:(PTPDFViewCtrl*)pdfViewCtrl
{
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], self.pdfViewCtrl.frame.size.width, self.pdfViewCtrl.frame.size.height);
    self.canvasView.frame = self.bounds;
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    self.canvasView.contentSize = pageFrame.size;
    self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);
    
    double lastZoom = drawnZoom;
    double currZoom = self.pdfViewCtrl.zoom;
    drawnZoom = currZoom;
    CGFloat scale = currZoom/lastZoom;
    CGAffineTransform transformToCanvas = CGAffineTransformMakeScale(scale, scale);
    self.canvasView.drawing = [self.canvasView.drawing drawingByApplyingTransform:transformToCanvas];
    CGRect frame = [self convertRect:self.canvasView.drawing.bounds fromView:self.canvasView];
    if (self.annotSnapshot) {
        self.annotSnapshot.frame = frame;
    }
    [super pdfViewCtrlOnLayoutChanged:pdfViewCtrl];
}

- (void)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl pageNumberChangedFrom:(int)oldPageNumber To:(int)newPageNumber
{
    [self commitAnnotation];
    _pageNumber = newPageNumber;
    [self.canvasView setDrawing:[[PKDrawing alloc] init]];
    [self.canvasView setHidden:NO];
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:newPageNumber];
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    CGRect pageFrame = CGRectMake(minX, minY, maxX-minX, maxY-minY);

    self.canvasView.contentSize = pageFrame.size;
    self.canvasView.contentOffset = CGPointMake(-pageFrame.origin.x, -pageFrame.origin.y);
}

-(void)cancelEditingAnnotation
{
    self.commitAnnotationOnToolChange = NO;
    [self.toolPicker setRulerActive:NO];
    [self.toolPicker setVisible:NO forFirstResponder:self.canvasView];
    if (editing && annotation) {
        editing = NO;
        [self keepToolAppearanceOnScreen];
        [self.pdfViewCtrl ShowAnnotation:annotation];
        [self.canvasView setHidden:YES];

        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            [self.pdfViewCtrl UpdateWithAnnot:annotation page_num:self.pageNumber];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        } @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    }
}

-(PTElement *)getFirstElementUsingReader:(PTElementReader *)reader fromObj:(PTObj *)obj ofType:(PTElementType)type
{
    @try
    {
        [self.pdfViewCtrl DocLockRead];

        if (![obj IsValid]) {
            return nil;
        }

        [reader ReaderBeginWithSDFObj:obj resource_dict:nil ocg_context:nil];

        for( PTElement* element = [reader Next]; element != 0; element = [reader Next] )
        {
            if( [element GetType] == type )
            {
                return element;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@", exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    return nil;
}

- (BOOL)onSwitchToolEvent:(id)userData
{
    NSString* eventString = (NSString*)userData;
    if( userData && [eventString isEqualToString:@"EditPencilDrawing"] && self.currentAnnotation){
        self.backToPanToolAfterUse = NO;
        self.shouldShowToolPicker = YES;
        [self editAnnotation:self.currentAnnotation onPage:self.annotationPageNumber];
        if ([self.toolManager.viewController.class isSubclassOfClass:[PTDocumentBaseViewController class]]) {
            PTDocumentBaseViewController *documentBaseViewController = (PTDocumentBaseViewController*)self.toolManager.viewController;
            if (documentBaseViewController.controlsHidden && !documentBaseViewController.hidesControlsOnTap) {
                // Don't show the controls if they have been explicitly hidden
            }else{
                [documentBaseViewController setControlsHidden:NO animated:YES];
            }
        }
    }else if( userData && [eventString isEqualToString:@"From Long Press"]){
        self.backToPanToolAfterUse = YES;
    }

    if (stylusAppendTimeout.timer.isValid && !CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)) {
        [self endDrawing];
    }

    return YES;
}

- (void)dealloc
{
    // If the tool gets switched from the annotation toolbar before the timer ends, commit the existing drawing
    if ((stylusAppendTimeout.timer.isValid || editing) && !CGSizeEqualToSize(self.canvasView.drawing.bounds.size,CGSizeZero)) {
        [self commitAnnotation];
    }
    if( [self.currentAnnotation IsValid])
    {
        [self.pdfViewCtrl ShowAnnotation:self.currentAnnotation];
        BOOL shouldUnlock = NO;
        @try {
            [self.pdfViewCtrl DocLockRead];
            shouldUnlock = YES;
            [self.pdfViewCtrl UpdateWithAnnot:self.currentAnnotation page_num:self.annotationPageNumber];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        } @finally {
            if (shouldUnlock) {
                [self.pdfViewCtrl DocUnlockRead];
            }
        }
    }
}

@end
