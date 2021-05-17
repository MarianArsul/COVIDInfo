//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDocumentInteractionController (PTAdditions)

- (void)pt_prepareForPresentation;

- (void)pt_cleanupFromPresentation;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UIDocumentInteractionController, PTAdditions)
PT_IMPORT_CATEGORY(UIDocumentInteractionController, PTAdditions)
