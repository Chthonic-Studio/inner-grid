shader_type canvas_item;

// =============================
// original:https://www.shadertoy.com/view/MsXGRf
//adaptation: GerardoLCDF
// =============================
uniform sampler2D channel0 : filter_nearest; 

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    
    vec2 size = vec2(256.0); 
    
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec2 rg = texture( channel0, (uv + 0.5) / size ).yx;
    
    return mix( rg.x, rg.y, f.z );
}

vec4 map( in vec3 p )
{
    vec3 r = p; p.y += 0.6;
    
    p = -4.0 * p / dot(p, p);
    

    float an = -1.0 * sin(0.1 * TIME + length(p.xz) + p.y);
    float co = cos(an);
    float si = sin(an);
    p.xz = mat2(vec2(co, si), vec2(-si, co)) * p.xz;
    
    p.xz += -1.0 + 2.0 * noise( p * 1.1 );

    float f;
    vec3 q = p * 0.85 - vec3(0.0, 1.0, 0.0) * TIME * 0.12;
    
    f  = 0.50000 * noise( q ); q = q * 2.02 - vec3(0.0, 1.0, 0.0) * TIME * 0.12;
    f += 0.25000 * noise( q ); q = q * 2.03 - vec3(0.0, 1.0, 0.0) * TIME * 0.12;
    f += 0.12500 * noise( q ); q = q * 2.01 - vec3(0.0, 1.0, 0.0) * TIME * 0.12;
    f += 0.06250 * noise( q ); q = q * 2.02 - vec3(0.0, 1.0, 0.0) * TIME * 0.12;
    f += 0.04000 * noise( q ); q = q * 2.00 - vec3(0.0, 1.0, 0.0) * TIME * 0.12;
    
    float den = clamp( (-r.y - 0.6 + 4.0 * f) * 1.2, 0.0, 1.0 );

    vec3 col = 1.2 * mix( vec3(1.0, 0.8, 0.6), 0.9 * vec3(0.3, 0.2, 0.35), den ) ;
    col += 0.05 * sin(0.05 * q);
    col *= 1.0 - 0.8 * smoothstep(0.6, 1.0, sin(0.7 * q.x) * sin(0.7 * q.y) * sin(0.7 * q.z)) * vec3(0.6, 1.0, 0.8);
    col *= 1.0 + 1.0 * smoothstep(0.5, 1.0, 1.0 - length( (fract(q.xz * 0.12) - 0.5) / 0.5 )) * vec3(1.0, 0.9, 0.8);
    col = mix( vec3(0.8, 0.32, 0.2), col, clamp( (r.y + 0.1) / 1.5, 0.0, 1.0 ) );
    
    return vec4( col, den );
}

void fragment()
{
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 q = FRAGCOORD.xy / screen_size; 

    vec2 p = (-1.0 + 2.0 * q) * vec2( screen_size.x / screen_size.y, 1.0 );

    vec2 mo = SCREEN_UV;

    float an = -0.07 * TIME + 3.0 * mo.x;
    vec3 ro = 4.5 * normalize(vec3(cos(an), 0.5, sin(an)));
    ro.y += 1.0;
    vec3 ta = vec3(0.0, 0.5, 0.0);
    float cr = -0.4 * cos(0.02 * TIME);
    
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross( vec3(sin(cr), cos(cr), 0.0), ww ) );
    vec3 vv = normalize( cross(ww, uu) );
    vec3 rd = normalize( p.x * uu + p.y * vv + 2.5 * ww );

    vec4 sum = vec4( 0.0 );
    vec3 bg = vec3(0.4, 0.5, 0.5) * 1.3;
    float t = 0.05 * fract( 10.5421 * dot(vec2(0.0149451, 0.038921), FRAGCOORD.xy) );
    const int MAX_STEPS = 128; 
    for( int i = 0; i < MAX_STEPS; i++ )
    {
        if( sum.a > 0.99 ) break;
        
        vec3 pos = ro + t * rd;
        vec4 col = map( pos );
        
        col.a *= 0.5;
        col.rgb = mix( bg, col.rgb, exp(-0.002 * t * t * t) ) * col.a;
        
        sum = sum + col * (1.0 - sum.a);
        
        t += 0.05;
    }
    
    vec3 final_col = clamp( mix( bg, sum.xyz / (0.001 + sum.w), sum.w ), 0.0, 1.0 );
    final_col = final_col * final_col * (3.0 - 2.0 * final_col) * 1.4 - 0.4;
    final_col *= 0.25 + 0.75 * pow( 16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1 );
    
    COLOR = vec4( final_col, 1.0 );
}