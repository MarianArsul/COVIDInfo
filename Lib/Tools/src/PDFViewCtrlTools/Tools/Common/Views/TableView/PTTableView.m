//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2021 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTTableView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTTableView ()
{
    CGSize _intrinsicContentSize;
}
@end

NS_ASSUME_NONNULL_END

@implementation PTTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        _intrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric,
                                           UIViewNoIntrinsicMetric);
        _intrinsicContentSizeEnabled = NO;
    }
    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        if ([coder containsValueForKey:PT_SELF_KEY(intrinsicContentSizeEnabled)]) {
            _intrinsicContentSizeEnabled = [coder decodeBoolForKey:PT_SELF_KEY(intrinsicContentSizeEnabled)];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeBool:_intrinsicContentSizeEnabled
               forKey:PT_SELF_KEY(intrinsicContentSizeEnabled)];
}

#pragma mark - Intrinsic content size

- (CGSize)intrinsicContentSize
{
    return _intrinsicContentSize;
}

- (void)setIntrinsicContentSizeEnabled:(BOOL)enabled
{
    _intrinsicContentSizeEnabled = enabled;
    
    [self updateIntrinsicContentSize];
}

- (void)updateIntrinsicContentSize
{
    const CGSize previousIntrinsicContentSize = self.intrinsicContentSize;
    
    if (![self isIntrinsicContentSizeEnabled]) {
        _intrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric,
                                           UIViewNoIntrinsicMetric);
    } else {
        const CGSize contentSize = self.contentSize;
        const UIEdgeInsets contentInset = self.contentInset;
        // NOTE: DON'T add the adjustedContentInset, since that will be added by the navigationController.???
        
        // Only consider vertical content size.
        const CGFloat contentInsetVertical = contentInset.top + contentInset.bottom;
        
        _intrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric,
                                           contentSize.height + contentInsetVertical);
    }
    
    if (!CGSizeEqualToSize(previousIntrinsicContentSize, _intrinsicContentSize)) {
        [self invalidateIntrinsicContentSize];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateIntrinsicContentSize];
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
{
    CGSize size = [super systemLayoutSizeFittingSize:targetSize];
    return size;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGSize size = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    return size;
}

@end
