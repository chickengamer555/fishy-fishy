shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// === SUBTLE WAVE PARAMETERS ===
uniform float wave_amplitude : hint_range(0.0, 0.01) = 0.003;
uniform float wave_frequency : hint_range(1.0, 50.0) = 12.0;
uniform float wave_speed : hint_range(0.1, 2.0) = 0.3;

// === SUBTLE CAUSTICS ===
uniform float caustic_strength : hint_range(0.0, 0.05) = 0.004;
uniform float caustic_speed : hint_range(0.1, 1.5) = 0.25;

// === TINT (USING BUILT-IN ALPHA) ===
uniform vec4 tint_color : source_color = vec4(0.4, 0.7, 0.9, 0.04);

void fragment() {
    vec2 uv = SCREEN_UV;

    // Very gentle wave distortion
    float wave = sin(uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
    uv.x += wave;

    // Very gentle caustics
    float caustics = sin((uv.x + TIME * caustic_speed) * 15.0) *
                     sin((uv.y + TIME * caustic_speed * 0.8) * 10.0) *
                     caustic_strength;
    uv += vec2(caustics * 0.2, caustics * 0.3);

    // Sample screen texture
    vec4 color = textureLod(SCREEN_TEXTURE, uv, 0.0);

    // Apply underwater tint using built-in alpha
    vec3 final_color = mix(color.rgb, tint_color.rgb, tint_color.a);

    COLOR = vec4(final_color, color.a);
}
