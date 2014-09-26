//
//  MetalView.h
//  MetalTriangle
//
//  Created by Hernan Saez on 9/21/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@class MetalView;

@protocol MetalViewDelegate <NSObject>

@required

- (void) reshape: (MetalView *) view;
- (void) render: (MetalView *) view;

@end

@interface MetalView : UIView

@property (nonatomic, weak) IBOutlet id <MetalViewDelegate> delegate;

@property (nonatomic, readonly) id <MTLDevice> device;
@property (nonatomic, readonly) id <CAMetalDrawable> currentDrawable;
@property (nonatomic, readonly) MTLRenderPassDescriptor *renderPassDescriptor;

@property (nonatomic) MTLPixelFormat depthPixelFormat;
@property (nonatomic) MTLPixelFormat stencilPixelFormat;

@property (nonatomic) NSUInteger sampleCount;

- (void) display;

- (void) releaseTextures;

@end

