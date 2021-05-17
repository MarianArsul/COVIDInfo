//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleDraw.h"

#import "PTColorDefaults.h"

#import "CGContext+PTAdditions.h"
#import "CGGeometry+PTAdditions.h"
#import "PTLineAnnot+PTAdditions.h"

#include <tgmath.h>

@interface PTAnnotationView : UIView

@property (strong, nonatomic) PTAnnot* annot;
@property (strong, nonatomic) PTPage* annotPage;
@property (strong, nonatomic) PTAnnotStyle* annotStyle;
@property (weak, nonatomic) PTPDFViewCtrl* pdfViewCtrl;
@property (nonatomic) int pageNumber;
@property (nonatomic) CGSize orgSize;
@property (nonatomic, strong) NSMutableArray* m_free_hand_strokes;
@end

@implementation PTAnnotationView


- (instancetype)initWithAnnot:(PTAnnot*)annot andPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onPageNumber:(int)pageNumber
{
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        _annot = annot;
        _annotStyle = [[PTAnnotStyle allocOverridden] initWithAnnot:annot];
        _pdfViewCtrl = pdfViewCtrl;
        _pageNumber = pageNumber;
        
        _annotPage = [[pdfViewCtrl GetDoc] GetPage:pageNumber];

        
        self.contentMode = UIViewContentModeRedraw;
        self.alpha = _annotStyle.opacity;
        
        if( self.annotStyle.annotType == PTExtendedAnnotTypeInk ||
           self.annotStyle.annotType == PTExtendedAnnotTypeFreehandHighlight)
        {
            [self setupInkAppearance];
        }
        
    }
    return self;
}

- (void)setupInkAppearance {
    PTInk* ink = [[PTInk alloc] initWithAnn:self.annot];
    
    PTPDFRect* offset = [ink GetRect];

    [offset Normalize];
//    PTPDFPoint* orgSizePageWidth = [[PTPDFPoint alloc] initWithPx:([offset Width]) py:0];
//    PTPDFPoint* orgSizeScreenWidth = [self.pdfViewCtrl ConvPagePtToScreenPt:orgSizePageWidth page_num:self.pageNumber];
    
//    PTPDFPoint* orgSizePageHeight = [[PTPDFPoint alloc] initWithPx:([offset Height]) py:0];
//    PTPDFPoint* orgSizeScreenHeight = [self.pdfViewCtrl ConvPagePtToScreenPt:orgSizePageHeight page_num:self.pageNumber];
    
    int pathCount = [ink GetPathCount];
    
    _m_free_hand_strokes = [[NSMutableArray alloc] init];
    NSMutableArray* free_hand_points = [[NSMutableArray alloc] init];
    
    for(int pathNumber = 0; pathNumber < pathCount; pathNumber++ )
    {
        int pointCount = [ink GetPointCount:pathNumber];
        
        for(int pointNumber = 0; pointNumber < pointCount; pointNumber++ )
        {
            
            PTPDFPoint* point = [ink GetPoint:pathNumber pointindex:pointNumber];
            
            PTPDFPoint* point2 = [self.pdfViewCtrl ConvPagePtToScreenPt:point page_num:self.pageNumber];
            
            PTPDFPoint* offsetPagePoint1 = [[PTPDFPoint alloc] initWithPx:[offset GetX1] py:[offset GetY1]];
            PTPDFPoint* offsetScreenSpace1 = [self.pdfViewCtrl ConvPagePtToScreenPt:offsetPagePoint1 page_num:self.pageNumber];
            
            PTPDFPoint* offsetPagePoint2 = [[PTPDFPoint alloc] initWithPx:[offset GetX2] py:[offset GetY2]];
            PTPDFPoint* offsetScreenSpace2 = [self.pdfViewCtrl ConvPagePtToScreenPt:offsetPagePoint2 page_num:self.pageNumber];
            double screenHeight = fabs([offsetScreenSpace1 getY] - [offsetScreenSpace2 getY]);
            [point2 setX:([point2 getX] - [offsetScreenSpace1 getX])];
            [point2 setY:-([point2 getY] - [offsetScreenSpace1 getY])];
            
            [free_hand_points addObject:[NSValue valueWithCGPoint:CGPointMake([point2 getX], screenHeight-[point2 getY])]];
            
            if( pointNumber == pointCount -1 )
            {
                // without this the link may be slightly shorter than it should be
                [free_hand_points addObject:[NSValue valueWithCGPoint:CGPointMake([point2 getX], screenHeight-[point2 getY])]];
            }
            
        }
        [_m_free_hand_strokes addObject:[free_hand_points copy]];
        [free_hand_points removeAllObjects];
        
    }
}

