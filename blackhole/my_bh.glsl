#iChannel0 "file://./texture/blackhole.png"

const int star_iterations = 10;
const vec3 col_star = vec3(1.0,0.9,0.85);

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

vec3 bgDark(vec3 p)
{
    return vec3(0.1, 0.1, 0.1);
}

vec3 bgGrid(vec3 p)
{
    return fract(p * vec3(2., 2., 2.));
}

float myStep(float e, float x)
{
    return x < e ? 0. : 1.f;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // x[0, x/y] y[0, 1]
    vec2 uv = fragCoord/iResolution.xy;
    // to [-1, 1]
    uv = uv*2.  - 1.;	
    uv.x *= iResolution.x / iResolution.y;

    vec4 backgroundColor = vec4(0.2, 0.2, 0.2, 1.0);
    vec3 eye = vec3(0, 0, 1);
    vec3 bhCenter = vec3(0.05*sin(iTime), sin(0.05*iTime), 0);
    float bhRadius = 0.2f;

    // assume screen is x[-x/y, x/y] y[-1, 1] at z = 0
    float screenScale = 2.f;
    vec3 v = normalize(vec3(uv * vec2(screenScale, screenScale), 0) - eye);
    vec3 rayPt = eye;

    float dt = 0.01f;
    int totStep = 800;
    float dToBhFace = 0.0f;
    float hitted = 0.8f;

    // physic stuff
    // v = v + a * t
    // rayPt = rayPt + v * t
    // f = G * M * m / r^2
    // a = G * M / r^2
    float GM = 0.2f;
    vec3 clr = vec3(0, 0, 0);
    for (int i = 0; i < totStep; i++)
    {
        dToBhFace = sdfSphere(rayPt - bhCenter, bhRadius);
        hitted = myStep(0.f, dToBhFace);
        if (hitted < 1.f) break;

        vec3 vToBh = bhCenter - rayPt;
        vec3 GDir = normalize(vToBh);
        float rPow2 = dot(vToBh, vToBh);
        vec3 a =  GDir * GM / rPow2;
        v += a * dt;
        rayPt += v * dt;
        clr += col_star * (1.0/vec3(dot(dToBhFace,dToBhFace))) * 0.00006 * hitted; // y=1/(x^2)
        if (rayPt.z < -1.) break;
    }
    //clr += pow(texture(iChannel0, rayPt.xy).rgb,vec3(3.0)) * hitted;
    fragColor = vec4(bgDark(rayPt) * hitted + clr * hitted, 1.f);
}