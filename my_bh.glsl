float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

vec3 bg(vec3 p)
{
    return fract(p);
}

float myStep(float e, float x)
{
    return x < e ? 0. : 1.f;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // x[0, x/y] y[0, 1]
    vec2 uv = fragCoord/iResolution.yy;
    // to [-1, 1]
    uv = uv*2.  - 1.;	

    vec4 backgroundColor = vec4(0.2, 0.2, 0.2, 1);
    vec3 eye = vec3(0, 0, 1);
    vec3 bhCenter = vec3(0, 0, 0);
    float bhRadius = 0.2f;

    // assume screen is x[-x/y, x/y] y[-1, 1] at z = 0
    float screenScale = 2.f;
    vec3 v = normalize(vec3(uv * vec2(screenScale, screenScale), 0) - eye);
    vec3 rayPt = eye;

    float dt = .01f;
    int totStep = 400;
    float dToBh = 0.f;
    float hitted = 1.f;
    for (int i = 0; i < totStep; i++)
    {
        dToBh = sdfSphere(rayPt - bhCenter, bhRadius);
        hitted = myStep(0.f, dToBh);
        if (hitted < 1.f) break;
        rayPt += v * dt;
        if (rayPt.z < -0.3) break;
    }
    fragColor = vec4(bg(rayPt) * hitted, 1.f);
}