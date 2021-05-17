//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsDefines.h"
#import "PTAnnotationStylePresetsGroup.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

PT_EXPORT
@interface PTAnnotationStyleManager : NSObject

@property (nonatomic, class, readonly, strong) PTAnnotationStyleManager *defaultManager;

- (PTAnnotationStylePresetsGroup *)stylePresetsForAnnotationType:(PTExtendedAnnotType)annotType;

- (PTAnnotationStylePresetsGroup *)stylePresetsForAnnotationType:(PTExtendedAnnotType)annotType identifier:(nullable NSString *)identifier;

- (void)setStylePresets:(PTAnnotationStylePresetsGroup *)stylePresets forAnnotationType:(PTExtendedAnnotType)annotType;

- (void)setStylePresets:(PTAnnotationStylePresetsGroup *)stylePresets forAnnotationType:(PTExtendedAnnotType)annotType identifier:(nullable NSString *)identifier;

- (void)saveStylePresets;

@end

NS_ASSUME_NONNULL_END
