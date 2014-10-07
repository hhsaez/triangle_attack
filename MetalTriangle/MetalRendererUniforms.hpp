/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
 Shared data types between CPU code and metal shader code
 
 */

#ifndef CRIMILD_METAL_RENDERING_RENDERER_UNIFORMS_
#define CRIMILD_METAL_RENDERING_RENDERER_UNIFORMS_

#import <simd/simd.h>

#ifdef __cplusplus

namespace crimild {
    
    namespace metal {

        typedef struct {
            simd::float4x4 pMatrix;
            simd::float4x4 vMatrix;
            simd::float4x4 mMatrix;
            simd::float4x4 nMatrix;
        } MetalRendererUniforms;
        
    }
}

#endif

#endif