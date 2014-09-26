//
//  MCPPRenderer.h
//  MetalTriangle
//
//  Created by Hernan Saez on 9/26/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#ifndef __MetalTriangle__MCPPRenderer__
#define __MetalTriangle__MCPPRenderer__

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <stdio.h>

@class MCPPView;

namespace MetalCPP {
    
    class Renderer {
    public:
        Renderer( MCPPView *view );
        virtual ~Renderer( void );
        
        void present( void );
        
        void setClearColor( float r, float g, float b, float a );
        
    private:
        bool prepare( void );
        bool configureViewport( void );
        bool configureBackgroundColor( void );
        bool acquireDevice( void );
        bool createCommandQueue( void );
        bool acquireDepthStencilState( void );
        bool createSemaphores( void );
        
        void cleanup( void );
        
        MTLRenderPassDescriptor *createDescriptor( void );
        void encodeFrame( id<MTLRenderCommandEncoder> encoder );
        
    private:
        MCPPView *_view;
        CAMetalLayer *_metalLayer;
        MTLViewport _viewport;
        
        id<MTLDevice> _device;
        id<MTLCommandQueue> _commandQueue;
        id<MTLDepthStencilState> _depthState;
        
        dispatch_semaphore_t _inflightSemaphore;
        
        MTLClearColor _clearColor;
    };
    
}

#endif
