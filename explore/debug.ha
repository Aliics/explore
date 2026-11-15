use fmt;
use types::c;
use sdl3;
use strings;

def DEBUG_KEY = sdl3::Scancode::S_F3;

let debug = false;

export fn handle_debug_info(keys: *keys) void = {
	if (is_key_released(keys, DEBUG_KEY)) {
		debug = !debug;
	};	
};

export fn render_debug_info(
	render: *sdl3::Renderer,
	keys: *keys,
	pos: fpos,
) void = {
	if (!debug) return;

	sdl3::SetRenderDrawColor(render, 0, 0, 0, 255)!;
			
	const pos_debug = fmt::asprintf(
		"pos: {:.2f}, {:.2f}", 
		pos.x, pos.y,
	)!;
	defer free(pos_debug);
	
	sdl3::RenderDebugText(render, 0.0, 0.0, c::fromstr(pos_debug)!)!;

	let keys_down = alloc([]: []str)!;
	// strs here are on stack. Don't use strings::freeall.
	defer free(*keys_down); 
	for (let k .. keys.down) {
		let name = c::tostr(sdl3::GetScancodeName(k))!;
		append(keys_down, name)!;
	};

	const joined = strings::join(",", *keys_down...)!;
	defer free(joined);

	const keys_debug = fmt::asprintf("keys: {{{}}}", joined)!;
	defer free(keys_debug);

	sdl3::RenderDebugText(render, 0.0, 10.0, c::fromstr(keys_debug)!)!;
};
