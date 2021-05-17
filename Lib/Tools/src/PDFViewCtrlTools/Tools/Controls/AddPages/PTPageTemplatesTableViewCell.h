//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const PTPageTemplateCollectionViewCell_reuseID = @"PTPageTemplateCollectionViewCell";

@interface PTPageTemplateCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *templatePreview;
@property (nonatomic, strong) UILabel *templateLabel;
@end

@interface PTPageTemplatesTableViewCell : UITableViewCell

@property (nonatomic, strong) UICollectionView *collectionView;

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
