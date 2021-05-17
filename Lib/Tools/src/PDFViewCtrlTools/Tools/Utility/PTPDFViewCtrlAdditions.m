//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTPDFViewCtrlAdditions.h"

extern TrnPagePresentationMode PTPagePresentationModeGetBaseMode(TrnPagePresentationMode mode)
{
    switch (mode) {
        case e_trn_single_page:
        case e_trn_single_continuous:
            return e_trn_single_page;
            
        case e_trn_facing:
        case e_trn_facing_continuous:
            return e_trn_facing;
            
        case e_trn_facing_cover:
        case e_trn_facing_continuous_cover:
            return e_trn_facing_cover;
            
        default:
        {
            NSLog(@"Unknown page presentation mode value: %d", mode);
            
            return e_trn_single_page;
        }
    }
}

extern BOOL PTPagePresentationModeIsContinuous(TrnPagePresentationMode mode)
{
    switch (mode) {
        case e_trn_single_page:
        case e_trn_facing:
        case e_trn_facing_cover:
            return NO;
            
        case e_trn_single_continuous:
        case e_trn_facing_continuous:
        case e_trn_facing_continuous_cover:
            return YES;
            
        default:
        {
            NSLog(@"Unknown page presentation mode value: %d", mode);
            
            return NO;
        }
    }
}

extern TrnPagePresentationMode PTPagePresentationModeGetEffectiveMode(TrnPagePresentationMode mode, BOOL continuous)
{
    switch (mode) {
        case e_trn_single_page:
        case e_trn_single_continuous:
            return (continuous) ? e_trn_single_continuous : e_trn_single_page;
            
        case e_trn_facing:
        case e_trn_facing_continuous:
            return (continuous) ? e_trn_facing_continuous : e_trn_facing;
            
        case e_trn_facing_cover:
        case e_trn_facing_continuous_cover:
            return (continuous) ? e_trn_facing_continuous_cover : e_trn_facing_cover;
            
        default:
        {
            NSLog(@"Unknown page presentation mode value: %d", mode);

            return e_trn_single_page;
        }
    }
}
