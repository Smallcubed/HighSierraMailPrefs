#import <objc/runtime.h>
#import "HSMailPrefSwizzle.h"

static NSComparisonResult compareVersions(NSOperatingSystemVersion ver1 ,NSOperatingSystemVersion ver2){
    if (ver1.majorVersion < ver2.majorVersion){
        return NSOrderedAscending;
    }
    if (ver1.majorVersion > ver2.majorVersion){
        return NSOrderedDescending;
    }
    if (ver1.minorVersion < ver2.minorVersion){
        return NSOrderedAscending;
    }
    if (ver1.minorVersion > ver2.minorVersion){
        return NSOrderedDescending;
    }
    if (ver1.patchVersion < ver2.patchVersion){
        return NSOrderedAscending;
    }
    if (ver1.patchVersion > ver2.patchVersion){
        return NSOrderedDescending;
    }
    return NSOrderedSame;
    
}
@implementation PLUGIN_POSTFIXED(Swizzle)


+(BOOL)swizzleInstanceMethod:(SEL)selector
                     toClass:(Class)mailClass
                minOSVersion:(NSOperatingSystemVersion)minVersion
                maxOSVersion:(NSOperatingSystemVersion)maxVersion{
    
    NSOperatingSystemVersion version = [NSProcessInfo instancesRespondToSelector:@selector(operatingSystemVersion)] ? [[NSProcessInfo processInfo] operatingSystemVersion] : (NSOperatingSystemVersion){10,0,0};
    
    if (compareVersions(version,minVersion)==NSOrderedAscending){
        return NO; // swizzle doesn't meet min version
    }
    if (compareVersions(version,maxVersion)==NSOrderedDescending){
        return NO; // swizzle exceeds max version
    }
    
        
    NSAssert(mailClass,@"Could not find target class %@",NSStringFromClass(mailClass));
    
    Method mailMethod = class_getInstanceMethod(mailClass, selector);
    NSAssert(mailMethod,@"Could not find target method -[%@ %@]",NSStringFromClass(mailClass),NSStringFromSelector(selector));
    
    Method pluginMethod = class_getInstanceMethod(self, selector); // look in myClass for method.
    NSAssert(pluginMethod,@"Could not find provider method -[%@ %@]",NSStringFromClass(self),NSStringFromSelector(selector));
    
    // the plugin selector is a concat of PLUGIN_ID and the selector   eg:  MTsetSelectedTabViewItemIndex:
    SEL pluginSelector = NSSelectorFromString([NSString stringWithFormat:@"%s%@",PLUGIN_STRINGIFY(PLUGIN_ID), NSStringFromSelector(selector)]);
    
    // 1. add method -setSelectedTabViewItemIndex: to MailTabViewController
    //      this will do nothing if the class (not a superclass) already implements the method.
    //      if a superclass implements the method, then this class add the method using the superclass's implementation.
    
    if (class_addMethod(mailClass, selector, method_getImplementation(mailMethod), method_getTypeEncoding(mailMethod))){
        mailMethod = class_getInstanceMethod(mailClass, selector); // relook up the method as it will have changed;
    }
    
    //  2. add method -PLUGINsetSelectedTabViewItemIndex: to MailTabViewController
    //       if this fails then there is a major issue in that the method already exists (some other plugin using same pluginID?)
    
    if (class_addMethod(mailClass, pluginSelector, method_getImplementation(pluginMethod), method_getTypeEncoding(pluginMethod))){
        pluginMethod = class_getInstanceMethod(mailClass, pluginSelector);
    }
    else{
        NSAssert(YES,@"problem! selector %@ already exists in %@",NSStringFromSelector(pluginSelector),NSStringFromClass(mailClass));
    }
    
    NSAssert(mailMethod != nil && pluginMethod != nil, @"Something horrible happened");
    
    // 3. swizzle up mail's method and the plugins method
    method_exchangeImplementations(mailMethod, pluginMethod);
    return YES;
}
@end

