shader_type canvas_item;

// === FISH TEXTURES (Different fish images to randomly choose from) ===
uniform sampler2D fish_image_1 : source_color;
uniform sampler2D fish_image_2 : source_color;
uniform sampler2D fish_image_3 : source_color;
uniform sampler2D fish_image_4 : source_color;
uniform sampler2D fish_image_5 : source_color;

// === FISH SETTINGS ===
uniform int fish_amount : hint_range(1, 15) = 8;
uniform float base_fish_speed : hint_range(0.1, 3.0) = 0.8;
uniform float fish_size : hint_range(0.1, 1.5) = 0.3;
uniform float overall_fish_alpha : hint_range(0.0, 1.0) = 1.0;

// === SWIMMING BEHAVIOR ===
uniform float swimming_curve_strength : hint_range(0.0, 2.0) = 0.8;
uniform float tail_wag_speed : hint_range(0.5, 5.0) = 3.0;
uniform float schooling_strength : hint_range(0.0, 1.0) = 0.4;
uniform float speed_variation : hint_range(0.0, 1.0) = 0.6;

// === SPAWN SETTINGS ===
uniform float spawn_rate : hint_range(0.1, 3.0) = 1.2;
uniform bool enable_vertical_spawn = true;
uniform bool enable_horizontal_spawn = true;

// Random function
float random(float seed) {
    return fract(sin(seed * 12.9898) * 43758.5453);
}

// Smooth random for more natural movement
float smooth_random(float seed) {
    return (random(seed) - 0.5) * 2.0;
}

// Get random fish texture based on fish ID
vec4 sample_random_fish(vec2 uv, float fish_id) {
    float texture_choice = random(fish_id * 456.789);
    
    if (texture_choice < 0.2) {
        return texture(fish_image_1, uv);
    } else if (texture_choice < 0.4) {
        return texture(fish_image_2, uv);
    } else if (texture_choice < 0.6) {
        return texture(fish_image_3, uv);
    } else if (texture_choice < 0.8) {
        return texture(fish_image_4, uv);
    } else {
        return texture(fish_image_5, uv);
    }
}

// Generate swimming path with curves and natural movement
vec2 get_swimming_position(float fish_id, float time, float progress) {
    // Base path from spawn to target
    vec2 spawn_point = vec2(-0.3, 0.2 + random(fish_id * 234.567) * 0.6);
    vec2 target_point = vec2(1.3, 0.2 + random(fish_id * 345.678) * 0.6);
    
    // Randomize spawn side
    float spawn_choice = random(fish_id * 789.123);
    if (spawn_choice > 0.5) {
        spawn_point = vec2(1.3, 0.2 + random(fish_id * 456.789) * 0.6);
        target_point = vec2(-0.3, 0.2 + random(fish_id * 567.890) * 0.6);
    }
    
    // Base linear movement
    vec2 base_pos = mix(spawn_point, target_point, progress);
    
    // Add swimming curves (S-shaped movement)
    float curve_offset_x = sin(progress * 3.14159 * 2.0 + fish_id) * swimming_curve_strength * 0.1;
    float curve_offset_y = sin(progress * 3.14159 * 4.0 + fish_id * 2.0) * swimming_curve_strength * 0.05;
    
    // Add continuous swimming motion (like tail wagging affects whole body)
    float swim_wave = sin(time * tail_wag_speed + fish_id * 3.14159);
    float swim_offset_x = swim_wave * 0.02;
    float swim_offset_y = swim_wave * 0.01;
    
    // Add schooling behavior (fish influence each other)
    vec2 schooling_offset = vec2(0.0);
    for (int i = 0; i < fish_amount; i++) {
        if (float(i) + 1.0 != fish_id) {
            float other_fish_id = float(i) + 1.0;
            float other_progress = fract(time * spawn_rate * (0.8 + random(other_fish_id) * 0.4) + other_fish_id * 1.5);
            
            // Get other fish position
            vec2 other_spawn = vec2(-0.3, 0.2 + random(other_fish_id * 234.567) * 0.6);
            vec2 other_target = vec2(1.3, 0.2 + random(other_fish_id * 345.678) * 0.6);
            if (random(other_fish_id * 789.123) > 0.5) {
                other_spawn = vec2(1.3, 0.2 + random(other_fish_id * 456.789) * 0.6);
                other_target = vec2(-0.3, 0.2 + random(other_fish_id * 567.890) * 0.6);
            }
            vec2 other_pos = mix(other_spawn, other_target, other_progress);
            
            // Calculate influence
            float distance = length(base_pos - other_pos);
            if (distance < 0.2 && distance > 0.01) {
                vec2 influence = normalize(base_pos - other_pos) * (0.2 - distance) * schooling_strength * 0.1;
                schooling_offset += influence;
            }
        }
    }
    
    return base_pos + vec2(curve_offset_x + swim_offset_x, curve_offset_y + swim_offset_y) + schooling_offset;
}

