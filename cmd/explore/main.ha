use explore::*;
use types::c;
use fmt;
use sdl3;

def WIDTH = 640;
def HEIGHT = 480;

def PLAYER_SIZE = 64;
def PLAYER_SPEED = 200.0;

fn load_bmp(path: str) *sdl3::Surface = {
	return match (sdl3::LoadBMP(c::nulstr(path))) {
	case let s: *sdl3::Surface => yield s;
	case let e: sdl3::error => 
		fmt::fatalf("Could not load {}: {}", path, e); 
	};
};

fn create_texture_from_surface(
	render: *sdl3::Renderer, 
	surf: *sdl3::Surface,
) *sdl3::Texture = {
	const tex = 
		match (sdl3::CreateTextureFromSurface(render, surf)) {
		case let t: *sdl3::Texture => yield t;
		case let e: sdl3::error =>
			fmt::fatalf("Could not create texture: {}", e);
		};

	sdl3::SetTextureScaleMode(tex, sdl3::ScaleMode::NEAREST)!;

	return tex;
};

export fn main() void = {
	sdl3::Init(sdl3::InitFlags::VIDEO)!;
	defer sdl3::Quit();

	const win = sdl3::CreateWindow(
		c::nulstr("explore\0"), 
		WIDTH, HEIGHT, 
		0,
	)!;
	defer sdl3::DestroyWindow(win);

	const render = sdl3::CreateRenderer(win, null)!;
	defer sdl3::DestroyRenderer(render);

	sdl3::SetRenderVSync(render, 1)!;

	const atlas_surf = load_bmp("rabbit.bmp\0");
	const atlas_tex = create_texture_from_surface(render, atlas_surf);
	defer sdl3::DestroyTexture(atlas_tex);

	const atlas_p = dim { w = 3, h = 3 };
	const atlas_s = dim {
		w = atlas_surf.w,
		h = atlas_surf.h, 
	};

	sdl3::DestroySurface(atlas_surf);
		
	const idle = asprite {
		time = 1_000,
		
		atlas_tex = atlas_tex,
		atlas_p   = atlas_p,
		atlas_s   = atlas_s,

		pposes = [
			pos {
				x = 0, ...
			},
			pos {
				x = 1, ...
			},
		],
	};

	let curr_asprite = &idle;

	let pos = fpos { ... };

	let keys = new_keys();
	defer free_keys(keys);

	let prev = sdl3::GetTicksNS();

	let running = true;
	for (running) {
		const dt = (sdl3::GetTicksNS() - prev): f32 / 1_000_000_000.0;
		prev = sdl3::GetTicksNS();

		const ev = sdl3::Event { ... };
		for (sdl3::PollEvent(&ev)) {
			switch (ev.event_type) {
				case sdl3::EventType::QUIT =>
				running = false;
				continue;
			case sdl3::EventType::KEY_DOWN =>
				const sc = ev.key.scancode;
				press_key(keys, ev.key.scancode);		
			case sdl3::EventType::KEY_UP =>
				release_key(keys, ev.key.scancode);
			case => void;
			};
		};

		defer clear_pressed(keys);
		defer clear_released(keys);

		{
			let mov = fpos { ... };
			for (let k .. keys.down) {
				switch (k) {
				case sdl3::Scancode::S_W => mov.y -= 1.0;
				case sdl3::Scancode::S_S => mov.y += 1.0;
				case sdl3::Scancode::S_A => mov.x -= 1.0;
				case sdl3::Scancode::S_D => mov.x += 1.0;
				case => void;
				};
			};

			pos.x += mov.x * dt * PLAYER_SPEED;
			pos.y += mov.y * dt * PLAYER_SPEED;
		};
		
		handle_debug_info(keys);
		
		sdl3::SetRenderDrawColor(render, 255, 50, 50, 255)!;
		sdl3::RenderClear(render)!;

		render_asprite(
			render, 
			*curr_asprite, 
			dim { w = PLAYER_SIZE, h = PLAYER_SIZE },
			pos,
		);

		render_debug_info(render, keys, pos);
		
		sdl3::RenderPresent(render)!;
	};
};
