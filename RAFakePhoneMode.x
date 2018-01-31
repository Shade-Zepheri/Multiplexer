#import "RAFakePhoneMode.h"
#import "RAMessagingClient.h"
#import "RAMessagingServer.h"

/*
This is a wrapper for the ReachAppFakePhoneMode subproject.
I split them apart when i was trying to find some issue with app resizing/touches.
*/

#define RA_4S_SIZE CGSizeMake(320, 480)
#define RA_5S_SIZE CGSizeMake(320, 568)
#define RA_6S_SIZE CGSizeMake(375, 667)
#define RA_6P_SIZE CGSizeMake(414, 736)

CGSize forcePhoneModeSize;

@implementation RAFakePhoneMode

+ (void)load {
  // Prevent iPhone issue
  if (!IS_IPAD) {
    return;
  }

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ // somehow, this is needed to make sure that both force resizing and Fake Phone Mode work. Without the dispatch_after, even if fake phone mode is disabled,
    // force resizing seems to render touches incorrectly ¯\_(ツ)_/¯
    if (!IS_SPRINGBOARD && [RAFakePhoneMode shouldFakeForThisProcess]) {
      dlopen("/Library/MobileSubstrate/DynamicLibraries/ReachAppFakePhoneMode.dylib", RTLD_NOW);
      [RAFakePhoneMode updateAppSizing];
    }
  });
}

+ (CGSize)fakedSize {
  if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
    return CGSizeMake(forcePhoneModeSize.height, forcePhoneModeSize.width);
  }

  return forcePhoneModeSize;
}

+ (CGSize)fakeSizeForAppWithIdentifier:(NSString *)identifier {
  return forcePhoneModeSize;
}

+ (void)updateAppSizing {
  CGSize fakeSize = [RAFakePhoneMode fakedSize];
  CGRect fakeFrame = CGRectMake(0, 0, fakeSize.width, fakeSize.height);
  [UIWindow keyWindow].frame = fakeFrame;
}

+ (BOOL)shouldFakeForAppWithIdentifier:(NSString* )identifier {
  IF_NOT_SPRINGBOARD {
    LogWarn(@"[ReachApp] WARNING: +[RAFakePhoneMode shouldFakeForAppWithIdentifier:] called from outside SpringBoard!");
    return NO;
  }

  return [[RAMessagingServer mainMessagingServer] getDataForIdentifier:identifier].forcePhoneMode;
}

+ (BOOL)shouldFakeForThisProcess {
  static BOOL fakeFlag = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (![RAMessagingClient defaultAppClient].hasRecievedData) {
      [[RAMessagingClient defaultAppClient] requestUpdateFromServer];
    }

    fakeFlag = [RAMessagingClient defaultAppClient].currentData.forcePhoneMode;
  });

  return fakeFlag;
}

@end

%ctor {
  forcePhoneModeSize = RA_6S_SIZE;
}

/*
%hook UIApplication
-(BOOL) _isClassic
{
    return %orig;

    if (IS_SPRINGBOARD || ignorePhoneMode)
        return %orig;

    if ([RAFakePhoneMode shouldFakeForThisProcess])
        return YES;

    return %orig;
}

- (void)_setClassicMode:(int)arg1
{
    %orig([RAFakePhoneMode shouldFakeForThisProcess] ? 2 : arg1);
    // 0 = no classic
    // 1 = standard
    // 2 = 5/5s?
    // 3 - 6 = standard
}
%end
*/
