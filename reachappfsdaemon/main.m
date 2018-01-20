#include <stdio.h>
#include <stdlib.h>
#import "headers.h"

int main(int argc, char **argv, char **envp) {
	@autoreleasepool {
		NSString *filePath = @"/var/mobile/Library/.reachapp.uiappexitsonsuspend.wantstochangerootapp";
	  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
	    LogError(@"FS Daemon: plist does not exist");
	    return 0;
	  }

		NSDictionary *contents = [NSDictionary dictionaryWithContentsOfFile:filePath];

	  LSApplicationProxy *appInfo = [LSApplicationProxy applicationProxyForIdentifier:contents[@"bundleIdentifier"]];
	  NSString *path = [NSString stringWithFormat:@"%@/Info.plist", appInfo.bundleURL.absoluteString];
		NSURL *pathURL = [NSURL URLWithString:path];
	  NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfURL:pathURL];
	  infoPlist[@"UIApplicationExitsOnSuspend"] = contents[@"UIApplicationExitsOnSuspend"];
	  BOOL success = [infoPlist writeToURL:pathURL atomically:YES];

	  if (!success) {
			LogError(@"FS Daemon: error writing to plist: %@", path);
		} else {
			[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
		}
	}

	return 0;
}
