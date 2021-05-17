//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTextScrollView.h"

#import "NSLayoutConstraint+PTPriority.h"

#include <tgmath.h>

@interface PTTextScrollView ()
{
    BOOL _needsLayoutForSelectionChange;
    BOOL _needsLayoutForTextChange;
}

@property (nonatomic, assign) BOOL constraintsLoaded;
@property (nonatomic, assign) BOOL textViewConstraintsLoaded;

@property (nonatomic, copy, nullable) UITextRange *previousTextViewSelectedTextRange;
@property (nonatomic, weak, nullable) UITextPosition *activeTextViewSelectionPosition;

@end

@implementation PTTextScrollView

#pragma mark - Constraints

- (void)loadConstraints
{
    
}

- (void)loadTextViewConstraints
{
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[
       [self.textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
       [self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
       [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor],
       [self.textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
       
       [self.textView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
       ]];
    
    [NSLayoutConstraint pt_activateConstraints:
     @[
       [self.textView.heightAnchor constraintEqualToAnchor:self.heightAnchor],
       ] withPriority:UILayoutPriorityDefaultLow];
}

- (void)updateConstraints
{
    // Load constraints.
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        
        self.constraintsLoaded = YES;
    }
    
    // Load text view constraints.
    if (!self.textViewConstraintsLoaded) {
        [self loadTextViewConstraints];
        
        self.textViewConstraintsLoaded = YES;
    }
    
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
    
    // Scroll text view for text selection changes.
    if (_needsLayoutForSelectionChange) {
        [self scrollTextViewCaretToVisibleIfNeeded];
    }
    
    // Reset layout invalidation flags.
    _needsLayoutForSelectionChange = NO;
    _needsLayoutForTextChange = NO;
}

- (void)scrollTextViewCaretToVisibleIfNeeded
{
    UITextPosition *cursorTextPosition = nil;
    
    if (self.activeTextViewSelectionPosition) {
        cursorTextPosition = self.activeTextViewSelectionPosition;
    }
    else if ([self.textView.selectedTextRange isEmpty]) {
        cursorTextPosition = self.textView.selectedTextRange.end;
    }
    else {
        // No cursor text position.
        return;
    }
    
    NSAssert(cursorTextPosition != nil,
             @"Cursor text position must be non-null");
    
    // Get the text view caret rect in the scroll view's coordinates.
    CGRect textViewCaretRect = [self.textView caretRectForPosition:cursorTextPosition];
    CGRect caretRect = [self convertRect:textViewCaretRect fromView:self.textView];
    
    // Check if caret rect is fully visible.
    CGRect intersection = CGRectIntersection(self.bounds, caretRect);
    if (!CGRectIsNull(intersection) && CGRectEqualToRect(intersection, caretRect)) {
        // Caret rect is fully visible. No scrolling is necessary.
        return;
    }
    
    // When the cursor is at the beginning or end of the document, the scroll view should be
    // scrolled up/down to the top/bottom (showing the text view's top/bottom textContainerInset).
    // Otherwise, just scroll enough to show the cursor.
    BOOL atBeginningOfDocument = [self isTextPositionAtBeginningOfDocument:cursorTextPosition];
    BOOL atEndOfDocument = [self isTextPositionAtEndOfDocument:cursorTextPosition];
    
    
    
    if (atBeginningOfDocument || atEndOfDocument) {
        // Scroll to the top or bottom of the scroll view.
        CGPoint contentOffset = self.contentOffset;
        
        if (atBeginningOfDocument) {
            contentOffset.y = 0;
        } else {
            contentOffset.y = fmax(0, self.contentSize.height - CGRectGetHeight(self.bounds));
        }
        
        // Don't animate scroll when text changed. This will make the scroll view jump when
        // a new line of text is entered, which is what we want.
        BOOL animate = !_needsLayoutForTextChange;
        
        [self setContentOffset:contentOffset animated:animate];
    } else {
        // Scroll to make the caret rect visible.
        [self scrollRectToVisible:caretRect animated:YES];
    }
}

- (BOOL)isTextPositionAtBeginningOfDocument:(UITextPosition *)textPosition
{
    return [self.textView.beginningOfDocument isEqual:textPosition];
}

- (BOOL)isTextPositionAtEndOfDocument:(UITextPosition *)textPosition
{
    return [self.textView.endOfDocument isEqual:textPosition];
}

#pragma mark - Layout invalidation

- (void)setNeedsLayoutForSelectionChange
{
    _needsLayoutForSelectionChange = YES;
    
    [self setNeedsLayout];
}

- (void)setNeedsLayoutForTextChange
{
    _needsLayoutForTextChange = YES;
    
    [self setNeedsLayout];
}

#pragma mark - Selected text range diffing

- (nullable UITextPosition *)changedSelectedTextPositionForSelectedTextRange:(nullable UITextRange *)selectedTextRange previousSelectedTextRange:(nullable UITextRange *)previousSelectedTextRange
{
    if (!previousSelectedTextRange || !selectedTextRange) {
        // No previous or current selection - cannot determine selection change.
        return nil;
    }
    
    if ([previousSelectedTextRange isEmpty]) {
        if (![selectedTextRange isEmpty]) {
            // The selection has become non-empty.
            // Check if the insertion point was expanded.
            if (![previousSelectedTextRange.start isEqual:selectedTextRange.start] &&
                [previousSelectedTextRange.end isEqual:selectedTextRange.end]) {
                // Insertion point was expanded backwards.
                return selectedTextRange.start;
            }
            else if ([previousSelectedTextRange.start isEqual:selectedTextRange.start] &&
                     ![previousSelectedTextRange.end isEqual:selectedTextRange.end]) {
                // Insertion point was expanded forwards.
                return selectedTextRange.end;
            }
        }
    } else {
        if (![selectedTextRange isEmpty]) {
            // A non-empty selection has changed.
            // Check which end of the selection was changed.
            if (![previousSelectedTextRange.start isEqual:selectedTextRange.start] &&
                [previousSelectedTextRange.end isEqual:selectedTextRange.end]) {
                // Selection start was changed.
                return selectedTextRange.start;
            }
            else if ([previousSelectedTextRange.start isEqual:selectedTextRange.start] &&
                     ![previousSelectedTextRange.end isEqual:selectedTextRange.end]) {
                // Selection end was changed.
                return selectedTextRange.end;
            }
        }
    }
    
    // Could not determine selection change.
    return nil;
}

#pragma mark - Text view

- (void)setTextView:(UITextView *)textView
{
    // Remove old text view.
    if (_textView) {
        [_textView removeFromSuperview];

        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:UITextViewTextDidChangeNotification
                                                    object:_textView];
        
        // Clear text view selection information.
        self.previousTextViewSelectedTextRange = nil;
        self.activeTextViewSelectionPosition = nil;
    }

    _textView = textView;

    // Add new text view.
    if (textView) {
        [self addSubview:textView];

        // Schedule text view constraints update.
        self.textViewConstraintsLoaded = NO;
        [self setNeedsUpdateConstraints];

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(textViewDidChangeWithNotification:)
                                                   name:UITextViewTextDidChangeNotification
                                                 object:textView];
        
        // Record the initial text view selection.
        self.previousTextViewSelectedTextRange = textView.selectedTextRange;
    }
}

#pragma mark - <UITextViewDelegate>

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    // Determine the changed text selection position (only for non-empty selections).
    self.activeTextViewSelectionPosition = [self changedSelectedTextPositionForSelectedTextRange:textView.selectedTextRange previousSelectedTextRange:self.previousTextViewSelectedTextRange];
    
    self.previousTextViewSelectedTextRange = textView.selectedTextRange;
    
    // Invalidate layout (may need to scroll to make cursor visible).
    [self setNeedsLayoutForSelectionChange];
}

#pragma mark - Notifications

- (void)textViewDidChangeWithNotification:(NSNotification *)notification
{
    if (notification.object != self.textView) {
        return;
    }
    
    // Invalidate layout (may need to make cursor visible).
    [self setNeedsLayoutForTextChange];
}

@end
