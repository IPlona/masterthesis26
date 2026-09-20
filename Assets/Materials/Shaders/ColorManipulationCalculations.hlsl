#ifndef COLORMANIPULATION_INCLUDE
#define COLORMANIPULATION_INCLUDE

float4 linear2sRGB_IT(half4 c) {
    //Based on the calculations of Ian Taylor in: https://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html?m=1
    half4 s1 = sqrt(c);
    half4 s2 = sqrt(s1);
    half4 s3 = sqrt(s2);

    return (0.585122381 * s1 + 0.783140355 * s2 - 0.368262736 * s3);
}
float3 sRGB2linear_IT(float3 c) {
    //Based on the calculations of Ian Taylor in: https://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html?m=1
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

float3 RGBtoHCV(in float3 RGB)
{
    //From Ian Taylor: https://www.chilliant.com/rgb2hsvx.html
    // Who based on work by Sam Hocevar and Emil Persson: https://web.archive.org/web/20200808153903/http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
    //Additionally, Sam Hocevar's earlier post about this: https://web.archive.org/web/20210613072819/http://lolengine.net/blog/2013/01/13/fast-rgb-to-hsv
    float Epsilon = 1e-10;
    
    //According to Persson, using ternary operator is faster than the lerp-step conditional.
    //Hocevar explains how they figured this type of conversion out of the usual RGBtoHSV conversion,
    // here: https://web.archive.org/web/20210613072819/http://lolengine.net/blog/2013/01/13/fast-rgb-to-hsv
    //Basically, instead of doing multiple check of min-max values he sorts RGB to go from highest to lowest
    // which can reduce the need for min-max operations and if-else statements.
    // Later he converst it to GLSL, which then Taylor converst to HLSL simplefying it further.
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0 / 3.0) : float4(RGB.gb, 0.0, -1.0 / 3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);

    float C = Q.x - min(Q.w, Q.y);

    float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
    return float3(H, C, Q.x);
}
float3 getHSV(half4 c) {
    //Credit to Ian Taylor: https://www.chilliant.com/rgb2hsvx.html
    // And Sam Hocevar and Emil Persson: https://web.archive.org/web/20200808153903/http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
    float Epsilon = 1e-10;

    //I want to compine these two functions, so I will.
    //float3 HCV = RGBtoHCV(c);
    //First comparsion -> sorting
    float4 P = (c.g < c.b) ? float4(c.bg, -1.0, 2.0 / 3.0) : float4(c.gb, 0.0, -1.0 / 3.0);
    float4 q = (c.r < P.x) ? float4(P.xyw, c.r) : float4(c.r, P.yzx);

    float chroma = q.x - min(q.w, q.y);

    float hue = abs((q.w - q.y) / (6 * chroma + Epsilon) + q.z);
    float Sat = chroma / (q.x + Epsilon);
    
    //Hue Saturation Value
    //float3 HCV = float3(hue, chroma, q.x);
    //float Sat = HCV.y / (HCV.z + Epsilon);
    //return float3(HCV.x, Sat, HCV.z);
    return float3(hue, Sat, q.x);
}

float3 getRGB(float3 c) {
    //Code credit to Patapom (https://stackoverflow.com/a/19400360), under CC BY-SA 3.0, aka. sharing (commercial) and editing is fine.

    //This is mising the "if saturation is 0 statement TODOOOO
    if (c.y <= 0) {
        return c.z;
    }

    //In the getHSV we do similiar conversions, but this is essential to ensure that the code works as should.
    c.x = fmod(100.0 + c.x, 1.0);

    float hueSlice = 6.0 * c.x;
    float hueSliceInteger = floor(hueSlice);                //Floor returns nearest full integer, aka. 1.2 -> 1, 3.9 -> 3
    float hueSliceInterpolant = hueSlice - hueSliceInteger;

    //By the comment + Nikolai Waldman https://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
    // we can start by doing temporary values.
    float3 tempRGB = float3(c.z * (1.0 - c.y),
        c.z * (1.0 - c.y * hueSliceInterpolant),
        c.z * (1.0 - c.y * (1.0 - hueSliceInterpolant)));

    //Patapom had pinpointed pattern in common HSVtoRGB functions, where switch/if-statem was used to determine
    // how each r g an b value should be calculated, noticing that every other "region" (aka. section in the color wheel)
    // wsa just shifted/rotated pattern, like so (x, y, z) to (z, x, y) to (y, z, x)
    // In the even parts the pattern to shift was (Value, Blue, Red) and uneven (Green, Value, Red)
    //
    // On additional note, one might recognize the correlation between "every other section" in Hue wheel
    // to the HSV color wheel being made off primary (RGB) and secondary (CYM) colors.
    float isOddSlice = fmod(hueSliceInteger, 2.0);
    float threeSliceSelector = 0.5 * (hueSliceInteger - isOddSlice);

    float3 shiftingRGBForEvenSlices = float3(c.z, tempRGB.zx);
    float3 shiftingRGBForOddSlice = float3(tempRGB.y, c.z, tempRGB.x);

    float3 shiftingRGB = lerp(shiftingRGBForEvenSlices, shiftingRGBForOddSlice, isOddSlice);
    //This is "how we choose if to use (V, B, R) pattern or (G, V, R) pattern. If isOddSlice = 0, we choose first, if 1 we choose second.

    float isNotFirst = saturate(threeSliceSelector);        //Similiarly as above using fmod and lerp to make if-statement
    float isNotSecond = saturate(threeSliceSelector - 1.0);

    float3 newRGB = lerp(shiftingRGB.xyz, lerp(shiftingRGB.zxy, shiftingRGB.yzx, isNotSecond), isNotFirst);
    //And done... Again.

    return newRGB;
}

#endif
