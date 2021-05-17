//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDigSigView.h"

#import "PTColorIndicatorView.h"
#import "PTToolsUtil.h"

#include <tgmath.h>

@interface PTDigSigView()
{
	CALayer* _topBorder;
	UILabel* _signHereLabel;
    
    CGPoint m_startPoint;
    CGPoint m_endPoint;
    CGPoint m_currentPoint;
    CGFloat m_leftMost, m_rightMost, m_topMost, m_bottomMost;
}

@property (strong, nonatomic) PTColorIndicatorView* blackPen;
@property (strong, nonatomic) PTColorIndicatorView* redPen;
@property (strong, nonatomic) PTColorIndicatorView* bluePen;

@property (strong, nonatomic) UIButton* clearButton;

// Whether the points need to be adjusted when the view is added to the window.
// The points will be adjusted to be centered in the view.
@property (nonatomic, assign) BOOL needsPointAdjustment;

@end

@implementation PTDigSigView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self initWithFrame:CGRectZero withColour:[UIColor blackColor] withStrokeThickness:2.0];
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame withColour:(UIColor*)color withStrokeThickness:(CGFloat)thickness
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _boundingRect = CGRectZero;
        m_rightMost = m_bottomMost = CGFLOAT_MIN;
        m_leftMost = m_topMost = CGFLOAT_MAX;
        
        _strokeColor = color;
        _strokeThickness = thickness;

        UIColor *bgColor = [UIColor whiteColor];
        if (@available(iOS 11.0, *)) {
            bgColor = [UIColor colorNamed:@"brightBGColor" inBundle:[PTToolsUtil toolsBundle] compatibleWithTraitCollection:self.traitCollection];
        }
        self.backgroundColor = bgColor;

        // sign here label
        _signHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height*2/3, frame.size.width, 30)];
        
        _signHereLabel.text = PTLocalizedString(@"Sign Here", @"Where to drag their finger to apply a signature to the document.");
        _signHereLabel.textAlignment = NSTextAlignmentCenter;
        _signHereLabel.font = [_signHereLabel.font fontWithSize:14];
        
        // line to sign on
        _topBorder = [CALayer layer];
        _topBorder.frame = CGRectMake(3.0f, 0.0f, frame.size.width-3.0f, 1.0f);
        _topBorder.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1.0f].CGColor;
        [_signHereLabel.layer addSublayer:_topBorder];
        [self addSubview:_signHereLabel];
        
        UIView* touchBlockingView = [[UIView alloc] init];
        touchBlockingView.userInteractionEnabled = YES;
        touchBlockingView.exclusiveTouch = YES;
        touchBlockingView.backgroundColor = UIColor.clearColor;
        touchBlockingView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:touchBlockingView];
        
        self.blackPen = [[PTColorIndicatorView alloc] init];
        self.blackPen.color = UIColor.blackColor;
        [self.blackPen addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(changeColor:)]];
        
        [self addSubview:self.blackPen];
                
        self.redPen = [[PTColorIndicatorView alloc] init];
        self.redPen.color = UIColor.redColor;
        [self.redPen addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(changeColor:)]];
        
        [self addSubview:self.redPen];
                
        self.bluePen = [[PTColorIndicatorView alloc] init];
        self.bluePen.color = UIColor.blueColor;
        [self.bluePen addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(changeColor:)]];
        
        [self addSubview:self.bluePen];
        
        _blackPen.translatesAutoresizingMaskIntoConstraints = NO;
        [_blackPen.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor constant:-10].active = YES;
        [_blackPen.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor constant:8].active = YES;
        
        _bluePen.translatesAutoresizingMaskIntoConstraints = NO;
        [_bluePen.trailingAnchor constraintEqualToAnchor:_blackPen.layoutMarginsGuide.trailingAnchor constant:-40].active = YES;
        [_bluePen.topAnchor constraintEqualToAnchor:_blackPen.topAnchor].active = YES;
        
        _redPen.translatesAutoresizingMaskIntoConstraints = NO;
        [_redPen.trailingAnchor constraintEqualToAnchor:_bluePen.layoutMarginsGuide.trailingAnchor constant:-40].active = YES;
        [_redPen.topAnchor constraintEqualToAnchor:_blackPen.topAnchor].active = YES;

        for (PTColorIndicatorView *button in @[_blackPen, _bluePen, _redPen]) {
            button.selected = [self.strokeColor isEqual:button.color];
        }

        [touchBlockingView.trailingAnchor constraintEqualToAnchor:_blackPen.trailingAnchor constant:10].active = YES;
        [touchBlockingView.leadingAnchor constraintEqualToAnchor:_redPen.leadingAnchor constant:-10].active = YES;
        [touchBlockingView.topAnchor constraintEqualToAnchor:_blackPen.topAnchor constant:-10].active = YES;
        [touchBlockingView.bottomAnchor constraintEqualToAnchor:_blackPen.bottomAnchor constant:10].active = YES;
        
        NSString* clearText = PTLocalizedString(@"Clear signature", @"Clear signature");
        _clearButton = [[UIButton alloc] init];
        _clearButton.tintColor = Nil;
        [_clearButton setTitle:clearText forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clearSignature) forControlEvents:UIControlEventTouchUpInside];
        
        _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_clearButton];
        [_clearButton.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor].active = YES;
        [_clearButton.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor].active = YES;
        _clearButton.enabled = NO;
        _clearButton.alpha = 0.5;
        
        UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] init];
        panRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:panRecognizer];
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:(CGRect)frame withColour:[UIColor blackColor] withStrokeThickness:2.0];
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.needsPointAdjustment) {
        // Points need to be adjusted.
        // We know the size of this view now, so the points can be shifted to be centered.
        [self adjustPoints];
        
        // Points have been adjusted.
        self.needsPointAdjustment = NO;
    }
    
	// resize your layers based on the view's new bounds
	_signHereLabel.frame = CGRectMake(0, self.frame.size.height*2/3, self.frame.size.width, 30);
	_topBorder.frame = CGRectMake(3.0f, 0.0f, self.frame.size.width-6.0f, 1.0f);
    [self.clearButton setTitleColor:self.clearButton.tintColor forState:UIControlStateNormal];

}

