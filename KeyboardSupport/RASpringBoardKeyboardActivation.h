#import "headers.h"
#import "RARunningAppsStateProvider.h"

@interface RASpringBoardKeyboardActivation : NSObject <RARunningAppsStateObserver>
+ (instancetype)sharedInstance;

@property (nonatomic, readonly, copy) NSString *currentIdentifier;

- (void)showKeyboardForAppWithIdentifier:(NSString *)identifier;
- (void)hideKeyboard;

- (UIWindow *)keyboardWindow;
@end
