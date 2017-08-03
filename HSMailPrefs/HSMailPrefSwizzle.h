#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifndef PLUGIN_ID
#error Preprocessor Macro PLUGIN_ID is not defined. This needs to be set in the Preprocessor Macros build setting for the target
#endif

#define _PLUGIN_STRINGIFY(a) #a
#define PLUGIN_STRINGIFY(a) _PLUGIN_STRINGIFY(a)

#define __PLUGIN_CODE_CONCAT(c,d) c ## d
#define _PLUGIN_CODE_CONCAT(a,b)   __PLUGIN_CODE_CONCAT(a,b)
#define __PLUGIN_CODE_CONCAT3(a,b,c) a ## b ## c
#define _PLUGIN_CODE_CONCAT3(a,b,c)   __PLUGIN_CODE_CONCAT3(a,b,c)

#define PLUGIN_PREFIXED(symbol) _PLUGIN_CODE_CONCAT(PLUGIN_ID,symbol)   // used for prefixing method name.  eg MTsetSelectedTabViewItemIndex
#define PLUGIN_POSTFIXED(symbol) _PLUGIN_CODE_CONCAT3(symbol,_,PLUGIN_ID)  //used for postfixing class name eg MailTabViewController_common_MT

#ifdef class
#undefine class
#endif

#define class(cname) YES?objc_getClass(#cname):0


@interface PLUGIN_POSTFIXED(Swizzle) :NSObject
+(BOOL)swizzleInstanceMethod:(SEL)selector
                     toClass:(Class)mailClass
                minOSVersion:(NSOperatingSystemVersion)minVersion
                maxOSVersion:(NSOperatingSystemVersion)maxVersion;

@end