- (void)adjustPoints
{
    if (self.points.count == 0) {
        return;
    }
    CGRect viewBounds = self.bounds;
    
    CGFloat adjustmentX = 0.0;
    CGFloat adjustmentY = 0.0;
    
    if (CGRectGetWidth(self.boundingRect) < CGRectGetWidth(viewBounds)) {
        adjustmentX = (CGRectGetWidth(viewBounds) - CGRectGetWidth(self.boundingRect)) / 2.0;
    }
    if (CGRectGetHeight(self.boundingRect) < CGRectGetHeight(viewBounds)) {
        adjustmentY = (CGRectGetHeight(viewBounds) - CGRectGetHeight(self.boundingRect)) / 2.0;
    }
    
    if (adjustmentX == 0.0 && adjustmentY == 0.0) {
        return;
    }
    
    NSMutableArray<NSValue *> *adjustedPoints = [NSMutableArray arrayWithCapacity:self.points.count];
    
    for (NSValue *value in self.points) {
        CGPoint point = value.CGPointValue;
        if (CGPointEqualToPoint(point, CGPointZero)) {
            [adjustedPoints addObject:value];
            continue;
        }
        
        point.x += adjustmentX;
        point.y += adjustmentY;
        
        [adjustedPoints addObject:@(point)];
    }
    
    self.points = adjustedPoints;
    
    self.boundingRect = CGRectOffset(self.boundingRect, adjustmentX, adjustmentY);
    
    [self setNeedsDisplay];
}

- (void)setPoints:(NSMutableArray<NSValue *> *)points
{
    _points = points;
    
    if (!self.window) {
        // View is not added to a window, so adjust the points once we know the size of this view.
        self.needsPointAdjustment = YES;
    }
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    _strokeColor = strokeColor;
    [self setNeedsDisplay];
}

- (void)setStrokeThickness:(CGFloat)strokeThickness
{
    _strokeThickness = strokeThickness;
    [self setNeedsDisplay];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    for (PTColorIndicatorView* button in @[self.blackPen, self.bluePen, self.redPen]) {
        button.selected = [self.strokeColor isEqual:button.color];
    }
}

