
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


The layout work will call out to specific plugins' viewControllers 
   just before it is deselected
   after it has been selected (after layout work done)
 
*/

#import "PluginPreferencesViewController.h" // necessary for calls to plugins

@implementation MailTabViewController
	
/* Code notes

   PLUGIN_PREFIX refers to the naming scheme of your plugin's swizzling mechanism
   
   for example, in MailTags the method is named -MTsetSelectedTabViewItemIndex:
   		in Mail Act-On it is named: -MAOsetSelectedTabViewItemIndex:
		
   The actual name of the method depends on how you swizzle from the provider class into the target class.
   Same goes for how you call down the swizzle chain

   swizzledSelf indicates that you are calling down the swizzle chain 
   ie . calling the swizzled out/original implementation of the method)
   
   in my code base, swizzled self is a cast of self to the original (swizzled) class.
   #define swizzledSelf ((MailTabViewController*)self)
   
   // but you may do this differently -- diferrent strokes for different folks.
   
   
*/
	
-(void)PLUGIN_PREFIXsetSelectedTabViewItemIndex:(NSUInteger)idx{
    // check to see if we should change the layout
    
    if (self.tabView.subviews.count==0  // first call will not have any views loaded -- so don't do layout work.
        || [self isKindOfClass:CLS(MailTabViewController)]==NO  // depending on swizzle technique, we may have swizzled NSTabViewController not MailTabViewController
        || [[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] //some other plugin is doing the layout work
        || idx == self.selectedTabViewItemIndex // I am not changing tabs here nothing to do.
        ){
        [swizzledSelf PLUGIN_PREFIXsetSelectedTabViewItemIndex:idx];
        return;
    }
    
    // grab the pluginExclusionLock
    [[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = @YES;
    
    // let the currently selected preference know it will soon not be the currently selected preference
    
    NSTabViewItem * newTabItem = self.tabViewItems[idx];
    
    if (idx < self.tabViewItems.count){
        NSUInteger currentIndex = [self selectedTabViewItemIndex];
        if (currentIndex <self.tabViewItems.count){
            NSTabViewItem * oldTabItem = self.tabViewItems[currentIndex];
            if ([oldTabItem.viewController respondsToSelector:@selector(mailTabViewController:willSelectTabViewItem:)]){
                [oldTabItem.viewController mailTabViewController:self willSelectTabViewItem:newTabItem];
            }
        }
    }
    
    NSWindow * prefWindow = [self.tabView window];

    // figure out the mininum width of the window to accommodate all the plugins' tab icons.
    CGFloat toolbarWidth = 0.0f;
    for (NSView * aView in  [[[[prefWindow.toolbar valueForKey:@"_toolbarView"] subviews] firstObject] subviews]){
        toolbarWidth += aView.frame.size.width + 2.0; // 2.0 padding between each view.
    }
    
    
    //  Get the best content size for the view
    CGFloat viewWidth = NSWidth(newTabItem.viewController.view.frame);
    NSSize contentSize = newTabItem.viewController.preferredContentSize;
    if (!CGSizeEqualToSize(contentSize, NSZeroSize)) {
        viewWidth = contentSize.width;
    }
    // get the maximum of the plugins view width and the toolbar width;
    // note that we have to get the view width BEFORE calling down the swizzle chain as adding the view to the window will change its width
    CGFloat newViewWidth = MAX(toolbarWidth, viewWidth);
    
    // call down the swizzle chain
    
    [swizzledSelf PLUGIN_PREFIXsetSelectedTabViewItemIndex:idx];
    
    // find and set width constraint on tabView;
    NSLayoutConstraint * widthConstraint = nil;
    for (NSLayoutConstraint *constraint in [self.tabView constraints]){
        if (constraint.firstAttribute == NSLayoutAttributeWidth && constraint.relation == NSLayoutRelationEqual && constraint.secondItem==nil){
            widthConstraint = constraint;
            break;
        }
    }
    if (!widthConstraint) {
        // no width constraint  -- lets add one.
        widthConstraint = [self.tabView.widthAnchor constraintEqualToConstant:newViewWidth];
    }
    
    // make sure the constraint is active and has the size we want.
    widthConstraint.active = YES;
    widthConstraint.constant =  newViewWidth;
    
    // let the newly selected plugin know it was just selected
    if ([newTabItem.viewController respondsToSelector:@selector(mailTabViewController:didSelectTabViewItem:)]){
        [newTabItem.viewController mailTabViewController:self didSelectTabViewItem:newTabItem];
    }
    
    // we are done here, release the exclusionLock
    [[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = nil;
}

@end
