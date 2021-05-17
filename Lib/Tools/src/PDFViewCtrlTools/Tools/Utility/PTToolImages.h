//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "AnnotTypes.h"
#import "PTAnnotStyle.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotationImageLayer : NSObject

- (instancetype)initWithStyleKey:(nullable PTAnnotStyleKey)styleKey images:(NSArray<UIImage *> *)images;

- (instancetype)initWithStyleKey:(nullable PTAnnotStyleKey)styleKey imageNames:(NSArray<NSString *> *)imageNames;

@property (nonatomic, copy, nullable) PTAnnotStyleKey styleKey;

@property (nonatomic, copy, nullable) NSArray<UIImage *> *images;

@end

@interface PTToolImages : NSObject

+ (nullable NSString *)imageNameForAnnotationType:(PTExtendedAnnotType)annotationType;

+ (nullable UIImage *)imageForAnnotationType:(PTExtendedAnnotType)annotationType;

+ (nullable NSArray<PTAnnotationImageLayer *> *)imageLayersForAnnotationType:(PTExtendedAnnotType)annotationType;

@end

NS_ASSUME_NONNULL_END
