//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotationStylePresetsGroup.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationStyleIndicatorView : UIControl

@property (nonatomic, strong, nullable) PTAnnotationStylePresetsGroup *presetsGroup;

@property (nonatomic, strong, nullable) PTAnnotStyle *style;

@property (nonatomic, strong) UIView *disclosureIndicatorView;

/**
 * Whether the disclosure indicator is enabled.
 *
 * The default value is `NO`.
 */
@property (nonatomic, getter=isDisclosureIndicatorEnabled) BOOL disclosureIndicatorEnabled;

/**
 * Whether the disclosure indicator is hidden.
 *
 * The default value is `YES`.
 */
@property (nonatomic, getter=isDisclosureIndicatorHidden) BOOL disclosureIndicatorHidden;

- (void)setDisclosureIndicatorHidden:(BOOL)hidden animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
