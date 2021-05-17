//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTPolylineCreate.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTPolylineCreate ()

#pragma mark - Annotation saving

- (nullable PTPolyLine *)createPolylineWithDoc:(PTPDFDoc *)doc pagePoints:(NSArray<PTPDFPoint *> *)pagePoints;

#pragma mark - Drawing

- (void)beginDrawPolylineWithRect:(CGRect)rect atPoint:(CGPoint)point withPoints:(NSArray<NSValue *> *)points;

- (void)drawPolylineWithRect:(CGRect)rect points:(NSArray<NSValue *> *)points;

- (void)endDrawPolylineWithRect:(CGRect)rect atPoint:(CGPoint)point withPoints:(NSArray<NSValue *> *)points;

@end

NS_ASSUME_NONNULL_END
