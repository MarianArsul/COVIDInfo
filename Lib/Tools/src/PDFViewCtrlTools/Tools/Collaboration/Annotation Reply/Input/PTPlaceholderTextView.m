//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPlaceholderTextView.h"

#import <tgmath.h>

@interface PTPlaceholderTextView ()

@property (nonatomic, strong, nullable) UILabel *placeholderLabel;

@end

@implementation PTPlaceholderTextView

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.placeholderLabel) {
        [self layoutPlaceholderLabel];
    }
}

- (void)layoutPlaceholderLabel
{
    // Skip if placeholder label is hidden.
    if ([self.placeholderLabel isHidden]) {
        return;
    }
    
    // Inset the placeholder from the edges of the text view bounds.
    CGRect frame = UIEdgeInsetsInsetRect(self.bounds, self.textContainerInset);
    
    // Inset the placeholder from the leading and trailing edges with the text container's line
    // fragment padding.
    CGFloat lineFragmentPadding = self.textContainer.lineFragmentPadding;
    UIEdgeInsets lineFragmentPaddingInset = UIEdgeInsetsMake(0, lineFragmentPadding, 0, lineFragmentPadding);
    frame = UIEdgeInsetsInsetRect(frame, lineFragmentPaddingInset);
    
    self.placeholderLabel.frame = frame;
}

#pragma mark - UITextView

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    
    // Synchronize placeholder label.
    if (self.placeholderLabel) {
        self.placeholderLabel.font = font;
    }
}

- (void)setAdjustsFontForContentSizeCategory:(BOOL)adjustsFontForContentSizeCategory
{
    [super setAdjustsFontForContentSizeCategory:adjustsFontForContentSizeCategory];
    
    // Synchronize placeholder label.
    if (self.placeholderLabel) {
        self.placeholderLabel.adjustsFontForContentSizeCategory = YES;
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    
    // Synchronize placeholder label.
    if (self.placeholderLabel) {
        self.placeholderLabel.textAlignment = textAlignment;
    }
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    // Update placeholder label for changed text.
    [self updatePlaceholderLabel];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];

    // Update placeholder label for changed text.
    [self updatePlaceholderLabel];
}

#pragma mark - Placeholder

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = [placeholder copy]; // @property (copy) semantics
    
    // Load placeholder label if necessary (non-empty placeholder).
    if (!self.placeholderLabel && placeholder.length > 0) {
        [self loadPlaceholderLabel];
    }
    
    // Update placeholder label text and visibility.
    if (self.placeholderLabel) {
        self.placeholderLabel.text = placeholder;
        
        [self updatePlaceholderLabel];
    }
}

#pragma mark - Placeholder label

- (void)loadPlaceholderLabel
{
    self.placeholderLabel = [[UILabel alloc] init];
    
    // Match text view font.
    self.placeholderLabel.font = self.font;
    self.placeholderLabel.adjustsFontForContentSizeCategory = self.adjustsFontForContentSizeCategory;
    
    // Placeholder label background is transparent.
    self.placeholderLabel.backgroundColor = nil;
    self.placeholderLabel.opaque = NO;
    
    // Placeholder label is restricted to a single line of text.
    self.placeholderLabel.numberOfLines = 1;
    
    // "Disabled" UILabels are drawn dimmed.
    self.placeholderLabel.enabled = NO;
    
    // Truncate end of placeholder.
    self.placeholderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    // Placeholder label starts hidden.
    self.placeholderLabel.hidden = YES;
    
    // Add placeholder label to the back of the view.
    [self addSubview:self.placeholderLabel];
    [self sendSubviewToBack:self.placeholderLabel];
    
    // Observe the text view for changes so that the placeholder can be shown/hidden as needed.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(textViewDidChangeWithNotification:)
                                               name:UITextViewTextDidChangeNotification
                                             object:self];
}

- (void)updatePlaceholderLabel
{
    if (!self.placeholderLabel) {
        return;
    }
    
    // Hide placeholder label when text view has text or placeholder is empty.
    BOOL hidden = (self.text.length > 0) || (self.placeholder.length == 0);
    if (self.placeholderLabel.hidden != hidden) {
        self.placeholderLabel.hidden = hidden;
        
        // Invalidate text view layout when placeholder label is shown.
        if (!hidden) {
            [self setNeedsLayout];
        }
    }
}

#pragma mark - Notifications

- (void)textViewDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self) {
        return;
    }
    
    // Update the placeholder label for the text view change.
    [self updatePlaceholderLabel];
}

@end
