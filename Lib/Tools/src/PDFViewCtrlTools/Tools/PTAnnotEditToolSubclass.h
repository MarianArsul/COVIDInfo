//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTAnnotEditTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTAnnotEditTool ()

#pragma mark Protected properties

@property (nonatomic, readwrite, assign) CGPoint touchOffset;

@property (nonatomic, readwrite, assign) CGRect annotRect;

- (void)setSelectionRectDelta:(CGRect)deltaRect;

- (void)moveAnnotation:(CGPoint)down;

- (BOOL)annotIsMovable:(PTAnnot *)annot;

- (BOOL)annotIsResizable:(PTAnnot*)annot;

- (void)resetHandleTransformsWithFeedback:(BOOL)feedback;

@end

NS_ASSUME_NONNULL_END
