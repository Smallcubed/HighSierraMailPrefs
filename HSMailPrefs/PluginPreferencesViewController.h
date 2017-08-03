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
// these get called from the cooperative swizzle of -[MailApp setPreferencesController:]
- (void) initializeFromDefaults;
- (void) saveChanges;


// optional delegate methods for MailTabViewController
// these will get called by cooperative swizzle of  -[MailTabViewController setSelectedTabViewItemIndex:]
-(void) mailTabViewController:(MailTabViewController*) controller willSelectTabViewItem:(NSTabViewItem*)tabItem;
-(void) mailTabViewController:(MailTabViewController*) controller didSelectTabViewItem:(NSTabViewItem*)tabItem;
@end
