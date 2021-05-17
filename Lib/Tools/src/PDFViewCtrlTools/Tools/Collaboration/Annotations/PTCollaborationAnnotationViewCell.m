//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTCollaborationAnnotationViewCell.h"

#import "PTCollaborationUnreadIndicatorView.h"
#import "PTToolImages.h"

#import <tgmath.h>

@interface PTCollaborationAnnotationViewCell ()

@property (nonatomic, strong) UIStackView *containerStackView;

@property (nonatomic, strong) UIStackView *messageStackView;

@property (nonatomic, strong) UILayoutGuide *contentLayoutGuide;
@property (nonatomic, strong, nullable) NSLayoutConstraint *leadingContentConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *topContentConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *trailingContentConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomContentConstraint;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTCollaborationAnnotationViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Container stack view.
        _containerStackView = [[UIStackView alloc] init];
        _containerStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _containerStackView.axis = UILayoutConstraintAxisHorizontal;
        _containerStackView.alignment = UIStackViewAlignmentTop;
        _containerStackView.distribution = UIStackViewDistributionFill;
        _containerStackView.spacing = 10.0;
        
        [self.contentView addSubview:_containerStackView];
        
        // Annotation image view.
        _annotationImageView = [[UIImageView alloc] init];
        _annotationImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _annotationImageView.hidden = YES;
        
        [_containerStackView addArrangedSubview:_annotationImageView];
        
        // Message stack view.
        _messageStackView = [[UIStackView alloc] init];
        _messageStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _messageStackView.axis = UILayoutConstraintAxisVertical;
        _messageStackView.alignment = UIStackViewAlignmentLeading;
        _messageStackView.distribution = UIStackViewDistributionFill;
        _messageStackView.spacing = 4.0;
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _titleLabel.numberOfLines = 1;
        
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _titleLabel.enabled = NO; // Dimmed appearance.
        
        [_messageStackView addArrangedSubview:_titleLabel];
        
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _messageLabel.numberOfLines = 2;
        
        _messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        
        [_messageStackView addArrangedSubview:_messageLabel];
        
        [_containerStackView addArrangedSubview:_messageStackView];
        
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _dateLabel.numberOfLines = 1;
        _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        
        [_containerStackView addArrangedSubview:_dateLabel];
        
        _unreadIndicatorView = [[PTCollaborationUnreadIndicatorView alloc] init];
        _unreadIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:_unreadIndicatorView];
        
        // Hide unread indicator by default.
        _unreadIndicatorView.hidden = YES;
        
        UILayoutGuide *layoutMarginsGuide = self.contentView.layoutMarginsGuide;
        
        _contentLayoutGuide = [[UILayoutGuide alloc] init];
        _contentLayoutGuide.identifier = @"content-layout-guide";
        [self.contentView addLayoutGuide:_contentLayoutGuide];
        
        self.leadingContentConstraint =
        [_contentLayoutGuide.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor
                                                          constant:0.0];
        self.topContentConstraint =
        [_contentLayoutGuide.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor
                                                      constant:0.0];
        self.trailingContentConstraint =
        [_contentLayoutGuide.trailingAnchor constraintEqualToAnchor:layoutMarginsGuide.trailingAnchor
                                                           constant:0.0];
        self.bottomContentConstraint =
        [_contentLayoutGuide.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor
                                                         constant:0.0];
        
        // Schedule contraints setup.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.containerStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *leadingMarginGuide = [[UILayoutGuide alloc] init];
    leadingMarginGuide.identifier = @"leading-margin-guide";
    [self.contentView addLayoutGuide:leadingMarginGuide];
    
    UILayoutGuide *contentLayoutGuide = self.contentLayoutGuide;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [leadingMarginGuide.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
       [leadingMarginGuide.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
       [leadingMarginGuide.trailingAnchor constraintEqualToAnchor:self.containerStackView.leadingAnchor],
       [leadingMarginGuide.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
       
       [self.unreadIndicatorView.centerXAnchor constraintEqualToAnchor:leadingMarginGuide.centerXAnchor],
       [self.unreadIndicatorView.centerYAnchor constraintEqualToAnchor:leadingMarginGuide.centerYAnchor],
       
       [self.unreadIndicatorView.leadingAnchor constraintGreaterThanOrEqualToAnchor:leadingMarginGuide.leadingAnchor],
       [self.unreadIndicatorView.topAnchor constraintGreaterThanOrEqualToAnchor:leadingMarginGuide.topAnchor],
       [self.unreadIndicatorView.trailingAnchor constraintLessThanOrEqualToAnchor:leadingMarginGuide.trailingAnchor],
       [self.unreadIndicatorView.bottomAnchor constraintLessThanOrEqualToAnchor:leadingMarginGuide.bottomAnchor],
       
       [self.containerStackView.leadingAnchor constraintEqualToAnchor:contentLayoutGuide.leadingAnchor],
       [self.containerStackView.topAnchor constraintEqualToAnchor:contentLayoutGuide.topAnchor],
       [self.containerStackView.trailingAnchor constraintEqualToAnchor:contentLayoutGuide.trailingAnchor],
       [self.containerStackView.bottomAnchor constraintEqualToAnchor:contentLayoutGuide.bottomAnchor],
       
       [self.annotationImageView.widthAnchor constraintEqualToAnchor:self.annotationImageView.heightAnchor],
       
       // Message stack view matches its parent's height. This allows short message content to be
       // vertically centered in the cell.
       [self.messageStackView.heightAnchor constraintEqualToAnchor:self.containerStackView.heightAnchor],
       
       self.leadingContentConstraint,
       self.topContentConstraint,
       self.trailingContentConstraint,
       self.bottomContentConstraint,
       ]];
    
    [self.messageStackView setContentHuggingPriority:UILayoutPriorityDefaultLow
                                             forAxis:UILayoutConstraintAxisVertical];
    [self.messageStackView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                           forAxis:UILayoutConstraintAxisVertical];
    
    [self.messageLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                       forAxis:UILayoutConstraintAxisVertical];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
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

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGSize systemLayoutSize = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    
    // Enforce a minimum cell (content) height of 44 pts.
    systemLayoutSize.height = fmax(44.0, systemLayoutSize.height);
    return systemLayoutSize;
}

