//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PTStandardColorsViewController;

@protocol PTStandardColorsViewControllerDelegate <NSObject>

- (void)standardColorsViewController:(PTStandardColorsViewController *)standardColorsViewController didSelectColor:(UIColor *)color;

@end

@interface PTStandardColorsViewController : UICollectionViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout colors:(nullable NSArray<UIColor *> *)colors;

@property (nonatomic, strong, nullable) UIColor *selectedColor;

@property (nonatomic, weak, nullable) id<PTStandardColorsViewControllerDelegate> colorPickerDelegate;

@property (nonatomic, copy, null_resettable) NSArray<UIColor *> *colors;

@end

NS_ASSUME_NONNULL_END
