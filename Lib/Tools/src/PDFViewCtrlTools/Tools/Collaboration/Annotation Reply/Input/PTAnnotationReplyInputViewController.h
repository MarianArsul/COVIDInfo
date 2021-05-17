//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotationReplyInputView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTAnnotationReplyInputViewController;

@protocol PTAnnotationReplyInputViewControllerDelegate <NSObject>
@optional

- (void)annotationReplyInputViewController:(PTAnnotationReplyInputViewController *)annotationReplyInputViewController didSubmitText:(NSString *)text;

@end

@interface PTAnnotationReplyInputViewController : UIViewController

@property (nonatomic, strong) PTAnnotationReplyInputView *inputView;

@property (nonatomic, weak, nullable) id<PTAnnotationReplyInputViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
