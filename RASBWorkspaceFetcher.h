@class SBMainWorkspace;

@interface RASBWorkspaceFetcher : NSObject
+ (Class)SBWorkspaceClass;
+ (SBMainWorkspace *)getCurrentSBWorkspaceImplementationInstanceForThisOS;
@end
