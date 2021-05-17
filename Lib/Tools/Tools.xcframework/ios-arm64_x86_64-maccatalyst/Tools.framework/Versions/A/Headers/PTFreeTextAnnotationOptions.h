//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTAnnotationOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
* An object that contains options for FreeText annotations.
*/
@interface PTFreeTextAnnotationOptions : PTAnnotationOptions

/**
 * The default font to use for new FreeText annotations. This
 * string must be specified using the PostscriptFile name, e.g.
 * "CourierNewPS-BoldItalicMT". These names can be retrieved as
 * follows:
 *
 * ```NSArray *fontFamilyNames = [UIFont familyNames];
 for (NSString *familyName in fontFamilyNames) {
         NSLog(@"Font Family Name = %@", familyName);
         NSArray *names = [UIFont fontNamesForFamilyName:familyName];
         NSLog(@"   Font Names = %@", names);
 }```
 *
 */
@property (nonatomic, copy) NSString* defaultFontName PT_UNAVAILABLE_MSG("Set default free text font with +[PTColorDefaults setDefaultFreeTextFontName:]");

/**
 * Whether the `PTFreeTextInputAccessoryView` is enabled when creating or editing free text annotations.
 * The default value of this property is `YES`.
 */
@property (nonatomic, assign) BOOL inputAccessoryViewEnabled;


@end

NS_ASSUME_NONNULL_END
