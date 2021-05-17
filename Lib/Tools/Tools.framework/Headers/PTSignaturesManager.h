//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTOverridable.h>

#import <PDFNet/PDFNet.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Creates signatures and manages saved ones.
 */
@interface PTSignaturesManager : NSObject <PTOverridable>

/**
 * Used to determine the number of saved signatures.
 *
 * @return the number of saved signatures.
 */
-(NSUInteger)numberOfSavedSignatures;

/**
 * Gets a saved signature.
 *
 * @param index the index number of the saved signature
 *
 * @return the saved signature.
 */
-(nullable PTPDFDoc*)savedSignatureAtIndex:(NSInteger)index;

/**
 *
 * Returns an image of the signature at the given index of the given hight.
 *
 * @param index The index of the signature.
 *
 * @param dpi The DPI to render the image at. (If unsure, start with 72.)
 *
 *
 * @return A rasterized copy of the signature.
 *
 */
-(nullable UIImage*)imageOfSavedSignatureAtIndex:(NSInteger)index dpi:(NSUInteger)dpi;

/**
 * Deletes the saved signature
 *
 * @param index the index of the signature to delete
 *
 * @return `YES` if the signature was successfully deleted; `NO` otherwise.
 */
-(BOOL)deleteSignatureAtIndex:(NSInteger)index;


/**
 *
 * Reorders the signatures
 *
 * @param fromIndex the originating index number of the signature
 *
 * @param toIndex the destination index number of the signature
 *
 * @return `YES` if the signature was successfully moved; `NO` otherwise.
 *
 */
-(BOOL)moveSignatureAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/**
 * Creates a new saved signature.
 *
 * @param points A set of FreeHand points.
 *
 * @param strokeColor The color of the freehand stroke.
 *
 * @param thickness The thickness of the freehand stroke.
 *
 * @param rect The bounding rect of the points.
 *
 * @param saveSignature `YES` if the signature shold be saved as the
 * default signature.
 *
 * @return a PDFDoc where page 1 is the signature.
 *
 */
-(PTPDFDoc*)createSignature:(NSMutableArray*)points withStrokeColor:(UIColor*)strokeColor withStrokeThickness:(CGFloat)thickness withinRect:(CGRect)rect saveSignature:(BOOL)saveSignature;


@end

NS_ASSUME_NONNULL_END
