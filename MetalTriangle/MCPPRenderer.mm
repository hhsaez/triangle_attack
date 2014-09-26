//
//  MCPPRenderer.cpp
//  MetalTriangle
//
//  Created by Hernan Saez on 9/26/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MCPPRenderer.h"
#import "MCPPView.h"

#define IN_FLIGHT_COMMAND_BUFFERS 1

using namespace MetalCPP;

Renderer::Renderer( MCPPView *view )
{
    _view = view;
    _metalLayer = (CAMetalLayer *) _view.layer;
    
    _metalLayer.presentsWithTransaction = false;
    _metalLayer.drawsAsynchronously = true;
    
    prepare();
    setClearColor( 0.65f, 0.65f, 0.65f, 1.0f );
}

Renderer::~Renderer( void )
{
    cleanup();
}

bool Renderer::prepare( void )
{
    return configureViewport()
        && configureBackgroundColor()
        && acquireDevice()
        && createCommandQueue()
        && acquireDepthStencilState()
        && createSemaphores();
}

bool Renderer::configureViewport( void )
{
    CGRect bounds = _view.frame;
    MTLViewport viewport = {
        0.0f, 0.0f,
        bounds.size.width, bounds.size.height,
        0.0f, 1.0f
    };
    _viewport = viewport;
    return true;
}

bool Renderer::configureBackgroundColor( void )
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if ( colorSpace != nullptr ) {
        CGFloat components[ 4 ] = { 0.5, 0.5, 0.5, 1.0 };
        CGColorRef grayColor = CGColorCreate( colorSpace, components );
        
        if ( grayColor != nullptr ) {
            _metalLayer.backgroundColor = grayColor;
            CFRelease( grayColor );
        }
        
        CFRelease( colorSpace );
    }
    
    return true;
}

bool Renderer::acquireDevice( void )
{
    _device = MTLCreateSystemDefaultDevice();
    if ( !_device ) {
        return false;
    }
    
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly = true;
    
    return true;
}

bool Renderer::createCommandQueue( void )
{
    _commandQueue = [_device newCommandQueue];

    return _commandQueue != nil;
}

bool Renderer::acquireDepthStencilState( void )
{
    MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
    if ( !depthStateDesc ) {
        return false;
    }
    
    depthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    depthStateDesc.depthWriteEnabled = true;
    
    _depthState = [_device newDepthStencilStateWithDescriptor: depthStateDesc];
    
    depthStateDesc = nil;
    
    return _depthState != nil;
}

bool Renderer::createSemaphores( void )
{
    _inflightSemaphore = dispatch_semaphore_create( IN_FLIGHT_COMMAND_BUFFERS );
    return true;
}

void Renderer::setClearColor( float r, float g, float b, float a )
{
    _clearColor = MTLClearColorMake( r, g, b, a );
}

void Renderer::cleanup( void )
{
    _depthState = nil;
    _commandQueue = nil;
    _device = nil;
    _view = nil;
    _metalLayer = nil;
}

void Renderer::present( void )
{
    dispatch_semaphore_wait( _inflightSemaphore, DISPATCH_TIME_FOREVER );
    
    id< MTLDrawable > drawable = [_metalLayer nextDrawable];
    if ( drawable != nil ) {
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        if (commandBuffer) {
            MTLRenderPassDescriptor *renderPassDrescriptor = createDescriptor();
            if (renderPassDrescriptor) {
                id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor: renderPassDrescriptor];
                if ( renderEncoder ) {
                    encodeFrame( renderEncoder );
                }
                
                __block dispatch_semaphore_t dispatchSemaphore = _inflightSemaphore;
                
                [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
                    dispatch_semaphore_signal( dispatchSemaphore );
                }];
                
                [commandBuffer presentDrawable: drawable];
                [commandBuffer commit];
            }
        }
    }
}

MTLRenderPassDescriptor *Renderer::createDescriptor( void )
{
    MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    if ( !descriptor ) {
        return nil;
    }
    
//    descriptor.colorAttachments[0].texture = nil;
    descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    descriptor.colorAttachments[0].clearColor = _clearColor;
    descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    return descriptor;
}

void Renderer::encodeFrame( id<MTLRenderCommandEncoder> encoder )
{
    [encoder setViewport: _viewport];
    [encoder setFrontFacingWinding: MTLWindingCounterClockwise];
    [encoder setDepthStencilState: _depthState];
    
    [encoder endEncoding];
}

