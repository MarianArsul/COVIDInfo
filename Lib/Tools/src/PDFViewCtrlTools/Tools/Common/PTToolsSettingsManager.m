//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "PTToolsSettingsManager.h"
#import "ToolsConfig.h"
#import "PTToolsUtil.h"

#define PT_SETTINGS_KEY(key) PT_CLASS_KEY(PTToolsSettingsManager, key)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


NSString*  const PTToolsSettingsCategoryKey = @"category";
NSString*  const PTToolsSettingsFooterDescriptionKey = @"footerDescription";
NSString*  const PTToolsSettingsSettingKey = @"settings";
NSString*  const PTToolsSettingsMultivalueKey = @"multivalue";
NSString*  const PTToolsSettingsCategoryDefaultValueKey = @"defaultValue";
NSString*  const PTToolsSettingsSettingNameKey = @"name";
NSString*  const PTToolsSettingsSettingKeyKey = @"key";
NSString*  const PTToolsSettingsPlistNameKey = @"settingsPlist";
NSString*  const PTToolsSettingsCategoryDescriptionKey = @"description";
NSString*  const PTToolsSettingsMinOSKey = @"minOSVersion";
NSString*  const PTToolsSettingsUnavailableKey = @"unavailableValue";

/*
 * To make a new setting:
 *
 * 1. Declare setting in PTToolsSettings.plist.
 * 2. Create property with getter/setter implementation on `PTToolsSettingsManager`.
 * 3. Register to observe property in `PTDocumentBaseViewController` init method.
 *
 */

@interface PTToolsSettingsManager()

@property (nonatomic, strong) NSMutableSet<NSString*>* availableSettingsKeys;

@end

@implementation PTToolsSettingsManager

+(PTToolsSettingsManager*)sharedManager
{
    static PTToolsSettingsManager *toolsSharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        toolsSharedInstance = [[PTToolsSettingsManager alloc] init];
        
        NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
        toolsSharedInstance.availableSettingsKeys = [NSMutableSet set];

        NSArray *settingsLists = @[toolsSharedInstance.toolsDefaultSettings,
                                   toolsSharedInstance.applePencilDefaultSettings];

        for (NSArray<NSDictionary<NSString *, id> *> *settingsList in settingsLists){
            for(NSDictionary* category in settingsList)
            {
                for(NSDictionary* setting in category[PTToolsSettingsSettingKey])
                {
                    if (![setting objectForKey:PTToolsSettingsCategoryDefaultValueKey]) {
                        continue;
                    }
                    // for use if setting is unavailable
                    NSString* minOS = setting[PTToolsSettingsMinOSKey];
                    if( minOS != Nil && SYSTEM_VERSION_LESS_THAN(minOS) )
                    {
                        [defaults setValue:setting[PTToolsSettingsUnavailableKey] forKey:setting[PTToolsSettingsSettingKeyKey]];
                    }
                    else
                    {
                        [toolsSharedInstance.availableSettingsKeys addObject:setting[PTToolsSettingsSettingKeyKey]];
                        NSNumber *settingValue = setting[PTToolsSettingsCategoryDefaultValueKey];

                        // always show text search on iPads.
                        if( [setting[PTToolsSettingsSettingKeyKey] isEqualToString:@"showTextSearchInMainToolbar"] && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad )
                        {
                            settingValue = [NSNumber numberWithBool:YES];
                        }
                        [defaults setValue:settingValue forKey:setting[PTToolsSettingsSettingKeyKey]];
                    }
                }
            }
            [NSUserDefaults.standardUserDefaults registerDefaults:defaults];
        }
    });

    return toolsSharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(NSArray<NSDictionary<NSString *, id> *> *)toolsDefaultSettings
{
    return [self defaultSettingsForPlistName:@"PTToolsSettings"];
}

-(NSArray<NSDictionary<NSString *, id> *> *)applePencilDefaultSettings
{
    return [self defaultSettingsForPlistName:@"PTApplePencilSettings"];
}

- (NSArray<NSDictionary<NSString *,id> *> *)defaultSettingsForPlistName:(NSString *)plistName
{
    NSString* settingsPath = [[PTToolsUtil toolsBundle] pathForResource:plistName ofType:@"plist"];
    
    return [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:settingsPath]];
}

-(BOOL)boolForKey:(NSString*)key
{
    return [NSUserDefaults.standardUserDefaults boolForKey:key];
}

-(void)setBool:(BOOL)value forKey:(NSString*)key
{
    if (![self.availableSettingsKeys containsObject:key])
    {
        NSAssert([self.availableSettingsKeys containsObject:key], @"Attempting to set unavailable key.");
        return;
    }
    
    [self willChangeValueForKey:key];
    [NSUserDefaults.standardUserDefaults setBool:value forKey:key];
    [self didChangeValueForKey:key];
}

-(NSInteger)integerForKey:(NSString*)key
{
    return [NSUserDefaults.standardUserDefaults integerForKey:key];
}

