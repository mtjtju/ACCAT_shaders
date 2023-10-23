#iChannel0 "file://./texture/blackhole.png"
#iChannel1 "file://./texture/noise.png"
const int star_iterations = 10;
const vec3 col_star = vec3(1.0,0.95,0.95);
const float pi = 3.14159265354;


#define iterations 17
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.800
#define tile   1.850
#define speed  0.010 

#define brightness 0.0005
#define darkmatter 0.600
#define distfading 0.730
#define saturation 0.350


vec3 bgStar( vec2 p)
{
	//get coords and direction
	vec2 uv=p.xy;
	uv.y*=iResolution.y/iResolution.x;
	vec3 dir=vec3(uv*zoom,1.);
	float time=iTime*speed+.25;

	//mouse rotation
	float a1=.5+iMouse.x/iResolution.x*2.;
	float a2=.8+iMouse.y/iResolution.y*2.;
	mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
	mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
	//dir.xz*=rot1;
	//dir.xy*=rot2;
	vec3 from=vec3(1.,.5,0.5);
	from+=vec3(time*2.,time,-2.);
	//from.xz*=rot1;
	//from.xy*=rot2;
	
	//volumetric rendering
	float s=0.1,fade=1.;
	vec3 v=vec3(0.);
	for (int r=0; r<volsteps; r++) {
		vec3 p=from+s*dir*.5;
		p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
		float pa,a=pa=0.;
		for (int i=0; i<iterations; i++) { 
			p=abs(p)/dot(p,p)-formuparam; // the magic formula
			a+=abs(length(p)-pa); // absolute sum of average change
			pa=length(p);
		}
		float dm=max(0.,darkmatter-a*a*.001); //dark matter
		a*=a*a; // add contrast
		if (r>6) fade*=1.-dm; // dark matter, don't render near
		v+=vec3(dm,dm*.5,0.);
		v+=fade;
		v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
		fade*=distfading; // distance fading
		s+=stepsize;
	}
	v=mix(vec3(length(v)),v,saturation); //color adjust
	return vec3(v*.01);	
}


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

    float eyer = 2.0;
    float eyea = (iMouse.x / iResolution.x) * pi * 2.0;
    float eyea2 = (iMouse.y / iResolution.y) * pi;

    vec3 eye = vec3(
        eyer * cos(eyea) * sin(eyea2),
        eyer * cos(eyea2),
        eyer * sin(eyea) * sin(eyea2));

    vec3 bhCenter = vec3(0, 0, 0);
    float bhRadius = 0.1f;

    // assume screen is x[-x/y, x/y] y[-1, 1] at z = 0
    float screenScale = 1.2f;
    vec3 front = normalize(bhCenter - eye);
    vec3 left = normalize(cross(vec3(0.0,1,0.2), front));
    vec3 up = normalize(cross(front, left));
    vec3 v = eye + front * eyer * 2.f + left * uv.x * screenScale + up * uv.y * screenScale;
    v = normalize(v);
    vec3 rayPt = eye;

    float dt = 0.02f;
    int totStep = 400;
    float dToBhFace = 0.0f;
    float hitted = 0.8f;

    // physic stuff
    // v = v + a * t
    // rayPt = rayPt + v * t
    // f = G * M * m / r^2
    // a = G * M / r^2
    float GM = 0.005f;
    vec3 clr = vec3(0, 0, 0);
    for (int i = 0; i < totStep; i++)
    {
        dToBhFace = sdfSphere(rayPt - bhCenter, bhRadius);
        hitted = myStep(0.f, dToBhFace);
        hitted = smoothstep(0.0, 0.666, dToBhFace);

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
        clr += col_star * 0.0012 * hitted / vec3(dot(vToBh, vToBh)); // y=1/(x^2)

        // dust disk
        float dr = length(vToBh.xz);
        float da = atan(vToBh.x,vToBh.z);

        // 1.8: ring denser
        vec2 disckParams = vec2(dr * 1.8 ,da * ((dr - bhRadius) * 0.01) + iTime*0.002 );
        disckParams *= vec2(10.0,20.0);
        vec3 diskClr = col_star * 0.5 * 
            max(0.0,texture(iChannel1,disckParams*vec2(0.1,0.5)).x+0.05);
        
        float diskStrength = -sdTorus((rayPt * vec3(1.0, 25.0, 1.0) - bhCenter), vec2(bhRadius * 5.0, bhRadius * 5.0));
        diskStrength = smoothstep(0., 1., diskStrength);

        clr += diskClr * diskStrength;
        //if (rayPt.z < -1.) break;
    }
    //clr += pow(texture(iChannel0, rayPt.xy / 6.0).rgb,vec3(3.0)) * hitted;
    fragColor = vec4(bgStar(rayPt.xy) * hitted + clr, 1.f);
}