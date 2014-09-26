//
//  MCCPViewController.m
//  MetalTriangle
//
//  Created by Hernan Saez on 9/26/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MCPPViewController.h"
#import "MCPPView.h"
#import "MCPPRenderer.h"

#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/CAMetalLayer.h>

@implementation MCPPViewController {
    
@private
    MetalCPP::Renderer *_renderer;
    CADisplayLink *_timer;
}

- (void) dealloc
{
    [self cleanup];
}

- (void) cleanup
{
    if (_renderer != nullptr) {
        delete _renderer;
        _renderer = nullptr;
    }
    
    if (_timer != nullptr) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark - View lifecycle

- (void) loadView
{
    self.view = [[MCPPView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    MCPPView *metalView = (MCPPView *) self.view;
    
    _renderer = new MetalCPP::Renderer(metalView);
    
    _timer = [CADisplayLink displayLinkWithTarget: self selector: @selector(render:)];
    [_timer addToRunLoop: [NSRunLoop mainRunLoop] forMode: NSDefaultRunLoopMode];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        [self cleanup];
    }
}

#pragma mark - Render

- (void) render: (id) sender
{
    @autoreleasepool {
        if (_renderer != nullptr) {
            _renderer->present();
        }
    }
}

@end

