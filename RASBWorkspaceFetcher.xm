#import "RASBWorkspaceFetcher.h"
#import <objc/runtime.h>

// IMPORTANT: DO NOT IMPORT HEADERS.H
// REASON: HEADERS.H IMPORTS THIS FILE
// Cant we just use a version check? (this seems terribly inefficient)

@interface __SBWorkspace__class_impl_dummy : NSObject
+ (id)sharedInstance;
@end


Class CurrentSBWorkspaceClass = nil;

@implementation RASBWorkspaceFetcher
+ (Class)SBWorkspaceClass {
	return CurrentSBWorkspaceClass;
}

+ (SBWorkspace*)getCurrentSBWorkspaceImplementationInstanceForThisOS {
	if (![CurrentSBWorkspaceClass respondsToSelector:@selector(sharedInstance)]) {
		HBLogError(@"[ReachApp] \"SBWorkspace\" class '%s' does not have '+sharedInstance' method", class_getName(CurrentSBWorkspaceClass));
		return nil;
	}

	return [CurrentSBWorkspaceClass sharedInstance];
}
@end

%ctor {
	// SBMainWorkspace: iOS 9
	// SBWorkspace: iOS 8
	CurrentSBWorkspaceClass = %c(SBMainWorkspace) ?: %c(SBWorkspace);
}
