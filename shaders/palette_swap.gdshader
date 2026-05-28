shader_type canvas_item;

// Sin source_color — los valores se usan raw sin conversión gamma
uniform vec4 color_skin  = vec4(0.92, 0.62, 0.13, 1.0);
uniform vec4 color_hair  = vec4(0.71, 0.19, 0.13, 1.0);
uniform vec4 color_shirt = vec4(0.42, 0.43, 0.0,  1.0);

uniform vec4 new_skin  = vec4(0.92, 0.62, 0.13, 1.0);
uniform vec4 new_hair  = vec4(1,  1,  1,  1.0);
uniform vec4 new_shirt = vec4(0.22, 0.53, 0, 1.0);

uniform float threshold = 0.1;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    if (pixel.a < 0.01) discard;

    if (distance(pixel.rgb, color_skin.rgb)  < threshold) pixel.rgb = new_skin.rgb;
    else if (distance(pixel.rgb, color_hair.rgb)  < threshold) pixel.rgb = new_hair.rgb;
    else if (distance(pixel.rgb, color_shirt.rgb) < threshold) pixel.rgb = new_shirt.rgb;

    COLOR = pixel;
}