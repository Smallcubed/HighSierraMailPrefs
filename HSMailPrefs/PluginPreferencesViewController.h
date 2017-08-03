//
//  PluginPreferencesViewController.h

#import <Cocoa/Cocoa.h>

@class MailTabViewController;

@protocol PluginPreferencesViewController <NSObject>

@required

@property (readonly,class) NSString *  preferencesIdentifier;
@property (readonly) NSString * preferencesIdentifier;
@property (readonly) NSImage* tabBarImage;
@property (readonly) NSString* tabBarLabel;

@optional

// optional delegate methods for when a newPreferencesController is set on MailApp
// these get called by HSMailPref's swizzle of -[MailApp setPreferencesController:] at appropriate times.
-(void) mailPreferencesWillOpen:(NSWindowController*)windowController;
-(void) mailPreferencesWillClose:(NSWindowController*)windowController;


// optional delegate methods for MailTabViewController
// these will get called by HSMailPref's swizzle of  -[MailTabViewController setSelectedTabViewItemIndex:] at the appropriate times.
-(void) mailTabViewController:(MailTabViewController*) controller willSelectTabViewItem:(NSTabViewItem*)tabItem;
-(void) mailTabViewController:(MailTabViewController*) controller didSelectTabViewItem:(NSTabViewItem*)tabItem;
@end
