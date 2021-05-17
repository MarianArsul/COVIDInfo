//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTCheckmarkView : UIView

@property (nonatomic, strong, null_resettable) UIColor *strokeColor;

@property (nonatomic, strong, null_resettable) UIColor *fillColor;

@property (nonatomic, assign, getter=isSelected) BOOL selected;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
