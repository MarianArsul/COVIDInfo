//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsMacros.h"

#import <Foundation/Foundation.h>

#define PT_CATEGORY_SYMBOL(class, category) PT_PASTE(pt_category_, PT_PASTE(class, PT_PASTE(_, category)))

#ifdef TOOLS_STATIC
    #define PT_DECLARE_CATEGORY_SYMBOL(class, category) PT_LOCAL void PT_CATEGORY_SYMBOL(class, category) (void);

    #define PT_DEFINE_CATEGORY_SYMBOL(class, category) void PT_CATEGORY_SYMBOL(class, category) (void) {}

    #define PT_IMPORT_CATEGORY(class, category) \
    __attribute__((used)) static void PT_PASTE(pt_import_, PT_CATEGORY_SYMBOL(class, category)) (void)\
    {\
        PT_CATEGORY_SYMBOL(class, category)();\
    }
#else
    #define PT_DECLARE_CATEGORY_SYMBOL(class, category)

    #define PT_DEFINE_CATEGORY_SYMBOL(class, category)

    #define PT_IMPORT_CATEGORY(class, category)
#endif
