//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPageColorTableViewCell.h"

@interface PTPageColorCollectionViewCell ()
@property (nonatomic, strong, nullable) UIColor *unselectedBorderColor;
@end

static const int borderWidth = 2;

@implementation PTPageColorCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _unselectedBorderColor = UIColor.darkGrayColor;
        self.layer.borderWidth = borderWidth;
        self.layer.borderColor = _unselectedBorderColor.CGColor;
    }
    return self;
}
- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.layer.borderWidth = selected ? 3 : borderWidth;
    self.layer.borderColor = selected ? self.tintColor.CGColor : self.unselectedBorderColor.CGColor;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.layer.borderColor = self.isSelected ? self.tintColor.CGColor : self.unselectedBorderColor.CGColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width*0.5;
}

@end

@interface PTPageColorTableViewCell ()
@property (nonatomic, assign) BOOL constraintsLoaded;
@end

@implementation PTPageColorTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
        [self.collectionView registerClass:[PTPageColorCollectionViewCell class] forCellWithReuseIdentifier:PTPageColorCollectionViewCell_reuseID];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.contentView addSubview:self.collectionView];
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
       [self setNeedsUpdateConstraints];
    }
    return self;
}

-(void)loadConstraints
{
    [NSLayoutConstraint activateConstraints:
           @[
             [self.collectionView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
             [self.collectionView.widthAnchor constraintEqualToConstant:150.0],
             [self.collectionView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0],
             [self.collectionView.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor],
             ]];
}

- (void)updateConstraints
{
    if (!self.constraintsLoaded) {
        [self loadConstraints];
        self.constraintsLoaded = YES;
    }
    // Call super implementation as final step.
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsUpdateConstraints];
}

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource,UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath
{
    self.collectionView.dataSource = dataSourceDelegate;
    self.collectionView.delegate = dataSourceDelegate;
    [self.collectionView setContentOffset:self.collectionView.contentOffset animated:NO];
    [self.collectionView reloadData];
}

@end