static CGPoint midPoint(CGPoint p1, CGPoint p2)
{
    
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
    
}

-(void)drawRect:(CGRect)rect
{
    PTExtendedAnnotType annotType = self.annotStyle.annotType;
    
    PTRotate ctrlRotation = [self.pdfViewCtrl GetRotation];
    PTRotate pageRotation = [self.annotPage GetRotation];
    PTRotate annotRotation = ((pageRotation + ctrlRotation) % 4);
    
    if( CGSizeEqualToSize(self.orgSize, CGSizeZero) )
    {
        self.orgSize = self.bounds.size;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, (self.frame.size.width-self.superview.bounds.size.width)/2, -(self.frame.size.height-self.superview.bounds.size.height)/2);
    
    UIColor* strokeColor = self.annotStyle.strokeColor;
    
    if( strokeColor == Nil )
    {
        strokeColor = UIColor.clearColor;
    }
    
    UIColor* fillColor = self.annotStyle.fillColor;
    
    if( fillColor == Nil )
    {
        fillColor = UIColor.clearColor;
    }
    
    double opacity = self.annotStyle.opacity;
    
    // Decrease freehand-highlight opacity slightly from 1.0, since we can't easily do a multiply
    // blend mode here.
    if (annotType == PTExtendedAnnotTypeFreehandHighlight &&
        opacity == 1.0) {
        opacity = 0.8;
    }
    
    double thickness = self.annotStyle.thickness;
    
    thickness *= [self.pdfViewCtrl GetZoom];
    
    CGContextSetLineWidth(context, thickness);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    
    double offset = (self.frame.size.width-self.superview.bounds.size.width)/2;
    
//    double offsetY = (self.frame.size.height-self.superview.bounds.size.height)/2;
    
    rect.origin.x += thickness/2-offset;
    rect.origin.y += thickness/2+offset;
    rect.size.width -= thickness;
    rect.size.height -= thickness;
    
    rect = CGRectInset(rect, offset, offset);
    
    if( self.annotStyle.annotType == PTExtendedAnnotTypeCircle )
    {
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextFillEllipseInRect(context, rect);
        CGContextAddEllipseInRect(context, rect);
    }
    else if( self.annotStyle.annotType == PTExtendedAnnotTypeSquare )
    {
        PTSquare* sq = [[PTSquare alloc] initWithAnn:self.annot];
        
        if( [sq GetBorderEffect] == e_ptCloudy )
        {
            // Correction for different border drawing between Core and CG
            rect.origin.x -= thickness/2;
            rect.origin.y -= thickness/2;
            rect.size.width += thickness;
            rect.size.height += thickness;

            CGContextBeginPath(context);

            NSMutableArray<NSValue *> *points = [NSMutableArray array];


            double borderEffectIntensity = [sq GetBorderEffectIntensity];

            CGPoint point1 = rect.origin;
            CGPoint point2 = CGPointMake(rect.size.width+rect.origin.x, rect.origin.y);
            CGPoint point3 = CGPointMake(rect.size.width+rect.origin.x, rect.size.height+rect.origin.y);
            CGPoint point4 = CGPointMake(rect.origin.x, rect.size.height+rect.origin.y);

            [points addObjectsFromArray:@[@(point1), @(point2), @(point3), @(point4)]];
            [points addObject:[points.firstObject copy]];


            [PTAnnotStyleDraw drawCloudWithRect:rect
                                         points:points
                                borderIntensity:borderEffectIntensity
                                           zoom:self.pdfViewCtrl.zoom];

            CGContextClosePath(context);
        }
        else
        {
            CGContextSetLineJoin(context, kCGLineJoinMiter);
            CGContextFillRect(context, rect);
            
            CGContextStrokeRectWithWidth(context, rect, thickness);
        }
    }
    else if( self.annotStyle.annotType == PTExtendedAnnotTypeInk ||
            self.annotStyle.annotType == PTExtendedAnnotTypeFreehandHighlight)
    {
        
        CGContextTranslateCTM(context, -(self.frame.size.width-self.superview.bounds.size.width)/2, (self.frame.size.height-self.superview.bounds.size.height)/2);
        
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGPoint previousPoint1 = CGPointZero;
        CGPoint previousPoint2 = CGPointZero;
        CGPoint currentPoint;
        
        
        CGContextSetLineJoin(context, kCGLineJoinRound);
        
        for (NSArray<NSValue*>* point_array in self.m_free_hand_strokes)
        {
            previousPoint1 = CGPointZero;
            previousPoint2 = CGPointZero;
            
            CGContextBeginPath(context);
            
            for (NSValue* val in point_array)
            {
                currentPoint = val.CGPointValue;
                
                
                currentPoint.x *= (self.bounds.size.width-offset*2)/(self.orgSize.width-offset*2);
                currentPoint.y *= (self.bounds.size.height-offset*2)/(self.orgSize.height-offset*2);
                currentPoint.x += offset;
                currentPoint.y += offset;
                
                if( annotRotation == e_pt90 || annotRotation == e_pt180)
                {
                    currentPoint.y = currentPoint.y - rect.size.height - thickness;
                }

                if( annotRotation == e_pt270 || annotRotation == e_pt180)
                {
                    currentPoint.x = currentPoint.x + rect.size.width + thickness;
                }
                

                if( CGPointEqualToPoint(previousPoint1, CGPointZero))
                    previousPoint1 = currentPoint;
                
                if( CGPointEqualToPoint(previousPoint2, CGPointZero))
                    previousPoint2 = currentPoint;
                
                CGPoint mid1 = midPoint(previousPoint1, previousPoint2);
                CGPoint mid2 = midPoint(currentPoint, previousPoint1);
                
                CGContextMoveToPoint(context, mid1.x, mid1.y);
                
                CGContextAddQuadCurveToPoint(context, previousPoint1.x, previousPoint1.y, mid2.x, mid2.y);
                
                previousPoint2 = previousPoint1;
                previousPoint1 = currentPoint;
            }
            
            CGContextStrokePath(context);
            
        }
    }
    else if( [self.annot GetType] == e_ptPolyline || [self.annot GetType] == e_ptPolygon || ([self.annot GetType] == e_ptLine && self.annotStyle.annotType != PTExtendedAnnotTypeArrow) )
    {
        PTLineAnnot* polyAnnot;
        
        if( [self.annot GetType] == e_ptPolyline )
        {
            polyAnnot = [[PTPolyLine alloc] initWithAnn:self.annot];
        }
        else if( [self.annot GetType] == e_ptPolygon )
        {
            polyAnnot = [[PTPolygon alloc] initWithAnn:self.annot];
        }
        else
        {
            // arrow, line, (ruler?)
            polyAnnot = [[PTLineAnnot alloc] initWithAnn:self.annot];
        }
        
        NSMutableArray<PTPDFPoint *> *pageVertices = [NSMutableArray array];
        
        int polyPointsCount = [polyAnnot GetVertexCount];
        double minX = DBL_MAX;
        double minY = DBL_MAX;
        
        for(int pointNumber = 0; pointNumber < polyPointsCount; pointNumber++ )
        {
            PTPDFPoint* pt = [polyAnnot GetVertex:pointNumber];
            minX = fmin(minX, [pt getX]);
            minY = fmin(minY, [pt getY]);
            
            [pageVertices addObject:pt];
        }
            
        PTPDFPoint* offsetCorner = [[PTPDFPoint alloc] initWithPx:minX py:minY];
        PTPDFPoint* offsetoffsetCornerScreenSpace = [self.pdfViewCtrl ConvPagePtToScreenPt:offsetCorner page_num:self.pageNumber];
        
        if( annotRotation == e_pt90 || annotRotation == e_pt180)
        {
            [offsetoffsetCornerScreenSpace setY:[offsetoffsetCornerScreenSpace getY]+rect.size.height+thickness];
        }

        if( annotRotation == e_pt270 || annotRotation == e_pt180)
        {
            [offsetoffsetCornerScreenSpace setX:[offsetoffsetCornerScreenSpace getX]-rect.size.width-thickness];
        }
        
        NSMutableArray<PTPDFPoint *> *screenVertices = [NSMutableArray array];
        for (PTPDFPoint *pageVertex in pageVertices) {
            PTPDFPoint* screenPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:pageVertex page_num:self.pageNumber];
            
            [screenPoint setX:([screenPoint getX]- [offsetoffsetCornerScreenSpace getX])];
            [screenPoint setY:-([offsetoffsetCornerScreenSpace getY] - self.bounds.size.height - [screenPoint getY])];
            
            [screenVertices addObject:screenPoint];
        }
    
        CGContextBeginPath(context);
        
        if (self.annotStyle.annotType == PTExtendedAnnotTypeCloudy) {
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            
            NSMutableArray<NSValue *> *points = [NSMutableArray array];
            for (PTPDFPoint *screenVertex in screenVertices) {
                [points addObject:@(CGPointMake([screenVertex getX],
                                                [screenVertex getY]))];
            }
            
            [points addObject:[points.firstObject copy]];
            
            double borderEffectIntensity = [polyAnnot GetBorderEffectIntensity];

            [PTAnnotStyleDraw drawCloudWithRect:rect
                                         points:points
                                borderIntensity:borderEffectIntensity
                                           zoom:self.pdfViewCtrl.zoom];
            
            CGContextClosePath(context);
        }
        else {
            for(int pointNumber = 0; pointNumber < polyPointsCount; pointNumber++ )
            {
                PTPDFPoint* point = [polyAnnot GetVertex:pointNumber];
                
                PTPDFPoint* screenPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:point page_num:self.pageNumber];
                
                if( pointNumber == 0 )
                {
                    CGContextMoveToPoint(context, ([screenPoint getX]- [offsetoffsetCornerScreenSpace getX]), -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-[screenPoint getY]));
                }
                else
                {
                    CGContextAddLineToPoint(context, ([screenPoint getX]- [offsetoffsetCornerScreenSpace getX]), -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-[screenPoint getY]));
                }
            }
            if( [self.annot GetType] == e_ptPolygon )
            {
                PTPDFPoint* point = [polyAnnot GetVertex:0];
                
                PTPDFPoint* screenPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:point page_num:self.pageNumber];
                
                CGContextAddLineToPoint(context, ([screenPoint getX]- [offsetoffsetCornerScreenSpace getX]), -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-[screenPoint getY]));
            }
        }
    }
    else if( self.annotStyle.annotType == PTExtendedAnnotTypeArrow )
    {
        
        PTLineAnnot* arrowAnnot = [[PTLineAnnot alloc] initWithAnn:self.annot];
        
        double polyPointsCount = [arrowAnnot GetVertexCount];
        double minX = DBL_MAX;
        double minY = DBL_MAX;
        
        for(int pointNumber = 0; pointNumber < polyPointsCount; pointNumber++ )
        {
            PTPDFPoint* pt = [arrowAnnot GetVertex:pointNumber];
            minX = fmin(minX, [pt getX]);
            minY = fmin(minY, [pt getY]);
        }
        
        
        PTPDFPoint* offsetCorner = [[PTPDFPoint alloc] initWithPx:minX py:minY];
        PTPDFPoint* offsetoffsetCornerScreenSpace = [self.pdfViewCtrl ConvPagePtToScreenPt:offsetCorner page_num:self.pageNumber];
        
        if( annotRotation == e_pt90 || annotRotation == e_pt180)
        {
            [offsetoffsetCornerScreenSpace setY:[offsetoffsetCornerScreenSpace getY]+rect.size.height+thickness];
        }

        if( annotRotation == e_pt270 || annotRotation == e_pt180)
        {
            [offsetoffsetCornerScreenSpace setX:[offsetoffsetCornerScreenSpace getX]-rect.size.width-thickness];
        }
        
        CGPoint firstSmall, secondSmall;
        
        PTPDFPoint* pageStartPoint = [arrowAnnot GetStartPoint];
        PTPDFPoint* screenStartPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:pageStartPoint page_num:self.pageNumber];
        
        CGPoint startPoint = CGPointMake([screenStartPoint getX], [screenStartPoint getY]);
        
        PTPDFPoint* pageEndPoint = [arrowAnnot GetEndPoint];
        PTPDFPoint* screenEndPoint = [self.pdfViewCtrl ConvPagePtToScreenPt:pageEndPoint page_num:self.pageNumber];
        
        
        CGPoint endPoint = CGPointMake([screenEndPoint getX], [screenEndPoint getY]);
        
        if( [arrowAnnot GetEndStyle] == e_ptOpenArrow )
        {
            CGPoint temp;
            temp = startPoint;
            startPoint = endPoint;
            endPoint = temp;
        }
        
        
        const double cosAngle = cos(3.1415926/6);
        const double sinAngle = sin(3.1415926/6);
        const double  arrowLength = 10*thickness/2;
        
        double dx = startPoint.x - endPoint.x;
        double dy = startPoint.y - endPoint.y;
        double len = dx*dx+dy*dy;
        
        if( len > 0 )
        {
            len = sqrt(len);
            dx /= len;
            dy /= len;
            
            double dx1 = dx * cosAngle - dy * sinAngle;
            double dy1 = dy * cosAngle + dx * sinAngle;
            
            firstSmall = CGPointMake(startPoint.x - arrowLength*dx1, startPoint.y - arrowLength*dy1);
            
            double dx2 = dx * cosAngle + dy * sinAngle;
            double dy2 = dy * cosAngle - dx * sinAngle;
            
            secondSmall = CGPointMake(startPoint.x - arrowLength*dx2, startPoint.y - arrowLength*dy2);
            
            // end of small line
            CGContextMoveToPoint(context, firstSmall.x - [offsetoffsetCornerScreenSpace getX], -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-firstSmall.y));
            
            // tip of arrow
            CGContextAddLineToPoint(context, startPoint.x - [offsetoffsetCornerScreenSpace getX], -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-startPoint.y));
            
            // end of second small line
            CGContextAddLineToPoint(context, secondSmall.x - [offsetoffsetCornerScreenSpace getX], -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-secondSmall.y));
            
            // tip of arrow
            CGContextMoveToPoint(context, startPoint.x - [offsetoffsetCornerScreenSpace getX], -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-startPoint.y));
            
            // base of long arrow line
            CGContextAddLineToPoint(context, endPoint.x - [offsetoffsetCornerScreenSpace getX], -([offsetoffsetCornerScreenSpace getY]-self.bounds.size.height-endPoint.y));
            
            
            
        }
    }
    
    
    CGContextDrawPath(context, kCGPathFillStroke);
}

