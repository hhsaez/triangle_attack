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

#ifndef CRIMILD_METAL_RENDERING_RENDERER_
#define CRIMILD_METAL_RENDERING_RENDERER_

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

#include <Crimild.hpp>

@class CrimildMetalView;

namespace crimild {
    
    namespace metal {
        
        class MetalRenderer : public crimild::Renderer {
        public:
            MetalRenderer( CrimildMetalView *view );
            virtual ~MetalRenderer( void );
            
            virtual void configure( void ) override;
            
            virtual void beginRender( void ) override;
            
            virtual void endRender( void ) override;
            
            virtual void clearBuffers( void ) override;
            
        public:
            virtual void bindUniform( ShaderLocation *location, int value ) override;
            virtual void bindUniform( ShaderLocation *location, float value ) override;
            virtual void bindUniform( ShaderLocation *location, const Vector3f &vector ) override;
            virtual void bindUniform( ShaderLocation *location, const RGBAColorf &color ) override;
            virtual void bindUniform( ShaderLocation *location, const Matrix4f &matrix ) override;
            
            virtual void setDepthState( DepthState *state ) override;
            virtual void setAlphaState( AlphaState *state ) override;
            
            virtual void applyTransformations( ShaderProgram *program, const Matrix4f &projection, const Matrix4f &view, const Matrix4f &model, const Matrix4f &normal ) override;
            virtual void restoreTransformations( ShaderProgram *program, Geometry *geometry, Camera *camera ) override;
            
            virtual void drawPrimitive( ShaderProgram *program, Primitive *primitive ) override;
            virtual void drawBuffers( ShaderProgram *program, Primitive::Type type, VertexBufferObject *vbo, unsigned int count ) override;
            
            virtual ShaderProgram *getShaderProgram( const char *name ) override { return _programs[ name ].get(); }
            
        public:
            id<MTLDevice> getDevice( void ) { return _device; }
            
            id< MTLRenderCommandEncoder > getRenderEncoder( void ) { return _renderEncoder; }
            
        private:
            CrimildMetalView *_view;
            CAMetalLayer *_layer;
            id< MTLDevice > _device;
            id< MTLCommandQueue > _commandQueue;
            id< MTLCommandBuffer > _commandBuffer;
            id< CAMetalDrawable > _drawable;
            MTLClearColor _clearColor;
            MTLViewport _viewport;
            id< MTLDepthStencilState > _depthStencilState;
            id< MTLRenderCommandEncoder > _renderEncoder;
            
            dispatch_semaphore_t _inflightSemaphore;
            
            id< MTLBuffer > _uniforms;
            
            std::map< std::string, Pointer< ShaderProgram > > _programs;
        };
        
    }
    
}

#endif

