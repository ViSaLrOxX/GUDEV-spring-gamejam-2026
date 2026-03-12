shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float aberration_amount = 0.0006; 

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Balanced Chromatic Aberration
    vec4 color;
    color.r = texture(SCREEN_TEXTURE, uv + vec2(aberration_amount, 0.0)).r;
    color.g = texture(SCREEN_TEXTURE, uv).g;
    color.b = texture(SCREEN_TEXTURE, uv - vec2(aberration_amount, 0.0)).b;
    color.a = 1.0;
    
    // Slight contrast boost to pop neon
    color.rgb = mix(vec3(0.5), color.rgb, 1.15);
    
    COLOR = color;
}
