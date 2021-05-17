//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationStylePresetsGroup.h"

#import "PTAutoCoding.h"

@implementation PTAnnotationStylePresetsGroup

- (instancetype)init
{
    return [self initWithStyles:@[]];
}

- (instancetype)initWithStyles:(NSArray<PTAnnotStyle *> *)styles
{
    self = [super init];
    if (self) {
        _styles = [styles copy]; // @property (copy) semantics.
        
        _selectedStyle = styles.firstObject;
    }
    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        [PTAutoCoding autoUnarchiveObject:self
                                  ofClass:[PTAnnotationStylePresetsGroup class]
                                withCoder:coder];
        
        // Ensure that selectedStyle is set.
        // NOTE: When decoding a version of this class without a _selectedStyle ivar
        // (only a _selectedIndex ivar), the selected style will not be set.
        if (_styles.count > 0 && !_selectedStyle) {
            _selectedStyle = _styles.firstObject;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [PTAutoCoding autoArchiveObject:self
                            ofClass:[PTAnnotationStylePresetsGroup class]
                            forKeys:nil
                          withCoder:coder];
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone
{
    // Perform a deep copy of the styles.
    NSArray<PTAnnotStyle *> *styles = [[NSArray alloc] initWithArray:self.styles
                                                           copyItems:YES];
    const NSUInteger selectedIndex = self.selectedIndex;
    
    PTAnnotationStylePresetsGroup *copy = [[[self class] alloc] initWithStyles:styles];
    if (selectedIndex != NSNotFound) {
        copy->_selectedStyle = styles[selectedIndex];
    }
    
    return copy;
}

#pragma mark - Styles

- (void)setStyles:(NSArray<PTAnnotStyle *> *)styles
{
    const NSUInteger previousSelectedIndex = self.selectedIndex;
    PTAnnotStyle *previousSelectedStyle = self.selectedStyle;
    
    _styles = [styles copy]; // @property (copy) semantics.
    
    // Attempt to re-select the previously selected style.
    const NSUInteger newSelectedIndex = ((styles && previousSelectedStyle) ?
                                         [styles indexOfObject:previousSelectedStyle] :
                                         NSNotFound);
    if (newSelectedIndex == NSNotFound) {
        if (previousSelectedIndex < styles.count) {
            // Select the style at the same index in the array as the previously selected style.
            _selectedStyle = styles[previousSelectedIndex];
        }
        else if (styles.count > 0) {
            // Select the style at index 0.
            _selectedStyle = styles.firstObject;
        }
        else {
            // There is no selected style.
            _selectedStyle = nil;
        }
    }
}

#pragma mark - Selected index

- (NSUInteger)selectedIndex
{
    if (!self.selectedStyle) {
        return NSNotFound;
    }
    
    return [self.styles indexOfObject:self.selectedStyle];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    self.selectedStyle = self.styles[selectedIndex];
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedIndex
{
    // Setting selectedStyle will trigger change notifications for selectedIndex
    // because it is listed as "affecting" selectedIndex.
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedIndex
{
    // Changes to the selectedStyle property should trigger change notifications
    // for the selectedIndex property.
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTAnnotationStylePresetsGroup, selectedStyle),
    ]];
}

#pragma mark - Selected style

- (void)setSelectedStyle:(PTAnnotStyle *)selectedStyle
{
    // Ensure selected style is in styles.
    if (![self.styles containsObject:selectedStyle]) {
        NSString *reason = [NSString stringWithFormat:@"selected style %@ is not in the list of styles",
                            selectedStyle];
        
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:reason
                                                       userInfo:nil];
        @throw exception;
        return;
    }
    
    _selectedStyle = selectedStyle;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingSelectedStyle
{
    return [NSSet setWithArray:@[
        PT_CLASS_KEY(PTAnnotationStylePresetsGroup, styles),
    ]];
}

@end
