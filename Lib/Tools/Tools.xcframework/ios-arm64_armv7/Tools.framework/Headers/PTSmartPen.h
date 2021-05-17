//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTTool.h>
#import <Tools/PTFreeHandCreate.h>
#import <Tools/PTTextMarkupCreate.h>
#import <Tools/PTAnnotationStylePresetsGroup.h>
#import <Tools/PTAnnotStyle.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTSmartPen;

/**
 * A tool that creates different types of annotations depending on if a touch begins over text in
 * the document or over a non-text area.
 */
PT_EXPORT
@interface PTSmartPen : PTTool

/**
 * The primary freehand/ink annotation creation tool. This tool is used for touches that do *not*
 * begin over text in the document.
 */
@property (nonatomic, readonly, strong) PTFreeHandCreate *primaryTool;

/**
 * The secondary text markup annotation creation tool. This tool is used for touches that begin over
 * text in the document.
 *
 * The `secondaryToolClass` property can be used to change the tool class of this property.
 */
@property (nonatomic, readonly, strong) PTTextMarkupCreate *secondaryTool;

/**
 * The tool class to use for the `secondaryTool`. The class must be a subclass of the
 * `PTTextMarkupCreate` abstract base class.
 *
 * The default value of this property is the `PTComboTool.defaultSecondaryToolClass` class property
 * value.
 */
@property (nonatomic, strong, null_resettable) Class secondaryToolClass;

/**
 * The default value for the `secondaryTool` instance property. The class must be a subclass of the
 * `PTTextMarkupCreate` abstract base class.
 *
 * The default value of this property is the `PTTextHighlightCreate` class. Setting a `Nil` value
 * for this property will reset the value to its default value.
 */
@property (nonatomic, class, strong, null_resettable) Class defaultSecondaryToolClass;

/**
 * The annotation style presets for the primary tool.
 */
@property (nonatomic, readonly, strong) PTAnnotationStylePresetsGroup *annotationStylePresets;

/**
 * Edit the annotation style from the group in `annotationStylePresets`.
 */
- (void)editAnnotationStyle:(PTAnnotStyle *)annotationStyle;

@end

NS_ASSUME_NONNULL_END
