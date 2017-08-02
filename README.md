# HighSierraMailPrefs
code snippets for Mail plugins to use to coordinate working with plugin preferences


In High Sierra, Apple has changed the way it deals with preferences, migrating from a "NSPreference Module" approach to a NSWindowController with NSTabViews

With  the change, it is a little trickier for plugins to get into the preferences and to play cooperatively with other plugins

Because of this, we have created code and a few techniques for plugins to play nicely together and to assist with the loading of plugins.  With the added bonus of being able to leverage old ways of handling preferences to avoid signficiant code rewrites and cross version compatiblity issues.

We have added 2 swizzles

### [MailApp setPreferencesController:]

This is called when Mail opens the preferences window and registers the newly created window controller with the App.

We swizzle this as this is the best point to add the extra preferences view controllers for the plugins.

### [MailTabViewController setSelectedTabViewItemIndex:]



This is called when the user switches preferences views.

We swizzle this to adjust the geometry of the window to allow different sizes for plugin preferences views.

Both swizzles are meant to be dropped into your plugins without modifications (except for the method names).  They are designed so that if the code remains unchanged, it will ensure the work of adding plugins, changing geometry only happens once even though there may be many plugins installed.  (so long as all these plugins adhere to the methodology)

Additionally we provide a PluginPreferencesViewController protocol and a sampleController.

The protocol work hand-in-hand with the swizzles for loading plugins and receiving calls from MailTabViewController at appropriate times.

---

## Instructions

1. Add file   `PluginPreferencesViewController.h` to your project
2. Create a subclass of `NSViewController`  which implements the `PluginPreferencesViewController` protocol

```
@interface MyPluginPrefViewController : NSViewController <PluginPreferencesViewController>

```
3. In the implementation make sure you include the register the pluginPrefController when loading.  This code is vital as it will register the controllers so they will be loaded.

```
#import <objc/runtime.h>

@implmentation MyPluginPrefViewController
+(void)load{
    // register this class with NSApp
    [self registerPluginPreferences];
}
+(void)registerPluginPreferences{
    void* key = sel_registerName("pluginPreferenceViewControllerClasses");
    NSMutableArray * muClasses = [objc_getAssociatedObject(NSApp, key) mutableCopy]?:[NSMutableArray new];;
    [muClasses addObject:self];
    objc_setAssociatedObject(NSApp, key, muClasses, OBJC_ASSOCIATION_RETAIN);
}
...

```
4. implement the other protocol methods as required or desired.  see the Sample for an example.  You will note in the sample, I have a old preferences controller from pre 10.13 days, I make an instance of that and use its view.

5. Swizzle the method `-[MailApp setPreferencesController:]` with the code in `MailApp.m` file.  Search and replace `PLUGIN_PREFIX` with your own plugin prefix.   If you have different swizzling techniques, you may need to do extra work here.

6. Swizzle the method `-[MailTabViewController setSelectedTabViewItemIndex:]` with the code in `MailTabViewController.m` file.  Search and replace `PLUGIN_PREFIX` with your own plugin prefix.   If you have different swizzling techniques, you may need to do extra work here.

7. build and run.

8. Contact me with questions  



