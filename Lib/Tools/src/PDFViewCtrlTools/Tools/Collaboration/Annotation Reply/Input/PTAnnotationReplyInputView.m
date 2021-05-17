//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationReplyInputView.h"

#import "PTTextScrollView.h"
#import "PTToolsUtil.h"

#include <tgmath.h>

static const CGFloat PTAnnotationReplyInputView_margin = 4.0;

@interface PTAnnotationReplyInputView () <UITextViewDelegate>

@property (nonatomic, strong) PTTextScrollView *textScrollView;

@property (nonatomic, assign) BOOL constraintsLoaded;

@end

@implementation PTAnnotationReplyInputView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Create text view.
        _textView = [[PTPlaceholderTextView alloc] initWithFrame:self.bounds];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _textView.delegate = self;
        
        _textView.scrollEnabled = NO;
        
        // The text container should track the text view's width (from Auto Layout), but the
        // text container height will be used to determine the view's height.
        _textView.textContainer.widthTracksTextView = YES;
        
        // Dynamic Type support.
        _textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        if (@available(iOS 10.0, *)) {
            _textView.adjustsFontForContentSizeCategory = YES;
        }
        
        _textView.placeholder = PTLocalizedString(@"Write your comment",
                                                  @"Annotation reply input placeholder");
        _textView.backgroundColor = nil;
        _textView.opaque = NO;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(textViewDidChangeWithNotification:)
                                                   name:UITextViewTextDidChangeNotification
                                                 object:_textView];
        
        // Create text scroll view.
        _textScrollView = [[PTTextScrollView alloc] init];
        _textScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _textScrollView.textView = _textView;
        
        if (@available(iOS 13.0, *)) {
            _textScrollView.backgroundColor = UIColor.tertiarySystemFillColor;
        } else {
            _textScrollView.backgroundColor = UIColor.whiteColor;
        }
        
        _textScrollView.layer.cornerRadius = PTAnnotationReplyInputView_margin;
        _textScrollView.layer.masksToBounds = YES;
        
        [self addSubview:_textScrollView];
        
        // Create submit button.
        _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _submitButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Disabled by default.
        _submitButton.enabled = NO;
        [_submitButton setTitle:PTLocalizedString(@"Post", @"Submit annotation reply button title")
                       forState:UIControlStateNormal];
        
        [_submitButton addTarget:self action:@selector(submitInput:) forControlEvents:UIControlEventPrimaryActionTriggered];
        
        [self addSubview:_submitButton];
        
        // Set layout margins.
        self.layoutMargins = UIEdgeInsetsMake(PTAnnotationReplyInputView_margin,
                                              PTAnnotationReplyInputView_margin,
                                              PTAnnotationReplyInputView_margin,
                                              PTAnnotationReplyInputView_margin);
        
        // Inset text by at least the scroll view's corner radius.
        UIEdgeInsets textContainerInset = _textView.textContainerInset;
        textContainerInset.left = fmax(textContainerInset.left, _textScrollView.layer.cornerRadius);
        textContainerInset.right = fmax(textContainerInset.right, _textScrollView.layer.cornerRadius);
        _textView.textContainerInset = textContainerInset;
        
        // Schedule constraints update.
        [self setNeedsUpdateConstraints];
    }
    return self;
}

#pragma mark - Constraints

- (void)loadConstraints
{
    
    
    self.textScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *spacer = [[UILayoutGuide alloc] init];
    spacer.identifier = @"trailing textView-button spacer";
    
    [self addLayoutGuide:spacer];
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.textScrollView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
       [self.textScrollView.trailingAnchor constraintEqualToAnchor:spacer.leadingAnchor],
       [self.textScrollView.topAnchor constraintEqualToAnchor:self.layoutMarginsGuide.topAnchor],
       [self.textScrollView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
       
       [self.textScrollView.heightAnchor constraintLessThanOrEqualToConstant:100.0],
       
       [self.submitButton.leadingAnchor constraintEqualToAnchor:spacer.trailingAnchor],
       [self.submitButton.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
       [self.submitButton.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
       
       [spacer.widthAnchor constraintEqualToConstant:10.0],
       ]];
    
    // Scroll view weakly hugs content and resists compression.
    [self.textScrollView setContentHuggingPriority:UILayoutPriorityDefaultLow
                                           forAxis:UILayoutConstraintAxisHorizontal];
    [self.textScrollView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                         forAxis:UILayoutConstraintAxisHorizontal];
    
    // Button stronly hugs content and *very* strongly resists compression.
    [self.submitButton setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                         forAxis:UILayoutConstraintAxisHorizontal];
    [self.submitButton setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh + 1)
                                                       forAxis:UILayoutConstraintAxisHorizontal];
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

#pragma mark - UIControl actions

- (void)submitInput:(id)sender
{
    NSString *text = self.textView.text;
    
    // Ensure that the text is non-empty.
    NSAssert(text.length > 0,
             @"Submitting empty text is not permitted");
    
    // Notify delegate of text submission.
    if ([self.delegate respondsToSelector:@selector(annotationReplyInputView:didSubmitText:)]) {
        [self.delegate annotationReplyInputView:self didSubmitText:text];
    }
}

#pragma mark - <UITextViewDelegate>

- (void)textViewDidChange:(UITextView *)textView
{
    
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    // Forward to text scroll view.
    if ([self.textScrollView respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.textScrollView textViewDidChangeSelection:textView];
    }
}

#pragma mark - Notifications

- (void)textViewDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.textView) {
        return;
    }
    
    // Enable button when there is some text.
    self.submitButton.enabled = (self.textView.text.length > 0);
}

#pragma mark - Public API

- (void)clear
{
    self.textView.text = nil;
    self.submitButton.enabled = (self.textView.text.length > 0);
}

@end
