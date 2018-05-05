#import <SpringBoard/SBApplication.h>
#import "RABackgrounder.h"

@interface SBApplication (Aura)
@property (retain, nonatomic) NSMutableDictionary<NSString *, NSNumber *> *_ra_indicatorInfo;

- (void)_ra_addStatusBarIconIfNecessary;

- (RAIconIndicatorViewInfo)_ra_iconIndicatorInfo;
- (void)_ra_setIconIndicatorInfo:(RAIconIndicatorViewInfo)info;

@end