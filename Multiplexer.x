#import "Multiplexer.h"
#import "RACompatibilitySystem.h"
#import "headers.h"

@implementation MultiplexerExtension
@end

@implementation Multiplexer
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(Multiplexer, sharedInstance->activeExtensions = [NSMutableArray array]);
}

- (NSString *)currentVersion {
	return @"1.0.0";
}

- (BOOL)isOnSupportedOS {
	return IS_IOS_BETWEEN(iOS_9_0, iOS_10_2);
}

- (void)registerExtension:(NSString *)name forMultiplexerVersion:(NSString *)version {
	if ([self.currentVersion compare:version options:NSNumericSearch] == NSOrderedDescending) {
		[RACompatibilitySystem showWarning:[NSString stringWithFormat:@"Extension %@ was built for Multiplexer version %@, which is above the current version. Compliancy issues may occur.", name, version]];
	}

	MultiplexerExtension *ext = [[MultiplexerExtension alloc] init];
	ext.name = name;
	ext.multiplexerVersion = version;
	[activeExtensions addObject:ext];
}

+ (SBAppToAppWorkspaceTransaction *)createSBAppToAppWorkspaceTransactionForExitingApp:(SBApplication *)app {
	// ** below code from Mirmir (https://github.com/EthanArbuckle/Mirmir/blob/lamo_no_ms/Lamo/CDTLamo.mm#L114-L138)
	SBWorkspaceApplicationTransitionContext *transitionContext = [%c(SBWorkspaceApplicationTransitionContext) context];

	//set layout role to 'side' (deactivating)
	SBWorkspaceDeactivatingEntity *deactivatingEntity = [%c(SBWorkspaceDeactivatingEntity) entity];
	deactivatingEntity.layoutRole = 3;
	[transitionContext setEntity:deactivatingEntity forLayoutRole:3];

	//set layout role for 'primary' (activating)
	SBWorkspaceHomeScreenEntity *homescreenEntity = [%c(SBWorkspaceHomeScreenEntity) entity];
	[transitionContext setEntity:homescreenEntity forLayoutRole:2];

	transitionContext.animationDisabled = YES;

	//create transititon request
	SBMainWorkspaceTransitionRequest *transitionRequest = [[%c(SBMainWorkspaceTransitionRequest) alloc] initWithDisplay:[%c(FBDisplayManager) mainDisplay]];
	transitionRequest.applicationContext = transitionContext;

	return [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithTransitionRequest:transitionRequest];
}

+ (BOOL)shouldShowControlCenterGrabberOnFirstSwipe {
	// Only keeping this method in case iOS 11 changes stuff
	return [[%c(SBControlCenterController) sharedInstance] _shouldShowGrabberOnFirstSwipe];
}
@end
