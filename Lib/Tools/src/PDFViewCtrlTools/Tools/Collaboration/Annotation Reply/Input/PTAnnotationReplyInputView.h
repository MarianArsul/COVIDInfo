//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPlaceholderTextView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotationReplyInputView;

@protocol PTAnnotationReplyInputViewDelegate <NSObject>
@optional

- (void)annotationReplyInputView:(PTAnnotationReplyInputView *)annotationReplyInputView didSubmitText:(NSString *)text;

@end

@interface PTAnnotationReplyInputView : UIView

@property (nonatomic, strong) PTPlaceholderTextView *textView;

@property (nonatomic, strong) UIButton *submitButton;

/**
 * Clear the contents of the text view and reset the state of the input view.
 */
- (void)clear;

@property (nonatomic, weak, nullable) id<PTAnnotationReplyInputViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