-(void)changeColor:(UITapGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer.view isKindOfClass:[PTColorIndicatorView class]]) {
        return;
    }
    PTColorIndicatorView *button = (PTColorIndicatorView *)gestureRecognizer.view;
    self.strokeColor = button.color;
    
    for (PTColorIndicatorView* button in @[self.blackPen, self.bluePen, self.redPen]) {
        button.selected = [self.strokeColor isEqual:button.color];
    }
    
    [self setNeedsDisplay];
}

-(void)clearSignature
{
    [self.points removeAllObjects];
    _clearButton.enabled = NO;
    _clearButton.alpha = 0.5f;
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    
    if( touch.view != self )
    {
        return;
    }
    
    m_startPoint = [touch locationInView:self];
	
    CGPoint pagePoint = CGPointMake(m_startPoint.x, m_startPoint.y);
    
	if( !self.points )
	{
		self.points = [[NSMutableArray alloc] initWithCapacity:50];
	}
    
    [self.points addObject:[NSValue valueWithCGPoint:pagePoint]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
 
    if( touch.view != self )
    {
        return;
    }
    
    m_currentPoint = [touch locationInView:self];
    CGPoint pagePoint = CGPointMake(m_currentPoint.x, m_currentPoint.y);
    
    [self.points addObject:[NSValue valueWithCGPoint:pagePoint]];
    
    m_leftMost = fmin(m_leftMost, m_currentPoint.x);
    m_rightMost = fmax(m_rightMost, m_currentPoint.x);
    m_topMost = fmin(m_topMost, m_currentPoint.y);
    m_bottomMost = fmax(m_bottomMost, m_currentPoint.y);
	
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.allObjects[0];
    if( touch.view != self )
    {
        return;
    }
    
	[self.points addObject:[NSValue valueWithCGPoint:CGPointZero]];

    _clearButton.enabled = YES;
    _clearButton.alpha = 1.0f;
    
	[self setNeedsDisplay];
    
    m_leftMost = fmin(m_leftMost, m_currentPoint.x);
    m_rightMost = fmax(m_rightMost, m_currentPoint.x);
    m_topMost = fmin(m_topMost, m_currentPoint.y);
    m_bottomMost = fmax(m_bottomMost, m_currentPoint.y);
	
	self.boundingRect = CGRectMake(m_leftMost, m_topMost, m_rightMost-m_leftMost, m_bottomMost-m_topMost);
}

- (void)setBoundingRect:(CGRect)boundingRect
{
    _boundingRect = boundingRect;
    
    // Update the bounding points.
    m_leftMost = CGRectGetMinX(boundingRect);
    m_rightMost = CGRectGetMaxX(boundingRect);
    m_topMost = CGRectGetMinY(boundingRect);
    m_bottomMost = CGRectGetMaxY(boundingRect);
}

static CGPoint midPoint(CGPoint p1, CGPoint p2)
{
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

- (void)drawRect:(CGRect)rect
{
    if( _points )
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
		if( ! context )
			return;
        
        // Set up context.
        CGContextSetLineWidth(context, self.strokeThickness);
        CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetAlpha(context, 1.0);
        
        CGContextBeginPath(context);
        
        CGPoint previousPoint1 = CGPointZero;
        CGPoint previousPoint2 = CGPointZero;
        
        // Draw quadratic bezier curves between points.
        // Strokes are separated by CGPointZero points.
		for (NSValue* val in _points)
		{
			CGPoint currentPoint = val.CGPointValue;
            
			if( !CGPointEqualToPoint(currentPoint, CGPointZero) )
			{
				if( CGPointEqualToPoint(previousPoint1, CGPointZero) )
					previousPoint1 = currentPoint;
				
				if( CGPointEqualToPoint(previousPoint2, CGPointZero) )
					previousPoint2 = currentPoint;
                
                CGPoint mid1 = midPoint(previousPoint1, previousPoint2);
                CGPoint mid2 = midPoint(currentPoint, previousPoint1);
				
				CGContextMoveToPoint(context, mid1.x, mid1.y);
				
				CGContextAddQuadCurveToPoint(context, previousPoint1.x, previousPoint1.y, mid2.x, mid2.y);
			}
			else
			{
                // Current point is CGPointZero: end of stroke.
                previousPoint1 = CGPointZero;
			}
			
			previousPoint2 = previousPoint1;
			previousPoint1 = currentPoint;
		}
        
        CGContextStrokePath(context);
    }
}

@end
