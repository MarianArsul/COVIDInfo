//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "CGContext+PTAdditions.h"

#include <tgmath.h>

void pt_CGContextAddArcTo(CGContextRef context, double radius, double xAxisRotation, BOOL isLargeArc, BOOL sweep, double endX, double endY)
{
    CGPoint start = CGContextGetPathCurrentPoint(context);
    double startX = start.x;
    double startY = start.y;
    
    double xRadius = radius, yRadius = radius;
    
    // Conversion from endpoint to center parameterization.
    // Reference: https://www.w3.org/TR/SVG/implnote.html#ArcConversionEndpointToCenter
    
    // Check for zero-length arc.
    if (startX == endX && startY == endY) {
        return;
    }
    
    if (xRadius == 0.0 || yRadius == 0.0) {
        // Arc is treated as a straight line segment joining the endpoints.
        CGContextAddLineToPoint(context, endX, endY);
        return;
    }
    
    if (xRadius < 0.0) {
        xRadius = -xRadius;
    }
    if (yRadius < 0.0) {
        yRadius = -yRadius;
    }
    
    // Calculate the middle point between
    // the current and the final points
    //------------------------
    double dx2 = (startX - endX) / 2.0;
    double dy2 = (startY - endY) / 2.0;
    
    double cosA = cos(xAxisRotation);
    double sinA = sin(xAxisRotation);
    
    // Calculate (x1, y1)
    //------------------------
    double x1 =  cosA * dx2 + sinA * dy2;
    double y1 = -sinA * dx2 + cosA * dy2;
    
    // Ensure radii are large enough
    //------------------------
    double prx = xRadius * xRadius;
    double pry = yRadius * yRadius;
    double px1 = x1 * x1;
    double py1 = y1 * y1;
    
    // Check that radii are large enough
    //------------------------
    double radiiCheck = (px1/prx) + (py1/pry);
    if (radiiCheck > 1.0) {
        xRadius = sqrt(radiiCheck) * xRadius;
        yRadius = sqrt(radiiCheck) * yRadius;
        prx = xRadius * xRadius;
        pry = yRadius * yRadius;
    }
    
    double denom = (prx*py1) + (pry*px1);
    if (!denom) {
        // we shouldn't divide by zero
        // (this is a strange case if it occurs in an actual document
        // since it seems to only occur when start=end)
        //NSCAssert(false, @"");
        return;
    }
    
    // Calculate (cx1, cy1)
    //------------------------
    double sign = (isLargeArc == sweep) ? -1.0 : 1.0;
    double sq   = ((prx*pry) - (prx*py1) - (pry*px1)) / (denom);
    double coef = sign * sqrt((sq < 0) ? 0 : sq);
    double cx1  = coef *  ((xRadius * y1) / yRadius);
    double cy1  = coef * -((yRadius * x1) / xRadius);
    
    // Calculate (cx, cy) from (cx1, cy1)
    //------------------------
    double sx2 = (startX + endX) / 2.0;
    double sy2 = (startY + endY) / 2.0;
    double cx = sx2 + (cosA * cx1 - sinA * cy1);
    double cy = sy2 + (sinA * cx1 + cosA * cy1);
    
    // Calculate the start angle (angle1) and the sweep angle (dangle)
    //------------------------
    double ux =  (x1 - cx1) / xRadius;
    double uy =  (y1 - cy1) / yRadius;
    double vx = (-x1 - cx1) / xRadius;
    double vy = (-y1 - cy1) / yRadius;
    double p, n;
    
    // Calculate the angle start
    //------------------------
    n = sqrt((ux*ux) + (uy*uy));
    p = ux; // (1 * ux) + (0 * uy)
    sign = (uy < 0) ? -1.0 : 1.0;
    double startAngle = sign * acos(p/n);
    
    // Calculate the sweep angle
    //------------------------
    n = sqrt((ux*ux + uy*uy) * (vx*vx + vy*vy));
    p = ux * vx + uy * vy;
    sign = ((ux * vy) - (uy * vx) < 0) ? -1.0 : 1.0;
    
    // we want to avoid taking the inverse cosine of
    // a value > 1 or < -1 since it is undefined
    // (this can occur due to rounding error)
    double acosValue = fmax(fmin(p/n, 1.0), -1.0);
    
    double sweepAngle = sign * acos(acosValue);
    
    // Ensure the sweep angle has the correct sign for the sweep direction.
    if (!sweep && sweepAngle > 0) {
        sweepAngle -= M_PI * 2.0;
    } else if (sweep && sweepAngle < 0) {
        sweepAngle += M_PI * 2.0;
    }
    
    double endAngle = startAngle + sweepAngle;
    
    // Rotate back to original coordinate system.
    startAngle += xAxisRotation;
    endAngle += xAxisRotation;
    
    // Core Graphics uses a flipped coordinate system in iOS, so sweep direction is also flipped.
    BOOL clockwise = !sweep;
    
    CGContextAddArc(context, cx, cy, radius, startAngle, endAngle, clockwise);
}
