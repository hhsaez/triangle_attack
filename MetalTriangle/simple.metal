#include <metal_stdlib>

#include "MetalRendererUniforms.hpp"

using namespace metal;

#define VERTEX_SIZE 7
#define POSITION_OFFSET 0
#define COLOR_OFFSET 3

struct ColoredPosition {
    float4 position [[ position ]];
    float4 color;
};

vertex ColoredPosition crimild_simple_vertex( constant float *vertices [[ buffer(0) ]],
                                              constant crimild::metal::MetalRendererUniforms &uniforms [[ buffer(1) ]],
                                              uint vid [[ vertex_id ]])
{
    ColoredPosition out;
    
    float4 pos = float4(
        vertices[ vid * VERTEX_SIZE + POSITION_OFFSET + 0 ],
        vertices[ vid * VERTEX_SIZE + POSITION_OFFSET + 1 ],
        0.0,
        1.0 );
    
    out.position = uniforms.pMatrix * uniforms.vMatrix * uniforms.mMatrix * pos;
    
    out.color = float4(
       vertices[ vid * VERTEX_SIZE + COLOR_OFFSET + 0 ],
       vertices[ vid * VERTEX_SIZE + COLOR_OFFSET + 1 ],
       vertices[ vid * VERTEX_SIZE + COLOR_OFFSET + 2 ],
       vertices[ vid * VERTEX_SIZE + COLOR_OFFSET + 3 ] );

    return out;
}

fragment half4 crimild_simple_fragment( ColoredPosition in [[ stage_in ]] )
{
    return half4( in.color );
}


