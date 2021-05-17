//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>

#import <PDFNet/PDFNet.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Returns the corresponding non-continuous page presentation mode for the given mode. If the mode
 * is already non-continuous then the input mode is returned.
 *
 * @param mode the page presentation mode
 *
 * @return the corresponding non-continuous page presentation mode
 */
PT_EXPORT TrnPagePresentationMode PTPagePresentationModeGetBaseMode(TrnPagePresentationMode mode);

/**
 * Returns whether the given page presentation mode is continuous.
 *
 * @param mode the page presentation mode
 *
 * @return `YES` if the page presentation mode is continuous, `NO` otherwise
 */
PT_EXPORT BOOL PTPagePresentationModeIsContinuous(TrnPagePresentationMode mode);

/**
 * This function is used to toggle the continuous aspect of a page presentation mode. For the
 * specified page presentation mode, a corresponding mode will be returned with the continuous
 * aspect added or removed according to the `continuous` parameter.
 *
 * @param mode the page presentation mode
 *
 * @param continuous `YES` if the resulting page presentation mode should be continuous, `NO` otherwise
 *
 * @return the corresponding page presentation mode with the continuous aspect added or removed
 * according to the `continuous` parameter.
 */
PT_EXPORT TrnPagePresentationMode PTPagePresentationModeGetEffectiveMode(TrnPagePresentationMode mode, BOOL continuous);

NS_ASSUME_NONNULL_END
