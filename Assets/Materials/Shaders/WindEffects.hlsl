#ifndef WINDDEFORMATION_INCLUDE
#define WINDDEFORMATION_INCLUDE


float WindWave(float currentPos, float uvAnchor, float WindSpeed, float WindAmp, float _WindUni = 1) {
    //This function "flickers" the whole object as if in the wind
    float wave = normalize(lerp(-1, 1, sin(_Time * WindSpeed + currentPos * _WindUni) * 0.5f)) + 0.25f + (WindAmp * 0.1f);
    return wave * uvAnchor * WindAmp;

}

float WaveEffect(float uvDirection, float uvAnchor, float4 Wave) {
    //This function gives the vertex a wave like effect
    float morpSin = sin(uvDirection * Wave.x + _Time * Wave.y) * Wave.z;
    return morpSin * uvAnchor;
}

#endif
