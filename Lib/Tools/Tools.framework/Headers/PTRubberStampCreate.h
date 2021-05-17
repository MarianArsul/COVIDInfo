//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTCreateToolBase.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents type of predefined stamp to use.
*/
typedef NSString * PTStampType NS_TYPED_ENUM;

/// A checkmark-type stamp.
PT_EXPORT const PTStampType PTStampTypeCheckMark;

/// A cross-type stamp.
PT_EXPORT const PTStampType PTStampTypeCrossMark;

/// A dot-type stamp.
PT_EXPORT const PTStampType PTStampTypeDot;

/**
 * Creates stamp annotations.
*/
@interface PTRubberStampCreate : PTCreateToolBase

/**
 * Which `PTStampType` to create.
*/
@property(nonatomic,strong) PTStampType stampType;

@end

NS_ASSUME_NONNULL_END
