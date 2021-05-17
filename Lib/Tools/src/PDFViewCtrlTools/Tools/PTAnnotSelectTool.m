//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotSelectTool.h"
#import "PTAnnotEditTool.h"

#import "PTToolsUtil.h"

#import "PTAnnot+PTAdditions.h"
#import "PTDate+NSDate.h"

@implementation PTAnnotSelectTool

+ (BOOL)createsAnnotation
{
    return NO;
}

+ (UIImage *)image
{
    return [PTToolsUtil toolImageNamed:@"ic_select_rectangular_black_24dp"];
}

+ (NSString *)localizedName
{
    return PTLocalizedString(@"Multi-select",
                             @"Multi-select tool name");
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.superview bringSubviewToFront:self];
    UITouch *touch = touches.allObjects[0];
    self.endPoint = self.startPoint = [touch locationInView:self.pdfViewCtrl];
    _pageNumber = [self.pdfViewCtrl GetPageNumberFromScreenPt:self.startPoint.x y:self.startPoint.y];
    self.annotationPageNumber = _pageNumber;
    if( self.pageNumber <= 0 )
    {
        return YES;
    }

    self.hidden = NO;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], 0, 0);
    
    PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
        PTPage* pg = [doc GetPage:self.pageNumber];
        
        PTPDFRect* pageRect = [pg GetCropBox];
        
        CGRect cropBox = [self PDFRectPage2CGRectScreen:pageRect PageNumber:self.pageNumber];
        
        CGRect cropBoxContainer = CGRectMake(cropBox.origin.x+[self.pdfViewCtrl GetHScrollPos], cropBox.origin.y+[self.pdfViewCtrl GetVScrollPos], cropBox.size.width, cropBox.size.height);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        if( context )
            CGContextClipToRect(context, cropBoxContainer);
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",exception.name, exception.reason);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
    CGPoint touchPoint = [touch locationInView:self.pdfViewCtrl];
    self.endPoint = [self boundToPageScreenPoint:touchPoint];
    
    CGPoint origin = CGPointMake(MIN(self.startPoint.x, self.endPoint.x), MIN(self.startPoint.y, self.endPoint.y));
    
    double drawWidth = MAX(0,fabs(self.endPoint.x-self.startPoint.x));
    double drawHeight = MAX(0,fabs(self.endPoint.y-self.startPoint.y));
    
    // used by rectangle and ellipse
    _drawArea = CGRectMake(origin.x, origin.y, drawWidth, drawHeight);
    
    double width = self.pdfViewCtrl.frame.size.width;
    double height = self.pdfViewCtrl.frame.size.height;
    
    self.frame = CGRectMake([self.pdfViewCtrl GetHScrollPos], [self.pdfViewCtrl GetVScrollPos], width, height);

    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl *)pdfViewCtrl onTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSArray<PTAnnot *> *annots = [self annotationsInRect];
    if (annots.count > 0) {
        self.currentAnnotation = annots.firstObject;
        
        PTAnnotEditTool *aet = (PTAnnotEditTool*)[self.toolManager changeTool:[PTAnnotEditTool class]];
        [aet setSelectedAnnotations:annots];
        [aet selectAnnotation:self.currentAnnotation onPageNumber:self.pageNumber];
    } else {
        if (self.backToPanToolAfterUse) {
            // No annotations selected. Back to default tool.
            self.nextToolType = self.defaultClass;
        } else {
            // Stay in the current tool.
            self.nextToolType = [self class];
        }
        return NO;
    }
    return YES;
}

- (BOOL)pdfViewCtrl:(PTPDFViewCtrl*)pdfViewCtrl onTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    return [self pdfViewCtrl:pdfViewCtrl onTouchesEnded:touches withEvent:event];
}

