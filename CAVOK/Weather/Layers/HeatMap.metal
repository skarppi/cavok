#include <metal_stdlib>
using namespace metal;

float HueValue(int, int, int, int, int);
float4 HSVtoRGB(float4);

// Point-Slope Equation of a Line: y - y1 = m(x - x1)
float HueValue (int x, int xFrom, int xTo, int hueFrom, int hueTo) {
    float slope = float(hueTo - hueFrom) / float(xTo - xFrom);
    return (slope * float(x - xFrom) + float(hueFrom)) / 360;
}

// http://chilliant.blogspot.fi/2010/11/rgbhsv-in-hlsl.html
float4 HSVtoRGB(float4 HSV)
{
    float R = abs(HSV.x * 6 - 3) - 1;
    float G = 2 - abs(HSV.x * 6 - 2);
    float B = 2 - abs(HSV.x * 6 - 4);
    
    float4 hue = saturate(float4(R,G,B, HSV.w));
    
    return ((hue - 1) * HSV.y + 1) * HSV.z;
}

kernel void heatMapShader(
                          texture2d<float, access::write> outTexture [[texture(0)]],
                          constant int &radius [[buffer(0)]],
                          constant int &count [[buffer(1)]],
                          const device int *data [[buffer(2)]],
                          const device int *steps [[buffer(3)]],
                          uint2 grid [[threads_per_grid]],
                          uint2 gid [[thread_position_in_grid]])
{
    // find distances to all known points, and min/max distances
    float allDistances[1000];
    float minDistance = 100000.0f;
    float maxDistance = 0.0f;
    
    for (int i=0; i < count; i++) {
        allDistances[i] = distance(float2(gid.x, grid.y - gid.y), float2(data[3*i], data[3*i + 1]));
        
        if(allDistances[i] > maxDistance) {
            maxDistance = allDistances[i];
        }
        if(allDistances[i] < minDistance) {
            minDistance = allDistances[i];
        }
    }

    
    // Inverse Distance Weighted interpolation using Shepard's method 
    // https://github.com/tomschofield/ofxHeatMap/blob/master/ofxHeatMap/src/ofxHeatMap.cpp
    float sumAllFactor = 0.0f;
    for (int i=0; i < count; i++) {
        sumAllFactor += pow((maxDistance - allDistances[i]) / ( maxDistance * allDistances[i]), 2);
    }
    
    if (sumAllFactor == 0.0f) {
        return;
    }
    
    float value=0.0f;
    for (int i = 0; i < count; i++) {
        float thisDistance = allDistances[i];
        
        if (thisDistance == 0.0f) {
            value += float(data[3*i + 2]);
        } else {
            float thisFactor = pow(((maxDistance - thisDistance )/( maxDistance * thisDistance)), 2);
            value += float(data[3*i + 2]) * thisFactor / sumAllFactor;
        }
    }
   
    float hue = 0.0f;
    
    for (int i = 5*4; i >= 0; i=i-4) {
        if(value >= steps[i]) {
            hue = HueValue(value, steps[i], steps[i+1], steps[i+2], steps[i+3]);
            break;
        }
    }

    // Scale to UV space coords
//    float2 uv = float2(gid) / float2(grid);
    // Transform to [(-1.0, -1.0), (1.0, 1.0)] range
//    uv = 2.0 * uv - 1.0;
    // Calculate how near to the center (0.0) or edge (1.0) this fragment is
//    float gradient = uv.x * uv.x + uv.y * uv.y;

    // start fading from the half radius
    float fadingDistance = radius / 2.0f;
    
    float alpha = 0.55f - 0.55f / fadingDistance * (minDistance - fadingDistance);
    
    float4 outColor = HSVtoRGB(float4(hue, 1.0f, 0.81f, clamp(alpha, 0.0f, 0.55f)));
    outTexture.write(outColor, gid);
}
