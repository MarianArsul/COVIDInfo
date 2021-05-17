//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPDFViewCtrl+PTAdditions.h"

#import "PTAnnot+PTAdditions.h"

#include <tgmath.h>

@implementation PTPDFViewCtrl (PTAdditions)

- (nullable NSString *)uniqueIDForAnnot:(PTAnnot *)annot
{
    if (!annot) {
        return nil;
    }
    
    NSString *annotationIdentifier = nil;
    
    BOOL shouldUnlock = NO;
    @try {
        [self DocLockRead];
        shouldUnlock = YES;
        
        if ([annot IsValid]) {
            annotationIdentifier = annot.uniqueID;
        }
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    } @finally {
        if (shouldUnlock) {
            [self DocUnlockRead];
        }
    }

    return annotationIdentifier;
}

- (PTAnnot *)findAnnotWithUniqueID:(NSString *)uniqueID onPageNumber:(int)pageNumber
{
    if (uniqueID.length == 0 || pageNumber < 1) {
        return nil;
    }
    
    BOOL shouldUnlock = NO;
    @try {
        [self DocLockRead];
        shouldUnlock = YES;
        
        NSArray<PTAnnot *> *annots = [self GetAnnotationsOnPage:pageNumber];
        for (PTAnnot *annot in annots) {
            if (![annot IsValid]) {
                continue;
            }
            
            // Check if the annot's unique ID matches.
            NSString *annotUniqueId = annot.uniqueID;
            if (annotUniqueId && [annotUniqueId isEqualToString:uniqueID]) {
                return annot;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [self DocUnlockRead];
        }
    }
    
    return nil;
}

- (void)flashAnnotation:(PTAnnot *)annot onPageNumber:(int)pageNumber
{
    PTPDFRect *screen_rect = [self GetScreenRectForAnnot:annot page_num: pageNumber];
    double x1 = [screen_rect GetX1];
    double x2 = [screen_rect GetX2];
    double y1 = [screen_rect GetY1];
    double y2 = [screen_rect GetY2];
    
    CGRect rect = CGRectMake(fmin(x1, x2), fmin(y1, y2),
                             fmax(x1, x2) - fmin(x1, x2), fmax(y1, y2) - fmin(y1, y2));
    
    rect.origin.x += [self GetHScrollPos];
    rect.origin.y += [self GetVScrollPos];
    
    [self SetCurrentPage:pageNumber];
    
    // Create a view to be our highlight marker.
    UIView *highlight = [[UIView alloc] initWithFrame:rect];
    highlight.backgroundColor = [UIColor colorWithRed:0.4375f green:0.53125f blue:1.0f alpha:1.0f];
    [self.toolOverlayView addSubview:highlight];
    
    // Pulse the annotation.
    highlight.alpha = 0.0f;
    
    // Alpha: 0.0 -> 1.0 -> 0.5 -> 1.0 -> 0.0
    [UIView animateKeyframesWithDuration:1.0 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.25 animations:^{
            highlight.alpha = 1.0;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
            highlight.alpha = 0.5;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.50 relativeDuration:0.25 animations:^{
            highlight.alpha = 1.0;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0.25 animations:^{
            highlight.alpha = 0.0;
        }];
    } completion:^(BOOL finished) {
        [highlight removeFromSuperview];
    }];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTPDFViewCtrl, PTAdditions)