@end

@implementation PTAnnotStyleDraw

+(BOOL)canVectorDrawWithAnnotType:(PTExtendedAnnotType)type
{
    NSArray* annotStyleCanDraw = @[
        @(PTExtendedAnnotTypeCircle),
        @(PTExtendedAnnotTypeSquare),
        @(PTExtendedAnnotTypeInk),
        @(PTExtendedAnnotTypeFreehandHighlight),
        @(PTExtendedAnnotTypePolyline),
        @(PTExtendedAnnotTypePolygon),
        @(PTExtendedAnnotTypeLine),
        @(PTExtendedAnnotTypeArrow),
        @(PTExtendedAnnotTypeCloudy),
        @(PTExtendedAnnotTypePerimeter),
        @(PTExtendedAnnotTypeArea),
    ];
    
    return [annotStyleCanDraw containsObject:@(type)];
}


+(UIImage*)imageFromRawBGRAData:(NSData*)data width:(int)width height:(int)height
{
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    const int bitsPerComponent = 8;
    const int bitsPerPixel = 4 * bitsPerComponent;
    const int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    double screenScale = [[UIScreen mainScreen] scale];
    
    UIImage *myImage = [UIImage imageWithCGImage:imageRef scale:screenScale orientation:UIImageOrientationUp];
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    return myImage;
}

