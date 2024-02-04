struct Input {
    x: f32,
    y: f32,
    aspect: f32,
    empty: i32
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
@group(2) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(3) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(3) @binding(1) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(3) @binding(2) var<storage, read_write> rot: array<f32>;
@group(3) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(3) @binding(4) var<storage, read_write> rot_vel_buf: array<f32>;
@group(3) @binding(5) var<storage, read_write> acc: array<vec3<f32>>;
@group(3) @binding(6) var<storage, read_write> fixity: array<Particle_Settings>;
@group(3) @binding(7) var<storage, read_write> forces: array<Forces>;
@group(4) @binding(0) var<storage, read_write> click_info: array<i32>;


const deltaTime: f32 = 0.0000390625;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;
    if click_info[0] == 1 && selections[id] == 1 { 
        positions[id] = positions[id] + vec2(input.x*input.aspect, input.y);
        velocities[id] = vec2(0.0, 0.0);//vec2(input.x, input.y)/deltaTime;
        velocities_buf[id] = vec2(0.0, 0.0);//vec2(input.x, input.y)/deltaTime;
        fixity[id] = Particle_Settings(
            1,
            1,
            1,
        );
    }
}