-(void)setInteger:(NSInteger)integer forKey:(NSString*)key
{
    if (![self.availableSettingsKeys containsObject:key])
    {
        NSAssert([self.availableSettingsKeys containsObject:key], @"Attempting to set unavailable key.");
        return;
    }

    [self willChangeValueForKey:key];
    [NSUserDefaults.standardUserDefaults setInteger:integer forKey:key];
    [self didChangeValueForKey:key];
}

-(BOOL)selectAnnotationAfterCreation
{
    return [self boolForKey:PT_SETTINGS_KEY(selectAnnotationAfterCreation)];
}

-(void)setSelectAnnotationAfterCreation:(BOOL)selectAnnotationAfterCreation
{
    [self setBool:selectAnnotationAfterCreation forKey:PT_SETTINGS_KEY(selectAnnotationAfterCreation)];
}

-(BOOL)tabsEnabled
{
    return [self boolForKey:PT_SETTINGS_KEY(tabsEnabled)];
}

-(void)setTabsEnabled:(BOOL)tabsEnabled
{
    [self setBool:tabsEnabled forKey:PT_SETTINGS_KEY(tabsEnabled)];
}

-(BOOL)automaticallyHideToolbars
{
    return [self boolForKey:PT_SETTINGS_KEY(automaticallyHideToolbars)];
}

-(void)setAutomaticallyHideToolbars:(BOOL)automaticallyHideToolbars
{
    [self setBool:automaticallyHideToolbars forKey:PT_SETTINGS_KEY(automaticallyHideToolbars)];
}

-(BOOL)showInkInMainToolbar
{
    return [self boolForKey:PT_SETTINGS_KEY(showInkInMainToolbar)];
}

-(void)setShowInkInMainToolbar:(BOOL)showInkInMainToolbar
{
    [self setBool:showInkInMainToolbar forKey:PT_SETTINGS_KEY(showInkInMainToolbar)];
}

-(BOOL)showTextSearchInMainToolbar
{
    return [self boolForKey:PT_SETTINGS_KEY(showTextSearchInMainToolbar)];
}

-(void)setShowTextSearchInMainToolbar:(BOOL)showTextSearchInMainToolbar
{
    [self setBool:showTextSearchInMainToolbar forKey:PT_SETTINGS_KEY(showTextSearchInMainToolbar)];
}

-(BOOL)javascriptEnabled
{
    return [self boolForKey:PT_SETTINGS_KEY(javascriptEnabled)];
}

-(void)setJavascriptEnabled:(BOOL)javascriptEnabled
{
    [self setBool:javascriptEnabled forKey:PT_SETTINGS_KEY(javascriptEnabled)];
}

-(BOOL)colorManagementEnabled
{
    return [self boolForKey:PT_SETTINGS_KEY(colorManagementEnabled)];
}

-(void)setColorManagementEnabled:(BOOL)colorManagementEnabled
{
    [self setBool:colorManagementEnabled forKey:PT_SETTINGS_KEY(colorManagementEnabled)];
}


-(BOOL)applePencilDrawsInk
{
    return [self boolForKey:PT_SETTINGS_KEY(applePencilDrawsInk)];
}

-(void)setApplePencilDrawsInk:(BOOL)applePencilDrawsInk
{
    [self setBool:applePencilDrawsInk forKey:PT_SETTINGS_KEY(applePencilDrawsInk)];
}

-(BOOL)freehandUsesPencilKit
{
    return [self boolForKey:PT_SETTINGS_KEY(freehandUsesPencilKit)];
}

-(void)setFreehandUsesPencilKit:(BOOL)freehandUsesPencilKit
{
    [self setBool:freehandUsesPencilKit forKey:PT_SETTINGS_KEY(freehandUsesPencilKit)];
}

- (BOOL)pencilHighlightMultiplyBlendModeEnabled
{
    return [self boolForKey:PT_SETTINGS_KEY(pencilHighlightMultiplyBlendModeEnabled)];
}

- (void)setPencilHighlightMultiplyBlendModeEnabled:(BOOL)pencilHighlightMultiplyBlendModeEnabled
{
    [self setBool:pencilHighlightMultiplyBlendModeEnabled forKey:PT_SETTINGS_KEY(pencilHighlightMultiplyBlendModeEnabled)];
}

- (PTPencilInteractionMode)pencilInteractionMode{
    return (PTPencilInteractionMode)[self integerForKey:PT_SETTINGS_KEY(pencilInteractionMode)];
}

- (void)setPencilInteractionMode:(PTPencilInteractionMode)pencilInteractionMode
{
    [self setInteger:pencilInteractionMode forKey:PT_SETTINGS_KEY(pencilInteractionMode)];
}

-(BOOL)stopScreenFromDimming
{
    return [self boolForKey:PT_SETTINGS_KEY(stopScreenFromDimming)];
}

-(void)setStopScreenFromDimming:(BOOL)stopScreenFromDimming
{
    [self setBool:stopScreenFromDimming forKey:PT_SETTINGS_KEY(stopScreenFromDimming)];
}



@end