- (NSArray<PTAnnot *> *)annotationsInRect
{
    NSMutableArray<PTAnnot *> *annotations = [NSMutableArray array];
    
    BOOL shouldUnlock = NO;
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        
        PTPage *page = [doc GetPage:self.pageNumber];
        if (![page IsValid]) {
            return nil;
        }
        int annotationCount = [page GetNumAnnots];
        NSMutableArray *primaryAnnots = [NSMutableArray array];
        NSMutableSet *groupIDs = [NSMutableSet set];
        for (int a = 0; a < annotationCount; a++) {
            PTAnnot *annot = [page GetAnnot:a];
            if (![annot IsValid] || ![annot IsMarkup]) { continue; }
            PTPDFRect* screen_rect = [self.pdfViewCtrl GetScreenRectForAnnot: annot page_num: self.self.pageNumber];
            CGRect annotRect = [self PDFRectScreen2CGRectScreen:screen_rect PageNumber:self.pageNumber];
            if (CGRectIntersectsRect(self.drawArea, annotRect)) {
                
                if (annot.annotationsInGroup.count > 1) {
                    if (![groupIDs containsObject:annot.annotationsInGroup.firstObject.uniqueID]) {
                        [groupIDs addObject:annot.annotationsInGroup.firstObject.uniqueID];
                        [primaryAnnots addObject:annot.annotationsInGroup.firstObject];
                    }
                }else{
                    [annotations addObject:annot];
                }
            }
        }
        for (PTAnnot *annot in primaryAnnots) {
            [annotations addObjectsFromArray:annot.annotationsInGroup];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",[exception name], [exception reason]);
    }
    @finally {
        if (shouldUnlock) {
            [self.pdfViewCtrl DocUnlockRead];
        }
    }
    
    [annotations sortUsingComparator:^NSComparisonResult(PTAnnot *a, PTAnnot *b) {
        NSDate *dateA = [a IsMarkup] ? [[[PTMarkup alloc] initWithAnn:a] GetCreationDates].NSDateValue : [a GetDate].NSDateValue;
        NSDate *dateB = [b IsMarkup] ? [[[PTMarkup alloc] initWithAnn:b] GetCreationDates].NSDateValue : [b GetDate].NSDateValue;
        return [dateA compare:dateB] == NSOrderedAscending;
    }];
    return [annotations copy];
}

-(CGPoint)boundToPageScreenPoint:(CGPoint)touchPoint
{
    PTPage* page;
    
    @try
    {
        [self.pdfViewCtrl DocLockRead];
        
        PTPDFDoc* doc = [self.pdfViewCtrl GetDoc];
        
        page = [doc GetPage:self.pageNumber];
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@: %@",[exception name], [exception reason]);
    }
    @finally {
        [self.pdfViewCtrl DocUnlockRead];
    }
    
    PTPDFRect* page_rect = [self pageBoxInScreenPtsForPageNumber:self.pageNumber];
    
    CGFloat minX = [page_rect GetX1];
    CGFloat maxX = [page_rect GetX2];
    CGFloat minY = [page_rect GetY1];
    CGFloat maxY = [page_rect GetY2];
    
    
    if( touchPoint.x < minX )
    {
        touchPoint.x = minX;
    }
    else if( touchPoint.x > maxX )
    {
        touchPoint.x = maxX;
    }
    
    if( touchPoint.y < minY )
    {
        touchPoint.y = minY;
    }
    else if( touchPoint.y > maxY )
    {
        touchPoint.y = maxY;
    }
    
    return CGPointMake(touchPoint.x, touchPoint.y);
    
}

-(void)setFrame:(CGRect)frame
{
    super.frame = frame;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    if( self.pageNumber >= 1)
    {
        CGRect myRect = self.drawArea;
        UIColor *color = [UIColor blueColor];
        CGFloat alpha = 0.2;
        CGContextSetFillColorWithColor(currentContext, color.CGColor);
        CGContextSetAlpha(currentContext, alpha);
        CGContextFillRect(currentContext, myRect);
        
        CGContextStrokePath(currentContext);
    }
}

@end
