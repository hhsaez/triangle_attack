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

#ifndef CRIMILD_METAL_RENDERING_CATALOGS_SHADER_PROGRAM_
#define CRIMILD_METAL_RENDERING_CATALOGS_SHADER_PROGRAM_

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <Crimild.hpp>

namespace crimild {
    
    namespace metal {
        
        class MetalRenderer;
        
        class MetalShaderProgramCatalog : public Catalog< ShaderProgram > {
        public:
            MetalShaderProgramCatalog( MetalRenderer *renderer );
            virtual ~MetalShaderProgramCatalog( void );
            
            virtual int getDefaultIdValue( void ) override;
            
            virtual void bind( ShaderProgram *program ) override;
            virtual void unbind( ShaderProgram *program ) override;
            
            virtual void load( ShaderProgram *program ) override;
            virtual void unload( ShaderProgram *program ) override;
            
        protected:
            MetalRenderer *getRenderer( void ) { return _renderer; }
            id< MTLLibrary > getDefaultLibrary( void );
            
        private:
            MetalRenderer *_renderer;
            id< MTLLibrary > _defaultLibrary;
            std::map< int, id< MTLRenderPipelineState > > _pipelines;
            int _nextBufferId;
        };
        
    }
    
}

#endif

