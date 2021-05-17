//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTAnnotationStyleManager.h"

#import "PTToolsUtil.h"

#import "UIColor+PTHexString.h"

/**
 * The name of the default annotation styles plist file, located in the Tools bundle.
 */
#define STYLE_PRESETS_PLIST_NAME @"AnnotationStylePresets" // .plist

/**
 * The identifier for the default style presets for a given annotation type.
 */
#define DEFAULT_STYLE_IDENTIFIER @""

/**
 * The name of the saved annotation style plist file, located in the Tools resources directory
 * (Library/Application Support/<Tools-bundle-identifier>/).
 */
#define STYLE_SAVED_PLIST_NAME STYLE_PRESETS_PLIST_NAME

#define PT_ANNOTSTYLE_KEY(key) PT_CLASS_KEY(PTAnnotStyle, key)

NS_ASSUME_NONNULL_BEGIN

typedef NSString * PTAnnotStylePresetKey NS_TYPED_EXTENSIBLE_ENUM;

static const PTAnnotStylePresetKey PTAnnotStylePresetKeyTypes = @"types";
static const PTAnnotStylePresetKey PTAnnotStylePresetKeyPresets = @"presets";

static const PTAnnotStylePresetKey PTAnnotStylePresetKeyColor = @"color";
static const PTAnnotStylePresetKey PTAnnotStylePresetKeyFillColor = @"fillColor";
static const PTAnnotStylePresetKey PTAnnotStylePresetKeyTextColor = @"textColor";
static const PTAnnotStylePresetKey PTAnnotStylePresetKeyTextSize = @"textSize";

@interface PTAnnotationStyleManager ()

@property (nonatomic, strong, nullable) NSMutableDictionary<PTExtendedAnnotName, NSMutableDictionary<NSString *, PTAnnotationStylePresetsGroup *> *> *annotationStylePresets;

@property (nonatomic, assign) BOOL defaultsLoaded;

@end

NS_ASSUME_NONNULL_END

@implementation PTAnnotationStyleManager

static PTAnnotationStyleManager * _Nullable PTAnnotStyleManager_defaultManager;

+ (PTAnnotationStyleManager *)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PTAnnotStyleManager_defaultManager = [[self alloc] init];
    });
    return PTAnnotStyleManager_defaultManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (PTAnnotationStylePresetsGroup *)stylePresetsForAnnotationType:(PTExtendedAnnotType)annotType
{
    return [self stylePresetsForAnnotationType:annotType identifier:nil];
}

- (PTAnnotationStylePresetsGroup *)stylePresetsForAnnotationType:(PTExtendedAnnotType)annotType identifier:(NSString *)identifier
{
    // Load the saved or default annotation style presets if necessary.
    if (!self.defaultsLoaded) {
        [self PT_loadStylePresets];
        
        self.defaultsLoaded = YES;
    }
    
    const PTExtendedAnnotName annotName = PTExtendedAnnotNameFromType(annotType);
    NSAssert(annotName.length > 0, @"Failed to get annotation type name");
    
    PTAnnotationStylePresetsGroup *stylePresets = nil;
    
    if (identifier.length > 0) {
        // Get the presets for the annotation type and identifier.
        stylePresets = self.annotationStylePresets[annotName][identifier];
        
        if (!stylePresets) {
            PTAnnotationStylePresetsGroup *defaultStylePresets = self.annotationStylePresets[annotName][DEFAULT_STYLE_IDENTIFIER];
            
            if (defaultStylePresets) {
                // Create a deep copy of the default annotation style presets.
                NSArray<PTAnnotStyle *> *copiedStyles = [[NSArray alloc] initWithArray:defaultStylePresets.styles
                                                                             copyItems:YES];
                
                stylePresets = [[PTAnnotationStylePresetsGroup alloc] initWithStyles:copiedStyles];
                
                // Save the copied style presets.
                [self setStylePresets:stylePresets
                    forAnnotationType:annotType
                           identifier:identifier];
            }
        }
    } else {
        // Use the default annotation style presets.
        stylePresets = self.annotationStylePresets[annotName][DEFAULT_STYLE_IDENTIFIER];
    }
    
    if (!stylePresets) {
        // Create fallback style presets.
        stylePresets = [[PTAnnotationStylePresetsGroup alloc] initWithStyles:@[
            [[PTAnnotStyle allocOverridden] initWithAnnotType:annotType],
            [[PTAnnotStyle allocOverridden] initWithAnnotType:annotType],
            [[PTAnnotStyle allocOverridden] initWithAnnotType:annotType],
            [[PTAnnotStyle allocOverridden] initWithAnnotType:annotType],
        ]];
        
        // Save the fallback style presets.
        [self setStylePresets:stylePresets
            forAnnotationType:annotType
                   identifier:identifier];
    }
    
    return stylePresets;
}

