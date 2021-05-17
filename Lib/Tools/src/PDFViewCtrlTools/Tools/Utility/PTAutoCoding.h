//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTAutoCoding : NSObject

+ (void)autoArchiveObject:(id)object withCoder:(NSCoder *)coder;

+ (void)autoArchiveObject:(id)object ofClass:(Class)cls forKeys:(nullable NSArray<NSString *> *)keys withCoder:(NSCoder *)coder;

+ (void)autoUnarchiveObject:(id)object withCoder:(NSCoder *)coder;

+ (void)autoUnarchiveObject:(id)object ofClass:(Class)cls withCoder:(NSCoder *)coder;

@end

NS_ASSUME_NONNULL_END
