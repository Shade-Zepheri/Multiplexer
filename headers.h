#import <AssertionServices/BKSProcessAssertion.h>
#import <BulletinBoard/BBBulletinRequest.h>
#include <dlfcn.h>
#include <execinfo.h>
#import <FrontBoard/FBApplicationProcess.h>
#import <FrontBoard/FBDisplayManager.h>
#import <FrontBoard/FBProcess.h>
#import <FrontBoard/FBProcessManager.h>
#import <FrontBoard/FBProcessState.h>
#import <FrontBoard/FBScene.h>
#import <FrontBoard/FBSceneManager.h>
#import <FrontBoard/FBWorkspaceEvent.h>
#import <FrontBoardServices/FBSDisplay.h>
#import <FrontBoardServices/FBSMutableSceneSettings.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <GraphicsServices/GraphicsServices.h>
#import <IOKit/hid/IOHIDEvent.h>
#include <libkern/OSCacheControl.h>
#include <mach/mach.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <notify.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBAppSwitcherController.h>
#import <SpringBoard/SBAppSwitcherModel.h>
#import <SpringBoard/SBAppToAppWorkspaceTransaction.h>
#import <SpringBoard/SBBulletinBannerController.h>
#import <SpringBoard/SBControlCenterController.h>
#import <SpringBoard/SBDisplayItem.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBIconLabel.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIconViewMap.h>
#import <SpringBoard/SBNotificationCenterController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <SpringBoard/SBScreenEdgePanGestureRecognizer.h>
#import <SpringBoard/SBMainDisplaySystemGestureManager.h>
#import <SpringBoard/SBMainSwitcherGestureCoordinator.h>
#import <SpringBoard/SBMainWorkspace.h>
#import <SpringBoard/SBMainWorkspaceTransitionRequest.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBWallpaperController.h>
#import <SpringBoard/SBWallpaperPreviewSnapshotCache.h>
#import <SpringBoard/SBWorkspaceApplicationTransitionContext.h>
#import <SpringBoard/SBWorkspaceDeactivatingEntity.h>
#import <SpringBoard/SBWorkspaceHomeScreenEntity.h>
#import <SpringBoardServices/SBSRestartRenderServerAction.h>
#import <QuartzCore/QuartzCore.h>
#include <stdbool.h>
#import <substrate.h>
#include <sys/sysctl.h>
#import <UIKit/_UIBackdropViewSettings.h>
#import <UIKit/_UIBackdropView.h>
#import <UIKit/UIKit.h>
#import <version.h>

static NSString *const MultiplexerBasePath = @"/Library/Multiplexer";

#import "RALocalizer.h"
#define LOCALIZE(key, local) [[objc_getClass("RALocalizer") sharedInstance] localizedStringForKey:key table:local]

#import "RAThemeManager.h"
// Note that "x" expands into the passed variable
#define THEMED(x) [[objc_getClass("RAThemeManager") sharedInstance] currentTheme].x

#import "RASBWorkspaceFetcher.h"
#define GET_SBWORKSPACE [RASBWorkspaceFetcher getCurrentSBWorkspaceImplementationInstanceForThisOS]

#define GET_STATUSBAR_ORIENTATION ![UIApplication sharedApplication]._accessibilityFrontMostApplication ? [UIApplication sharedApplication].statusBarOrientation : [UIApplication sharedApplication]._accessibilityFrontMostApplication.statusBarOrientation

#if DEBUG
#define LogDebug HBLogDebug
#define LogInfo HBLogInfo
#define LogWarn HBLogWarn
#define LogError HBLogError
#else
#define LogDebug(...)
#define LogInfo(...)
#define LogWarn(...)
#define LogError(...)
#endif

#if MULTIPLEXER_CORE
extern BOOL $__IS_SPRINGBOARD;
#define IS_SPRINGBOARD $__IS_SPRINGBOARD
#else
#define IS_SPRINGBOARD IN_SPRINGBOARD
#endif

#define ON_MAIN_THREAD(block) \
    { \
      if ([NSThread isMainThread]) { \
        block(); \
      } else { \
        dispatch_sync(dispatch_get_main_queue(), block); \
      } \
    }

#define IF_SPRINGBOARD if (IS_SPRINGBOARD)
#define IF_NOT_SPRINGBOARD if (!IS_SPRINGBOARD)
#define IF_THIS_PROCESS(x) if ([[x objectForKey:@"bundleIdentifier"] isEqualToString:[NSBundle mainBundle].bundleIdentifier])

#ifdef __cplusplus
extern "C" {
#endif

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
void BKSHIDServicesCancelTouchesOnMainDisplay();
void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *app, int reasonID, BOOL report, NSString *description);

#ifdef __cplusplus
}
#endif

#define RADIANS_TO_DEGREES(radians) (radians * 180.0 / M_PI)
#define DEGREES_TO_RADIANS(degrees) (degrees * M_PI / 180)

//void SET_BACKGROUNDED(id settings, BOOL val);

#define SHARED_INSTANCE2(cls, extracode) \
static cls *sharedInstance = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
    sharedInstance = [[cls alloc] init]; \
    extracode; \
}); \
return sharedInstance;

#define SHARED_INSTANCE(cls) SHARED_INSTANCE2(cls, );

////////////////////////////////////////////////////////////////////////////////////////////////

@interface UIRemoteKeyboardWindow : UIWindow //UITextEffectsWindow
+ (instancetype)remoteKeyboardWindowForScreen:(id)arg1 create:(BOOL)arg2;
@end

@interface SBIconImageView : UIView {
    UIImageView *_overlayView;
    //SBIconProgressView *_progressView;
    BOOL _isPaused;
    UIImage *_cachedSquareContentsImage;
    BOOL _showsSquareCorners;
    SBIcon *_icon;
    CGFloat _brightness;
    CGFloat _overlayAlpha;
}

