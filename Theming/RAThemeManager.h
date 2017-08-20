#import "RATheme.h"

@interface RAThemeManager : NSObject {
	NSMutableDictionary *allThemes;
}
@property (strong, nonatomic, readonly) RATheme *currentTheme;
+ (instancetype)sharedInstance;

- (NSArray *)allThemes;
- (void)invalidateCurrentThemeAndReload:(NSString *)currentIdentifier;
@end
