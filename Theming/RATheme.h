#import <UIKit/UIKit.h>

@interface RATheme : NSObject

@property (copy, nonatomic) NSString *themeIdentifier;
@property (copy, nonatomic) NSString *themeName;

// Backgrounder
@property (strong, nonatomic) UIColor *backgroundingIndicatorBackgroundColor;
@property (strong, nonatomic) UIColor *backgroundingIndicatorTextColor;

// Mission Control
@property (nonatomic) NSInteger missionControlBlurStyle;
@property (strong, nonatomic) UIColor *missionControlScrollViewBackgroundColor;
@property (nonatomic) CGFloat missionControlScrollViewOpacity;
@property (nonatomic) CGFloat missionControlIconPreviewShadowRadius;

// Windowed Multitasking
@property (strong, nonatomic) UIColor *windowedMultitaskingWindowBarBackgroundColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingCloseIconBackgroundColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingCloseIconTint;
@property (strong, nonatomic) UIColor *windowedMultitaskingMaxIconBackgroundColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingMaxIconTint;
@property (strong, nonatomic) UIColor *windowedMultitaskingMinIconBackgroundColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingMinIconTint;
@property (strong, nonatomic) UIColor *windowedMultitaskingRotationIconBackgroundColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingRotationIconTint;

@property (nonatomic) NSUInteger windowedMultitaskingBarButtonCornerRadius;

@property (strong, nonatomic) UIColor *windowedMultitaskingCloseIconOverlayColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingMaxIconOverlayColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingMinIconOverlayColor;
@property (strong, nonatomic) UIColor *windowedMultitaskingRotationIconOverlayColor;

@property (strong, nonatomic) UIColor *windowedMultitaskingBarTitleColor;
@property (nonatomic) NSTextAlignment windowedMultaskingBarTitleTextAlignment;
@property (nonatomic) NSInteger windowedMultitaskingBarTitleTextInset;

@property (nonatomic) NSInteger windowedMultitaskingCloseButtonAlignment;
@property (nonatomic) NSInteger windowedMultitaskingCloseButtonPriority;
@property (nonatomic) NSInteger windowedMultitaskingMaxButtonAlignment;
@property (nonatomic) NSInteger windowedMultitaskingMaxButtonPriority;
@property (nonatomic) NSInteger windowedMultitaskingMinButtonAlignment;
@property (nonatomic) NSInteger windowedMultitaskingMinButtonPriority;
@property (nonatomic) NSInteger windowedMultitaskingRotationAlignment;
@property (nonatomic) NSInteger windowedMultitaskingRotationPriority;

@property (nonatomic) NSInteger windowedMultitaskingBlurStyle;
@property (strong, nonatomic) UIColor *windowedMultitaskingOverlayColor;

// Quick Access
@property (nonatomic) BOOL quickAccessUseGenericTabLabel;

// SwipeOver
@property (strong, nonatomic) UIColor *swipeOverDetachBarColor;
@property (strong, nonatomic) UIColor *swipeOverDetachImageColor;
@end
