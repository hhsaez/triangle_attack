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

#include "MetalShaderProgramCatalog.hpp"
#include "MetalRenderer.hpp"

using namespace crimild;
using namespace crimild::metal;

MetalShaderProgramCatalog::MetalShaderProgramCatalog( MetalRenderer *renderer )
    : _nextBufferId( 0 ),
      _renderer( renderer ),
      _defaultLibrary( nil )
{
    
}

MetalShaderProgramCatalog::~MetalShaderProgramCatalog( void )
{
    
}

int MetalShaderProgramCatalog::getDefaultIdValue( void )
{
    int bufferId = _nextBufferId++;
    return bufferId;
}

id< MTLLibrary > MetalShaderProgramCatalog::getDefaultLibrary( void )
{
    if ( _defaultLibrary == nil ) {
        _defaultLibrary = [getRenderer()->getDevice() newDefaultLibrary];
        if ( _defaultLibrary == nil ) {
            Log::Error << "Cannot create default library" << Log::End;
        }
    }
    
    return _defaultLibrary;
}

void MetalShaderProgramCatalog::bind( ShaderProgram *program )
{
    Catalog< ShaderProgram >::bind( program );
    
    [getRenderer()->getRenderEncoder() setRenderPipelineState: _pipelines[ program->getCatalogId() ]];
}

void MetalShaderProgramCatalog::unbind( ShaderProgram *program )
{
    Catalog< ShaderProgram >::unbind( program );
}

void MetalShaderProgramCatalog::load( ShaderProgram *program )
{
    NSString *vertexProgramName = [NSString stringWithUTF8String: program->getVertexShader()->getSource()];
    id <MTLFunction> vertexProgram = [getDefaultLibrary() newFunctionWithName: vertexProgramName];
    if ( vertexProgram == nullptr ) {
        Log::Error << "Could not load vertex program named " << [vertexProgramName UTF8String] << Log::End;
        return;
    }
    
    NSString *fragmentProgramName = [NSString stringWithUTF8String: program->getFragmentShader()->getSource()];
    id <MTLFunction> fragmentProgram = [getDefaultLibrary() newFunctionWithName: fragmentProgramName];
    if ( fragmentProgram == nullptr ) {
        Log::Error << "Could not load fragment program named " << [fragmentProgramName UTF8String] << Log::End;
        return;
    }
    
    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.sampleCount = 1;
    desc.vertexFunction = vertexProgram;
    desc.fragmentFunction = fragmentProgram;
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    NSError *error = nullptr;
    id<MTLRenderPipelineState> renderPipeline = [getRenderer()->getDevice() newRenderPipelineStateWithDescriptor: desc error: &error];
    if ( renderPipeline == nullptr ) {
        Log::Error << "Couldn't create render pipeline: " << [[error description] UTF8String] << Log::End;
        return;
    }
    
    Catalog< ShaderProgram >::load( program );
    
   _pipelines[ program->getCatalogId() ] = renderPipeline;
}

void MetalShaderProgramCatalog::unload( ShaderProgram *program )
{
    _pipelines[ program->getCatalogId() ] = nullptr;

    Catalog< ShaderProgram >::unload( program );
}

