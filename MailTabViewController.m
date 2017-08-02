
Swizzled method in MailTabViewController.

-(void)MTsetSelectedTabViewItemIndex:(NSUInteger)idx{

	if ([[NSThread currentThread] threadDictionary][@"pluginExclusionLock"]){
	  [swizzledSelf MTsetSelectedTabViewItemIndex:idx];
	  return;
	}
	
	// grab the pluginExclusionLock
	[[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = @YES;
	[swizzledSelf MTsetSelectedTabViewItemIndex:idx];
	NSWindow * prefWindow = [self.tabView window];

	NSTabViewItem * newTabItem = [[self tabViewItems] objectAtIndex:idx];
	NSSize preferredSize = [newTabItem.viewController preferredContentSize];

	CGFloat toolbarWidth = 0.0f;
	for (NSView * aView in  [[[[prefWindow.toolbar valueForKey:@"_toolbarView"] subviews] firstObject] subviews]){
	  toolbarWidth += aView.frame.size.width + 2.0;
	}
	preferredSize.width = MAX(preferredSize.width,toolbarWidth);

	if ( preferredSize.height>0 ){
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
		widthConstraint = [self.tabView.widthAnchor constraintEqualToConstant:bestWidth];
		widthConstraint.constant = bestWidth;
		widthConstraint.active = YES;
	}

	widthConstraint.constant =  preferredSize.width;
	[[NSThread currentThread] threadDictionary][@"pluginExclusionLock"] = nil;
}

