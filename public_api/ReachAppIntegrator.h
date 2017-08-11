#import <RAWidget.h>
#import <dlfcn.h>
#import <objc/runtime.h>

// original ReachApp widget api integrator for existing Reachability tweaks

#define CHECK_FOR_REACHAPP \
if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/MultiplexerCore.dylib"]) { \
	dlopen("/Library/MobileSubstrate/DynamicLibraries/MultiplexerCore.dylib", RTLD_NOW | RTLD_GLOBAL); \
}

#define IF_REACHAPP if (objc_getClass("RAWidget"))