+(UIImage*)getAnnotationAppearanceImage:(PTPDFDoc*)doc withAnnot:(PTAnnot*)annot onPageNumber:(int)pageNumber withDPI:(int)dpi forViewerRotation:(PTRotate)viewerRotation
{
    
    if( [annot GetType] != e_ptFreeText)
    {
        dpi = MIN(360, dpi);
    }
    
    if( [annot GetFlag:e_ptno_rotate] == YES )
    {
        dpi = 100;
    }
    
    BOOL shouldUnlockRead = false;
    
    @try {
        [doc LockRead];
        shouldUnlockRead = true;
        
        if ( [annot IsValid] == NO ) {
            return Nil;
        }
        
        PTPDFDraw* draw = [[PTPDFDraw alloc] initWithDpi:dpi];
        [draw SetPageTransparent:YES];
        [draw SetAntiAliasing:YES];
        PTPDFRect* annotRect = [annot GetRect];
        
        // Create a new transparent page
        PTPDFDoc* annotOnlyDoc = [[PTPDFDoc alloc] init];
        
        PTPDFRect* pageRect = [[PTPDFRect alloc] initWithX1:0 y1:0 x2:[annotRect Width] y2:[annotRect Height]];
        
        PTPage* page = [annotOnlyDoc PageCreate:pageRect];
        
        PTRotate pageRotation;
        
        // copy the annotation
        PTObj* srcAnnotation = [annot GetSDFObj];
        PTObj* pEntry = [srcAnnotation FindObj:@"P"];
        
        PTPage* orgPage = [doc GetPage:pageNumber];
        
        NSAssert([orgPage IsValid] , @"Page must be valid");
        
        pageRotation = [orgPage GetRotation];
        
        if( ![pEntry IsValid] )
        {
            pEntry = [orgPage GetSDFObj];
        }

        [page SetRotation:pageRotation];
        
        
        [draw SetRotate:viewerRotation];
        
        [annotOnlyDoc PagePushBack:page];
        
        PTVectorObj* objList = [[PTVectorObj alloc] init];
        [objList add:srcAnnotation];
        
        PTVectorObj* excludeList = [[PTVectorObj alloc] init];
        [excludeList add:pEntry];
        
        PTVectorObj* destAnnot = [[annotOnlyDoc GetSDFDoc] ImportObjsWithExcludeList:objList exclude_list:excludeList];
        
        if( [destAnnot size] > 0 )
        {
            PTAnnot* dest = [[PTAnnot alloc] initWithD:[destAnnot get:0]];
            [dest SetRect:pageRect];
            [page AnnotPushBack:dest];
            
            if( [annot GetFlag:e_ptno_rotate] == NO )
            {
                [dest SetRotation:[annot GetRotation]];
            }
            
            PTBitmapInfo* bitmapInfoObject = [draw GetBitmap:page pix_fmt:e_ptbgra demult:NO];
            
            NSData* data = [bitmapInfoObject GetBuffer];
            UIImage* image = [self imageFromRawBGRAData:data width:[bitmapInfoObject getWidth] height:[bitmapInfoObject getHeight]];
            return image;
        }
        
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception: %@\n%@\n%@", exception.name, exception.reason, exception.description);
    }
    @finally
    {
        if( shouldUnlockRead )
        {
            [doc UnlockRead];
        }
        
    }
    
    return Nil;
}

