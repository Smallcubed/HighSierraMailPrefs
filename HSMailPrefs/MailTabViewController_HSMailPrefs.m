//
//  MailTabViewController_PLUGIN.m swizzle
#import "HSMailPrefSwizzle.h"
#import "PluginPreferencesViewController.h"

// useful macros
// lets see you do this in swift!  ;P

@interface MailTabViewController : NSTabViewController
-(void)PLUGIN_PREFIXED(setSelectedTabViewItemIndex):(NSInteger)idx;
@end


@interface PLUGIN_POSTFIXED(MailTabViewController_HSMailPrefs) : PLUGIN_POSTFIXED(Swizzle)
@end

@implementation PLUGIN_POSTFIXED(MailTabViewController_HSMailPrefs)

+(void)load{
    // check the osVersion and swizzle
    [self swizzleInstanceMethod:@selector(setSelectedTabViewItemIndex:)
                        toClass:@class(MailTabViewController)
                   minOSVersion:(NSOperatingSystemVersion){10,13,0}
                   maxOSVersion:(NSOperatingSystemVersion){10,13,99}];
}
#define self ((MailTabViewController*)self)

// swizzle method will add a selector using the pluginPrefix to the target Mail class
// eg if the selector is -setSelectedTabViewItemIndex: and the PLUGIN_ID is MT,
//       then method MTsetSelectedTabViewItemIndex: is added to the target class
//    once added, the swizzle with exchange implementation pointers with the current mail Method



// Swizzled methods
// we use the plugin prefix macro to
-(void)setSelectedTabViewItemIndex:(NSInteger)idx{
    // check to see if we should change the layout
    
    if (self.tabView.subviews.count==0  // first call will not have any views loaded -- so don't do layout work.
        || [self isKindOfClass:objc_getClass("MailTabViewController")]==NO  // depending on swizzle technique, we may have swizzled NSTabViewController not MailTabViewController
        || [[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] //some other plugin is doing the layout work
        || idx == self.selectedTabViewItemIndex // I am not changing tabs here nothing to do.
        ){
        [self PLUGIN_PREFIXED(setSelectedTabViewItemIndex):idx]; // call down the swizzle chain
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
                [(NSViewController <PluginPreferencesViewController> *)oldTabItem.viewController mailTabViewController:(MailTabViewController*)self willSelectTabViewItem:newTabItem];
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
    
    [self PLUGIN_PREFIXED(setSelectedTabViewItemIndex):idx];
    
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
        [(NSViewController <PluginPreferencesViewController> *) newTabItem.viewController mailTabViewController: (MailTabViewController*)self didSelectTabViewItem:newTabItem];
    }
    
    // we are done here, release the exclusionLock
    [[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = nil;
}


@end
