//
//  MetalView.m
//  MetalTriangle
//
//  Created by Hernan Saez on 9/21/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MetalView.h"

@implementation MetalView {
    
@private
    __weak CAMetalLayer *_metalLayer;
    
    BOOL _layerSizeDidUpdate;
    
    id <MTLTexture> _depthTex;
    id <MTLTexture> _stencilTex;
    id <MTLTexture> _msaaTex;
}

@synthesize currentDrawable = _currentDrawable;
@synthesize renderPassDescriptor = _renderPassDescriptor;

+ (id) layerClass
{
    return [CAMetalLayer class];
}

#pragma mark - Initialization/Cleanup

- (id) initWithFrame: (CGRect) frame
{
    if (self = [super initWithFrame: frame]) {
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

- (void) dealloc
{
    
}

- (void)initCommon
{
    self.opaque = YES;
    self.backgroundColor = nil;
    
    _metalLayer = (CAMetalLayer *) self.layer;
    
    _device = MTLCreateSystemDefaultDevice();
    
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    _metalLayer.framebufferOnly = YES;
}

#pragma mark - Lifecycle

- (void) didMoveToWindow
{
    self.contentScaleFactor = self.window.screen.nativeScale;
}

- (void) setContentScaleFactor: (CGFloat) contentScaleFactor
{
    [super setContentScaleFactor: contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}

#pragma mark - Setup

- (void) setupRenderPassDescriptorForTexture: (id <MTLTexture>) texture
{
    if (_renderPassDescriptor == nil) {
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    }
    
    MTLRenderPassColorAttachmentDescriptor *colorAttachment = _renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture = texture;
    
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.clearColor = MTLClearColorMake(0.65f, 0.65f, 0.65f, 1.0f);
    
    if (_sampleCount > 1) {
        BOOL doUpdate = (_msaaTex.width != texture.width)
        || (_msaaTex.height != texture.height)
        || (_msaaTex.sampleCount != _sampleCount);
        
        if (!_msaaTex || (_msaaTex && doUpdate)) {
            MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatBGRA8Unorm
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            desc.textureType = MTLTextureType2DMultisample;
            desc.sampleCount = _sampleCount;
            
            _msaaTex = [_device newTextureWithDescriptor: desc];
        }
        
        colorAttachment.texture = _msaaTex;
        colorAttachment.resolveTexture = texture;
        colorAttachment.storeAction = MTLStoreActionMultisampleResolve;
    }
    else {
        colorAttachment.storeAction = MTLStoreActionStore;
    }
    
    if (_depthPixelFormat != MTLPixelFormatInvalid) {
        BOOL doUpdate = (_depthTex.width != texture.width)
        || (_depthTex.height != texture.height)
        || (_depthTex.sampleCount != _sampleCount);
        
        if (!_depthTex || doUpdate) {
            MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _depthPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _depthTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassDepthAttachmentDescriptor *depthAttachment = _renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTex;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
    
    if (_stencilPixelFormat != MTLPixelFormatInvalid) {
        BOOL doUpdate  = (_stencilTex.width != texture.width)
        || (_stencilTex.height != texture.height)
        || (_stencilTex.sampleCount != _sampleCount);
        
        if (!_stencilTex || doUpdate) {
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: _stencilPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType = (_sampleCount > 1) ? MTLTextureType2DMultisample : MTLTextureType2D;
            desc.sampleCount = _sampleCount;
            
            _stencilTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassStencilAttachmentDescriptor* stencilAttachment = _renderPassDescriptor.stencilAttachment;
            stencilAttachment.texture = _stencilTex;
            stencilAttachment.loadAction = MTLLoadActionClear;
            stencilAttachment.storeAction = MTLStoreActionDontCare;
            stencilAttachment.clearStencil = 0;
        }
    }
}

- (MTLRenderPassDescriptor *) renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if (!drawable) {
        NSLog(@">> ERROR: Failed to get a drawable!");
        _renderPassDescriptor = nil;
    }
    else {
        [self setupRenderPassDescriptorForTexture: drawable.texture];
    }
    
    return _renderPassDescriptor;
}

- (id <CAMetalDrawable>) currentDrawable
{
    if (_currentDrawable == nil) {
        _currentDrawable = [_metalLayer nextDrawable];
    }
    
    return _currentDrawable;
}

#pragma mark - Display

- (void) display
{
    @autoreleasepool {
        if (_layerSizeDidUpdate) {
            CGSize drawableSize = self.bounds.size;
            drawableSize.width *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            
            _metalLayer.drawableSize = drawableSize;
            
            [self.delegate reshape: self];
            
            _layerSizeDidUpdate = NO;
        }
        
        [self.delegate render: self];
        
        _currentDrawable = nil;
    }
}

- (void) releaseTextures
{
    _depthTex = nil;
    _stencilTex = nil;
    _msaaTex = nil;
}

@end

