//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationReplyHeaderView.h"

#import "PTToolImages.h"
#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

@interface PTAnnotationReplyHeaderView ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, assign) BOOL firstLayoutDone;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTAnnotationReplyHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        // Horizontal stack view.
        _stackView = [[UIStackView alloc] init];
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.distribution = UIStackViewDistributionFill;
        _stackView.spacing = 10.0;

        [self.contentView addSubview:_stackView];
        
        // Image view.
        _imageView = [[UIImageView alloc] init];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
                
        [_stackView addArrangedSubview:_imageView];
        
        // Label.
        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _label.numberOfLines = 2;
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        
        _label.font = [UIFont italicSystemFontOfSize:UIFont.systemFontSize];
        
        [_stackView addArrangedSubview:_label];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.imageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

    // Allow the label to grow to fill the available space.
    [self.label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    UILayoutGuide *layoutMarginsGuide = self.contentView.layoutMarginsGuide;

    [NSLayoutConstraint activateConstraints:
     @[
       [self.stackView.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
       [self.stackView.trailingAnchor constraintEqualToAnchor:layoutMarginsGuide.trailingAnchor],
       [self.stackView.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
       [self.stackView.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
       
       [self.imageView.widthAnchor constraintEqualToConstant:16.0],
       [self.imageView.heightAnchor constraintEqualToAnchor:self.imageView.widthAnchor],
       ]];
}

- (void)updateConstraints
{
    // Only load constraints after the first layout update, otherwise the loaded constraints will be
    // broken by the (zero width/height) contentView's autoresizingMask constraints.
    if (self.firstLayoutDone && !self.constraintsLoaded) {
        [self loadConstraints];
        
        // Constraints are loaded.
        self.constraintsLoaded = YES;
    }
    
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Wait until after the first layout update to load constraints.
    if (!self.firstLayoutDone) {
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
        
        self.firstLayoutDone = YES;
    }
}

#pragma mark - Public API

- (void)configureWithAnnotation:(PTManagedAnnotation *)annotation
{
    self.imageView.image = [PTToolImages imageForAnnotationType:(PTExtendedAnnotType)annotation.type];
    
    self.imageView.tintColor = annotation.color;
    self.imageView.alpha = annotation.opacity;
    
    self.label.text = annotation.contents;
}

@end
