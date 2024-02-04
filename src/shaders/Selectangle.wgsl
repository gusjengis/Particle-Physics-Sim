struct Input {
    x: i32,
    y: i32,
    w: u32,
    h: u32
}

struct Particle_Settings {
    x_vel: i32,
    y_vel: i32,
    rot_vel: i32,
}

struct Forces {
    x: f32,
    y: f32,
    rot: f32,
    delX: f32,
    delY: f32,
    delRot: f32,
}

@group(0) @binding(0) var<uniform> input: Input;
@group(1) @binding(0) var<storage, read_write> selections: array<i32>;
@group(2) @binding(0) var tex_sampler: texture_2d<f32>;


@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;
    if id < input.w*input.h {
        let pixel_coord = vec2(id % input.w, id / input.w);
        let pixel_color = textureLoad(tex_sampler, pixel_coord, 0);
        let clicked_particle = u32((pixel_color.r)*255.0*255.0*255.0) + u32((pixel_color.g)*255.0*255.0) + u32((pixel_color.b)*255.0) - 1u;
        selections[clicked_particle] = 1;
    }
}