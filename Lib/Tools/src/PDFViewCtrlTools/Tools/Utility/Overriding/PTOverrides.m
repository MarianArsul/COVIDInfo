//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTOverrides.h"

#import "ToolsDefines.h"
#import "PTOverridable.h"

static NSMutableDictionary<Class, Class> *PTOverrides_overriddenClasses;

@interface PTOverrides ()

@property (nonatomic, class, readonly, strong) NSMutableDictionary<Class, Class> *overriddenClasses;

@end

@implementation PTOverrides

+ (void)overrideClass:(Class)cls withClass:(Class)subclass
{
    // Check if the class to override is marked as overridable.
    if (![cls conformsToProtocol:@protocol(PTOverridable)]) {
        // Throw invalid argument exception.
        NSString *reason = [NSString stringWithFormat:@"Class override failed: class \"%@\" does not conform to <%@>",
                            NSStringFromClass(cls), NSStringFromProtocol(@protocol(PTOverridable))];
        
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:reason
                                                       userInfo:nil];
        
        @throw exception;
        return;
    }
    
    // Check if the specified subclass is actually a subclass of cls.
    if (![subclass isSubclassOfClass:cls]) {
        // Throw invalid argument exception.
        NSString *reason = [NSString stringWithFormat:@"Class override failed: class \"%@\" is not a subclass of \"%@\"",
                            NSStringFromClass(subclass), NSStringFromClass(cls)];
        
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:reason
                                                       userInfo:nil];
        
        @throw exception;
        return;
    }
    
    Class previousClass = [self overriddenClassForClass:cls];
    if (previousClass) {
        PTLog(@"Removing previous class override of \"%@\" for class \"%@\"",
              NSStringFromClass(previousClass), NSStringFromClass(cls));
    }
    
    @synchronized (self) {
        // NSObject class responds to copy and copyWithZone: methods.
        self.overriddenClasses[(id<NSCopying>)cls] = subclass;
    }
}

+ (Class)overriddenClassForClass:(Class)cls
{
    @synchronized (self) {
        return self.overriddenClasses[cls];
    }
}

#pragma mark - overriddenClasses

+ (NSMutableDictionary<Class, Class> *)overriddenClasses
{
    @synchronized (self) {
        if (!PTOverrides_overriddenClasses) {
            PTOverrides_overriddenClasses = [NSMutableDictionary dictionary];
        }
    }
    
    return PTOverrides_overriddenClasses;
}

@end
