shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// 🌊 Wave distortion
uniform float wave_amplitude = 0.005;
uniform float wave_frequency = 60.0;
uniform float wave_speed = 1.0;

// 💡 Light caustics shimmer
uniform float caustic_strength = 0.003;
uniform float caustic_speed = 1.0;

// 🎨 Tint overlay (subtle blue)
uniform vec4 tint_color : source_color = vec4(0.0, 0.1, 0.3, 0.1);

void fragment() {
    vec2 uv = SCREEN_UV;

    // 💦 Horizontal wave distortion using built-in TIME
    float wave = sin(uv.y * wave_frequency + TIME * wave_speed);
    uv.x += wave * wave_amplitude;

    // 🌟 Light caustics shimmer
    float caustics = sin((uv.x + TIME * caustic_speed) * 40.0) *
                     sin((uv.y + TIME * caustic_speed * 0.7) * 30.0) *
                     caustic_strength;
    uv += vec2(caustics, caustics);

    // 🖼️ Sample screen texture with distorted UVs
    vec4 color = texture(SCREEN_TEXTURE, uv);

    // 🎨 Apply subtle underwater tint
    color.rgb = mix(color.rgb, tint_color.rgb, tint_color.a);

    COLOR = color;
}