+ (id)dequeueRecycledIconImageViewOfClass:(Class)arg1;
+ (void)recycleIconImageView:(id)arg1;
+ (CGFloat)cornerRadius;
@property(nonatomic) BOOL showsSquareCorners; // @synthesize showsSquareCorners=_showsSquareCorners;
@property(nonatomic) CGFloat overlayAlpha; // @synthesize overlayAlpha=_overlayAlpha;
@property(nonatomic) CGFloat brightness; // @synthesize brightness=_brightness;
@property(retain, nonatomic) SBIcon *icon; // @synthesize icon=_icon;
- (BOOL)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)iconImageDidUpdate:(id)arg1;
- (CGRect)visibleBounds;
- (CGSize)sizeThatFits:(CGSize)arg1;
- (id)squareDarkeningOverlayImage;
- (id)darkeningOverlayImage;
- (id)squareContentsImage;
- (UIImage*)contentsImage;
- (void)_clearCachedImages;
- (id)_generateSquareContentsImage;
- (void)_updateProgressMask;
- (void)_updateOverlayImage;
- (id)_currentOverlayImage;
- (void)updateImageAnimated:(BOOL)arg1;
- (id)snapshot;
- (void)prepareForReuse;
- (void)layoutSubviews;
- (void)setPaused:(BOOL)arg1;
- (void)setProgressAlpha:(CGFloat)arg1;
- (void)_clearProgressView;
- (void)progressViewCanBeRemoved:(id)arg1;
- (void)setProgressState:(NSInteger)arg1 paused:(BOOL)arg2 percent:(CGFloat)arg3 animated:(BOOL)arg4;
- (void)_updateOverlayAlpha;
- (void)setIcon:(id)arg1 animated:(BOOL)arg2;
- (void)dealloc;
- (instancetype)initWithFrame:(CGRect)arg1;
@end

@interface SBFWallpaperView : UIView
@property (nonatomic,readonly) UIImage *wallpaperImage;
- (void)setGeneratesBlurredImages:(BOOL)arg1;
- (void)_startGeneratingBlurredImages;
- (void)prepareToAppear;
@end

@interface SBFStaticWallpaperView : SBFWallpaperView
@property (setter=_setDisplayedImage:,getter=_displayedImage,nonatomic,retain) UIImage *displayedImage;
- (UIImage*)_displayedImage;
- (void)_setDisplayedImage:(UIImage*)arg1;
@end

@class _SBAppSwitcherSnapshotContext;

@interface SBAppSwitcherSnapshotView : UIView
@property (nonatomic,copy,readonly) SBDisplayItem *displayItem;
@property (assign,nonatomic) BOOL shouldTransitionToDefaultPng;
+ (instancetype)appSwitcherSnapshotViewForDisplayItem:(id)arg1 orientation:(NSInteger)arg2 preferringDownscaledSnapshot:(BOOL)arg3 loadAsync:(BOOL)arg4 withQueue:(id)arg5 ;
- (void)setOrientation:(NSInteger)arg1 orientationBehavior:(int)arg2;
- (void)_loadSnapshotAsync;
- (void)_loadZoomUpSnapshotSync;
- (void)_loadSnapshotSync;
- (UIImage*)_syncImageFromSnapshot:(id)arg1 ;
- (instancetype)initWithDisplayItem:(id)arg1 application:(id)arg2 orientation:(NSInteger)arg3 preferringDownscaledSnapshot:(BOOL)arg4 async:(BOOL)arg5 withQueue:(id)arg6;
- (_SBAppSwitcherSnapshotContext*)_contextForAvailableSnapshotWithLayoutState:(id)arg1 preferringDownscaled:(BOOL)arg2 defaultImageOnly:(BOOL)arg3 ;
@end

@interface _SBFVibrantSettings : NSObject {
    int _style;
    UIColor *_referenceColor;
    id _legibilitySettings; // _UILegibilitySettings *_legibilitySettings;
    float _referenceContrast;
    UIColor *_tintColor;
    UIColor *_shimmerColor;
    UIColor *_chevronShimmerColor;
    UIColor *_highlightColor;
    UIColor *_highlightLimitingColor;
}

+ (id)vibrantSettingsWithReferenceColor:(id)arg1 referenceContrast:(float)arg2 legibilitySettings:(id)arg3;
@property(retain, nonatomic) UIColor *highlightLimitingColor; // @synthesize highlightLimitingColor=_highlightLimitingColor;
@property(retain, nonatomic) UIColor *highlightColor; // @synthesize highlightColor=_highlightColor;
@property(retain, nonatomic) UIColor *chevronShimmerColor; // @synthesize chevronShimmerColor=_chevronShimmerColor;
@property(retain, nonatomic) UIColor *shimmerColor; // @synthesize shimmerColor=_shimmerColor;
@property(retain, nonatomic) UIColor *tintColor; // @synthesize tintColor=_tintColor;
@property(readonly, nonatomic) float referenceContrast; // @synthesize referenceContrast=_referenceContrast;
//@property(readonly, nonatomic) _UILegibilitySettings *legibilitySettings; // @synthesize legibilitySettings=_legibilitySettings;
@property(readonly, nonatomic) UIColor *referenceColor; // @synthesize referenceColor=_referenceColor;
@property(readonly, nonatomic) int style; // @synthesize style=_style;
- (id)highlightLimitingViewWithFrame:(CGRect)arg1;
- (id)tintViewWithFrame:(CGRect)arg1;
- (id)_computeSourceColorDodgeColorForDestinationColor:(id)arg1 producingLuminanceChange:(float)arg2;
- (int)_style;
- (unsigned int)hash;
- (BOOL)isEqual:(id)arg1;
- (void)dealloc;
- (instancetype)initWithReferenceColor:(id)arg1 referenceContrast:(float)arg2 legibilitySettings:(id)arg3;

@end

typedef struct {
    BOOL itemIsEnabled[34];
    char timeString[64];
    int gsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    char serviceString[100];
    char serviceCrossfadeString[100];
    char serviceImages[2][100];
    char operatorDirectory[1024];
    unsigned serviceContentType;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned dataNetworkType;
    int batteryCapacity;
    unsigned batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned thermalSunlightMode : 1;
    unsigned slowActivity : 1;
    unsigned syncActivity : 1;
    char activityDisplayId[256];
    unsigned bluetoothConnected : 1;
    unsigned displayRawGSMSignal : 1;
    unsigned displayRawWifiSignal : 1;
    unsigned locationIconType : 1;
    unsigned quietModeInactive : 1;
    unsigned tetheringConnectionCount;
    unsigned batterySaverModeActive : 1;
    unsigned deviceIsRTL : 1;
    unsigned lock : 1;
    char breadcrumbTitle[256];
    char breadcrumbSecondaryTitle[256];
    char personName[100];
    char returnToAppBundleIdentifier[100];
    unsigned electronicTollCollectionAvailable : 1;
    unsigned wifiLinkWarning : 1;
} StatusBarData;

