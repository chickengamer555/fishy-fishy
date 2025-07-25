shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// === WAVE PARAMETERS ===
uniform float wave_amplitude : hint_range(0.0, 0.005) = 0.001;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float wave_speed : hint_range(0.1, 1.0) = 0.5;

// === TINT (USING BUILT-IN ALPHA) ===
uniform vec4 tint_color : source_color = vec4(0.4, 0.7, 0.9, 0.04);

void fragment() {
    vec2 uv = SCREEN_UV;

    // Very subtle wave distortion
    float wave = sin(uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
    uv.x += wave;

    vec4 color = textureLod(SCREEN_TEXTURE, uv, 0.0);

    // Apply underwater tint
    vec3 final_color = mix(color.rgb, tint_color.rgb, tint_color.a);

    COLOR = vec4(final_color, color.a);
}
