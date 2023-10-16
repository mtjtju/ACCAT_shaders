
vec3 black_hole_pos = vec3(0.0,0,1.5); 		//黑洞的位置
float event_horizon_radius = 0.3;		//黑洞的事件视界半径
float HitTest(vec3 p){
	return length(p) - event_horizon_radius;
}
vec3 GetBg(vec3 p)
{
    return smoothstep(vec3(0),vec3(1.),fract(p*1.));
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //映射到0~1之间
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv*2.  - 1.;	
    uv.x *= iResolution.x / iResolution.y;	
	vec3 eye = vec3(0.,0.,-2);    //eye or camera postion 相机位置
    vec3 sd = vec3(uv.x,uv.y,-1); //screen coord 屏幕坐标
    vec3 ray_dir = normalize( sd - eye);//ray direction 射线方向
    
    vec3 col = vec3(0.);
    
	float hitbh = 0.;
    
    const int maxStep = 400;//光线最大步进数
    float st = 0.;      
    vec3 p = sd;
    vec3 v = ray_dir;
    float dt = 0.01;
    float GM = 0.8;   
    vec3 cp = black_hole_pos + 2.*vec3(0.1*sin(iTime),sin(0.11*iTime),0.);
    for(int i = 0;i<maxStep;++i)
    {
       	//F = G * M * m / r^2;
    	//a = F/m
    	//v = v + a * dt;
    	//p = p + v * dt;
        p += v * dt;
        vec3 relP = cp - p;        
        float r2 = dot(relP,relP);
        vec3 a = GM/r2 * normalize(relP); //加速度的方向朝向黑洞，为relP
        v += a * dt;        
        float hit = HitTest(relP); //hit表示距物体的最小距离
		hitbh = step(hit,0.);   
        if(hitbh > 0.)break;
    }
    col = GetBg(p)*(1.-hitbh);
    fragColor = vec4(col,1.0);
}