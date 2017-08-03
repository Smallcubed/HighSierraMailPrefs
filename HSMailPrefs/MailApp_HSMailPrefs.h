//
//  MailApp_HSMailPrefs.h
//  MailTags4
//
//  Created by Scott Morrison on 2017-08-03.
//
#import <Cocoa/Cocoa.h>
#import "HSMailPrefSwizzle.h"

@interface MailApp : NSApplication
-(NSWindowController*)preferencesController;
-(void)setPreferencesController:(NSWindowController*)controller;
-(void)PLUGIN_PREFIXED(setPreferencesController):(NSWindowController*)controller;
-(void)registerPluginPreferenceViewControllerClass:(Class)class;

@end


#define MailApp_HSMailPrefs PLUGIN_POSTFIXED(MailApp_HSMailPrefs)

@interface MailApp_HSMailPrefs : PLUGIN_POSTFIXED(Swizzle)
+(void)registerPluginPreferenceViewControllerClass:(Class)class;
@end



