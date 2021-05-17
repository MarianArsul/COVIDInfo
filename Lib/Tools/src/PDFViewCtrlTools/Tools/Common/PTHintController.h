//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTHintController : NSObject

@property (nonatomic, class, readonly) PTHintController *sharedHintController;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *message;

- (void)showWithTitle:(NSString *)title message:(nullable NSString *)message fromView:(UIView *)view rect:(CGRect)targetRect;

- (void)showFromView:(UIView *)view rect:(CGRect)targetRect;

- (void)hide;

@property (nonatomic, readonly, assign, getter=isVisible) BOOL visible;

@end

NS_ASSUME_NONNULL_END
