#import "headers.h"

%ctor {
	IF_NOT_SPRINGBOARD {
		return;
	}
#if DEBUG
	LogInfo(@"[DRM] Not checking statistics on debug build");
#else
	LogInfo(@"[DRM] Would Normally Check DRM but public beta so ¯\_(ツ)_/¯");
/* Doesnt work cuz elijah's server is down but what ever
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *statsPath = @"/var/mobile/Library/Preferences/.multiplexer.stats_checked";
		if ([[NSFileManager defaultManager] fileExistsAtPath:statsPath]) {
			return;
		}

		CFStringRef (*$MGCopyAnswer)(CFStringRef);

		void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
		$MGCopyAnswer = (CFStringRef (*)(CFStringRef))dlsym(gestalt, "MGCopyAnswer");

		NSString *udid = (__bridge_transfer NSString*)$MGCopyAnswer(CFSTR("UniqueDeviceID"));
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://elijahandandrew.com/multiplexer/stats.php?udid=%@", udid]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];

		NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
		NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultConfiguration];
		[[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
			NSInteger code = httpResponse.statusCode;
			if (!error && (code == 0 || code == 200)) {
				[[NSFileManager defaultManager] createFileAtPath:statsPath contents:[NSData data] attributes:nil];
			}
		}] resume];
	});
*/
#endif
}
