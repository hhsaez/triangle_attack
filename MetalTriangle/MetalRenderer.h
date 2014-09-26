//
//  MetalRenderer.h
//  MetalTriangle
//
//  Created by Hernan Saez on 9/21/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MetalView.h"

@interface MetalRenderer : NSObject <MetalViewDelegate>

@property (nonatomic, readonly) id <MTLDevice> device;

@property (nonatomic, readonly) NSUInteger constantDataBufferIndex;

@property (nonatomic, readonly) MTLPixelFormat depthPixelFormat;
@property (nonatomic, readonly) MTLPixelFormat stencilPixelFormat;
@property (nonatomic, readonly) NSUInteger sampleCount;

- (void) configure: (MetalView *) metalView;

@end
