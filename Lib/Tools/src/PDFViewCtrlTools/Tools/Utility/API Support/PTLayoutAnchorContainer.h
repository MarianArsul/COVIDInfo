//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PTLayoutAnchorContainer <NSObject>
@required

@property (nonatomic, readonly, strong) NSLayoutXAxisAnchor *leadingAnchor;
@property (nonatomic, readonly, strong) NSLayoutXAxisAnchor *trailingAnchor;
@property (nonatomic, readonly, strong) NSLayoutXAxisAnchor *leftAnchor;
@property (nonatomic, readonly, strong) NSLayoutXAxisAnchor *rightAnchor;
@property (nonatomic, readonly, strong) NSLayoutYAxisAnchor *topAnchor;
@property (nonatomic, readonly, strong) NSLayoutYAxisAnchor *bottomAnchor;
@property (nonatomic, readonly, strong) NSLayoutDimension *widthAnchor;
@property (nonatomic, readonly, strong) NSLayoutDimension *heightAnchor;
@property (nonatomic, readonly, strong) NSLayoutXAxisAnchor *centerXAnchor;
@property (nonatomic, readonly, strong) NSLayoutYAxisAnchor *centerYAnchor;

@end

@interface UIView (PTLayoutAnchorContainerSupport) <PTLayoutAnchorContainer>
@end

@interface UILayoutGuide (PTLayoutAnchorContainerSupport) <PTLayoutAnchorContainer>
@end

NS_ASSUME_NONNULL_END
