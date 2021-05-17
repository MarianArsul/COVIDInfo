//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTShapeView.h"

#import "CGGeometry+PTAdditions.h"

@implementation PTShapeView

@dynamic layer;

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (void)setBounds:(CGRect)bounds
{
    CGRect previousBounds = self.bounds;
    
    [super setBounds:bounds];
    
    if (!CGRectEqualToRect(previousBounds, bounds)) {
        [self updatePath];
    }
}

- (void)updatePath
{
    CGPathRef path = self.layer.path;
    if (!path || CGPathIsEmpty(path)) {
        return;
    }
    
    CGRect boundingBox = CGPathGetBoundingBox(path);
    if (CGRectIsEmpty(boundingBox)) {
        return;
    }
    CGRect viewBounds = self.bounds;
    
    CGFloat boundingBoxAspectRatio = PTCGSizeAspectRatio(boundingBox.size);
    CGFloat viewAspectRatio = PTCGSizeAspectRatio(viewBounds.size);
    
    CGFloat scaleFactor = 1.0;
    if (boundingBoxAspectRatio > viewAspectRatio) {
        // Width is the limiting dimension.
        scaleFactor = CGRectGetWidth(viewBounds) / CGRectGetWidth(boundingBox);
    } else {
        // Height is the limiting dimension.
        scaleFactor = CGRectGetHeight(viewBounds) / CGRectGetHeight(boundingBox);
    }
    
    CGAffineTransform pathTransform = CGAffineTransformIdentity;
    
    pathTransform = CGAffineTransformScale(pathTransform, scaleFactor, scaleFactor);
    
    pathTransform = CGAffineTransformTranslate(pathTransform,
                                               -CGRectGetMinX(boundingBox), -CGRectGetMinY(boundingBox));
    
    // If you want to be fancy you could also center the path in the view
    // i.e. if you don't want it to stick to the top.
    // It is done by calculating the heigth and width difference and translating
    // half the scaled value of that in both x and y (the scaled side will be 0)
    CGSize scaledSize = CGSizeApplyAffineTransform(boundingBox.size,
                                                   CGAffineTransformMakeScale(scaleFactor, scaleFactor));
    CGSize centerOffset = CGSizeMake((CGRectGetWidth(viewBounds) - scaledSize.width) / (scaleFactor * 2.0),
                                     (CGRectGetHeight(viewBounds) - scaledSize.height) / (scaleFactor * 2.0));
    pathTransform = CGAffineTransformTranslate(pathTransform, centerOffset.width, centerOffset.height);
    
    CGPathRef scaledPath = CGPathCreateMutableCopyByTransformingPath(path, &pathTransform);
    
    self.layer.path = scaledPath;
    
    CGPathRelease(scaledPath);
    scaledPath = nil;
}

@end
