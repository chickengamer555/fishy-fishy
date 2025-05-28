shader_type canvas_item;

// === FISH TEXTURES ===
uniform sampler2D fish_texture_1 : source_color;
uniform sampler2D fish_texture_2 : source_color;
uniform sampler2D fish_texture_3 : source_color;
uniform sampler2D fish_texture_4 : source_color;
uniform sampler2D fish_texture_5 : source_color;

// === FISH MOVEMENT SETTINGS ===
uniform float fish_speed_1 : hint_range(0.1, 5.0) = 1.0;
uniform float fish_speed_2 : hint_range(0.1, 5.0) = 1.5;
uniform float fish_speed_3 : hint_range(0.1, 5.0) = 0.8;
uniform float fish_speed_4 : hint_range(0.1, 5.0) = 2.0;
uniform float fish_speed_5 : hint_range(0.1, 5.0) = 1.2;

// === FISH SIZE SETTINGS ===
uniform float fish_size_1 : hint_range(0.1, 2.0) = 0.3;
uniform float fish_size_2 : hint_range(0.1, 2.0) = 0.4;
uniform float fish_size_3 : hint_range(0.1, 2.0) = 0.2;
uniform float fish_size_4 : hint_range(0.1, 2.0) = 0.5;
uniform float fish_size_5 : hint_range(0.1, 2.0) = 0.35;

// === FISH SPAWN SETTINGS ===
uniform float fish_frequency_1 : hint_range(0.1, 10.0) = 3.0;
uniform float fish_frequency_2 : hint_range(0.1, 10.0) = 4.5;
uniform float fish_frequency_3 : hint_range(0.1, 10.0) = 2.8;
uniform float fish_frequency_4 : hint_range(0.1, 10.0) = 5.2;
uniform float fish_frequency_5 : hint_range(0.1, 10.0) = 3.7;

// === FISH DIRECTION SETTINGS ===
uniform bool fish_1_left_to_right = true;
uniform bool fish_2_left_to_right = false;
uniform bool fish_3_left_to_right = true;
uniform bool fish_4_left_to_right = false;
uniform bool fish_5_left_to_right = true;

// === FISH VERTICAL POSITION ===
uniform float fish_1_y_pos : hint_range(0.0, 1.0) = 0.3;
uniform float fish_2_y_pos : hint_range(0.0, 1.0) = 0.6;
uniform float fish_3_y_pos : hint_range(0.0, 1.0) = 0.2;
uniform float fish_4_y_pos : hint_range(0.0, 1.0) = 0.8;
uniform float fish_5_y_pos : hint_range(0.0, 1.0) = 0.5;

// === GLOBAL SETTINGS ===
uniform float overall_fish_alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool enable_fish_1 = true;
uniform bool enable_fish_2 = true;
uniform bool enable_fish_3 = true;
uniform bool enable_fish_4 = true;
uniform bool enable_fish_5 = true;

// Random function
float random(float seed) {
    return fract(sin(seed * 12.9898) * 43758.5453);
}

// Fish animation function
vec4 animate_fish(sampler2D fish_tex, vec2 uv, float time, float speed, float size, 
                  float frequency, bool left_to_right, float y_position, float fish_id) {
    
    // Calculate fish cycle timing
    float cycle_time = time * frequency;
    float cycle_progress = fract(cycle_time);
    
    // Add randomness to spawn timing based on fish_id
    float spawn_offset = random(fish_id * 123.456) * 2.0;
    cycle_progress = fract(cycle_progress + spawn_offset);
    
    // Fish position calculation
    float fish_x;
    if (left_to_right) {
        fish_x = -0.2 + cycle_progress * 1.4; // Move from left (-0.2) to right (1.2)
    } else {
        fish_x = 1.2 - cycle_progress * 1.4; // Move from right (1.2) to left (-0.2)
    }
    
    // Add slight vertical bobbing
    float bob_offset = sin(time * speed * 3.0 + fish_id * 2.0) * 0.05;
    float fish_y = y_position + bob_offset;
    
    // Calculate fish bounds
    vec2 fish_center = vec2(fish_x, fish_y);
    vec2 fish_half_size = vec2(size * 0.5, size * 0.3); // Fish are wider than tall
    
    // Check if current pixel is within fish bounds
    if (uv.x >= fish_center.x - fish_half_size.x && uv.x <= fish_center.x + fish_half_size.x &&
        uv.y >= fish_center.y - fish_half_size.y && uv.y <= fish_center.y + fish_half_size.y) {
        
        // Calculate UV coordinates for fish texture
        vec2 fish_uv = (uv - fish_center + fish_half_size) / (fish_half_size * 2.0);
        
        // Flip fish horizontally if moving right to left
        if (!left_to_right) {
            fish_uv.x = 1.0 - fish_uv.x;
        }
        
        // Sample fish texture
        vec4 fish_color = texture(fish_tex, fish_uv);
        
        // Fade in/out at edges of screen for smooth appearance/disappearance
        float edge_fade = 1.0;
        if (fish_x < 0.1) {
            edge_fade = smoothstep(0.0, 0.1, fish_x + 0.2);
        } else if (fish_x > 0.9) {
            edge_fade = smoothstep(1.2, 1.1, fish_x);
        }
        
        fish_color.a *= edge_fade;
        return fish_color;
    }
    
    return vec4(0.0, 0.0, 0.0, 0.0); // Fully transparent if not within fish bounds
}

void fragment() {
    vec2 uv = UV;
    vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0); // Start with transparent background
    
    // Animate each fish if enabled
    if (enable_fish_1) {
        vec4 fish1 = animate_fish(fish_texture_1, uv, TIME, fish_speed_1, fish_size_1, 
                                  fish_frequency_1, fish_1_left_to_right, fish_1_y_pos, 1.0);
        if (fish1.a > 0.0) {
            final_color = mix(final_color, fish1, fish1.a);
        }
    }
    
    if (enable_fish_2) {
        vec4 fish2 = animate_fish(fish_texture_2, uv, TIME, fish_speed_2, fish_size_2, 
                                  fish_frequency_2, fish_2_left_to_right, fish_2_y_pos, 2.0);
        if (fish2.a > 0.0) {
            final_color = mix(final_color, fish2, fish2.a);
        }
    }
    
    if (enable_fish_3) {
        vec4 fish3 = animate_fish(fish_texture_3, uv, TIME, fish_speed_3, fish_size_3, 
                                  fish_frequency_3, fish_3_left_to_right, fish_3_y_pos, 3.0);
        if (fish3.a > 0.0) {
            final_color = mix(final_color, fish3, fish3.a);
        }
    }
    
    if (enable_fish_4) {
        vec4 fish4 = animate_fish(fish_texture_4, uv, TIME, fish_speed_4, fish_size_4, 
                                  fish_frequency_4, fish_4_left_to_right, fish_4_y_pos, 4.0);
        if (fish4.a > 0.0) {
            final_color = mix(final_color, fish4, fish4.a);
        }
    }
    
    if (enable_fish_5) {
        vec4 fish5 = animate_fish(fish_texture_5, uv, TIME, fish_speed_5, fish_size_5, 
                                  fish_frequency_5, fish_5_left_to_right, fish_5_y_pos, 5.0);
        if (fish5.a > 0.0) {
            final_color = mix(final_color, fish5, fish5.a);
        }
    }
    
    // Apply overall alpha
    final_color.a *= overall_fish_alpha;
    
    COLOR = final_color;
} 