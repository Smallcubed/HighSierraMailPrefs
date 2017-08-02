//
//  PluginPreferencesViewController.m

#import "PluginPreferencesViewController.h"
#import "SierraPreferencesController.h"
#import <objc/runtime.h>

/* preferences for MacOS 10.13
 */

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface PluginPreferencesViewController ()
// not necessary but we have a ivar for a old style (pre 10.13) preference controller 
// so we can provide compatibility
@property (strong) SierraPreferencesController * preferenceController;
@end

__attribute__((annotate("returns_localized_nsstring"))) static inline NSString *_fakeLocalizedString(NSString *s){return s;} 

@implementation PluginPreferencesViewController

//-----------------------------------------------------------------------------------------------
//- Cooperative code start  -- do not edit this code unless you want to ruin it for everyone. ;)
+(void)load{
    // register this class with NSApp
    void* key = sel_registerName("pluginPreferenceViewControllerClasses");
    NSMutableArray * muClasses = [objc_getAssociatedObject(NSApp, key) mutableCopy]?:[NSMutableArray new];;
    [muClasses addObject:self];
    objc_setAssociatedObject(NSApp, key, muClasses, OBJC_ASSOCIATION_RETAIN);
}

// Cooperative Code end.
//-----------------------------------------------------------------------------------------------

// Specific to a plugin
-(NSString*) nibName{
    return @"MyPluginPreferenceNibName";
}

+(NSString *) preferencesIdentifier{
    return @"myPluginPrefIdentifier"; //eg mailtagsprefs
}
-(NSString *) preferencesIdentifier{
    return [[self class] preferencesIdentifier];
}

-(NSString*)tabBarLabel {
    return @"Example"; // eg "MailTags"
}

-(NSImage*)tabBarImage{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForImageResource: @"myPluginIcon" ];
    NSImage * theImage= [[NSImage alloc] initWithContentsOfFile: path];
    return theImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


#pragma mark Delegate methods from -[MailApp setPreferencesController:]

- (void) saveChanges{
    [self.preferenceController saveChanges];
}

- (void) initializeFromDefaults{
    [self.preferenceController initializeFromDefaults];
}

#pragma mark Delegate methods from -[MailTabViewController setSelectedTabViewItemIndex:]

-(void) mailTabViewController:(MailTabViewController*) controller willSelectTabViewItem:(NSTabViewItem*)tabItem{
    if(tabItem.viewController != self){
        NSLog(@"Thanks for visiting PluginPreferencesViewController! Please come again");
    }
}
-(void) mailTabViewController:(MailTabViewController*) controller didSelectTabViewItem:(NSTabViewItem*)tabItem{
     NSLog(@"Welcome to PluginPreferencesViewController! How can I help you?");
}


-(instancetype) init{
    self = [super init];
    if (self){
        
        // for compatibility with 10.12 and earlier we are using a 10.12 preference controller object and will basically pass through a few methods
        // depending on what you do, you may not want to do anything.
        
        
        SierraPreferencesController * prefController  = [[SierraPreferencesController alloc] init]; // the old Pre 10.13 controller.
        self.preferenceController = prefController;
        [[NSBundle bundleForClass:[self class]] loadNibNamed:[self nibName] owner:prefController topLevelObjects:nil];
        self.view = [prefController prefView];
        [self viewDidLoad];
        
    }
    return self;
}




@end
