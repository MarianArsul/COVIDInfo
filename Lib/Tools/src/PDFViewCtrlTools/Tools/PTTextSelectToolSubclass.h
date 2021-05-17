//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTTextSelectTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTTextSelectTool ()

- (void)selectionBarUp:(PTSelectionBar *)bar withTouches:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

#pragma mark Protected (redeclared) properties

@property (readwrite, nonatomic, assign) CGPoint selectionStart;

@property (readwrite, nonatomic, assign) CGPoint selectionEnd;

@property (readwrite, nonatomic, assign) CGPoint selectionStartCorner;

@property (readwrite, nonatomic, assign) CGPoint selectionEndCorner;

@property (readwrite, nonatomic, assign) int selectionStartPageNumber;

@property (readwrite, nonatomic, assign) int selectionEndPageNumber;

@property (readwrite, nonatomic, strong, nullable) PTSelectionBar* leadingBar;

@property (readwrite, nonatomic, strong, nullable) PTSelectionBar* trailingBar;

@end

NS_ASSUME_NONNULL_END
