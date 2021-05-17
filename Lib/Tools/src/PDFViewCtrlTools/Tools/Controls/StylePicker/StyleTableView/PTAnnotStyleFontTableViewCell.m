//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotStyleFontTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotStyleFontTableViewCell ()

@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *fontLabel;

@property (nonatomic) BOOL constraintsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotStyleFontTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Stack view;
        _stackView = [[UIStackView alloc] init];
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.distribution = UIStackViewDistributionFill;
        _stackView.spacing = 10;
        
        _stackView.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
        _stackView.preservesSuperviewLayoutMargins = YES;
        _stackView.layoutMarginsRelativeArrangement = YES;
        
        [self.contentView addSubview:_stackView];
                
        // Label.
        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _label.numberOfLines = 1;
        
        // Strongly hug content along horizontal axis.
        [_label setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                  forAxis:UILayoutConstraintAxisHorizontal];
        
        [_stackView addArrangedSubview:_label];
        
        // Font label.
        _fontLabel = [[UILabel alloc] init];
        _fontLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _fontLabel.allowsDefaultTighteningForTruncation = YES;
        _fontLabel.textAlignment = NSTextAlignmentRight;
                
        // Weakly hug content along horizontal axis...
        [_fontLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                      forAxis:UILayoutConstraintAxisHorizontal];
        // .. and strongly resist compression along horizontal axis.
        [_fontLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                    forAxis:UILayoutConstraintAxisHorizontal];
                
        [_stackView addArrangedSubview:_fontLabel];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
    ]];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Configuration

- (void)configureWithItem:(PTAnnotStyleFontTableViewItem *)item
{
    self.label.text = item.title;
    
    UIFont *font = [UIFont fontWithDescriptor:item.fontDescriptor
                                         size:UIFont.labelFontSize];
    if (@available(iOS 11.0, *)) {
        // Scale the font for the Body text style.
        UIFontMetrics *fontMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
        font = [fontMetrics scaledFontForFont:font];
    }
    self.fontLabel.font = font;
    self.fontLabel.text = font.familyName;
}

@end
