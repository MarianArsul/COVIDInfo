//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTToolsUtil.h"
#import "PTAnnotStylePreview.h"

static NSString * const PT_textPreviewString = @"Abcde";
static const CGFloat PT_textPreviewDefaultTextSize = 36.0;

@interface PTAnnotStylePreview ()

@property (nonnull, nonatomic, strong) CAShapeLayer *shapeLayer;

@property (nonatomic) BOOL opaqueStroke;

@property (nonnull, nonatomic, readonly) UIBezierPath *adjustedShapePath;

@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) CAShapeLayer *textDecorationLayer;

@property (nonatomic, readonly) UIBezierPath *textDecorationPath;

@property (nonatomic, readonly, getter=isShapePreview) BOOL shapePreview;

@property (nonatomic) BOOL didSetupConstraints;

- (void)configureForAnnotType:(PTExtendedAnnotType)annotType;

- (BOOL)shouldInsetPath;

@end

@implementation PTAnnotStylePreview

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _fillColor = [UIColor clearColor];
        _textColor = nil; // Use system default color.
        _opaqueStroke = NO;

        if ([self.layer isKindOfClass:[CAShapeLayer class]]) {
            _shapeLayer = (CAShapeLayer *) self.layer;
        } else {
            _shapeLayer = [CAShapeLayer layer];

            [self.layer addSublayer:_shapeLayer];
        }

        _shapeLayer.strokeColor = _color.CGColor;
        _shapeLayer.fillColor = _fillColor.CGColor;

        _textLabel = [[UILabel alloc] initWithFrame:frame];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.hidden = YES;
        _textLabel.text = PT_textPreviewString;
        _textLabel.font = [UIFont systemFontOfSize:PT_textPreviewDefaultTextSize];


        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_textLabel];

        _textDecorationLayer = [CAShapeLayer layer];
        _textDecorationLayer.frame = _textLabel.bounds;
        _textDecorationLayer.path = nil;
        [_textLabel.layer addSublayer:_textDecorationLayer];

        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:
         @[
           [self.textLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
           [self.textLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
           ]];

        // Constraints are set up.
        self.didSetupConstraints = YES;
    }

    // Call super implementation as final step.
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if ([self isShapePreview]) {
        self.shapeLayer.path = self.adjustedShapePath.CGPath;
    } else {
        self.textDecorationLayer.frame = self.textLabel.bounds;

        self.textDecorationLayer.path = self.textDecorationPath.CGPath;
    }
}

