//
//  MetalViewController.m
//  MetalTriangle
//
//  Created by Hernan Saez on 9/21/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MetalViewController.h"
#import "MetalView.h"

@implementation MetalViewController {
@private
    // app control
    CADisplayLink *_timer;
    
    // boolean to determine if the first draw has occured
    BOOL _firstDrawOccurred;
    
    CFTimeInterval _timeSinceLastDrawPreviousTime;
    
    // pause/resume
    BOOL _simulationLoopPaused;
}

#pragma mark - Initialization/Cleanup

- (id) init
{
    if (self = [super init]) {
        [self initCommon];
    }
    
    return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    if (self = [super initWithCoder: aDecoder]) {
        [self initCommon];
    }
    
    return self;
}

- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil
{
    if (self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil]) {
        [self initCommon];
    }
    
    return self;
}

- (void) initCommon
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    _interval = 1;
    self.renderer = [[MetalRenderer alloc] init];
}

- (void) dealloc
{
    if (self.renderer != nil) {
        self.renderer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                              forKeyPath: UIApplicationDidEnterBackgroundNotification
                                                 context: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                              forKeyPath: UIApplicationWillEnterForegroundNotification
                                                 context: nil];
    
    if (_timer != nil) {
        [self stopSimulationLoop];
    }
}

#pragma mark - View Lifecycle

- (void) loadView
{
    self.view = [[MetalView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.renderer configure: (MetalView *) self.view];
}

- (void) viewWillAppear: (BOOL) animated
{
    [super viewWillAppear: animated];
    
    [self dispatchSimulationLoop];
}

- (void) viewWillDisappear: (BOOL) animated
{
    [super viewWillDisappear: animated];
    
    [self stopSimulationLoop];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) didEnterBackground: (id) sender
{
    self.paused = YES;
}

- (void) willEnterForeground: (id) sender
{
    self.paused = NO;
}

#pragma mark - Simulation Management

- (void) dispatchSimulationLoop
{
    _timer = [[UIScreen mainScreen] displayLinkWithTarget: self
                                                     selector: @selector(simulationLoop)];
    _timer.frameInterval = _interval;
    [_timer addToRunLoop: [NSRunLoop mainRunLoop]
                 forMode: NSDefaultRunLoopMode];
}

- (void) stopSimulationLoop
{
    if (_timer != nil) {
        [_timer invalidate];
    }
}

- (void) simulationLoop
{
    // perform actual simulation step
    
    if (!_firstDrawOccurred) {
        _timeSinceLastDraw = 0.0;
        _timeSinceLastDrawPreviousTime = CACurrentMediaTime();
        _firstDrawOccurred = YES;
    }
    else {
        CFTimeInterval currentTime = CACurrentMediaTime();
        _timeSinceLastDraw = currentTime - _timeSinceLastDrawPreviousTime;
        _timeSinceLastDrawPreviousTime = currentTime;
    }
    
    [(MetalView *) self.view display];
}

- (void) setPaused: (BOOL) pause
{
    if (_simulationLoopPaused == pause) {
        return;
    }
    
    if (_timer != nil) {
        _simulationLoopPaused = pause;
        _timer.paused = pause;
        if (pause) {
            [(MetalView *) self.view releaseTextures];
        }
    }
}

- (BOOL) isPaused
{
    return _simulationLoopPaused;
}

@end