+(UIView*)getAnnotationVectorAppearanceView:(PTPDFDoc*)doc withAnnot:(PTAnnot*)annot andPDFViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onPageNumber:(int)pageNumber
{
    PTAnnotationView* annotationView = [[PTAnnotationView alloc] initWithAnnot:annot andPDFViewCtrl:pdfViewCtrl onPageNumber:pageNumber];
    
    return annotationView;
}

+(void)drawIntoContext:(CGContextRef)context withStyle:(PTAnnotStyle*)annotStyle withCrop:(CGRect)rect atZoom:(double)zoom
{

    UIColor* strokeColor = annotStyle.strokeColor;

    UIColor* fillColor = annotStyle.fillColor;

    double opacity = annotStyle.opacity;

    double thickness = annotStyle.thickness;

    thickness *= zoom;

    CGContextSetLineWidth(context, thickness);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextSetAlpha(context, opacity);
    
    rect.origin.x += thickness/2;
    rect.origin.y += thickness/2;
    rect.size.width -= thickness;
    rect.size.height -= thickness;


    if( annotStyle.annotType == PTExtendedAnnotTypeCircle )
    {
        CGContextFillEllipseInRect(context, rect);
        CGContextAddEllipseInRect(context, rect);
    }
    else if( annotStyle.annotType == PTExtendedAnnotTypeSquare )
    {
        CGContextFillRect(context, rect);
        CGContextStrokeRectWithWidth(context, rect, thickness);
    }

        
        CGContextStrokePath(context);

}

