# HighSierraMailPrefs

Submodule for Mail plugins to use to coordinate working with plugin preferences

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

---

## Instructions

1. Clone the HSMailPrefs repository as a submodule to your current working copy
2. Add the subfolder "HSMailPrefs" to your project.  (This is the folder that contains HSMailPreSwizzle.h file)
3. Make sure that all the following implementation files are added to your target:

> * `HSMailPrefSwizzle.m`
> * `MailApp_HSMailPrefs.m`
> * `MailTabViewController_HSMailPrefs.m`
        
( Note that these need ARC to Build so set add compiler flag `-fojbc-arc`  if your project isn't ARC)
        
4. Add a preprocessor macro to your build settings
            `PLUGIN_ID=XXX` where XXX is your usual plugin id  (eg MT for MailTags, MAO for MailPerspectives)

That's it.  Build and run.

The code take care of its own swizzling and will make ensure that it won't collide with other plugins (so long as the values for PLUGIN_ID are different).

### Adding a PluginPreferenceViewController

Now that Mail's individual plugin panes are controlled by NSViewControllers rather than NSPreferences objects, You may will need to create  your own PluginPreferenceViewController.  We added a `PluginPreferencesViewController` protocol (in PluginPreferencesViewController.h)

There is a `SamplePluginViewController.h/.m` for you to model your on.

In addition to the @required methods of the protocol, the preferencesViewController will need to register itself to be recognized by our code for loading preferences.

To do this you must
`#import "MailApp_HSMailPrefs.h"`

and then call  `[MailApp_HSMailPrefs registerPluginPreferenceViewControllerClass:self];` in your preferencesViewController `+load` method.

```
+(void)load{
    // register this PluginPreferenceViewController class
    [MailApp_HSMailPrefs registerPluginPreferenceViewControllerClass:self];
}
```

If you want to you reuse your Preferences controllers from 10.12 and earlier, you can store init and store an instance of it in the new view controller.  See `SamplePluginViewController.m` for an example.



        
