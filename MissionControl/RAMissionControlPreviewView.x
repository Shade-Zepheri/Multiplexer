#import "RAMissionControlPreviewView.h"
#import "RASnapshotProvider.h"
#import "RADesktopWindow.h"

@implementation RAMissionControlPreviewView
- (void)generatePreview {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    //self.image = [[%c(RASnapshotProvider) sharedInstance] snapshotForIdentifier:self.application.bundleIdentifier];
    UIImage *img = [[RASnapshotProvider sharedInstance] snapshotForIdentifier:self.application.bundleIdentifier];
    self.image = img;
  });
  //if (!icon)
  //  icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:self.application.bundleIdentifier];
  //if (icon && !iconView)
  //    iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];

  NSOperationQueue *targetQueue = [NSOperationQueue mainQueue];
  [targetQueue addOperationWithBlock:^{
    SBIconModel *iconModel = [[%c(SBIconController) sharedInstance] valueForKey:@"_iconModel"];
    if (!icon) {
      SBApplicationIcon *icon = [iconModel applicationIconForBundleIdentifier:app.bundleIdentifier];
    }
    
    if (icon && !iconView) {
      if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
  			iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
  		} else {
  			iconView = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] _iconViewForIcon:icon];
  		}
    }
  }];
  [targetQueue waitUntilAllOperationsAreFinished];

  iconView.layer.shadowRadius = THEMED(missionControlIconPreviewShadowRadius); // iconView.layer.cornerRadius;
  iconView.layer.shadowOpacity = 0.8;
  iconView.layer.shadowOffset = CGSizeMake(0, 0);
  //iconView.layer.shouldRasterize = YES;
  //iconView.layer.rasterizationScale = UIScreen.mainScreen.scale;
  iconView.userInteractionEnabled = NO;
  iconView.iconLabelAlpha = 0;
  CGFloat scale = (iconView.frame.size.width - 3.0) / iconView.frame.size.width;
  iconView.transform = CGAffineTransformMakeScale(scale, scale);

  dispatch_async(dispatch_get_main_queue(), ^{
    [self addSubview:iconView];
    [self updateIconViewFrame];
  });
}

- (void)generatePreviewAsync {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self generatePreview];
  });
}

- (void)generateDesktopPreviewAsync:(id)desktop_ completion:(dispatch_block_t)completionBlock {
  RADesktopWindow *desktop = (RADesktopWindow *)desktop_;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    UIImage *image = [[RASnapshotProvider sharedInstance] snapshotForDesktop:desktop];

    dispatch_async(dispatch_get_main_queue(), ^{ //Potential problem here
      self.image = image;
    });

    if (completionBlock) {
      completionBlock();
    }
  });
}

- (void)updateIconViewFrame {
  if (!iconView) {
    return;
  }

  [self bringSubviewToFront:iconView];
  iconView.frame = CGRectMake( (self.frame.size.width / 2) - (iconView.frame.size.width / 2), (self.frame.size.height / 2) - (iconView.frame.size.height / 2), iconView.frame.size.width, iconView.frame.size.height );
}
@end
