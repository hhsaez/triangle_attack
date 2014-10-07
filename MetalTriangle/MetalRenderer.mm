/*
 * Copyright (c) 2014, Hernan Saez
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "MetalRenderer.hpp"
#include "MetalVertexBufferObjectCatalog.hpp"
#include "MetalShaderProgramCatalog.hpp"

#import "CrimildMetalView.h"
#import "MetalRendererUniforms.hpp"

using namespace crimild;
using namespace crimild::metal;

static const long IN_FLIGHT_COMMAND_BUFFERS = 1;

simd::float4x4 convertMatrix( const Matrix4f &input )
{
    simd::float4 c0 = { input[ 0 ], input[ 1 ], input[ 2 ], input[ 3 ] };
    simd::float4 c1 = { input[ 4 ], input[ 5 ], input[ 6 ], input[ 7 ] };
    simd::float4 c2 = { input[ 8 ], input[ 9 ], input[ 10 ], input[ 11 ] };
    simd::float4 c3 = { input[ 12 ], input[ 13 ], input[ 14 ], input[ 15 ] };
    
    return simd::float4x4( c0, c1, c2, c3 );
}

MetalRenderer::MetalRenderer( CrimildMetalView *view )
    : _view( view )
{
    setScreenBuffer( new FrameBufferObject( _view.bounds.size.width, _view.bounds.size.height ) );
    
    setVertexBufferObjectCatalog( new MetalVertexBufferObjectCatalog( this ) );
    setShaderProgramCatalog( new MetalShaderProgramCatalog( this ) );
    
    _programs[ "default" ] = new ShaderProgram( new Shader( "crimild_simple_vertex" ), new Shader( "crimild_simple_fragment" ) );
}

MetalRenderer::~MetalRenderer( void )
{
    _depthStencilState = nil;
    _commandQueue = nil;
    _device = nil;
    _view = nil;
    _layer = nil;
}

void MetalRenderer::configure( void )
{
    // create device
    _device = MTLCreateSystemDefaultDevice();
    
    // create command queue
    _commandQueue = [_device newCommandQueue];

    // configure layer
    _layer = (CAMetalLayer *) _view.layer;
    _layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _layer.framebufferOnly = true;
    _layer.presentsWithTransaction = false;
    _layer.drawsAsynchronously = true;
    _layer.device = _device;
    
    // configure viewport
    CGRect bounds = _view.frame;
    MTLViewport viewport = {
        0.0f, 0.0f,
        bounds.size.width, bounds.size.height,
        0.0f, 1.0f
    };
    _viewport = viewport;
    
    // configure background color
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if ( colorSpace != nullptr ) {
        CGFloat components[ 4 ] = { 0.5, 0.5, 0.5, 1.0 };
        CGColorRef grayColor = CGColorCreate( colorSpace, components );
        
        if ( grayColor != nullptr ) {
            _layer.backgroundColor = grayColor;
            CFRelease( grayColor );
        }
        
        CFRelease( colorSpace );
    }
    
    // acquire depth-stencil state
    MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
    if ( !depthStateDesc ) {
        Log::Error << "Cannot create depth-stencil descriptor";
        return;
    }
    depthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    depthStateDesc.depthWriteEnabled = true;
    _depthStencilState = [_device newDepthStencilStateWithDescriptor: depthStateDesc];
    depthStateDesc = nil;

    // create semaphores
    _inflightSemaphore = dispatch_semaphore_create( IN_FLIGHT_COMMAND_BUFFERS );
    
}

void MetalRenderer::beginRender( void )
{
    dispatch_semaphore_wait( _inflightSemaphore, DISPATCH_TIME_FOREVER );

    _drawable = [_layer nextDrawable];
    if ( _drawable == nil ) {
        Log::Error << "Cannot obtain next drawable" << Log::End;
        return;
    }

    _commandBuffer = [_commandQueue commandBuffer];
    if ( _commandBuffer == nil ) {
        Log::Error << "Cannot obtain command buffer" << Log::End;
        return;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    if ( renderPassDescriptor == nil ) {
        Log::Error << "Cannot obtain a render pass descriptor" << Log::End;
        return;
    }
    
    renderPassDescriptor.colorAttachments[0].texture = _drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    const RGBAColorf &clearColor = getScreenBuffer()->getClearColor();
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake( clearColor[ 0 ], clearColor[ 1 ], clearColor[ 2 ], clearColor[ 3 ] );

    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    _renderEncoder = [_commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
    if ( _renderEncoder == nil ) {
        Log::Error << "Cannot create render encoder" << Log::End;
        return;
    }
    
    [_renderEncoder setViewport: _viewport];
    [_renderEncoder setFrontFacingWinding: MTLWindingCounterClockwise];
    [_renderEncoder setDepthStencilState: _depthStencilState];
}

void MetalRenderer::endRender( void )
{
    [_renderEncoder endEncoding];

    __block dispatch_semaphore_t dispatchSemaphore = _inflightSemaphore;
    
    [_commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>) {
        dispatch_semaphore_signal( dispatchSemaphore );
    }];
    
    [_commandBuffer presentDrawable: _drawable];
    [_commandBuffer commit];
}

void MetalRenderer::clearBuffers( void )
{

}

void MetalRenderer::bindUniform( ShaderLocation *location, int value )
{

}

void MetalRenderer::bindUniform( ShaderLocation *location, float value )
{

}

void MetalRenderer::bindUniform( ShaderLocation *location, const Vector3f &vector )
{

}

void MetalRenderer::bindUniform( ShaderLocation *location, const RGBAColorf &color )
{

}

void MetalRenderer::bindUniform( ShaderLocation *location, const Matrix4f &matrix )
{

}

void MetalRenderer::setDepthState( DepthState *state )
{

}

void MetalRenderer::setAlphaState( AlphaState *state )
{

}

void MetalRenderer::applyTransformations( ShaderProgram *program, const Matrix4f &projection, const Matrix4f &view, const Matrix4f &model, const Matrix4f &normal )
{
    // TODO: is this correct?
    _uniforms = [_device newBufferWithLength: sizeof( MetalRendererUniforms ) options:0];
    MetalRendererUniforms *uniforms = (MetalRendererUniforms *)[_uniforms contents];
    
    uniforms->pMatrix = convertMatrix( projection );
    uniforms->vMatrix = convertMatrix( view );
    uniforms->mMatrix = convertMatrix( model );
    uniforms->nMatrix = convertMatrix( normal );
}

void MetalRenderer::restoreTransformations( ShaderProgram *program, Geometry *geometry, Camera *camera )
{
    _uniforms = nil;
}

void MetalRenderer::drawPrimitive( ShaderProgram *program, Primitive *primitive )
{
    [getRenderEncoder() setVertexBuffer: _uniforms offset: 0 atIndex: 1];
    
    [getRenderEncoder() drawPrimitives: MTLPrimitiveTypeTriangle
                           vertexStart: 0
                           vertexCount: primitive->getVertexBuffer()->getVertexCount()
                         instanceCount: 1];
}

void MetalRenderer::drawBuffers( ShaderProgram *program, Primitive::Type type, VertexBufferObject *vbo, unsigned int count )
{

}

