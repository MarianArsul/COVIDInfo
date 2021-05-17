//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>

#import <UIKit/UIKit.h>
#import <PDFNet/PDFNet.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility methods for the Tools framework.
 */
@interface PTToolsUtil : NSObject

/**
 * Returns an image in the tools bundle, regardless of extension.
 *
 * @param name The name of the image, with or without an extension.
 *
 * @return A UIImage created from the named file.
 */
+ (nullable UIImage*)toolImageNamed:(NSString*)name;

/**
 * Returns an image in the tools bundle, regardless of extension.
 *
 * @param name The name of the image, with or without an extension.
 *
 * @param inverted If true, returns a color-inverted version of the image
 *
 * @return A UIImage created from the named file.
 */
+ (nullable UIImage*)toolImageNamed:(NSString*)name inverted:(BOOL)inverted;

/**
 * Creates a 1 page `PTPDFDoc` from a `UIView`.
 *
 * @param aView The view to turn into a PDF
 *
 * @return a PDF created from the view.
 */
+(PTPDFDoc*)createPTPDFDocFromFromUIView:(UIView*)aView;



/**
 * The Tools framework bundle.
 */
@property (nonatomic, class, readonly) NSBundle *toolsBundle;

/**
 * The directory URL for Tools-specific saved resources, data and configuration files, etc.
 */
@property (nonatomic, class, readonly, nullable) NSURL *toolsResourcesDirectoryURL;

@end

/**
 * Returns a localized version of a string, using the `PTTools.toolsBundle` bundle.
 */
PT_EXPORT NSString *PTLocalizedString(NSString *key, NSString * _Nullable comment);

/**
 * Returns a localized version of a string from the specified table, using the `PTTools.toolsBundle` bundle.
 */
PT_EXPORT NSString *PTLocalizedStringFromTable(NSString *key, NSString * _Nullable table, NSString * _Nullable comment) NS_SWIFT_NAME(PTLocalizedString(key:table:comment:));

NS_ASSUME_NONNULL_END