- (void)configureForAnnotType:(PTExtendedAnnotType)annotType
{
    self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    if (@available(iOS 11.0, *)) {
        self.backgroundColor = [UIColor colorNamed:@"brightBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
    }

    if ([self isShapePreview]) {
        // Hide text preview.
        self.textLabel.hidden = YES;
        self.backgroundColor = nil;
        // Set shape colors.
        self.shapeLayer.strokeColor = self.color.CGColor;
        self.shapeLayer.fillColor = self.fillColor.CGColor;

        self.shapeLayer.lineWidth = self.thickness;
        self.shapeLayer.opacity = self.opacity;

        // Set line cap and join style.
        NSString *lineCap;
        NSString *lineJoin = kCALineJoinMiter;
        switch (annotType) {
            case PTExtendedAnnotTypeLine:
                lineCap = kCALineCapButt;
                break;
            case PTExtendedAnnotTypeInk:
            case PTExtendedAnnotTypeFreehandHighlight:
                lineCap = kCALineCapRound;
                break;
            case PTExtendedAnnotTypeCloudy:
                lineCap = kCALineCapRound;
                lineJoin = kCALineJoinRound;
                break;
            default:
                lineCap = kCALineCapButt;
                break;
        }
        self.shapeLayer.lineCap = lineCap;
        self.shapeLayer.lineJoin = lineJoin;

        // Set shape path.
        self.shapeLayer.path = self.adjustedShapePath.CGPath;
    } else {
        // Hide shape preview.
        self.shapeLayer.path = nil;
        self.shapeLayer.opacity = 1.0; // Reset opacity, since the shape layer is this view's layer.

        switch (annotType) {
            case PTExtendedAnnotTypeFreeText:
            case PTExtendedAnnotTypeCallout:
                self.textLabel.textColor = self.textColor;
                self.textLabel.alpha = self.opacity;
                break;
            case PTExtendedAnnotTypeHighlight:
                [self setHighlightColor:self.color withAlpha:self.opacity];
                break;
            case PTExtendedAnnotTypeUnderline:
            case PTExtendedAnnotTypeSquiggly:
            case PTExtendedAnnotTypeStrikeOut:
            case PTExtendedAnnotTypeCloudy:
                self.textDecorationLayer.strokeColor = self.color.CGColor;
                self.textDecorationLayer.lineWidth = self.thickness;
                self.textDecorationLayer.opacity = self.opacity;
                break;
            default:
                break;
        }

        self.textDecorationLayer.path = self.textDecorationPath.CGPath;

        // Show text label.
        self.textLabel.hidden = NO;
    }
}

- (void)setHighlightColor:(UIColor *)color withAlpha:(CGFloat)alpha
{
    CGColorRef targetColorRef = CGColorCreateCopyWithAlpha(color.CGColor,
                                                           CGColorGetAlpha(color.CGColor) * alpha);
    UIColor *targetColor = [UIColor colorWithCGColor:targetColorRef];
    CGColorRelease(targetColorRef);

    self.textLabel.backgroundColor = targetColor;
}

#pragma mark - Public property accessors

- (void)setAnnotType:(PTExtendedAnnotType)annotType
{
    _annotType = annotType;

    [self configureForAnnotType:annotType];
}

- (void)setColor:(UIColor *)color
{
    _color = color;

    switch (self.annotType) {
        case PTExtendedAnnotTypeHighlight:
            [self setHighlightColor:color withAlpha:self.opacity];
            break;
        case PTExtendedAnnotTypeUnderline:
        case PTExtendedAnnotTypeSquiggly:
        case PTExtendedAnnotTypeStrikeOut:
            self.textDecorationLayer.strokeColor = color.CGColor;
            break;
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypeArrow:
        case PTExtendedAnnotTypeSquare:
        case PTExtendedAnnotTypeCircle:
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypeFreehandHighlight:
        case PTExtendedAnnotTypePolyline:
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypeCloudy:
        case PTExtendedAnnotTypeRedact:
        case PTExtendedAnnotTypeRuler:
        case PTExtendedAnnotTypePerimeter:
        case PTExtendedAnnotTypeArea:
            self.shapeLayer.strokeColor = color.CGColor;
            self.opaqueStroke = CGColorGetAlpha(color.CGColor) > 0.0;
            self.shapeLayer.path = self.adjustedShapePath.CGPath;
            break;
        default:
            break;
    }
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;

    self.shapeLayer.fillColor = fillColor.CGColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;

    self.textLabel.textColor = textColor;
}

- (void)setFontDescriptor:(UIFontDescriptor *)fontDescriptor
{
    _fontDescriptor = fontDescriptor;

    CGFloat currentSize = self.textLabel.font.pointSize;
    
    self.textLabel.font = [UIFont fontWithDescriptor:fontDescriptor size:currentSize];
}

- (void)setThickness:(CGFloat)thickness
{
    _thickness = thickness;

    self.shapeLayer.lineWidth = thickness;
    self.shapeLayer.path = self.adjustedShapePath.CGPath;

    self.textDecorationLayer.lineWidth = thickness;
    self.textDecorationLayer.path = self.textDecorationPath.CGPath;
}

- (void)setOpacity:(CGFloat)opacity
{
    _opacity = opacity;

    if ([self isShapePreview]) {
        self.shapeLayer.opacity = opacity;
    } else {
        switch (self.annotType) {
            case PTExtendedAnnotTypeFreeText:
            case PTExtendedAnnotTypeCallout:
                self.textLabel.alpha = opacity;
                break;
            case PTExtendedAnnotTypeHighlight:
                [self setHighlightColor:self.color withAlpha:opacity];
                break;
            case PTExtendedAnnotTypeUnderline:
            case PTExtendedAnnotTypeSquiggly:
            case PTExtendedAnnotTypeStrikeOut:
                self.textDecorationLayer.opacity = opacity;
                break;
            default:
                break;
        }
    }
}

- (void)setTextSize:(CGFloat)textSize
{
    _textSize = textSize;

    UIFontDescriptor* fontDescriptor = self.textLabel.font.fontDescriptor;
    
    self.textLabel.font = [UIFont fontWithDescriptor:fontDescriptor size:textSize];
    
}

- (BOOL)isShapePreview
{
    switch (self.annotType) {
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypeSquare:
        case PTExtendedAnnotTypeCircle:
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypeFreehandHighlight:
        case PTExtendedAnnotTypePolyline:
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypeRedact:
        case PTExtendedAnnotTypeRuler:
        case PTExtendedAnnotTypePerimeter:
        case PTExtendedAnnotTypeArea:
            return YES;
        case PTExtendedAnnotTypeFreeText:
        case PTExtendedAnnotTypeCallout:
        case PTExtendedAnnotTypeHighlight:
        case PTExtendedAnnotTypeUnderline:
        case PTExtendedAnnotTypeSquiggly:
        case PTExtendedAnnotTypeStrikeOut:
            return NO;
        default:
            return YES;
    }
}

#pragma mark - Private property accessors

- (void)setOpaqueStroke:(BOOL)opaqueStroke
{
    if (opaqueStroke != _opaqueStroke) {
        _opaqueStroke = opaqueStroke;

        // Stroke visibility changed - update shape path insets.
        self.shapeLayer.path = self.adjustedShapePath.CGPath;
    }
}

- (UIBezierPath *)adjustedShapePath
{
    CGRect bounds = self.shapeLayer.bounds;
    
    if ([self shouldInsetPath]) {
        bounds = CGRectInset(bounds, self.thickness / 2, self.thickness / 2);
    }

    switch (self.annotType) {
        case PTExtendedAnnotTypeLine:
        case PTExtendedAnnotTypePolyline:
        case PTExtendedAnnotTypeRuler:
        case PTExtendedAnnotTypePerimeter:
            return [self linePathWithBounds:bounds];
            break;
        case PTExtendedAnnotTypeArrow:
            return [self arrowPathWithBounds:bounds];
            break;
        case PTExtendedAnnotTypeCloudy:
            return [self cloudPathWithBounds:bounds];
            break;
        case PTExtendedAnnotTypePolygon:
        case PTExtendedAnnotTypeArea:
            return [self hexagonalPathWithBounds:bounds];
            break;
        case PTExtendedAnnotTypeSquare:
        case PTExtendedAnnotTypeRedact:
            return [UIBezierPath bezierPathWithRect:bounds];
            break;
        case PTExtendedAnnotTypeCircle:
            return [UIBezierPath bezierPathWithOvalInRect:bounds];
            break;
        case PTExtendedAnnotTypeInk:
        case PTExtendedAnnotTypeFreehandHighlight:
            return [self inkPathWithBounds:bounds];
            break;
        default:
            return [UIBezierPath bezierPath];
            break;
    }
}

- (BOOL)shouldInsetPath
{
    switch (self.annotType) {
        // Inset square (and redaction) and circle paths when stroke is opaque.
        case PTExtendedAnnotTypeSquare:
        case PTExtendedAnnotTypeCircle:
        case PTExtendedAnnotTypeRedact:
            return (self.opaqueStroke == YES);
        default:
            return NO;
    }
}

- (UIBezierPath *)textDecorationPath
{
    CGRect bounds = self.textDecorationLayer.bounds;

    switch (self.annotType) {
        case PTExtendedAnnotTypeUnderline:
            return [self underlinePathWithBounds:bounds];
        case PTExtendedAnnotTypeSquiggly:
            return [self squigglyUnderlinePathWithBounds:bounds];
        case PTExtendedAnnotTypeStrikeOut:
            return [self linePathWithBounds:bounds];
        default:
            return nil;
    }
}

- (UIBezierPath *)linePathWithBounds:(CGRect)bounds
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGFloat centerY = bounds.origin.y + floorf(bounds.size.height / 2.0);
    
    // Configure style preview for ruler measurements
    CGFloat capOffset = self.thickness*2.0f;
    if (self.annotType == PTExtendedAnnotTypeRuler) {
        [path moveToPoint:CGPointMake(bounds.origin.x, centerY-capOffset)];
        [path addLineToPoint:CGPointMake(bounds.origin.x, centerY+capOffset)];
    }
    
    // Start point.
    [path moveToPoint:CGPointMake(bounds.origin.x, centerY)];
    // Line to end point.
    [path addLineToPoint:CGPointMake(bounds.origin.x + bounds.size.width, centerY)];
  
    if (self.annotType == PTExtendedAnnotTypeRuler) {
        [path moveToPoint:CGPointMake(bounds.origin.x+(bounds.size.width), centerY-capOffset)];
        [path addLineToPoint:CGPointMake(bounds.origin.x+(bounds.size.width), centerY+capOffset)];
    }
    return path;
}