- (void)setStylePresets:(PTAnnotationStylePresetsGroup *)stylePresets forAnnotationType:(PTExtendedAnnotType)annotType
{
    [self setStylePresets:stylePresets forAnnotationType:annotType identifier:nil];
}

- (void)setStylePresets:(PTAnnotationStylePresetsGroup *)stylePresets forAnnotationType:(PTExtendedAnnotType)annotType identifier:(NSString *)identifier
{
    const PTExtendedAnnotName annotName = PTExtendedAnnotNameFromType(annotType);
    NSAssert(annotName.length > 0, @"Failed to get annotation type name");

    [self PT_setStylePresets:stylePresets
           forAnnotationName:annotName
                  identifier:identifier];
}

- (void)PT_setStylePresets:(PTAnnotationStylePresetsGroup *)stylePresets forAnnotationName:(PTExtendedAnnotName)annotName identifier:(NSString *)identifier
{
    // Ensure that the map of identifiers for the annotation type exists.
    if (!self.annotationStylePresets[annotName]) {
        self.annotationStylePresets[annotName] = [NSMutableDictionary dictionary];
    }
    
    if (identifier.length > 0) {
        self.annotationStylePresets[annotName][identifier] = stylePresets;
    } else {
        // Register presets as the default for the annotation type.
        self.annotationStylePresets[annotName][DEFAULT_STYLE_IDENTIFIER] = stylePresets;
    }
}

- (NSURL *)savedStylePresetsURL
{
    NSURL *toolsResourcesURL = PTToolsUtil.toolsResourcesDirectoryURL;
    NSAssert(toolsResourcesURL != nil,
             @"Failed to get Tools resources directory URL.");
    
    return [[toolsResourcesURL URLByAppendingPathComponent:STYLE_SAVED_PLIST_NAME]
            URLByAppendingPathExtension:@"plist"];
}

- (void)saveStylePresets
{
    if (!self.annotationStylePresets) {
        return;
    }
    
    NSURL *savedPlistURL = [self savedStylePresetsURL];
    NSAssert(savedPlistURL != nil, @"Failed to get saved annotation style plist URL");
    
    // Perform a recursive deep copy of the annotation style presets.
    NSMutableDictionary<PTExtendedAnnotName, NSDictionary<NSString *, PTAnnotationStylePresetsGroup *> *> *annotationStylePresetsCopy = [NSMutableDictionary dictionary];
    // Manually (deep) copy each of the top-level dictionary's values. We want to perform a copy at
    // every level, so a default -copy at the root level does not suffice.
    [self.annotationStylePresets enumerateKeysAndObjectsUsingBlock:^(PTExtendedAnnotName key, NSMutableDictionary<NSString *, PTAnnotationStylePresetsGroup *> *value, BOOL *stop) {
        // Perform a deep copy of the value.
        annotationStylePresetsCopy[key] = [[NSDictionary alloc] initWithDictionary:value
                                                                         copyItems:YES];
    }];
    NSDictionary<PTExtendedAnnotName, NSDictionary<NSString *, PTAnnotationStylePresetsGroup *> *> *annotationStylePresets = [annotationStylePresetsCopy copy];
    
    // Create the archive of the copied objects on a background thread.
    // Encoding the annotation style presets group and individual styles takes the most amount of time.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:annotationStylePresets];
        
        NSError *error = nil;
        BOOL success = [data writeToURL:savedPlistURL
                                options:0
                                  error:&error];
        if (!success) {
            NSLog(@"Failed to save annotation style presets: %@", error);
        }
    });
}

- (void)PT_loadStylePresets
{
    [self PT_loadDefaultAnnotStylePresets];
    [self PT_loadSavedStylePresets];
}

