//
//  MetalSharedTypes.h
//  MetalTriangle
//
//  Created by Hernan Saez on 9/24/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#ifndef MetalTriangle_MetalSharedTypes_h
#define MetalTriangle_MetalSharedTypes_h

#import <simd/simd.h>

#ifdef __cplusplus

namespace Metal
{
    typedef struct {
        simd::float4x4 modelview_projection_matrix;
        simd::float4x4 normal_matrix;
        simd::float4 ambient_color;
        simd::float4 diffuse_color;
        int multiplier;
    } constants_t;
}

#endif

#endif

