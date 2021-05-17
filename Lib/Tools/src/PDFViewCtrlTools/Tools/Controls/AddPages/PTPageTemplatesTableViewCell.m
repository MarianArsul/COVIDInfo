//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPageTemplatesTableViewCell.h"

@interface PTPageTemplateCollectionViewCell ()
@property (nonatomic, strong, nullable) UIColor *unselectedBorderColor;
@end

@implementation PTPageTemplateCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _unselectedBorderColor = UIColor.lightGrayColor;
        _templateLabel = [[UILabel alloc] init];
        _templateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _templateLabel.textAlignment = NSTextAlignmentCenter;
        _templateLabel.adjustsFontSizeToFitWidth = YES;
        _templateLabel.numberOfLines = 0;

        _templatePreview = [[UIImageView alloc] init];
        _templatePreview.translatesAutoresizingMaskIntoConstraints = NO;
        _templatePreview.layer.masksToBounds = YES;
        [self.contentView addSubview:_templateLabel];
        [self.contentView addSubview:_templatePreview];
        _templatePreview.layer.cornerRadius = 5;
        _templatePreview.layer.borderWidth = 1;
        _templatePreview.layer.borderColor = _unselectedBorderColor.CGColor;

        [NSLayoutConstraint activateConstraints:
         @[
           [_templateLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
           [_templateLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
           [_templateLabel.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
           [_templateLabel.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor multiplier:0.25],
           [_templatePreview.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
           [_templatePreview.bottomAnchor constraintEqualToAnchor:_templateLabel.topAnchor],
           [_templatePreview.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
           [_templatePreview.heightAnchor constraintEqualToAnchor:self.contentView.widthAnchor multiplier:(4.0/3.0)],
           ]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.templatePreview.layer.borderWidth = selected ? 3 : 1;
    self.templatePreview.layer.borderColor = selected ? self.tintColor.CGColor : self.unselectedBorderColor.CGColor;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.templatePreview.layer.borderColor = self.isSelected ? self.tintColor.CGColor : self.unselectedBorderColor.CGColor;
}
@end

@implementation PTPageTemplatesTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
        [self.collectionView registerClass:[PTPageTemplateCollectionViewCell class] forCellWithReuseIdentifier:PTPageTemplateCollectionViewCell_reuseID];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.contentView addSubview:self.collectionView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.collectionView.frame = self.contentView.bounds;
}

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource,UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath
{
    self.collectionView.dataSource = dataSourceDelegate;
    self.collectionView.delegate = dataSourceDelegate;
    [self.collectionView setContentOffset:self.collectionView.contentOffset animated:NO];
    [self.collectionView reloadData];
}

@end