#pragma mark - Cloud

static const double PTCloudCreateDefaultBorderIntensity = 2.0;

static const double PTCloudCreateScale = 8.0;

static const double PTCloudCreateSameVertexThreshold = 1.0 / 8192;

+ (double)polyWrapDirectionForPoints:(NSArray<NSValue *> *)points
{
    NSUInteger count = points.count;
    
    NSAssert(count > 2, @"At least 3 points are required to determine polygon wrap direction.");
    
    CGPoint A = points[0].CGPointValue;
    double accum = 0.0;
    
    for (NSUInteger i = 1; i < count; i++) {
        CGPoint B = points[i].CGPointValue;
        accum += (B.x - A.x) * (B.y + A.y);
        A = B;
    }
    
    return (accum >= 0) ? 1.0 : -1.0;
}

+ (void)drawCloudWithRect:(CGRect)rect points:(NSArray<NSValue *> *)points borderIntensity:(double)borderIntensity zoom:(double)zoom
{
    NSArray<NSValue *> *polygon = points;
    NSUInteger size = polygon.count;
    if (size < 3) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (borderIntensity < 0.1) {
        borderIntensity = PTCloudCreateDefaultBorderIntensity;
    }
    borderIntensity *= zoom;
    
    const double sweepDirection = [self polyWrapDirectionForPoints:polygon];
    const BOOL clockwise = round(sweepDirection) != 1.0;
    
    double maxCloudSize = PTCloudCreateScale * borderIntensity;
    double edgeAngle = 0.0;
    CGPoint firstPos = polygon[0].CGPointValue;
    double lastCloudSize = maxCloudSize;
    double firstCloudSize = maxCloudSize;
    
    CGPoint lastEdge = PTCGPointSubtract(firstPos, polygon[size - 2].CGPointValue);
    BOOL useLargeFirstArc = YES;
    
    BOOL hasFirstPoint = NO;
    
    for (NSUInteger i = 0; i < (size - 1); i++) {
        CGPoint pos = polygon[i].CGPointValue;
        const CGPoint edge = PTCGPointSubtract(polygon[i + 1].CGPointValue, pos);
        double length = PTCGPointLength(edge);
        // Avoid division by 0 from duplicated points.
        if (length <= PTCloudCreateSameVertexThreshold) {
            continue;
        }
        
        // Split the edge into some integral number of clouds.
        const CGPoint direction = PTCGPointDivide(edge, length);
        int numClouds = (int)fmax(floor(length / maxCloudSize), 1);
        double cloudSize = length / numClouds;
        edgeAngle = PTCGPointAngleFromXAxis(direction);
        
        // Back start position out to before the vertex
        // as we're going to increment before using it.
        pos = PTCGPointSubtract(pos, PTCGPointMultiply(direction, cloudSize * 0.5));
        
        // Which direction are we turning at this vertex?
        double cross = PTCGPointCrossProduct(lastEdge, edge);
        
        NSUInteger c = 0;
        if (!hasFirstPoint) {
            // Skip the first iteration for the first leg (we'll complete it at the end).
            c++;
            firstCloudSize = cloudSize;
            useLargeFirstArc = (cross * sweepDirection) < 0;
            pos = PTCGPointAdd(pos, PTCGPointMultiply(direction, cloudSize));
            firstPos = pos;
            // Start the curve.
            CGContextMoveToPoint(context, firstPos.x, firstPos.y);
            hasFirstPoint = YES;
        }
        // For the first iteration, combine the radius with the previous edge.
        double radius = (lastCloudSize + cloudSize) * 0.25;
        for (; c < numClouds; c++) {
            if (c == 1) {
                // On the second iteration, we can use values exclusive to this edge.
                radius = cloudSize * 0.5;
            }
            pos = PTCGPointAdd(pos, PTCGPointMultiply(direction, cloudSize));
            BOOL useLargeArc = (c == 0 && (cross * sweepDirection) < 0);
            
            pt_CGContextAddArcTo(context, radius, edgeAngle, useLargeArc, clockwise, pos.x, pos.y);
        }
        lastEdge = edge;
        lastCloudSize = cloudSize;
    }
    if (!hasFirstPoint) {
        CGContextMoveToPoint(context, firstPos.y, firstPos.y);
    }
    double closingRadius = (firstCloudSize + lastCloudSize) * 0.25;
    // Now we close the poly, using the values we saved on the first vertex.
    pt_CGContextAddArcTo(context, closingRadius, edgeAngle, useLargeFirstArc, clockwise, firstPos.x, firstPos.y);
}

@end
