#iChannel0 "file://./texture/blackhole.png"
#iChannel1 "file://./texture/noise.png"
const int star_iterations = 10;
const vec3 col_star = vec3(1.0,0.9,0.85);

// t[radius, sub radius]
// p: position
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

vec3 bgDark(vec3 p)
{
    return vec3(0.01, 0.01, 0.01);
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
    vec3 eye = vec3(0, 0.1, 1);
    vec3 bhCenter = vec3(0, 0, 0);
    float bhRadius = 0.1f;

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
        hitted = smoothstep(0.0, 0.888, dToBhFace);
        if(hitted < 0.0001f) break;
        //if (hitted < 0.f) break;

        vec3 vToBh = bhCenter - rayPt;
        vec3 GDir = normalize(vToBh);
        float rPow2 = dot(vToBh, vToBh);
        vec3 a =  GDir * GM / rPow2;
        v += a * dt;
        rayPt += v * dt * hitted;

        // sphere color:
        // clr += col_star: increase every hit, looks fine, inner circle too bright
        // *= hitted: decrease clr close to surface, inner circle ok,but clr edge too sharp
        // /= r^2: glowing near surface. brightest very close to surface
        clr += col_star * 0.0016 * hitted / vec3(dot(vToBh, vToBh)); // y=1/(x^2)

        // dust disk
        float pi = 3.14159265354;
        float dr = length(vToBh.xz);
        float da = atan(vToBh.x,vToBh.z);
        vec2 disckParams = vec2(dr,da * (0.01 + (dr - bhRadius)*0.002) + iTime*0.002 );
        disckParams *= vec2(10.0,20.0);
        vec3 diskClr = vec3(1.0, 0.9, 0.8) * 0.1 * 
            max(0.0,texture(iChannel1,disckParams*vec2(0.1,0.5)).x+0.05);
        
        float diskStrength = -sdTorus((rayPt * vec3(1.0, 25.0, 1.0) - bhCenter), vec2(0.8, 0.9));
        diskStrength = smoothstep(0., 1., diskStrength);

        clr += diskClr * diskStrength;
        //if (rayPt.z < -1.) break;
    }
    //clr += pow(texture(iChannel0, rayPt.xy).rgb,vec3(3.0)) * hitted;
    fragColor = vec4(bgDark(rayPt) * hitted + clr, 1.f);
}