- (UIBezierPath *)arrowPathWithBounds:(CGRect)bounds
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGFloat centerY = bounds.origin.y + floorf(bounds.size.height / 2.0);
    
    // Add head of arrow first:
    // Start at end of top arrowhead "barb".
    [path moveToPoint:CGPointMake(bounds.origin.x+(0.90*bounds.size.width), centerY-(0.1*bounds.size.width))];
    // Add line to center of arrowhead.
    [path addLineToPoint:CGPointMake(bounds.origin.x + bounds.size.width, centerY)];
    // Add line to bottom arrowhead "barb"
    [path addLineToPoint:CGPointMake(bounds.origin.x+(0.90*bounds.size.width), centerY+(0.1*bounds.size.width))];
    
    // Add tail of arrow:
    // Move to center of arrowhead.
    [path moveToPoint:CGPointMake(bounds.origin.x + bounds.size.width, centerY)];
    // Add line to base of arrow tail.
    [path addLineToPoint:CGPointMake(bounds.origin.x, centerY)];
    
    return path;
}


- (UIBezierPath *)inkPathWithBounds:(CGRect)bounds
{
    UIBezierPath *path = [UIBezierPath bezierPath];

    CGFloat centerX = bounds.origin.x + floorf(bounds.size.width / 2.0);
    CGFloat centerY = bounds.origin.y + floorf(bounds.size.height / 2.0);

    // Start point.
    [path moveToPoint:CGPointMake(bounds.origin.x, centerY)];
    // Cubic Bézier curve to end point.
    [path addCurveToPoint:CGPointMake(bounds.origin.x + bounds.size.width, centerY)

            controlPoint1:CGPointMake(centerX, bounds.origin.y + floorf(bounds.size.height * 1.5))

            controlPoint2:CGPointMake(centerX, bounds.origin.y - floorf(bounds.size.height / 2))];

    return path;
}

