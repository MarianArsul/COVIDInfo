//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTAnnotationOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An object that contains options for image stamp annotations.
 */
@interface PTImageStampAnnotationOptions : PTAnnotationOptions

/**
 * Whether the annotation can be rotated. The default value is `YES`.
 */
@property (nonatomic, assign, getter=isRotationEnabled) BOOL rotationEnabled;

/**
 * Whether the annotation can be cropped. The default value is `YES`.
 */
@property (nonatomic, assign, getter=isCropEnabled) BOOL cropEnabled;

@end

NS_ASSUME_NONNULL_END
