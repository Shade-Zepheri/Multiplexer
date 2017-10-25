#import "headers.h"
#import "RADesktopWindow.h"
#import "RAWindowBar.h"

typedef struct {
	CGPoint center;
	CGAffineTransform transform;
} RAPreservedWindowInformation;

// Cuz struct causes compiling errors
@interface RAPreservedDesktopInformation : NSObject
@property (assign, nonatomic) NSUInteger index;
@property (copy, nonatomic) NSArray *openApps;

- (instancetype)initWithIndex:(NSUInteger)index;

@end


@interface RAWindowStatePreservationSystemManager : NSObject {
	NSMutableDictionary *dict;
}
+ (instancetype)sharedInstance;

- (void)loadInfo;
- (void)saveInfo;

// Desktop
- (void)saveDesktopInformation:(RADesktopWindow *)desktop;
- (BOOL)hasDesktopInformationAtIndex:(NSInteger)index;
- (RAPreservedDesktopInformation *)desktopInformationForIndex:(NSInteger)index;

// Window
- (void)saveWindowInformation:(RAWindowBar *)window;
- (BOOL)hasWindowInformationForIdentifier:(NSString *)appIdentifier;
- (RAPreservedWindowInformation)windowInformationForAppIdentifier:(NSString *)identifier;
- (void)removeWindowInformationForIdentifier:(NSString *)appIdentifier;
@end
