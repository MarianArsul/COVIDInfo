//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTKeyValueObservedChange.h"

@implementation PTKeyValueObservedChange

- (instancetype)init
{
    return [self initWithObject:nil keyPath:nil change:nil];
}

- (instancetype)initWithObject:(id)object keyPath:(NSString *)keyPath change:(NSDictionary<NSKeyValueChangeKey, id> *)change
{
    self = [super init];
    if (self) {
        _object = object;
        _keyPath = [keyPath copy];
        _change = change;
    }
    return self;
}

#pragma mark - Convenience

- (NSKeyValueChange)kind
{
    NSNumber *kindNumber = self.change[NSKeyValueChangeKindKey];
    return kindNumber.unsignedIntegerValue;
}

- (id)oldValue
{
    return self.change[NSKeyValueChangeOldKey];
}

- (id)newValue
{
    return self.change[NSKeyValueChangeNewKey];
}

- (NSIndexSet *)indexes
{
    return self.change[NSKeyValueChangeIndexesKey];
}

- (BOOL)isPrior
{
    NSNumber *priorNumber = self.change[NSKeyValueChangeNotificationIsPriorKey];
    return priorNumber.boolValue;
}

@end
