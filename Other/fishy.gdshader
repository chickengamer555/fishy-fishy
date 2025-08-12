shader_type canvas_item;

uniform sampler2D fish_texture_1 : filter_nearest;
uniform sampler2D fish_texture_2 : filter_nearest;
uniform sampler2D fish_texture_3 : filter_nearest;
uniform sampler2D fish_texture_4 : filter_nearest;
uniform sampler2D fish_texture_5 : filter_nearest;
uniform sampler2D fish_texture_6 : filter_nearest;
uniform sampler2D fish_texture_7 : filter_nearest;
uniform sampler2D fish_texture_8 : filter_nearest;
uniform sampler2D fish_texture_9 : filter_nearest;
uniform sampler2D fish_texture_10 : filter_nearest;

uniform float min_speed : hint_range(0.05, 1.0) = 0.15;
uniform float max_speed : hint_range(0.2, 2.0) = 0.6;
uniform float fish_scale : hint_range(1.0, 20.0) = 10.0;
uniform float spawn_delay : hint_range(0.0, 10.0) = 4.0;

uniform bool flip_fish_1 = true;
uniform bool flip_fish_2 = true;
uniform bool flip_fish_3 = true;
uniform bool flip_fish_4 = true;
uniform bool flip_fish_5 = true;
uniform bool flip_fish_6 = true;
uniform bool flip_fish_7 = true;
uniform bool flip_fish_8 = true;
uniform bool flip_fish_9 = true;
uniform bool flip_fish_10 = true;

uniform vec4 background_color : source_color = vec4(0.1, 0.3, 0.5, 1.0);

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
}

void fragment() {
    vec2 uv = UV;
    vec4 final_color = background_color;
    
    // Create 10 fish with staggered appearance
    for (int i = 0; i < 10; i++) {
        float fish_id = float(i);
        
        // Randomized fish parameters
        float fish_speed = min_speed + random(vec2(fish_id, 1.0)) * (max_speed - min_speed);
        float cycle_duration = 8.0 / fish_speed; // Time to cross screen
        float respawn_delay = 3.0 + random(vec2(fish_id, 4.0)) * 3.0; // Respawn delay (3-6 seconds)
        
        // Calculate current cycle time
        float total_cycle_time = cycle_duration + respawn_delay;
        float cycle_time = mod(TIME + fish_id * spawn_delay, total_cycle_time);
        
        // Skip if in respawn delay period
        if (cycle_time > cycle_duration) continue;
        
        // Randomize starting direction each cycle (changes over time)
        float cycle_number = floor((TIME + fish_id * spawn_delay) / total_cycle_time);
        bool starts_from_left = random(vec2(fish_id, cycle_number * 13.7)) > 0.5;
        float progress = cycle_time / cycle_duration;
        
        // Randomize starting vertical position each cycle
        float random_y_offset = random(vec2(fish_id, cycle_number * 7.3)) * 0.6;
        
        // Linear horizontal movement across screen
        vec2 fish_pos;
        if (starts_from_left) {
            fish_pos.x = -0.15 + progress * 1.3; // Left to right
        } else {
            fish_pos.x = 1.15 - progress * 1.3; // Right to left
        }
        
        // Randomized vertical position with gentle bobbing
        float base_y = 0.15 + random_y_offset;
        fish_pos.y = base_y + 0.05 * sin(TIME * 2.0 + fish_id * 2.0);
        
        // Fish size with some variation
        float size = fish_scale / 100.0 * (0.8 + 0.4 * random(vec2(fish_id, 3.0)));
        
        // Determine actual movement direction for flipping
        bool moving_right = starts_from_left;
        
        // Get individual flip setting for this fish
        bool should_flip = false;
        if (i == 0) should_flip = flip_fish_1;
        else if (i == 1) should_flip = flip_fish_2;
        else if (i == 2) should_flip = flip_fish_3;
        else if (i == 3) should_flip = flip_fish_4;
        else if (i == 4) should_flip = flip_fish_5;
        else if (i == 5) should_flip = flip_fish_6;
        else if (i == 6) should_flip = flip_fish_7;
        else if (i == 7) should_flip = flip_fish_8;
        else if (i == 8) should_flip = flip_fish_9;
        else if (i == 9) should_flip = flip_fish_10;
        
        // Transform UV to fish local space
        vec2 fish_uv = uv - fish_pos;
        
        // Flip horizontally based on movement direction and individual setting
        // If should_flip is true, fish faces right by default, flip when moving left
        // If should_flip is false, fish faces left by default, flip when moving right
        bool needs_flip = (should_flip && !moving_right) || (!should_flip && moving_right);
        if (needs_flip) {
            fish_uv.x = -fish_uv.x;
        }
        
        // Scale and center
        fish_uv = fish_uv / size + 0.5;
        
        // Only sample if within texture bounds
        if (fish_uv.x >= 0.0 && fish_uv.x <= 1.0 && fish_uv.y >= 0.0 && fish_uv.y <= 1.0) {
            vec4 fish_color = vec4(0.0);
            
            // Sample appropriate fish texture
            if (i == 0) fish_color = texture(fish_texture_1, fish_uv);
            else if (i == 1) fish_color = texture(fish_texture_2, fish_uv);
            else if (i == 2) fish_color = texture(fish_texture_3, fish_uv);
            else if (i == 3) fish_color = texture(fish_texture_4, fish_uv);
            else if (i == 4) fish_color = texture(fish_texture_5, fish_uv);
            else if (i == 5) fish_color = texture(fish_texture_6, fish_uv);
            else if (i == 6) fish_color = texture(fish_texture_7, fish_uv);
            else if (i == 7) fish_color = texture(fish_texture_8, fish_uv);
            else if (i == 8) fish_color = texture(fish_texture_9, fish_uv);
            else if (i == 9) fish_color = texture(fish_texture_10, fish_uv);
            
            // Apply smooth alpha blending
            final_color = mix(final_color, fish_color, fish_color.a);
        }
    }
    
    COLOR = final_color;
}