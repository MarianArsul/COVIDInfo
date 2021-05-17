
//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTRotateWidgetView.h"
#import "PTToolsUtil.h"

static const int circleDiameter = 12;

@interface PTRotateWidgetView ()

@property (nonatomic, readonly, strong, nonnull) CAShapeLayer *shapeLayer;

@end

@implementation PTRotateWidgetView

- (instancetype)initAtPoint:(CGPoint)point
{
    int diameter = PTRotateWidgetView.diameter;
    self = [super initWithFrame:CGRectMake(point.x, point.y, diameter, diameter)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UIColor *bgColor = [UIColor whiteColor];
        UIImage *rotateHandleImage = [PTToolsUtil toolImageNamed:@"ic_rotate_right_black_24px.png"];
        UIImageView *rotateImageView = [[UIImageView alloc] initWithImage:rotateHandleImage];
        rotateImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:rotateImageView];
        [NSLayoutConstraint activateConstraints:
         @[[rotateImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
           [rotateImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
           [rotateImageView.heightAnchor constraintEqualToAnchor:self.heightAnchor],
           [rotateImageView.widthAnchor constraintEqualToAnchor:self.widthAnchor]]];

        rotateImageView.tintColor = bgColor;

        // Set up circle shape.
        self.shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
        self.shapeLayer.lineWidth = 1;
    }
    
    return self;
}

-(void)didMoveToWindow
{
    self.shapeLayer.fillColor = self.window.tintColor.CGColor;
    self.shapeLayer.strokeColor = UIColor.whiteColor.CGColor;
    self.shapeLayer.shadowColor = UIColor.blackColor.CGColor;
    self.shapeLayer.shadowRadius = 0.5;
    self.shapeLayer.shadowOpacity = 0.2;
    self.shapeLayer.shadowOffset = CGSizeMake(0,1);

    self.shapeLayer.lineWidth = 0.5;
}

+ (int)diameter
{
    return circleDiameter*2;
}

#pragma mark - Layer

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer
{
    return (CAShapeLayer *)(self.layer);
}
@end
