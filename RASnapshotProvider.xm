#import "headers.h"
#import "RASnapshotProvider.h"
#import "RAWindowBar.h"
#import "RAResourceImageProvider.h"

@implementation RASnapshotProvider
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RASnapshotProvider, sharedInstance->imageCache = [[NSCache alloc] init]);
}

- (UIImage *)snapshotForIdentifier:(NSString *)identifier orientation:(UIInterfaceOrientation)orientation {
	/*if (![NSThread isMainThread])
	{
		__block id result = nil;
		NSOperationQueue* targetQueue = [NSOperationQueue mainQueue];
		[targetQueue addOperationWithBlock:^{
		    result = [self snapshotForIdentifier:identifier orientation:orientation];
		}];
		[targetQueue waitUntilAllOperationsAreFinished];
		return result;
	}*/
	@autoreleasepool {
		if ([imageCache objectForKey:identifier]) {
			return [imageCache objectForKey:identifier];
		}

		UIImage *image = nil;

		SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:identifier];
		__block SBAppSwitcherSnapshotView *view = nil;

		ON_MAIN_THREAD(^{
			if ([%c(SBUIController) respondsToSelector:@selector(switcherController)]) {
				view = [[[%c(SBUIController) sharedInstance] switcherController] performSelector:@selector(_snapshotViewForDisplayItem:) withObject:item];
				[view setOrientation:orientation orientationBehavior:0];
			} else {
				view = [%c(SBAppSwitcherSnapshotView) appSwitcherSnapshotViewForDisplayItem:item orientation:orientation preferringDownscaledSnapshot:NO loadAsync:NO withQueue:nil];
			}
		});

		if (view) {
			if ([view respondsToSelector:@selector(_loadSnapshotSync)]) {
				dispatch_sync(dispatch_get_main_queue(), ^{
					[view _loadSnapshotSync];
				});
				image = [(UIImageView *)[view valueForKey:@"_snapshotImageView"] image];
			} else {
				// prettry much implementing _loadSnapshotSyncPreferringDownscaled since the image isnt saved anywhere
				_SBAppSwitcherSnapshotContext *snapshotContext = [view _contextForAvailableSnapshotWithLayoutState:nil preferringDownscaled:NO defaultImageOnly:NO];
				image = [view _syncImageFromSnapshot:snapshotContext.snapshot];
			}
		}

		if (!image) {
			LogWarn(@"Couldn't Get Switcher Image; Using SplashScreen");
			SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];

			if (app && app.mainSceneID) {
				@try {
					CGRect frame = CGRectMake(0, 0, 0, 0);
					UIView *view = [%c(SBUIController) _zoomViewWithSplashboardLaunchImageForApplication:app sceneID:app.mainSceneID screen:UIScreen.mainScreen interfaceOrientation:0 includeStatusBar:YES snapshotFrame:&frame];

					if (view) { //renderInContext appears to actually be faster
						UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, 0);

						ON_MAIN_THREAD(^{
							[view.layer renderInContext:UIGraphicsGetCurrentContext()];
						});

						image = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
					}
				}
				@catch (NSException *ex) {
					LogError(@"[ReachApp] error generating snapshot: %@", ex);
				}
			}

			if (!image) { // we can only hope it does not reach this point of desperation
				image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Default.png", app.path]];
			}
		}

		if (image) {
			[imageCache setObject:image forKey:identifier];
		}

		return image;
	}
}

- (UIImage *)snapshotForIdentifier:(NSString *)identifier {
	return [self snapshotForIdentifier:identifier orientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)forceReloadOfSnapshotForIdentifier:(NSString *)identifier {
	[imageCache removeObjectForKey:identifier];
}

- (UIImage *)storedSnapshotOfMissionControl {
	return [imageCache objectForKey:@"missioncontrol"];
}

- (void)storeSnapshotOfMissionControl:(UIWindow *)window {
	UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 0);

	[window.layer renderInContext:UIGraphicsGetCurrentContext()];

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	if (image) {
		[imageCache setObject:image forKey:@"missioncontrol"];
	}
}

- (NSString *)createKeyForDesktop:(RADesktopWindow *)desktop {
	return [NSString stringWithFormat:@"desktop-%tu", desktop.hash];
}

- (UIImage *)snapshotForDesktop:(RADesktopWindow *)desktop {
	NSString *key = [self createKeyForDesktop:desktop];
	if ([imageCache objectForKey:key]) {
		return [imageCache objectForKey:key];
	}

	UIImage *img = [self renderPreviewForDesktop:desktop];
	if (img) {
		[imageCache setObject:img forKey:key];
	}
	return img;
}

- (void)forceReloadSnapshotOfDesktop:(RADesktopWindow *)desktop {
	[imageCache removeObjectForKey:[self createKeyForDesktop:desktop]];
}

