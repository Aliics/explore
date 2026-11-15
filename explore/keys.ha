use sdl3::{
	Scancode,
};

export type keys = struct {
	down: *[]Scancode,
	pressed: *[]Scancode,	
	released: *[]Scancode,	
};

export fn new_keys() *keys = {
	let keys = alloc(keys { 
		down = alloc([]: []Scancode)!,
		pressed = alloc([]: []Scancode)!,
		released = alloc([]: []Scancode)!,
	})!;
	return keys;
};

export fn free_keys(keys: *keys) void = {
	free(keys.down);
	free(keys);
};

fn is_key_down(keys: *keys, sc: Scancode) bool = {
	for (let k .. keys.down) {
		if (k == sc) {
			return true;
		};
	};
	return false;
};

export fn press_key(keys: *keys, sc: Scancode) void = {
	if (!is_key_down(keys, sc)) {
		append(keys.down, sc)!;
		append(keys.pressed, sc)!;
	};
};

export fn release_key(keys: *keys, sc: Scancode) void = {
	for (let i = 0z; i < len(keys.down); i += 1) {
		if (keys.down[i] == sc) {
			delete(keys.down[i]);
			append(keys.released, sc)!;
		};
	};	
};

export fn is_key_pressed(keys: *keys, sc: Scancode) bool = {
	for (let k .. keys.pressed) {
		if (k == sc) {
			return true;
		};
	};
	return false;
};

export fn is_key_released(keys: *keys, sc: Scancode) bool = {
	for (let k .. keys.released) {
		if (k == sc) {
			return true;
		};
	};
	return false;
};

export fn clear_pressed(keys: *keys) void = {
	for (let i = 0z; i < len(keys.pressed); i += 1) {
		delete(keys.pressed[i]);
	};
};

export fn clear_released(keys: *keys) void = {
	for (let i = 0z; i < len(keys.released); i += 1) {
		delete(keys.released[i]);
	};
};
