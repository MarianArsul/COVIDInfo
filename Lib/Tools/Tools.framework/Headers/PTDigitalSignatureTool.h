//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/PTTool.h>
#import <Tools/ToolsDefines.h>
#import <Tools/PTDigSigViewController.h>
#import <Tools/PTFloatingSigViewController.h>

#define PT_SIGNATURE_FIELD_ID @"PT_SIGNATURE_FIELD_ID"

NS_ASSUME_NONNULL_BEGIN

/**
 * Handles creation of signatures and digitally signing documents.
 */
@interface PTDigitalSignatureTool : PTTool <PTDigSigViewControllerDelegate, PTFloatingSigViewControllerDelegate>


@property (nonatomic, assign) BOOL showDefaultSignature PT_DEPRECATED_MSG(7.1.0, "Use showsSavedSignatures");

/**
* Whether the controller shows a list of saved signatures. The default value of this property is `YES`.
*/
@property (nonatomic, assign) BOOL showsSavedSignatures;

@end

NS_ASSUME_NONNULL_END