#pragma mark Content insets

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _contentInsets = contentInsets;
    
    self.leadingContentConstraint.constant = contentInsets.left;
    self.topContentConstraint.constant = contentInsets.top;
    self.trailingContentConstraint.constant = contentInsets.right;
    self.bottomContentConstraint.constant = contentInsets.bottom;
}

#pragma mark - Configuration

- (void)configureWithAnnotation:(PTManagedAnnotation *)annotation
{
    self.unreadIndicatorView.hidden = (annotation.unreadCount == 0);
    
    self.annotationImageView.image = [PTToolImages imageForAnnotationType:(PTExtendedAnnotType)annotation.type];
    self.annotationImageView.tintColor = annotation.color;
    self.annotationImageView.alpha = annotation.opacity;
    self.annotationImageView.hidden = (self.annotationImageView.image == nil);
    
    NSString *titleText = annotation.contents;
    if (titleText.length == 0) {
        // Use localized display name of annotation type.
        titleText = PTLocalizedAnnotationNameFromType((PTExtendedAnnotType)annotation.type);
    }
    self.titleLabel.text = titleText;
    self.titleLabel.hidden = (self.titleLabel.text.length == 0);
    
    PTManagedAnnotation *lastReply = annotation.lastReply;
    
    NSString *author = lastReply.author.name ?: lastReply.author.identifier;
    NSString *contents = lastReply.contents;
    if (contents) {
        NSMutableAttributedString *messageAttributedText = [[NSMutableAttributedString alloc] init];
        
        if (author) {
            NSAttributedString *authorString = [[NSAttributedString alloc] initWithString:author attributes:
                                                @{
                                                  NSFontAttributeName: [UIFont boldSystemFontOfSize:self.messageLabel.font.pointSize],
                                                  }];
            [messageAttributedText appendAttributedString:authorString];
            [messageAttributedText appendAttributedString:[[NSAttributedString alloc] initWithString:PT_LocalizationNotNeeded(@": ")]];
        }
        if (contents) {
            [messageAttributedText appendAttributedString:[[NSAttributedString alloc] initWithString:contents]];
        }
        
        self.messageLabel.attributedText = [messageAttributedText copy];
    } else {
        self.messageLabel.text = nil;
    }
    self.messageLabel.hidden = (self.messageLabel.text.length == 0);

    NSDate *date = annotation.creationDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if ([NSCalendar.currentCalendar isDateInToday:date]) {
        // Only show time for today.
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    } else {
        // Only show date otherwise.
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    
    self.dateLabel.text = [dateFormatter stringFromDate:date];
}

@end
