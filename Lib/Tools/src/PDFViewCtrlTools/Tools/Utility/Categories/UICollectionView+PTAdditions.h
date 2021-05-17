//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTCategoryDefines.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionView (PTAdditions)

- (void)pt_scrollItemToVisible:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)pt_performBatchUpdates:(void (^ _Nullable)(void))updates completion:(void (^ _Nullable)(BOOL finished))completion animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

PT_DECLARE_CATEGORY_SYMBOL(UICollectionView, PTAdditions)
PT_IMPORT_CATEGORY(UICollectionView, PTAdditions)
