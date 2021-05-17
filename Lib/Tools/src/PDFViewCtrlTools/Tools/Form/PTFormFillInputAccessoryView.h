//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTFormFillInputAccessoryView;

@protocol PTFormFillInputAccessoryViewDelegate <NSObject>
@optional

- (void)formFillInputAccessoryView:(PTFormFillInputAccessoryView *)formFillInputAccesoryView didPressPreviousButtonItem:(UIBarButtonItem *)item;

- (void)formFillInputAccessoryView:(PTFormFillInputAccessoryView *)formFillInputAccesoryView didPressNextButtonItem:(UIBarButtonItem *)item;

- (void)formFillInputAccessoryView:(PTFormFillInputAccessoryView *)formFillInputAccesoryView didPressDoneButtonItem:(UIBarButtonItem *)item;

@end

@interface PTFormFillInputAccessoryView : UIView <UIToolbarDelegate>

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UIToolbar *toolbar;

@property (nonatomic, weak, nullable) id<PTFormFillInputAccessoryViewDelegate> delegate;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
