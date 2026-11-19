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

fn bbox_intersect(a: sdl3::FRect, b: sdl3::FRect) bool = {
	const at = a.y;
	const ab = at + a.h;
	const al = a.x;
	const ar = al + a.w;
	const bt = b.y;
	const bb = bt + b.h;
	const bl = b.x;
	const br = bl + b.w;
	return 
		// horizontal trapped
		(at < bt && ab > bt || at < bb && ab > bb) &&
		// vertical trapped
		(al < bl && ar > bl || al < br && ar > br) || 
		// horizontal trapped
		(bt < at && bb > at || bt < ab && bb > ab) &&
		// vertical trapped
		(bl < al && br > al || bl < ar && br > ar);
};

type sprite = struct {
	pos: pos,
	
	sprite_t: *sdl3::Texture,
	sprite_s: dim,
};

type obstacle = struct {
	sprite,
	coll: bool,
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

	const rock_surf = load_bmp("rock-pile.bmp\0");
	const rock_tex = create_texture_from_surface(render, rock_surf);
	defer sdl3::DestroyTexture(rock_tex);	

	sdl3::DestroySurface(rock_surf);	
	
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

	const obstacles = [
		obstacle {
			pos = pos { x = 128, y = 128 },
			
			sprite_t = rock_tex,
			sprite_s = dim { w = 128, h = 128 },

			coll = true,
		},

		obstacle {
			pos = pos { x = 312, y = 256 },
			
			sprite_t = rock_tex,
			sprite_s = dim { w = 64, h = 64 },

			coll = true,
		},
	];

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

			const next = fpos {
				x = pos.x + mov.x * dt * PLAYER_SPEED,
				y = pos.y + mov.y * dt * PLAYER_SPEED,	
			};

			const pbbox = sdl3::FRect {
				w = PLAYER_SIZE: f32, h = PLAYER_SIZE: f32,
				x = next.x, y = next.y,
			};
			const next_locks = {
				let locks = false;
				for (let ob .. obstacles) {
					const obbox = sdl3::FRect {
						w = ob.sprite_s.w: f32, 
						h = ob.sprite_s.h: f32,
						x = ob.pos.x: f32,
						y = ob.pos.y: f32,	
					};
					if (bbox_intersect(pbbox, obbox)) {
						locks = true;
						break;
					};
				};
				yield locks;
			};

			if (!next_locks) {
				pos = next;
			};
		};
		
		handle_debug_info(keys);
		
		sdl3::SetRenderDrawColor(render, 50, 215, 75, 255)!;
		sdl3::RenderClear(render)!;

		render_asprite(
			render, 
			*curr_asprite, 
			dim { w = PLAYER_SIZE, h = PLAYER_SIZE },
			pos,
		);

		for (let ob .. obstacles) {
			sdl3::RenderTexture(
				render,
				ob.sprite_t,
				null,
				&sdl3::FRect {
					w = ob.sprite_s.w: f32, 
					h = ob.sprite_s.h: f32,
					x = ob.pos.x: f32,
					y = ob.pos.y: f32,	
				},
			)!;
		};

		render_debug_info(render, keys, pos);
		
		sdl3::RenderPresent(render)!;
	};
};
