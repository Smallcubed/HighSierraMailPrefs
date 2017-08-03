// * this is a swizzle of -[Mailapp setPreferencesController:] method in Mail on 10.13

// last updated for build 17A315i

// the code will check a plugin_lock so that other plugins don't run the same code

// if it can grab the lock it will Instantiate ALL plugins view controllers registered with MailApp
// See the PluginPreferenceViewController Example

/*
     if the preference controller is being set to nil,
     it will send a "SaveChanges" method to all plugin view controllers
*/

#import "MailApp_HSMailPrefs.h"
#import "PluginPreferencesViewController.h"



@implementation MailApp_HSMailPrefs
+(void)load{
    // check the osVersion and swizzle
    
    __unused BOOL result = [self swizzleInstanceMethod:@selector(setPreferencesController:)
                                               toClass:@class(MailApp)
                                          minOSVersion:(NSOperatingSystemVersion){10,13,0}
                                          maxOSVersion:(NSOperatingSystemVersion){10,13,99}];
    
}
#define self ((MailApp*)self)

+(void)registerPluginPreferenceViewControllerClass:(Class)class{
    NSAssert([NSThread isMainThread],@"needs to be called on the main thread");
    void* key = sel_registerName("pluginPreferenceViewControllerClasses");
    NSMutableArray * muClasses = [objc_getAssociatedObject(NSApp, key) mutableCopy]?:[NSMutableArray new];;
    [muClasses addObject:class];
    objc_setAssociatedObject(NSApp, key, muClasses, OBJC_ASSOCIATION_RETAIN);
}
-(void)setPreferencesController:(NSWindowController*)prefController{
    // check the plugin lock
    if ([[NSThread currentThread] threadDictionary][@"setPreferencesController_PluginLock"]){
        [self PLUGIN_PREFIXED(setPreferencesController): prefController];
    }
    else{
        // grab the pluginlock
        [[NSThread currentThread] threadDictionary][@"setPreferencesController_PluginLock"] = @YES;
        
        if (prefController){
            
            // turn off the constraint the right aligns the font pickers in the fonts preferences because it looks ugly in wider windows.
            // this may change in future updates of Mail!
            NSTabViewController * tabViewController = (NSTabViewController*)[prefController contentViewController];
            
            NSArray <NSTabViewItem*> * items  = [tabViewController tabViewItems];
            for (NSTabViewItem * item in items){
                if ( [item.identifier isEqualToString:@"fontspref"] ){
                    NSView * containerView = [[[[[item.viewController view] subviews] firstObject] subviews] firstObject];
                    for (NSLayoutConstraint * constraint in containerView.constraints){
                        if (constraint.firstItem ==containerView && [constraint.secondItem isKindOfClass:@class(FontPreferenceContainerView) ]  && constraint.firstAttribute==NSLayoutAttributeTrailing && constraint.constant == 16){
                            [constraint setActive:NO];
                        }
                    }
                }
            }
            
            // each of the plugin classes should be registered in a mutable set
            // instantiate each of the plugin preferenceViewController Classes and send them an initializeFromDefaults message
            
            void* classesKey = sel_registerName("pluginPreferenceViewControllerClasses");
            NSArray * pluginPrefClasses = [objc_getAssociatedObject(NSApp, classesKey) copy];
            
            NSArray <NSString*> * currentInstalledIdentifiers = [items valueForKey:@"identifier"];
            
            [pluginPrefClasses enumerateObjectsUsingBlock:^(id PrefClass, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![PrefClass respondsToSelector:@selector(preferencesIdentifier)]){
                    return;
                }
                NSString * identifier = [PrefClass preferencesIdentifier];
                if (![currentInstalledIdentifiers containsObject:identifier]){
                    NSViewController <PluginPreferencesViewController> * controller = [PrefClass new];
                    NSTabViewItem * tabViewItem = [[NSTabViewItem alloc] initWithIdentifier: identifier];
                    tabViewItem.view = [controller view];
                    tabViewItem.viewController = controller;
                    [tabViewController addTabViewItem:tabViewItem];
                    // once it added, we can get the toolbar item and set the label and image
                    for (NSToolbarItem * toolbarItem in [prefController.window.toolbar items]){
                        if ([toolbarItem.itemIdentifier isEqualToString: identifier]){
                            toolbarItem.label = [controller tabBarLabel];
                            toolbarItem.image = [controller tabBarImage];
                            break;
                        }
                    }
                    // send the new controller an initialize from defaults ( if it responds to it.)
                    
                    if ([controller respondsToSelector:@selector(initializeFromDefaults)]){
                        [controller initializeFromDefaults];
                    }
                }
            }];
            
        }
        else{
            // the windowController is likely being deallocate and closed
            // send each of the plugin view controllers a  saveChanges message ( if it responds to it.)
            
            NSWindowController * currentWindowController = [self preferencesController];
            NSTabViewController *tabViewcontroller = (NSTabViewController *)[currentWindowController contentViewController];
            for(NSTabViewItem *tabViewItem in [tabViewcontroller tabViewItems]) {
                if ([tabViewItem.viewController respondsToSelector:@selector(saveChanges)]){
                    [(__kindof NSViewController*)(tabViewItem.viewController) saveChanges];
                }
            }
        }
        // call down the swizzle chain
        [self PLUGIN_PREFIXED(setPreferencesController):prefController];
        
        // release the plugin lock
        [[NSThread currentThread] threadDictionary][@"setPreferencesController_PluginLock"] = nil;
    }
}
@end

