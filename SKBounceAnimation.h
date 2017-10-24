//
//  SKBounceAnimation.h
//  SKBounceAnimation
//
//  Created by Soroush Khanlou on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef CGFloat SKBounceAnimationStiffness;

extern SKBounceAnimationStiffness SKBounceAnimationStiffnessLight;
extern SKBounceAnimationStiffness SKBounceAnimationStiffnessMedium;
extern SKBounceAnimationStiffness SKBounceAnimationStiffnessHeavy;

@interface SKBounceAnimation : CAKeyframeAnimation

@property (strong, nonatomic) id fromValue;
@property (strong, nonatomic) id byValue;
@property (strong, nonatomic) id toValue;
@property (nonatomic) NSUInteger numberOfBounces;
@property (nonatomic) BOOL shouldOvershoot; //default YES
@property (nonatomic) BOOL shake; //if shaking, set fromValue to the furthest value, and toValue to the current value
@property (nonatomic) SKBounceAnimationStiffness stiffness;

+ (SKBounceAnimation *)animationWithKeyPath:(NSString *)keyPath;


@end
