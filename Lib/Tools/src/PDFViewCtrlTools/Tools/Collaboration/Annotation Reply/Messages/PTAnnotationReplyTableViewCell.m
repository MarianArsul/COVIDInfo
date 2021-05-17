//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationReplyTableViewCell.h"

#import "PTAuthorInitialView.h"
#import "PTToolsUtil.h"

#include <tgmath.h>

static const CGFloat PTAnnotationReplyTableViewCell_authorImageSize = 32.0;

@interface PTAnnotationReplyTableViewCell ()

@property (nonatomic, strong) PTAuthorInitialView *authorView;

// Container view: author & date, message contents
@property (nonatomic, strong) UIView *messageContainerView;

// Horizontal stack view: author name, message date
@property (nonatomic, strong) UIStackView *headerStackView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@property (nonatomic, strong, nullable) UILayoutGuide *authorViewSpacer;

@end

@implementation PTAnnotationReplyTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Message container view.
        _messageContainerView = [[UIView alloc] init];
        _messageContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:_messageContainerView];
        
        // Author view.
        _authorView = [[PTAuthorInitialView alloc] init];
        _authorView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_messageContainerView addSubview:_authorView];
        
        // Header (author and date labels) stack view.
        _headerStackView = [[UIStackView alloc] init];
        _headerStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _headerStackView.axis = UILayoutConstraintAxisHorizontal;
        _headerStackView.alignment = UIStackViewAlignmentBottom;
        _headerStackView.distribution = UIStackViewDistributionFill;
        _headerStackView.spacing = 10.0;
        
        [_headerStackView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        [_messageContainerView addSubview:_headerStackView];
        
        // Author label.
        _authorLabel = [[UILabel alloc] init];
        _authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _authorLabel.numberOfLines = 1;
        _authorLabel.font = [UIFont systemFontOfSize:UIFont.systemFontSize weight:UIFontWeightSemibold];
        
        [_authorLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        [_headerStackView addArrangedSubview:_authorLabel];
        
        // Timestamp label.
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _dateLabel.numberOfLines = 1;
        _dateLabel.font = [UIFont systemFontOfSize:UIFont.systemFontSize weight:UIFontWeightRegular];
        _dateLabel.alpha = 0.8;
        
        [_dateLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        
        [_headerStackView addArrangedSubview:_dateLabel];
        
        // Message label.
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _messageLabel.numberOfLines = 0; // No line limit.
        
        [_messageContainerView addSubview:_messageLabel];
        
        _authorViewSpacer = [[UILayoutGuide alloc] init];
        [_messageContainerView addLayoutGuide:_authorViewSpacer];
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    self.messageContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutMarginsGuide = self.contentView.layoutMarginsGuide;
    
    UILayoutGuide *messageSpacer = [[UILayoutGuide alloc] init];
    [self.messageContainerView addLayoutGuide:messageSpacer];
    
    UILayoutGuide *messageLayout = [[UILayoutGuide alloc] init];
    [self.messageContainerView addLayoutGuide:messageLayout];

    [NSLayoutConstraint activateConstraints:
     @[
       [self.messageContainerView.leadingAnchor constraintEqualToAnchor:layoutMarginsGuide.leadingAnchor],
       [self.messageContainerView.trailingAnchor constraintEqualToAnchor:layoutMarginsGuide.trailingAnchor],
       [self.messageContainerView.topAnchor constraintEqualToAnchor:layoutMarginsGuide.topAnchor],
       [self.messageContainerView.bottomAnchor constraintEqualToAnchor:layoutMarginsGuide.bottomAnchor],
       
       [self.authorView.leadingAnchor constraintEqualToAnchor:self.messageContainerView.leadingAnchor],
       [self.authorView.topAnchor constraintEqualToAnchor:self.messageContainerView.topAnchor],
       [self.authorView.widthAnchor constraintEqualToConstant:PTAnnotationReplyTableViewCell_authorImageSize],
       [self.authorView.heightAnchor constraintEqualToConstant:PTAnnotationReplyTableViewCell_authorImageSize],
       
       [self.authorViewSpacer.leadingAnchor constraintEqualToAnchor:self.authorView.trailingAnchor],
       [self.authorViewSpacer.widthAnchor constraintEqualToConstant:10.0],
       
       [messageLayout.leadingAnchor constraintEqualToAnchor:self.authorViewSpacer.trailingAnchor],
       [messageLayout.topAnchor constraintEqualToAnchor:self.messageContainerView.topAnchor],
       [messageLayout.trailingAnchor constraintEqualToAnchor:self.messageContainerView.trailingAnchor],
       [messageLayout.bottomAnchor constraintEqualToAnchor:self.messageContainerView.bottomAnchor],
       
       [self.headerStackView.leadingAnchor constraintEqualToAnchor:messageLayout.leadingAnchor],
       [self.headerStackView.topAnchor constraintEqualToAnchor:messageLayout.topAnchor],
       [self.headerStackView.trailingAnchor constraintEqualToAnchor:messageLayout.trailingAnchor],
       [self.headerStackView.bottomAnchor constraintEqualToAnchor:messageSpacer.topAnchor],
       
       [self.messageLabel.leadingAnchor constraintEqualToAnchor:messageLayout.leadingAnchor],
       [self.messageLabel.topAnchor constraintEqualToAnchor:messageSpacer.bottomAnchor],
       [self.messageLabel.trailingAnchor constraintEqualToAnchor:messageLayout.trailingAnchor],
       [self.messageLabel.bottomAnchor constraintEqualToAnchor:messageLayout.bottomAnchor],
       
       [messageSpacer.heightAnchor constraintEqualToConstant:4.0],
       ]];
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
    CGSize systemLayoutSize = [super systemLayoutSizeFittingSize:targetSize
                                   withHorizontalFittingPriority:horizontalFittingPriority
                                         verticalFittingPriority:verticalFittingPriority];
    
    // Enforce a minimum cell (content) height of 44 pts.
    systemLayoutSize.height = fmax(44.0, systemLayoutSize.height);
    return systemLayoutSize;
}

#pragma mark - Configuration

- (void)configureWithAnnotation:(PTManagedAnnotation *)annotation
{
    self.authorView.name = annotation.author.name ?: annotation.author.identifier;
    
    if (annotation.author.name.length > 0) {
        self.authorLabel.text = annotation.author.name;
    }
    else if (annotation.author.identifier.length > 0) {
        self.authorLabel.text = annotation.author.identifier;
    }
    else {
        self.authorLabel.text = PTLocalizedString(@"Unknown",
                                                  @"Unknown annotation author");
    }
    
    // Use modification or creation date.
    NSDate *date = annotation.modificationDate ?: annotation.creationDate;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // Show short month names for date.
    formatter.dateStyle = NSDateFormatterMediumStyle;
    // Don't show seconds for time.
    formatter.timeStyle = NSDateFormatterShortStyle;
    // Format date as relative ("Today", "Yesterday") if possible.
    formatter.doesRelativeDateFormatting = YES;
    
//    // Remove date from format for today.
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    if ([calendar isDateInToday:date]) {
//        formatter.dateStyle = NSDateFormatterMediumStyle;
//        formatter.timeStyle = NSDateFormatterShortStyle;
//    } else {
//        formatter.dateStyle = NSDateFormatterMediumStyle;
//        formatter.timeStyle = NSDateFormatterShortStyle;
//    }
    
    self.dateLabel.text = [formatter stringFromDate:date];
    
    self.messageLabel.text = annotation.contents;
}

@end
