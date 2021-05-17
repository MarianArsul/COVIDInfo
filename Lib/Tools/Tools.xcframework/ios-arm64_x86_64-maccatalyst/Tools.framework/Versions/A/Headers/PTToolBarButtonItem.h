//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTSelectableBarButtonItem.h>

NS_ASSUME_NONNULL_BEGIN

PT_EXPORT
@interface PTToolBarButtonItem : PTSelectableBarButtonItem <NSCopying>

- (instancetype)initWithToolClass:(Class)toolClass target:(nullable id)target action:(nullable SEL)action;

@property (nonatomic, strong, nullable) Class toolClass;

@property (nonatomic, copy, nullable) NSString *identifier;

@end

NS_ASSUME_NONNULL_END
