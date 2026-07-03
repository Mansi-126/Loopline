//
//  Loopline.metal
//  Loopline
//
//  Created by Mansi Gangani on 03/07/26.
//

//#include <metal_stdlib>
//using namespace metal;
//
//


#include <metal_stdlib>
using namespace metal;

// Flowing gradient along the drawn path. `progress` sweeps a highlight
// down the line so the path feels alive, like current flowing through it.
[[ stitchable ]] half4 pathFlow(float2 position, half4 color, float time, float2 size) {
    if (color.a < 0.01h) return color;
    float t = position.x / max(size.x, 1.0) + position.y / max(size.y, 1.0);
    float wave = 0.5 + 0.5 * sin(t * 6.0 - time * 2.4);
    half3 base = half3(1.0, 0.42, 0.29);          // coral
    half3 hot  = half3(1.0, 0.62, 0.42);          // lighter coral
    half3 c = mix(base, hot, half(wave));
    return half4(c * color.a, color.a);
}

// Celebratory shimmer sweep across a solved board.
[[ stitchable ]] half4 winShimmer(float2 position, half4 color, float time, float2 size) {
    if (color.a < 0.01h) return color;
    float diag = (position.x + position.y) / (size.x + size.y);
    float band = smoothstep(0.0, 0.15, abs(diag - fract(time * 0.45)) ) ;
    half boost = half(1.0 - band) * 0.55h;
    return half4(min(color.rgb + boost, half3(1.0)), color.a);
}

// Soft animated grain for the paper background — barely perceptible,
// but makes flat color feel like material.
[[ stitchable ]] half4 paperGrain(float2 position, half4 color, float time) {
    float n = fract(sin(dot(position + time * 0.1, float2(12.9898, 78.233))) * 43758.5453);
    return half4(color.rgb + half3((n - 0.5) * 0.015), color.a);
}
