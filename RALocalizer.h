@interface RALocalizer : NSObject
@property (strong, nonatomic) NSBundle *bundle;
+ (instancetype)sharedInstance;
- (NSString *)localizedStringForKey:(NSString *)key table:(NSString *)table;
@end