@interface UIStatusBar : UIView
+ (CGFloat)heightForStyle:(int)arg1 orientation:(int)arg2;
- (void)setOrientation:(int)arg1;
- (void)requestStyle:(int)arg1;
- (void)forceUpdateToData:(StatusBarData *)arg1 animated:(BOOL)arg2;
@end

@interface UIStatusBarServer
+ (StatusBarData *)getStatusBarData;
@end

@interface SBModeViewController : UIViewController {
    UIView* _headerView;
}
- (void)_addBulletinObserverViewController:(id)controller;
- (void)addViewController:(id)controller;
@end

@interface SBNCColumnViewController : UIViewController

@end

@interface SBNotificationCenterLayoutViewController : UIViewController
@property (nonatomic,retain,readonly) SBModeViewController * modeViewController;
@end

@interface SBNotificationCenterViewController : UIViewController {
    UIView *_clippingView;
    UIView *_containerView;
    UIView *_contentClippingView;
    UIView *_contentView;
    UIView *_backgroundView;
    UIView *_tintView;
}
@property (nonatomic,readonly) UIPageControl * pageControl;
@property (nonatomic,readonly) CGRect contentFrame;
- (CGRect)_containerFrame;
- (void)_setContainerFrame:(CGRect)arg1 ;
- (void)prepareLayoutForDefaultPresentation;
- (void)_loadContainerView;
- (void)_loadContentView;
@end

@interface SBSearchEtceteraLayoutContentView : UIView
@end

@interface SBNotificationCenterController ()
- (BOOL) isVisible;
- (CGFloat)percentComplete;
- (BOOL)isTransitioning;
- (BOOL)isPresentingControllerTransitioning;
@end

@interface UIScreen (ohBoy)
- (CGRect)_gkBounds;
- (CGRect) _referenceBounds;
- (CGPoint)convertPoint:(CGPoint)arg1 toCoordinateSpace:(id)arg2;
+ (CGPoint)convertPoint:(CGPoint)arg1 toView:(id)arg2;
@end

@interface UIAutoRotatingWindow : UIWindow
- (instancetype)_initWithFrame:(CGRect)arg1 attached:(BOOL)arg2;
- (void)updateForOrientation:(UIInterfaceOrientation)arg1;
@end

@interface LSApplicationProxy ()
@property (nonatomic, readonly) NSURL *bundleURL;
@property (nonatomic, readonly) NSArray *UIBackgroundModes;
@end

@interface UIViewController ()
- (void)setInterfaceOrientation:(UIInterfaceOrientation)arg1;
- (void)_setInterfaceOrientationOnModalRecursively:(int)arg1;
- (void)_updateInterfaceOrientationAnimated:(BOOL)arg1;
@end

@interface BBAction
+ (id)actionWithCallblock:(id /* block */)arg1;
+ (id)actionWithTextReplyCallblock:(id)arg1;
+ (id)actionWithLaunchBundleID:(id)arg1 callblock:(id)arg2;
+ (id)actionWithLaunchURL:(id)arg1 callblock:(id)arg2;
+ (id)actionWithCallblock:(id)arg1;
@end

