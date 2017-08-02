
/* 
Swizzled method in MailTabViewController.

This method takes care of doing the layout of the MailTabView to accommodate different sizes for different plugin views.

All plugins need to coordinate on this to prevent weirdness in the size of the plugin window and prevent one plugin
from fouling things up for other plugins.

about the "PluginExclusionLock"
As the changes here only need to be performed once regardless of the number of plugins installed,
we use a object stored on the thread dictionary to ensure only the first plugin makes the changes.

The first plugin (which will be indeterminate) encountered will set a value on the thread dictionary and
then perform the work.

All subsequent plugins will check for the flag and if present, simply pass the control down the swizzle chain.

The general structure is
-(void) SwizzleSetSelectedTabViewItemIndex:(NSUInteger)idx{
	if ThreadDictionary flag present
	    call swizzled method 
	else
	    set ThreadDictionary flag
	    call swizzled method
	    do layout work  // magic happens here
	    remove threadDictionary flag
}


The layout work will call out to the viewController of the selected item for specifics
	

*/
@interface NSViewController (MailPlugin)
	// declaration so that compiler will not scream at you about selector not found.
	// plugins should implement this method if they need to do any specific updates internal
	// to their preference view controller
-(void)	wasSelectedByPreferencesTabViewController:(MailTabViewController*) controller;
-(void)	willBeDeselectedByPreferencesTabViewController:(MailTabViewController*) controller;

@end
@implementation MailTabViewController
	
-(void)MTsetSelectedTabViewItemIndex:(NSUInteger)idx{

	if ([[NSThread currentThread] threadDictionary][@"pluginExclusionLock"]){
	  	[swizzledSelf MTsetSelectedTabViewItemIndex:idx];
	  	return;
	}
	
	// grab the pluginExclusionLock
	[[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = @YES;
	
	// let the currently selected preference know it will soon not be the currently selected preference
	
	if (idx < self.tabViewItems.count){
		NSTabViewItem * oldTabItem = self.tabViewItems[idx];
		if ([oldTabItem.viewController respondsToSelector:@selector(willBeDeselectedByPreferencesTabViewController:)]){
	  		[oldTabItem.viewController willBeDeselectedByPreferencesTabViewController:self];
		}
	}
		    
	// call down the swizzle chain 
	[swizzledSelf MTsetSelectedTabViewItemIndex:idx];
	
	// magic begins here.
		    
	NSTabViewItem * newTabItem = self.tabViewItems[idx];
	
	// ask the current item its preferred size.   By default NSViewController returns {0,0}
	// each plugin should override this in their view controller subclass to provide a size.
	    
	NSSize preferredSize = [newTabItem.viewController preferredContentSize];

	NSWindow * prefWindow = [self.tabView window];
	// figure out the mininum width of the window to accommodate all the plugins' tab icons.
	CGFloat toolbarWidth = 0.0f;
	for (NSView * aView in  [[[[prefWindow.toolbar valueForKey:@"_toolbarView"] subviews] firstObject] subviews]){
	  	toolbarWidth += aView.frame.size.width + 2.0; // 2.0 padding between each view.
	}
	
	// select the maximum of the plugins preferred width and the toolbar width;
	    
	preferredSize.width = MAX(preferredSize.width,toolbarWidth);

	if ( preferredSize.height>0 ){
        	// currently the tabview doesn't have a height constraint.
	 	 NSRect frame = [prefWindow frame];
	 	 CGFloat height = preferredSize.height+TabItemHeight; // 78 for the height the tabs
	  	frame.origin.y = NSMaxY(frame)-height;
	  	frame.size.height = height;
	  	[prefWindow setFrame:frame display:NO];
	}

	// find and set width constraint on tabView;

	for (NSLayoutConstraint *constraint in [self.tabView constraints]){
	  	if (constraint.firstAttribute == NSLayoutAttributeWidth && constraint.relation == NSLayoutRelationEqual && constraint.secondItem==nil){
			widthConstraint = constraint;
	  	}
	}
	if (!widthConstraint) {
		// no width constraint  -- lets add one.
		widthConstraint = [self.tabView.widthAnchor constraintEqualToConstant:preferredSize.width];
	}
	
	// make sure the constraint is active and has the size we want.
	widthConstraint.active = YES;
	widthConstraint.constant =  preferredSize.width;
	
	// let the newly selected plugin know it was just selected
	if ([newTabItem.viewController respondsToSelector:@selector(wasSelectedByPreferencesTabViewController:)]){
	  	[newTabItem.viewController wasSelectedByPreferencesTabViewController:self];
	}
	
	// we are done here, release the exclusionLock     
	[[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = nil;
}

@end
