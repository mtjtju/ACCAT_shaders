// https://www.shadertoy.com/view/llSGRG
// My edit of https://www.shadertoy.com/view/XdjXDy
// So yeah, thank bloodnok for this brilliant shader, not me
// The original one just had some visual problems which I corrected
// Or I should probably say; 'corrected' to fit my own taste
// So don't praise me, praise bloodnok
#iChannel0 "file://./blackhole.png"
#iChannel1 "file://./noise.png"
const float pi = 3.1415927;

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

// t[radius, sub radius]
// p: position
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 pp = fragCoord.xy/iResolution.xy;  // xy to [0,1]
	pp = -1.0 + 2.0*pp;                     // xy to [-1, 1]
	pp.x *= iResolution.x/iResolution.y;    // x to [-w/h, w/h]

	vec3 lookAt = vec3(0.0, -0.1, 0.0);
    
    float eyer = 2.0;
    float eyea = (iMouse.x / iResolution.x) * pi * 2.0;
    float eyea2 = ((iMouse.y / iResolution.y)-0.24) * pi * 2.0;
    
	vec3 ro = vec3(
        eyer * cos(eyea) * sin(eyea2),
       eyer * cos(eyea2),
        eyer * sin(eyea) * sin(eyea2)); //camera position
    
    
	vec3 front = normalize(lookAt - ro);
	vec3 left = normalize(cross(normalize(vec3(0.0,1,-0.1)), front));
	vec3 up = normalize(cross(front, left));
	vec3 rd = normalize(front*1.5 + left*pp.x + up*pp.y); // rect vector
    
    
    vec3 bh = vec3(0.0,0.0,0.0);
    float bhr = 0.1;
    float bhmass = 5.0;
   	bhmass *= 0.001; // premul G
    
    vec3 p = ro;
    vec3 pv = rd;
    float dt = 0.02;
    
    vec3 col = vec3(0.0);
    
    float noncaptured = 1.0;
    
    vec3 c1 = vec3(0.5,0.46,0.4);
    vec3 c2 = vec3(1.0,0.8,0.6);
    
    
    for(float t=0.0;t<1.0;t+=0.005)
    {
        p += pv * dt * noncaptured; // cur ray pos
        
        // gravity
        // ray end to bh center
        vec3 bhv = bh - p; 
        float r = dot(bhv,bhv);
        // ray dir += 1 * acceleration
        pv += normalize(bhv) * ((bhmass) / r); 
        
        // map sdSphere smoothly to [0, 0.666]
        noncaptured = smoothstep(0.0, 0.666, sdSphere(p-bh,bhr)); 
        
        // Texture for the accretion disc
        float dr = length(bhv.xz);
        float da = atan(bhv.x,bhv.z);
        // vec2[distance from p to bh center, sum of a var linear with arc length and a incre(t)]
        vec2 ra = vec2(dr,da * (0.01 + (dr - bhr)*0.002) + 2.0 * pi + iTime*0.005 );
        ra *= vec2(10.0,20.0);
        
        // mix(a, b, ratio)  res = a + (b-a) * ratio
        vec3 dcol = mix(
          c2,
          c1,
          pow(length(bhv)-bhr,2.0)) * // farther bigger
            max(0.0,texture(iChannel1,ra*vec2(0.1,0.5)).r+0.05) * // texture color
            (4.0 / ((0.001+(length(bhv) - bhr)*50.0) ));          // nearer bigger
        
        // vec3(1.0,25.0,1.0): scale torus, y /= 25
        col += max(
          vec3(0.0),
          dcol * smoothstep(0.0, 1.0, 
          -sdTorus( (p * vec3(1.0,25.0,1.0)) - bh, vec2(0.8,0.99))) * noncaptured);
        
        //col += dcol * (1.0/dr) * noncaptured * 0.001;
        
        // Glow
        col += vec3(1.0,0.9,0.85) * (1.0/vec3(dot(bhv,bhv))) * 0.0026 * noncaptured; // y=1/(x^2)
        
    }
    
    // BG
    // col += pow(texture(iChannel0, pv).rgb,vec3(3.0)) * noncaptured;
    
    // FInal color
    fragColor = vec4(col,1.0);
}