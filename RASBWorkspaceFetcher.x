#import "RASBWorkspaceFetcher.h"
#import <objc/runtime.h>

// IMPORTANT: DO NOT IMPORT HEADERS.H
// REASON: HEADERS.H IMPORTS THIS FILE
// Could get rid of this class but iOS 11 may need it

@interface SBWorkspace : NSObject
+ (instancetype)sharedInstance;
@end

Class CurrentSBWorkspaceClass = nil;

@implementation RASBWorkspaceFetcher
+ (Class)SBWorkspaceClass {
	return CurrentSBWorkspaceClass;
}

+ (SBWorkspace *)getCurrentSBWorkspaceImplementationInstanceForThisOS {
	if (![CurrentSBWorkspaceClass respondsToSelector:@selector(sharedInstance)]) {
		HBLogError(@"\"SBWorkspace\" class '%s' does not have '+sharedInstance' method", class_getName(CurrentSBWorkspaceClass));
		return nil;
	}

	return [CurrentSBWorkspaceClass sharedInstance];
}
@end

%ctor {
	// SBMainWorkspace: iOS 9
	// SBWorkspace: iOS 8
	CurrentSBWorkspaceClass = %c(SBMainWorkspace);
}
