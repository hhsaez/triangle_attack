//
//  MetalViewController.h
//  MetalTriangle
//
//  Created by Hernan Saez on 9/21/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MetalRenderer.h"

#import <UIKit/UIKit.h>

@interface MetalViewController : UIViewController

@property (nonatomic, strong) MetalRenderer *renderer;

@property (nonatomic, assign) NSUInteger interval;
@property (nonatomic, readonly) NSTimeInterval timeSinceLastDraw;

@property (nonatomic, assign, getter=isPaused) BOOL paused;

- (void) dispatchSimulationLoop;
- (void) stopSimulationLoop;

@end