typedef enum {
    NSNotificationSuspensionBehaviorDrop = 1,
    NSNotificationSuspensionBehaviorCoalesce = 2,
    NSNotificationSuspensionBehaviorHold = 3,
    NSNotificationSuspensionBehaviorDeliverImmediately = 4
} NSNotificationSuspensionBehavior;

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (instancetype)defaultCenter;
- (void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(NSString *)notificationSender suspensionBehavior:(NSNotificationSuspensionBehavior)suspendedDeliveryBehavior;
- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(NSString *)notificationSender;
- (void)postNotificationName:(NSString *)notificationName object:(NSString *)notificationSender userInfo:(NSDictionary *)userInfo deliverImmediately:(BOOL)deliverImmediately;
@end

@interface SBLockStateAggregator
- (void) _updateLockState;
- (BOOL) hasAnyLockState;
@end

@interface BBBulletinRequest ()

@property(copy) BBAction * acknowledgeAction;
@property(copy) BBAction * replyAction;

@property(retain) NSDate * expirationDate;
@end

@interface SBAppSwitcherWindow : UIWindow
@end

@interface SBChevronView : UIView
@property(retain, nonatomic) _SBFVibrantSettings *vibrantSettings;
- (void) setState:(int)state animated:(BOOL)animated;
- (void)setBackgroundView:(id)arg1;
@property(retain, nonatomic) UIColor *color;
@end

@interface SBControlCenterGrabberView : UIView
- (SBChevronView*) chevronView;
- (void)_setStatusState:(int)arg1;
@end

@interface SBAppSwitcherController ()
- (void)forceDismissAnimated:(BOOL)arg1;
- (void)animateDismissalToDisplayLayout:(id)arg1 withCompletion:(id/*block*/)arg2;
- (void)animatePresentationFromDisplayLayout:(id)arg1 withViews:(id)arg2 withCompletion:(id/*block*/)arg3;
@property(nonatomic, copy) NSObject *startingDisplayLayout; // @synthesize startingDisplayLayout=_startingDisplayLayout;
- (void)switcherWasPresented:(BOOL)arg1;
@end

@interface SBUIController ()
+ (id)_zoomViewWithSplashboardLaunchImageForApplication:(id)arg1 sceneID:(id)arg2 screen:(id)arg3 interfaceOrientation:(NSInteger)arg4 includeStatusBar:(BOOL)arg5 snapshotFrame:(CGRect *)arg6;
- (id) switcherController;
- (id)_appSwitcherController;
- (void) activateApplicationAnimated:(SBApplication*)app;
- (UIWindow *)switcherWindow;
- (void)_animateStatusBarForSuspendGesture;
- (void)_showControlCenterGestureCancelled;
- (void)_showControlCenterGestureFailed;
- (void)_hideControlCenterGrabber;
- (void)_showControlCenterGestureEndedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2;
- (void)_showControlCenterGestureChangedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2 duration:(CGFloat)arg3;
- (void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1;
- (void)restoreContentUpdatingStatusBar:(BOOL)arg1;
- (void) restoreContentAndUnscatterIconsAnimated:(BOOL)arg1;
- (BOOL)shouldShowControlCenterTabControlOnFirstSwipe;- (BOOL)isAppSwitcherShowing;
- (BOOL) _activateAppSwitcher;
- (void)_releaseTransitionOrientationLock;
- (void)_releaseSystemGestureOrientationLock;
- (void)releaseSwitcherOrientationLock;
- (void)_lockOrientationForSwitcher;
- (void)_lockOrientationForSystemGesture;
- (void)_lockOrientationForTransition;
- (void)_dismissSwitcherAnimated:(BOOL)arg1;
- (void)dismissSwitcherAnimated:(BOOL)arg1;
- (void)_dismissAppSwitcherImmediately;
- (void)dismissSwitcherForAlert:(id)arg1;

- (UIView *)contentView;
- (void)activateApplication:(id)arg1;
@end

@protocol SBSystemGestureRecognizerDelegate <UIGestureRecognizerDelegate>
@required
- (id)viewForSystemGestureRecognizer:(id)arg1;
@end

@interface SBSystemGestureManager ()
@property (assign ,getter=areSystemGesturesDisabledForAccessibility, nonatomic) BOOL systemGesturesDisabledForAccessibility;
@end

@interface SBHomeScreenViewController : UIViewController
@end

@interface SBHomeScreenWindow : UIWindow
@property (nonatomic, weak,readonly) SBHomeScreenViewController *homeScreenViewController;
@end

@interface BKSWorkspace : NSObject
- (NSString *)topActivatingApplication;
@end

@interface SpringBoard (OrientationSupport)
- (UIInterfaceOrientation)activeInterfaceOrientation;
- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation;
@end

typedef NS_ENUM(NSInteger, UIScreenEdgePanRecognizerType) {
    UIScreenEdgePanRecognizerTypeMultitasking,
    UIScreenEdgePanRecognizerTypeNavigation,
    UIScreenEdgePanRecognizerTypeOther
};

@protocol _UIScreenEdgePanRecognizerDelegate;

@interface _UIScreenEdgePanRecognizer : NSObject
- (instancetype)initWithType:(UIScreenEdgePanRecognizerType)type;
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(CGFloat)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(CGFloat)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation forceState:(int)arg5;
- (void)reset;
@property (nonatomic, assign) id <_UIScreenEdgePanRecognizerDelegate> delegate;
@property (nonatomic, readonly) NSInteger state;
@property (nonatomic) UIRectEdge targetEdges;
@property (nonatomic) CGRect screenBounds;
@property (nonatomic,readonly) CGPoint _lastTouchLocation;
@end

@protocol _UIScreenEdgePanRecognizerDelegate <NSObject>
@optional
- (void)screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer *)screenEdgePanRecognizer;
@end

@interface UIDevice (UIDevicePrivate)
- (void)setOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;
@end

@interface _UIBackdropView ()
@property (assign,nonatomic) CGFloat _blurRadius;
- (void)_setCornerRadius:(CGFloat)radius;
- (void)_applyCornerRadiusToSubviews;
@end

@interface UIKeyboardImpl
+ (id)activeInstance;
+ (instancetype)sharedInstance;
- (void)handleKeyEvent:(id)arg1;
- (void)handleKeyWithString:(id)arg1 forKeyEvent:(id)arg2 executionContext:(id)arg3;
- (void)deleteBackward;
- (void) setInHardwareKeyboardMode:(BOOL)arg1;
@end

@interface UIPhysicalKeyboardEvent
+ (id)_eventWithInput:(id)arg1 inputFlags:(int)arg2;
@property(retain, nonatomic) NSString *_privateInput; // @synthesize _privateInput;
@property(nonatomic) int _inputFlags; // @synthesize _inputFlags;
@property(nonatomic) int _modifierFlags; // @synthesize _modifierFlags;
@property(retain, nonatomic) NSString *_markedInput; // @synthesize _markedInput;
@property(retain, nonatomic) NSString *_commandModifiedInput; // @synthesize _commandModifiedInput;
@property(retain, nonatomic) NSString *_shiftModifiedInput; // @synthesize _shiftModifiedInput;
@property(retain, nonatomic) NSString *_unmodifiedInput; // @synthesize _unmodifiedInput;
@property(retain, nonatomic) NSString *_modifiedInput; // @synthesize _modifiedInput;
@property(readonly, nonatomic) int _gsModifierFlags;
- (void)_privatizeInput;
- (void)dealloc;
- (id)_cloneEvent;
- (BOOL)isEqual:(id)arg1;
- (BOOL)_matchesKeyCommand:(id)arg1;
@property(readonly, nonatomic) long _keyCode;
@property(readonly, nonatomic) BOOL _isKeyDown;
- (int)type;
@end

@interface FBWorkspaceEventQueue : NSObject
+ (instancetype)sharedInstance;
- (void)executeOrAppendEvent:(FBWorkspaceEvent *)event;
@end

@interface SBDeactivationSettings
- (instancetype)init;
- (void)setFlag:(int)flag forDeactivationSetting:(unsigned)deactivationSetting;
@end

@interface SBMainWorkspace ()
- (BOOL)isUsingReachApp;
- (void)_exitReachabilityModeWithCompletion:(id)arg1;
- (void)_disableReachabilityImmediately:(BOOL)arg1;
- (void)handleReachabilityModeDeactivated;
- (void)RA_animateWidgetSelectorOut:(id)completion;
- (void)RA_setView:(UIView*)view preferredHeight:(CGFloat)preferredHeight;
- (void)RA_launchTopAppWithIdentifier:(NSString*) bundleIdentifier;
- (void)RA_showWidgetSelector;
- (void)updateViewSizes:(CGPoint)center animate:(BOOL)animate;
- (void)RA_closeCurrentView;
- (void)RA_handleLongPress:(UILongPressGestureRecognizer*)gesture;
- (void)RA_updateViewSizes;
- (void)appViewItemTap:(id)sender;
@end

@interface UIGestureRecognizerTarget : NSObject {
  id _target;
}
@end

@interface FBWindowContextHostManager : NSObject
- (UIView *)hostViewForRequester:(NSString *)arg1 appearanceStyle:(NSUInteger)style;
- (UIView *)hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (void)resumeContextHosting;
- (UIView *)_hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (id)snapshotViewWithFrame:(CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3;
- (id)snapshotUIImageForFrame:(CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3 outTransform:(struct CGAffineTransform *)arg4;
- (id)visibleContexts;
- (void)orderRequesterFront:(id)arg1;
- (void)enableHostingForRequester:(id)arg1 orderFront:(BOOL)arg2;
- (void)enableHostingForRequester:(id)arg1 priority:(int)arg2;
- (void)disableHostingForRequester:(id)arg1;
- (void)_updateHostViewFrameForRequester:(id)arg1;
- (void)invalidate;

@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_identifier;
@end

@interface FBSSceneSnapshotContext : NSObject
@property (nonatomic,copy) FBSSceneSettings *settings;
@property (nonatomic,copy,readonly) NSString *sceneID;
@property (nonatomic,copy) NSString *name;
@property (assign,nonatomic) CGRect frame;
@property (assign,nonatomic) CGFloat scale;
@property (nonatomic,copy) NSSet *layersToExclude;
@property (assign,nonatomic) CGFloat expirationInterval;
@end

@interface UIMutableApplicationSceneSettings : FBSMutableSceneSettings
@end

@interface SBApplication ()
@property (nonatomic,copy) NSString * mainSceneID;
@property (setter=_setDeactivationSettings:, nonatomic, copy) SBDeactivationSettings * _deactivationSettings;

- (id)mainScreenContextHostManager;
- (void)activate;

- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(BOOL)arg1;
- (void)notifyResumeActiveForReason:(NSInteger)arg1;

- (BOOL)_isRecentlyUpdated;
- (BOOL)_isNewlyInstalled;
- (UIInterfaceOrientation)statusBarOrientation;

@end

@interface SBApplicationController ()

- (NSArray *)runningApplications;

@end

@interface FBWindowContextHostWrapperView : UIView
@property(readonly, nonatomic) FBWindowContextHostManager *manager; // @synthesize manager=_manager;
@property(nonatomic) unsigned int appearanceStyle; // @synthesize appearanceStyle=_appearanceStyle;
- (void)_setAppearanceStyle:(unsigned int)arg1 force:(BOOL)arg2;
- (id)_stringForAppearanceStyle;
- (id)window;
@property(readonly, nonatomic) CGRect referenceFrame; // @dynamic referenceFrame;
@property(readonly, nonatomic, getter=isContextHosted) BOOL contextHosted; // @dynamic contextHosted;
- (void)clearManager;
- (void)_hostingStatusChanged;
- (BOOL)_isReallyHosting;
- (void)updateFrame;

@property(retain, nonatomic) UIColor *backgroundColorWhileNotHosting;
@property(retain, nonatomic) UIColor *backgroundColorWhileHosting;
@end
@interface FBWindowContextHostView : UIView
@end

@interface UIKeyboard : UIView
+ (BOOL)isOnScreen;
+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (CGRect)defaultFrameForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (id)activeKeyboard;

- (BOOL)isMinimized;
- (void)minimize;
@end

@interface SBReachabilityManager
+ (instancetype)sharedInstance;
@property(readonly, nonatomic) BOOL reachabilityModeActive; // @synthesize reachabilityModeActive=_reachabilityModeActive;
- (void)_handleReachabilityDeactivated;
- (void)_handleReachabilityActivated;
@end

@interface UIImage ()
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

@interface UITextEffectsWindow : UIWindow
+ (instancetype)sharedTextEffectsWindow;
- (unsigned int)contextID;
@end

@interface UIWindow ()
+ (UIWindow *)keyWindow;
- (id) firstResponder;
+ (void)setAllWindowsKeepContextInBackground:(BOOL)arg1;
- (void) _setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(CGFloat)duration force:(BOOL)force;
- (void)_setRotatableViewOrientation:(UIInterfaceOrientation)arg1 updateStatusBar:(BOOL)arg2 duration:(CGFloat)arg3 force:(BOOL)arg4;
- (void)_rotateWindowToOrientation:(UIInterfaceOrientation)arg1 updateStatusBar:(BOOL)arg2 duration:(CGFloat)arg3 skipCallbacks:(BOOL)arg4;
- (unsigned int)_contextId;
- (UIInterfaceOrientation) _windowInterfaceOrientation;
@end

@interface UIApplication ()
@property (nonatomic) BOOL RA_networkActivity;
@property (nonatomic, retain, readonly) SBApplication *_accessibilityFrontMostApplication;
- (void)_handleKeyUIEvent:(id)arg1;
- (UIStatusBar*) statusBar;
- (id)_mainScene;
- (BOOL)_isSupportedOrientation:(int)arg1;

// SpringBoard methods
- (void)setWantsOrientationEvents:(BOOL)events;

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3;

- (void) RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting;
- (void) RA_forceStatusBarVisibility:(BOOL)visible orRevert:(BOOL)revert;
- (void) RA_updateWindowsForSizeChange:(CGSize)size isReverting:(BOOL)revert;

- (void)applicationDidResume;
- (void)_sendWillEnterForegroundCallbacks;
- (void)suspend;
- (void)applicationWillSuspend;
- (void)_setSuspended:(BOOL)arg1;
- (void)applicationSuspend;
- (void)_deactivateForReason:(int)arg1 notify:(BOOL)arg2;
@end

@interface SBIconLabelView : UIView
@end

@interface SBIcon (iOS81)
- (BOOL) isBeta;
- (BOOL)isApplicationIcon;
@end

@interface SBIconModel (iOS81)
- (NSArray *)visibleIconIdentifiers;
- (id)applicationIconForBundleIdentifier:(id)arg1;
@end

@interface SBIconModel (iOS40)
- (/*SBApplicationIcon*/SBIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBIcon (iOS40)
- (void)prepareDropGlow;
- (UIImageView *)dropGlow;
- (void)showDropGlow:(BOOL)showDropGlow;
- (NSInteger)badgeValue;
- (id)leafIdentifier;
- (SBApplication*)application;
- (NSString*)applicationBundleID;
@end

@protocol SBIconViewDelegate, SBIconViewLocker;
@class SBIconImageContainerView, SBIconBadgeImage;

@interface SBIconAccessoryImage : UIImage
- (instancetype)initWithImage:(id)arg1 ;
@end

@interface SBDarkeningImageView : UIImageView
- (void)setImage:(id)arg1 brightness:(CGFloat)arg2;
- (void)setImage:(id)arg1;
@end

@interface SBIconBadgeView : UIView
{
    NSString *_text;
    BOOL _animating;
    id/*block*/ _queuedAnimation;
    BOOL _displayingAccessory;
    SBIconAccessoryImage *_backgroundImage;
    SBDarkeningImageView *_backgroundView;
    SBDarkeningImageView *_textView;
}

+ (id)_createImageForText:(id)arg1 highlighted:(BOOL)arg2;
+ (id)_checkoutImageForText:(id)arg1 highlighted:(BOOL)arg2;
+ (id)_checkoutBackgroundImage;
+ (id)checkoutAccessoryImagesForIcon:(id)arg1 location:(int)arg2;
+ (struct CGPoint)_overhang;
+ (CGFloat)_textPadding;
+ (struct CGPoint)_textOffset;
+ (CGFloat)_maxTextWidth;
+ (id)_textFont;
- (void)_resizeForTextImage:(id)arg1;
- (void)_clearText;
- (void)_zoomOutWithPreparation:(id/*block*/)arg1 animation:(id/*block*/)arg2 completion:(id/*block*/)arg3;
- (void)_zoomInWithTextImage:(id)arg1 preparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_crossfadeToTextImage:(id)arg1 withPreparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)setAccessoryBrightness:(CGFloat)arg1;
- (struct CGPoint)accessoryOriginForIconBounds:(CGRect)arg1;
- (void)prepareForReuse;
- (BOOL)displayingAccessory;
- (void)configureForIcon:(id)arg1 location:(int)arg2 highlighted:(BOOL)arg3;
- (void)configureAnimatedForIcon:(id)arg1 location:(int)arg2 highlighted:(BOOL)arg3 withPreparation:(id/*block*/)arg4 animation:(id/*block*/)arg5 completion:(id/*block*/)arg6;
- (void)layoutSubviews;
- (void)dealloc;
- (instancetype)init;
@end

@interface SBIconParallaxBadgeView : SBIconBadgeView
- (void)_applyParallaxSettings;
- (void)settings:(id)arg1 changedValueForKey:(id)arg2;
@end

@interface SBIconView : UIView {
  SBIcon *_icon;
  id<SBIconViewDelegate> _delegate;
  id<SBIconViewLocker> _locker;
  SBIconImageContainerView *_iconImageContainer;
  SBIconImageView *_iconImageView;
  UIImageView *_iconDarkeningOverlay;
  UIImageView *_ghostlyImageView;
  UIImageView *_reflection;
  UIImageView *_shadow;
  SBIconBadgeImage *_badgeImage;
  UIImageView *_badgeView;
  SBIconLabel *_label;
  BOOL _labelHidden;
  BOOL _labelOnWallpaper;
  UIView *_closeBox;
  int _closeBoxType;
  UIImageView *_dropGlow;
  unsigned _drawsLabel : 1;
  unsigned _isHidden : 1;
  unsigned _isGrabbed : 1;
  unsigned _isOverlapping : 1;
  unsigned _refusesRecipientStatus : 1;
  unsigned _highlighted : 1;
  unsigned _launchDisabled : 1;
  unsigned _isJittering : 1;
  unsigned _allowJitter : 1;
  unsigned _touchDownInIcon : 1;
  unsigned _hideShadow : 1;
  NSTimer *_delayedUnhighlightTimer;
  unsigned _onWallpaper : 1;
  unsigned _ghostlyRequesters;
  int _iconLocation;
  float _iconImageAlpha;
  float _iconImageBrightness;
  float _iconLabelAlpha;
  float _accessoryAlpha;
  CGPoint _unjitterPoint;
  CGPoint _grabPoint;
  NSTimer *_longPressTimer;
  unsigned _ghostlyTag;
  UIImage *_ghostlyImage;
  BOOL _ghostlyPending;
  }

@property (assign, nonatomic) BOOL RA_isIconIndicatorInhibited;

/*
- (void)RA_updateIndicatorView:(NSInteger)info;
- (void)RA_updateIndicatorViewWithExistingInfo;
- (void)RA_setIsIconIndicatorInhibited:(BOOL)value;
- (void)RA_setIsIconIndicatorInhibited:(BOOL)value showAgainImmediately:(BOOL)value2;
*/

+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;
+ (BOOL)allowsRecycling;
+ (id)_jitterPositionAnimation;
+ (id)_jitterTransformAnimation;
+ (CGSize)defaultIconImageSize;
+ (CGSize)defaultIconSize;

- (instancetype)initWithDefaultSize;
- (void)dealloc;

@property(assign) id<SBIconViewDelegate> delegate;
@property (nonatomic) BOOL RA_networkActivity;
@property(assign) id<SBIconViewLocker> locker;
@property(readonly, retain) SBIcon *icon;
- (void)setIcon:(SBIcon *)icon;

- (int)location;
- (void)setLocation:(int)location;
- (void)showIconAnimationDidStop:(id)showIconAnimation didFinish:(id)finish icon:(id)icon;
- (void)setIsHidden:(BOOL)hidden animate:(BOOL)animate;
- (BOOL)isHidden;
- (BOOL)isRevealable;
- (void)positionIconImageView;
- (void)applyIconImageTransform:(CATransform3D)transform duration:(float)duration delay:(float)delay;
- (void)setDisplayedIconImage:(id)image;
- (id)snapshotSettings;
- (id)iconImageSnapshot:(id)snapshot;
- (id)reflectedIconWithBrightness:(CGFloat)brightness;
- (void)setIconImageAlpha:(CGFloat)alpha;
- (void)setIconLabelAlpha:(CGFloat)alpha;
- (SBIconImageView *)iconImageView;
- (void)setLabelHidden:(BOOL)hidden;
- (void)positionLabel;
- (CGSize)_labelSize;
- (Class)_labelClass;
- (void)updateLabel;
- (void)_updateBadgePosition;
- (id)_overriddenBadgeTextForText:(id)text;
- (void)updateBadge;
- (id)_automationID;
- (BOOL)pointMostlyInside:(CGPoint)inside withEvent:(UIEvent *)event;
- (CGRect)frameForIconOverlay;
- (void)placeIconOverlayView;
- (void)updateIconOverlayView;
- (void)_updateIconBrightness;
- (BOOL)allowsTapWhileEditing;
- (BOOL)delaysUnhighlightWhenTapped;
- (BOOL)isHighlighted;
- (void)setHighlighted:(BOOL)highlighted;
- (void)setHighlighted:(BOOL)highlighted delayUnhighlight:(BOOL)unhighlight;
- (void)_delayedUnhighlight;
- (BOOL)isInDock;
- (id)_shadowImage;
- (void)_updateShadow;
- (void)updateReflection;
- (void)setDisplaysOnWallpaper:(BOOL)wallpaper;
- (void)setLabelDisplaysOnWallpaper:(BOOL)wallpaper;
- (BOOL)showsReflection;
- (float)_reflectionImageOffset;
- (void)setFrame:(CGRect)frame;
- (void)setIsJittering:(BOOL)isJittering;
- (void)setAllowJitter:(BOOL)allowJitter;
- (BOOL)allowJitter;
- (void)removeAllIconAnimations;
- (void)setIconPosition:(CGPoint)position;
- (void)setRefusesRecipientStatus:(BOOL)status;
- (BOOL)canReceiveGrabbedIcon:(id)icon;
- (CGFloat)grabDurationForEvent:(id)event;
- (void)setIsGrabbed:(BOOL)grabbed;
- (BOOL)isGrabbed;
- (void)setIsOverlapping:(BOOL)overlapping;
- (CGAffineTransform)transformToMakeDropGlowShrinkToIconSize;
- (void)prepareDropGlow;
- (void)showDropGlow:(BOOL)glow;
- (void)removeDropGlow;
- (id)dropGlow;
- (BOOL)isShowingDropGlow;
- (void)placeGhostlyImageView;
- (id)_genGhostlyImage:(id)image;
- (void)prepareGhostlyImageIfNeeded;
- (void)prepareGhostlyImage;
- (void)prepareGhostlyImageView;
- (void)setGhostly:(BOOL)ghostly requester:(int)requester;
- (void)setPartialGhostly:(float)ghostly requester:(int)requester;
- (void)removeGhostlyImageView;
- (BOOL)isGhostly;
- (int)ghostlyRequesters;
- (void)longPressTimerFired;
- (void)cancelLongPressTimer;
- (void)touchesCancelled:(id)cancelled withEvent:(id)event;
- (void)touchesBegan:(id)began withEvent:(id)event;
- (void)touchesMoved:(id)moved withEvent:(id)event;
- (void)touchesEnded:(id)ended withEvent:(id)event;
- (BOOL)isTouchDownInIcon;
- (void)setTouchDownInIcon:(BOOL)icon;
- (void)hideCloseBoxAnimationDidStop:(id)hideCloseBoxAnimation didFinish:(id)finish closeBox:(id)box;
- (void)positionCloseBoxOfType:(int)type;
- (id)_newCloseBoxOfType:(int)type;
- (void)setShowsCloseBox:(BOOL)box;
- (void)setShowsCloseBox:(BOOL)box animated:(BOOL)animated;
- (BOOL)isShowingCloseBox;
- (void)closeBoxTapped;
- (BOOL)pointInside:(CGPoint)inside withEvent:(id)event;
- (UIEdgeInsets)snapshotEdgeInsets;
- (void)setShadowsHidden:(BOOL)hidden;
- (void)_updateShadowFrameForShadow:(id)shadow;
- (void)_updateShadowFrame;
- (BOOL)_delegatePositionIsEditable;
- (void)_delegateTouchEnded:(BOOL)ended;
- (BOOL)_delegateTapAllowed;
- (int)_delegateCloseBoxType;
- (id)createShadowImageView;
- (void)prepareForRecycling;
- (CGRect)defaultFrameForProgressBar;
- (void)iconImageDidUpdate:(id)iconImage;
- (void)iconAccessoriesDidUpdate:(id)iconAccessories;
- (void)iconLaunchEnabledDidChange:(id)iconLaunchEnabled;
- (SBIconImageView*)_iconImageView;

@end

@class NSMapTable;

@interface SBIconController (iOS90)
- (BOOL)canUninstallIcon:(SBIcon *)icon;
@end

@interface SBIconBlurryBackgroundView : UIView {
    CGRect _wallpaperRelativeBounds;
    BOOL _isBlurring;
    id _wantsBlurEvaluator;
    struct CGPoint _wallpaperRelativeCenter;
}

@property(copy, nonatomic) id wantsBlurEvaluator; // @synthesize wantsBlurEvaluator=_wantsBlurEvaluator;
@property(readonly, nonatomic) BOOL isBlurring; // @synthesize isBlurring=_isBlurring;
@property(nonatomic) struct CGPoint wallpaperRelativeCenter; // @synthesize wallpaperRelativeCenter=_wallpaperRelativeCenter;
- (BOOL)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)setBlurring:(BOOL)arg1;
- (void)setWallpaperColor:(struct CGColor *)arg1 phase:(CGSize)arg2;
- (BOOL)wantsBlur:(id)arg1;
- (CGRect)wallpaperRelativeBounds;
- (void)didAddSubview:(id)arg1;
- (void)dealloc;
- (instancetype)initWithFrame:(CGRect)arg1;
@end

@interface SBFolderIconBackgroundView : SBIconBlurryBackgroundView
- (instancetype)initWithDefaultSize;
@end

@interface BBServer
- (void)publishBulletin:(id)arg1 destinations:(NSUInteger)arg2 alwaysToLockScreen:(BOOL)arg3;
- (id)_allBulletinsForSectionID:(id)arg1;

- (id)allBulletinIDsForSectionID:(id)arg1;
- (id)noticesBulletinIDsForSectionID:(id)arg1;
- (id)bulletinIDsForSectionID:(id)arg1 inFeed:(NSUInteger)arg2;
@end

@interface SBSwitcherSnapshotImageView : UIView
@property (nonatomic,readonly) UIImage *image;
- (UIImage *)image;
@end

@interface XBApplicationSnapshot : NSObject
@end

@interface _SBAppSwitcherSnapshotContext : NSObject
@property (nonatomic,retain) XBApplicationSnapshot *snapshot;
@end

@interface SBMainSwitcherViewController : UIViewController
+ (instancetype)sharedInstance;
- (BOOL)dismissSwitcherNoninteractively;
- (BOOL)isVisible;
- (BOOL)activateSwitcherNoninteractively;
@end

@interface SBSwitcherContainerView : UIView
@property (nonatomic,retain) UIView * contentView;
- (void)layoutSubviews;
- (UIView *)contentView;
@end

@interface SBUIChevronView : UIView
@property (assign,nonatomic) NSInteger state;
@property (nonatomic,retain) UIColor * color;
- (instancetype)initWithFrame:(CGRect)arg1;
- (instancetype)initWithColor:(id)arg1 ;
- (void)setColor:(UIColor *)arg1 ;
- (void)setState:(NSInteger)arg1 animated:(BOOL)arg2;
- (void)setBackgroundView:(id)arg1;
@end

@interface FBApplicationProcess ()
- (BOOL)isApplicationProcess;
@end

@interface SBPagedScrollView : UIScrollView
@property (assign, nonatomic) NSUInteger currentPageIndex;
@property (copy, nonatomic) NSArray *pageViews;
@end

@interface SBApplicationShortcutMenuContentView : UIView
@end

@interface SBSApplicationShortcutIcon : NSObject
@end

@interface SBSApplicationShortcutSystemIcon : SBSApplicationShortcutIcon
- (instancetype)initWithType:(NSInteger)type;
@end

@interface SBSApplicationShortcutItem : NSObject
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *localizedTitle;
@property (nonatomic, copy) NSString *localizedSubtitle;
@property (nonatomic, copy) SBSApplicationShortcutIcon *icon;
@property (nonatomic, copy) NSString *bundleIdentifierToLaunch;
+ (instancetype)staticShortcutItemWithDictionary:(NSDictionary *)dictionary localizationHandler:(/*^block*/id)handler;
@end

@class SBAppView, SBAppViewController;

@protocol SBApplicationHosting <NSObject>
@required

- (SBApplication *)hostedApp;
- (BOOL)isHostingAnApp;
- (BOOL)canHostAnApp;
- (void)hostedAppWillRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

@protocol SBAppViewControllerDelegate <NSObject>
@optional

-(BOOL)appViewController:(SBAppViewController *)controller shouldTransitionToMode:(NSInteger)mode;
-(void)appViewController:(SBAppViewController *)controller didTransitionFromMode:(NSInteger)fromMode toMode:(NSInteger)toMode;
-(void)appViewControllerWillActivateApplication:(id)application;
-(void)appViewControllerDidDeactivateApplication:(id)application;

@end

@interface SBUIAppIconForceTouchController : NSObject
+ (NSArray *)filteredApplicationShortcutItemsWithStaticApplicationShortcutItems:(NSArray *)staticItems dynamicApplicationShortcutItems:(NSArray *)dynamicItems;
@end

@interface SBWorkspaceApplication : NSObject
+ (instancetype)entityForApplication:(SBApplication *)application;
@end

@interface SBAppView : UIView

- (void)setForcesStatusBarHidden:(BOOL)hidden;
- (CGSize)sizeThatFits:(CGSize)size;

@end

@interface SBAppViewController : UIViewController <SBApplicationHosting>
@property (nonatomic,copy,readonly) NSString *bundleIdentifier;
@property (assign,nonatomic) BOOL automatesLifecycle;
@property (assign,nonatomic) NSInteger requestedMode;
@property (nonatomic,readonly) NSInteger currentMode;
@property (nonatomic,readonly) SBAppView *appView;
@property (assign,nonatomic) NSUInteger options;
@property (assign,nonatomic) BOOL ignoresOcclusions;

- (instancetype)initWithIdentifier:(NSString *)identifier andApplication:(SBWorkspaceApplication *)application;

- (SBApplication *)hostedApp;
- (BOOL)isHostingAnApp;
- (BOOL)canHostAnApp;
- (void)hostedAppWillRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (void)invalidate;

@end

@interface UIViewController (BaseBoardUI)

- (BOOL)bs_addChildViewController:(UIViewController *)childController;
- (BOOL)bs_addChildViewController:(UIViewController *)childController animated:(BOOL)animated transitionBlock:(void(^)())block;

- (BOOL)bs_removeChildViewController:(UIViewController *)childController;
- (BOOL)bs_removeChildViewController:(UIViewController *)childController animated:(BOOL)animated transitionBlock:(void(^)())block;

@end

@interface SBSearchEtceteraLayoutView : UIView
@property (getter=_visibleView,nonatomic,retain,readonly) SBSearchEtceteraLayoutContentView *visibleView;
@property (getter=_scrollView,nonatomic,retain,readonly) SBPagedScrollView *scrollView;

- (id)_visibleView;
@end

@interface SBSearchEtceteraIsolatedViewController : UIViewController
@property (nonatomic,retain,readonly) SBSearchEtceteraLayoutView *contentView;
@property (assign, nonatomic) NSUInteger currentMode;

+ (instancetype)sharedInstance;
@end

//temp until I update the headers
@interface SBIconBadgeView ()

- (void)_configureAnimatedForText:(NSString *)text highlighted:(BOOL)highlighted withPreparation:(void(^)())preparation animation:(void(^)())animation completion:(void(^)())completion;

- (CGPoint)accessoryOriginForIconBounds:(CGRect)bounds;

@end

@interface SBIconView ()
@property (strong, nonatomic) SBIconBadgeView *_ra_badgeView;

- (CGRect)_frameForAccessoryView;
// Cuz above method needs an accessoryView to work
- (CGRect)_ra_frameForAccessoryView:(SBIconBadgeView *)accessoryView;

// Added methods
- (void)_ra_createCustomBadgeView;
- (void)_ra_updateCustomBadgeView:(NSInteger)info;
- (void)_ra_updateCustomBadgeWithExitingInfo;

@end