// Calculate fish rotation based on movement direction
float get_fish_rotation(vec2 current_pos, vec2 previous_pos) {
    vec2 direction = current_pos - previous_pos;
    if (length(direction) > 0.001) {
        return atan(direction.y, direction.x);
    }
    return 0.0;
}

// Rotate UV coordinates
vec2 rotate_uv(vec2 uv, float angle) {
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    vec2 centered_uv = uv - 0.5;
    return vec2(
        centered_uv.x * cos_angle - centered_uv.y * sin_angle,
        centered_uv.x * sin_angle + centered_uv.y * cos_angle
    ) + 0.5;
}

// Fish animation function with realistic swimming
vec4 animate_fish(vec2 uv, float time, float fish_id) {
    
    // Individual fish speed variation
    float fish_speed_multiplier = 0.8 + random(fish_id * 123.456) * speed_variation;
    float adjusted_spawn_rate = spawn_rate * fish_speed_multiplier;
    
    // Calculate fish cycle timing with individual offset
    float cycle_time = time * adjusted_spawn_rate + fish_id * 1.5;
    float cycle_progress = fract(cycle_time);
    
    // Get current swimming position
    vec2 fish_pos = get_swimming_position(fish_id, time, cycle_progress);
    
    // Get previous position for rotation calculation
    float prev_progress = fract(cycle_time - 0.01);
    vec2 prev_pos = get_swimming_position(fish_id, time - 0.01, prev_progress);
    
    // Calculate fish rotation
    float fish_rotation = get_fish_rotation(fish_pos, prev_pos);
    
    // Add subtle size variation based on distance (depth effect)
    float depth_scale = 0.8 + 0.4 * sin(cycle_progress * 3.14159);
    float current_fish_size = fish_size * depth_scale;
    
    // Calculate fish bounds
    vec2 fish_half_size = vec2(current_fish_size * 0.5, current_fish_size * 0.3);
    
    // Check if current pixel is within fish bounds
    if (uv.x >= fish_pos.x - fish_half_size.x && uv.x <= fish_pos.x + fish_half_size.x &&
        uv.y >= fish_pos.y - fish_half_size.y && uv.y <= fish_pos.y + fish_half_size.y) {
        
        // Calculate UV coordinates for fish texture
        vec2 fish_uv = (uv - fish_pos + fish_half_size) / (fish_half_size * 2.0);
        
        // Apply rotation to fish UV
        fish_uv = rotate_uv(fish_uv, fish_rotation);
        
        // Clamp UV to prevent sampling outside texture
        if (fish_uv.x >= 0.0 && fish_uv.x <= 1.0 && fish_uv.y >= 0.0 && fish_uv.y <= 1.0) {
            
            // Sample random fish texture
            vec4 fish_color = sample_random_fish(fish_uv, fish_id);
            
            // Add swimming animation to alpha (breathing effect)
            float breathing = 0.9 + 0.1 * sin(time * tail_wag_speed * 2.0 + fish_id);
            fish_color.a *= breathing;
            
            // Fade in/out at edges for smooth appearance/disappearance
            float edge_fade = 1.0;
            float dist_to_edge = min(min(fish_pos.x + 0.3, 1.3 - fish_pos.x), 
                                    min(fish_pos.y + 0.1, 0.9 - fish_pos.y));
            if (dist_to_edge < 0.15) {
                edge_fade = smoothstep(0.0, 0.15, dist_to_edge);
            }
            
            fish_color.a *= edge_fade * depth_scale;
            return fish_color;
        }
    }
    
    return vec4(0.0, 0.0, 0.0, 0.0); // Transparent if not within fish bounds
}

void fragment() {
    vec2 uv = UV;
    vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0); // Start with transparent background
    
    // Animate the specified number of fish
    for (int i = 0; i < fish_amount; i++) {
        float fish_id = float(i) + 1.0;
        vec4 fish_color = animate_fish(uv, TIME, fish_id);
        
        if (fish_color.a > 0.0) {
            final_color = mix(final_color, fish_color, fish_color.a);
        }
    }
    
    // Apply overall alpha
    final_color.a *= overall_fish_alpha;
    
    COLOR = final_color;
} 