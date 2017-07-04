#import <Foundation/Foundation.h>
#import <version.h>

%group iOS8
%hookf(int, BSAuditTokenTaskHasEntitlement, id connection, NSString *entitlement) {
  if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
    return true;
  }

  return %orig;
}
%end

%group iOS9
%hookf(int, BSXPCConnectionHasEntitlement, id connection, NSString *entitlement) {
  if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
    return true;
  }

  return %orig;
}
%end

%ctor {
  // We can never be too sure (im pretty sure we can)
  if (IS_IOS_OR_NEWER(iOS_9_0)) {
    void *BSXPCConnectionHasEntitlement = MSFindSymbol(NULL, "_BSXPCConnectionHasEntitlement");
    %init(iOS9);
  } else {
    void *BSAuditTokenTaskHasEntitlement = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
    %init(iOS8);
  }
}
