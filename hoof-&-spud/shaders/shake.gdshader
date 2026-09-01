shader_type canvas_item;

// Sways the top of a sprite while leaving its base planted, so a struck tree
// wobbles from the trunk up. Driven by ShakeComponent, which decays
// shake_strength back to zero after each hit.

// Current sway amount in pixels at the very top of the sprite. 0 = at rest.
uniform float shake_strength : hint_range(0.0, 8.0) = 0.0;

// Oscillations per second.
uniform float speed : hint_range(0.0, 60.0) = 26.0;

// How sharply the sway falls off toward the base. 1 is linear, higher values
// keep more of the trunk still.
uniform float falloff : hint_range(0.5, 4.0) = 1.6;

void vertex() {
	// UV.y is 0 at the top of the sprite and 1 at the bottom, so this is 1 at
	// the crown and 0 at the base.
	float height = pow(1.0 - UV.y, falloff);
	VERTEX.x += sin(TIME * speed) * shake_strength * height;
}