- (UIBezierPath *)underlinePathWithBounds:(CGRect)bounds
{
    UIBezierPath *path = [UIBezierPath bezierPath];

    CGFloat bottomY = bounds.origin.y + bounds.size.height;

    // Start point.
    [path moveToPoint:CGPointMake(bounds.origin.x, bottomY)];
    // Line to end point.
    [path addLineToPoint:CGPointMake(bounds.origin.x + bounds.size.width, bottomY)];

    return path;
}


- (UIBezierPath *)squigglyUnderlinePathWithBounds:(CGRect)bounds
{
    return [self underlinePathWithBounds:bounds];
}

- (UIBezierPath *)hexagonalPathWithBounds:(CGRect)bounds
{
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);

    CGFloat centerX = CGRectGetMidX(bounds);
    CGFloat centerY = CGRectGetMidY(bounds);

    CGFloat diameter = MIN(width, height);
    CGFloat radius = diameter*0.5;
    CGFloat hexagonHeight = (radius*sqrt(3.0)*0.5);

    CGFloat left = centerX - (radius);
    CGFloat right = centerX + (radius);
    CGFloat top = centerY - hexagonHeight;
    CGFloat bottom = centerY + hexagonHeight;

    UIBezierPath *path = [UIBezierPath bezierPath];

    // Start point (left centre point)
    [path moveToPoint:CGPointMake(left, centerY)];

    // Move clockwise around the hexagon
    [path addLineToPoint:CGPointMake(centerX - (diameter*0.25), top)];
    [path addLineToPoint:CGPointMake(centerX + (diameter*0.25), top)];
    [path addLineToPoint:CGPointMake(right, centerY)];
    [path addLineToPoint:CGPointMake(centerX + (diameter*0.25), bottom)];
    [path addLineToPoint:CGPointMake(centerX - (diameter*0.25), bottom)];
    [path closePath];

    return path;
}

- (UIBezierPath *)cloudPathWithBounds:(CGRect)bounds
{
    UIBezierPath *path = [UIBezierPath bezierPath];

    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);

    // Limit the preview to a square shape
    CGFloat maxWidth = 0.9*MIN(width, height);

    // Set how many arcs to draw between corners. The actual number of arcs on each side will be one more than this value as this takes into account the corner points.
    CGFloat nArcs = 4.0;
    CGFloat diameter = (1.0/nArcs)*maxWidth;
    CGFloat radius = 0.5*diameter;

    CGFloat centerX = CGRectGetMidX(bounds);
    CGFloat centerY = CGRectGetMidY(bounds);

    CGFloat left = centerX - (0.5*maxWidth);
    CGFloat right = centerX + (0.5*maxWidth);
    CGFloat top = centerY - (0.5*maxWidth);
    CGFloat bottom = centerY + (0.5*maxWidth);

    // Top edge
    for (int a = 0; a < nArcs; a++) {
        CGFloat startAngle = a == 0 ? M_PI_2 : M_PI;
        [path addArcWithCenter:CGPointMake(left+(a*diameter), top) radius:radius startAngle:startAngle endAngle:0 clockwise:YES];
    }
    // Right edge
    for (int a = 0; a < nArcs; a++) {
        CGFloat startAngle = a == 0 ? M_PI : 3*M_PI_2;
        [path addArcWithCenter:CGPointMake(right, top+(a*diameter)) radius:radius startAngle:startAngle endAngle:M_PI_2 clockwise:YES];
    }
    // Bottom edge
    for (int a = 0; a < nArcs; a++) {
        CGFloat startAngle = a == 0 ? 3*M_PI_2 : 0;
        [path addArcWithCenter:CGPointMake(right-(a*diameter), bottom) radius:radius startAngle: startAngle endAngle:M_PI clockwise:YES];
    }
    // Left edge
    for (int a = 0; a < nArcs; a++) {
        CGFloat startAngle = a == 0 ? 2*M_PI : M_PI_2;
        [path addArcWithCenter:CGPointMake(left, bottom-(a*diameter)) radius:radius startAngle: startAngle endAngle:3*M_PI_2 clockwise:YES];
    }

    return path;
}

@end
