//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import <Tools/ToolsDefines.h>
#import <Tools/PTBaseCollaborationManager.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTBaseCollaborationManager;
@class PTCollaborationManager;

/**
 * The object that is responsible for sending local changes to the remote server, and for receiving
 * remote changes from the server.
 */
PT_EXPORT
@interface PTCollaborationManager : PTBaseCollaborationManager

@end

NS_ASSUME_NONNULL_END
