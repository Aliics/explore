use sdl3;

export type asprite = struct {
	time: int,
	
	atlas_tex: *sdl3::Texture,
	atlas_p:   dim,
	atlas_s:   dim,
	
	pposes: []pos,
};

fn asprite_psize(a: asprite) dim = {
	return dim {
		w = a.atlas_s.w / a.atlas_p.w,
		h = a.atlas_s.h / a.atlas_p.h,
	};
};

export fn asprite_pfrect(a: asprite, p: int) sdl3::FRect = {
		const psize = asprite_psize(a);
		const ppos = a.pposes[p];
		return sdl3::FRect {
			x = (ppos.x * psize.w): f32, 
			y = (ppos.y * psize.h): f32,
			w = psize.w: f32, h = psize.h: f32,
		};
};

export fn asprite_frame(a: asprite) int = {
	const ft = a.time / len(a.pposes): int;
	const t = sdl3::GetTicks(): int % a.time;
	return t / ft;
};

export fn render_asprite(
	render: *sdl3::Renderer, 
	a: asprite, 
	sz: dim, 
	pos: fpos,
) void = {
	const src = asprite_pfrect(a, asprite_frame(a));
	const trans = sdl3::FRect {
		w = sz.w: f32, h = sz.h: f32,
		x = pos.x, y = pos.y,
	};
	sdl3::RenderTexture(render, a.atlas_tex, &src, &trans)!;
};