- (void)PT_loadSavedStylePresets
{
    NSURL *savedPlistURL = [self savedStylePresetsURL];
    NSAssert(savedPlistURL != nil, @"Failed to get saved annotation style plist URL");

    // Check if the saved style plist file exists.
    if (![NSFileManager.defaultManager fileExistsAtPath:savedPlistURL.path]) {
        return;
    }
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:savedPlistURL
                                         options:0
                                           error:&error];
    if (!data) {
        NSLog(@"Failed to load saved annotation style presets: %@", error);
        return;
    }
    
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (![object isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary<PTExtendedAnnotName, NSDictionary<NSString *, PTAnnotationStylePresetsGroup *> *> *savedStylePresets = (NSDictionary *)object;
    
    for (PTExtendedAnnotName annotName in savedStylePresets) {
        NSDictionary<NSString *, PTAnnotationStylePresetsGroup *> *presetGroups = savedStylePresets[annotName];
        
        for (NSString *identifier in presetGroups) {
            PTAnnotationStylePresetsGroup *presetGroup = presetGroups[identifier];
            
            [self PT_setStylePresets:presetGroup
                   forAnnotationName:annotName
                          identifier:identifier];
        }
    }
}

- (void)PT_loadDefaultAnnotStylePresets
{
    NSURL *url = [PTToolsUtil.toolsBundle URLForResource:STYLE_PRESETS_PLIST_NAME
                                           withExtension:@"plist"];
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    NSError *error = nil;
    id propertyList = [NSPropertyListSerialization propertyListWithData:data
                                                                options:NSPropertyListImmutable
                                                                 format:nil
                                                                  error:&error];
    if (!propertyList) {
        NSLog(@"Failed to read default annot style presets: %@", error);
        return;
    }
    
    NSAssert([propertyList isKindOfClass:[NSArray class]],
             @"Default annot style presets root object must be an array: found %@",
             NSStringFromClass([propertyList class]));
    
    NSArray<id> *propertyArray = (NSArray *)propertyList;
    
    // Dictionary of all style presets for all annotation types.
    NSMutableDictionary<PTExtendedAnnotName, NSMutableDictionary<NSString *, PTAnnotationStylePresetsGroup *> *> *allStylePresets = [NSMutableDictionary dictionary];
    
    for (id value in propertyArray) {
        if (![value isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Expected a dictionary: found %@", NSStringFromClass([value class]));
            continue;
        }
        NSDictionary<NSString *, id> *presetsGroup = (NSDictionary *)value;
        
        // Check the "types" array (of strings).
        id types = presetsGroup[PTAnnotStylePresetKeyTypes];
        if (!types) {
            // No annotation types specified.
            continue;
        }
        if (![types isKindOfClass:[NSArray class]]) {
            NSLog(@"Expected an array: found %@", NSStringFromClass([types class]));
            continue;
        }
        NSArray<id> *typesArray = (NSArray *)types;
        
        // Check the "presets" array (of dictionaries).
        id presets = presetsGroup[PTAnnotStylePresetKeyPresets];
        if (!presets) {
            // No presets specified.
            continue;
        }
        if (![presets isKindOfClass:[NSArray class]]) {
            NSLog(@"Expected an array: found %@", NSStringFromClass([presets class]));
            continue;
        }
        NSArray<id> *presetsArray = (NSArray *)presets;
        for (id type in typesArray) {
            const PTExtendedAnnotType annotType = PTExtendedAnnotTypeFromName(type);
            if (annotType == PTExtendedAnnotTypeUnknown) {
                NSLog(@"Unknown annotation type: %@", type);
                continue;
            }
            
            NSArray<PTAnnotStyle *> *stylePresets = [self PT_stylePresetsFromDefaults:presetsArray
                                                                 forAnnotationType:annotType];
            
            allStylePresets[type] = [@{
                DEFAULT_STYLE_IDENTIFIER: [[PTAnnotationStylePresetsGroup alloc] initWithStyles:stylePresets]
            } mutableCopy];
        }
    }
    
    self.annotationStylePresets = allStylePresets;
}

- (NSArray<PTAnnotStyle *> *)PT_stylePresetsFromDefaults:(NSArray<id> *)styleDefaults forAnnotationType:(PTExtendedAnnotType)annotationType
{
    NSMutableArray<PTAnnotStyle *> *stylePresets = [NSMutableArray array];
    
    for (id styleDefault in styleDefaults) {
        if (![styleDefault isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Expected a dictionary: found %@", NSStringFromClass([styleDefault class]));
            continue;
        }
        NSDictionary<NSString *, id> *styleDefaultDictionary = (NSDictionary *)styleDefault;
        
        PTAnnotStyle *stylePreset = [[PTAnnotStyle allocOverridden] initWithAnnotType:annotationType];
        
        for (NSString *key in styleDefaultDictionary) {
            id value = styleDefaultDictionary[key];
            
            NSDictionary<PTAnnotStylePresetKey, NSString *> *colorKeys = @{
                PTAnnotStylePresetKeyColor: PT_ANNOTSTYLE_KEY(color),
                PTAnnotStylePresetKeyFillColor: PT_ANNOTSTYLE_KEY(fillColor),
                PTAnnotStylePresetKeyTextColor: PT_ANNOTSTYLE_KEY(textColor),
            };
            
            NSDictionary<PTAnnotStylePresetKey, NSString *> *numericKeys = @{
                PTAnnotStylePresetKeyTextSize: PT_ANNOTSTYLE_KEY(textSize),
            };
            
            NSString *annotStyleKey = nil;
            if ((annotStyleKey = colorKeys[key])) {
                // Handle color key.
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *colorString = (NSString *)value;
                    UIColor *color = [UIColor pt_colorWithHexString:colorString];
                    
                    [stylePreset setValue:color forKey:annotStyleKey];
                }
            }
            else if ((annotStyleKey = numericKeys[key])) {
                // Handle numeric key.
                [stylePreset setValue:value forKey:annotStyleKey];
            } else {
                // Unknown key.
            }
        }
        
        [stylePresets addObject:stylePreset];
    }

    return [stylePresets copy];
}

@end