- (UIImage *)rotateImageToMatchOrientation:(UIImage *)oldImage {
	CGFloat degrees;
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationUnknown:
		case UIInterfaceOrientationPortrait:
			degrees = 0;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			degrees = 180;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			degrees = 90;
			break;
		case UIInterfaceOrientationLandscapeRight:
			degrees = 270;
			break;
	}

	// https://stackoverflow.com/questions/20764623/rotate-newly-created-ios-image-90-degrees-prior-to-saving-as-png

	__block CGSize rotatedSize;

	ON_MAIN_THREAD(^{
		//Calculate the size of the rotated view's containing box for our drawing space
		static UIView *rotatedViewBox = [[UIView alloc] init];
		rotatedViewBox.frame = CGRectMake(0,0,oldImage.size.width, oldImage.size.height);
		CGAffineTransform t = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
		rotatedViewBox.transform = t;
		rotatedSize = rotatedViewBox.frame.size;
	});

	//CGSize rotatedSize = rotatedViewBox.frame.size;
	//CGSize rotatedSize = CGSizeApplyAffineTransform(oldImage.size, CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees)));

	//Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();

	//Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);

	//Rotate the image context
	CGContextRotateCTM(bitmap, DEGREES_TO_RADIANS(degrees));

	//Now, draw the rotated/scaled image into the context
	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

- (UIImage *)renderPreviewForDesktop:(RADesktopWindow *)desktop {
	@autoreleasepool {
		UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, 0);
		CGContextRef context = UIGraphicsGetCurrentContext();

		ON_MAIN_THREAD(^{
			//apparently SB has native caching since iOS 7
			SBWallpaperPreviewSnapshotCache *previewCache = [[%c(SBWallpaperController) sharedInstance] valueForKey:@"_previewCache"];
			UIImage *homeScreenSnapshot = [previewCache homeScreenSnapshot];
			UIImage *image = [RAResourceImageProvider imageWithImage:homeScreenSnapshot scaledToSize:[UIScreen mainScreen].bounds.size];
			CGRect imageFrame = CGRectMake(0, 0, image.size.width, image.size.height);

			//since drawInRect STILL doesnt work
			CGContextTranslateCTM(context, 0, imageFrame.size.height);
			CGContextScaleCTM(context, 1.0, -1.0);

			CGContextDrawImage(context, imageFrame, image.CGImage);

			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextTranslateCTM(context, 0, -imageFrame.size.height);
		});

		for (UIView *view in desktop.subviews) { // Application views
			if (![view isKindOfClass:[%c(RAWindowBar) class]]) {
				continue;
			}
			RAHostedAppView *hostedView = [((RAWindowBar *)view) attachedView];

			UIImage *image = [self snapshotForIdentifier:hostedView.bundleIdentifier orientation:hostedView.orientation];
			CIImage *coreImage = image.CIImage;
			if (!coreImage) {
				coreImage = [CIImage imageWithCGImage:image.CGImage];
			}
			//coreImage = [coreImage imageByApplyingTransform:view.transform];
			CGFloat rotation = atan2(hostedView.transform.b, hostedView.transform.a);

			CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
			coreImage = [coreImage imageByApplyingTransform:transform];
			image = [UIImage imageWithCIImage:coreImage];
			[image drawInRect:view.frame]; // by using frame, we take care of scale.
		}
		//if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
		//	CGContextRotateCTM(c, DEGREES_TO_RADIANS(90));
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		//image = [self rotateImageToMatchOrientation:image];
		return image;
	}
}

- (UIImage *)wallpaperImage {
	return [self wallpaperImage:YES];
}

- (UIImage *)wallpaperImage:(BOOL)blurred {
	NSString *key = blurred ? @"wallpaperImageBlurred" : @"wallpaperImage";
	if ([imageCache objectForKey:key]) {
		return [imageCache objectForKey:key];
	}
	//its really that easy elijah (ok maybe i need to resize the image);
	SBWallpaperController *wallpaperController = [%c(SBWallpaperController) sharedInstance];
	UIImage *oldImage;
	if ([wallpaperController respondsToSelector:@selector(homescreenWallpaperView)]) {
		if ([wallpaperController homescreenWallpaperView]) {
			oldImage = [wallpaperController homescreenWallpaperView].displayedImage;
		} else {
			oldImage = [wallpaperController sharedWallpaperView].displayedImage;
		}
	} else {
		if ([wallpaperController valueForKey:@"_homescreenWallpaperView"]) {
			oldImage = [[wallpaperController valueForKey:@"_homescreenWallpaperView"] wallpaperImage];
		} else {
			oldImage = [[wallpaperController valueForKey:@"_sharedWallpaperView"] wallpaperImage];
		}
	}

	UIImage *image = [RAResourceImageProvider imageWithImage:oldImage scaledToSize:[UIScreen mainScreen].bounds.size];

	if (blurred) {
		CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[gaussianBlurFilter setDefaults];
		CIImage *inputImage = [CIImage imageWithCGImage:[image CGImage]];
		[gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
		[gaussianBlurFilter setValue:@25 forKey:kCIInputRadiusKey];

		CIImage *outputImage = [gaussianBlurFilter outputImage];
		outputImage = [outputImage imageByCroppingToRect:CGRectMake(0, 0, image.size.width * [UIScreen mainScreen].scale, image.size.height * [UIScreen mainScreen].scale)];
		CIContext *context = [CIContext contextWithOptions:nil];
		CGImageRef cgimg = [context createCGImage:outputImage fromRect:[inputImage extent]];  // note, use input image extent if you want it the same size, the output image extent is larger
		image = [UIImage imageWithCGImage:cgimg];
		CGImageRelease(cgimg);
	}

	[imageCache setObject:image forKey:key];

	return image;
}

- (void)forceReloadEverything {
	[imageCache removeAllObjects];
}
@end
