struct VertexIn {
    @location(0) position: vec2<f32>,
};

struct Dimensions {
    width: f32, time: f32,
    height: f32, temp: f32,
    xOff: f32, yOff: f32,
    scale: f32, dark: f32,
}

struct Camera {
    view_proj: mat4x4<f32>,
    eye: mat4x4<f32>,
    focus: mat4x4<f32>,
};

struct Material {
    red: f32,
    green: f32,
    blue: f32,
    density: f32,
    normal_stiffness: f32,
    shear_stiffness: f32,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) position: vec4<f32>,
    // @location(1) color: vec3<f32>,
    @location(1) rot: f32,
    @location(2) rot_vel: f32,
    @location(3) id: u32,
    @location(4) scale: f32
};

struct Settings {
    circular_particles: i32,
    render_rot: i32,
    color_code_rot: i32,
    colors: i32,
    render_bonds: i32,
    w: f32,
    h: f32,
    stiffness: f32,
    random_colors: i32
}

struct Bond {
    index: i32,
    angle: f32,
    length: f32
};

@group(0) @binding(0) var<uniform> dim: Dimensions;
@group(1) @binding(0) var<storage, read_write> pos_buf: array<vec2<f32>>;
@group(2) @binding(0) var<storage, read_write> radii_buf: array<f32>;
// @group(3) @binding(0) var<storage, read_write> color_buf: array<vec3<f32>>;
@group(3) @binding(2) var<storage, read_write> rot_buf: array<f32>;
@group(3) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(4) @binding(0) var<storage, read_write> bonds: array<Bond>;
@group(4) @binding(1) var<storage, read_write> bond_info: array<vec2<i32>>;
@group(4) @binding(4) var<storage, read_write> material_pointers: array<i32>;
@group(5) @binding(0) var<uniform> settings: Settings;
@group(6) @binding(0) var<storage, read_write> materials: array<Material>;
@group(7) @binding(0) var<storage, read_write> selections: array<i32>;


@vertex
fn vs_main(
    in: VertexIn,
    @builtin(instance_index) instance: u32,
) -> VertexOutput {
    var out: VertexOutput;
    let aspect = dim.width/dim.height;
    let scale= dim.scale;
    let xy = 1.0/scale*vec2(in.position.x * aspect, in.position.y);
    let center = scale*vec2(pos_buf[instance].x / aspect, pos_buf[instance].y);
    let off = vec2(-dim.xOff, dim.yOff)/1000.0/scale;
    out.clip_position = vec4(in.position, 0.0, 1.0);
    out.position = vec4((xy + off), 0.0, 1.0);
    // out.color = color_buf[instance % u32(settings.colors)];
    // if material_pointers[instance] != -1 { out.color = vec3(materials[(material_pointers[instance])].red, materials[(material_pointers[instance])].green, materials[(material_pointers[instance])].blue); }
    out.rot = rot_buf[instance];
    out.rot_vel = rot_vel[instance];
    out.id = instance;
    out.scale = scale;
    return out;
}

const PI = 3.141592653589793238;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    if in.position.x >= settings.w || in.position.x <= -settings.w || in.position.y >= settings.h || in.position.y <= -settings.h {
        return vec4(0.02, 0.02, 0.02, 1.0);
    } 

    // if abs(in.position.x) % 1.0 < 0.003 || abs(in.position.x) % 1.0 > 0.997 || abs(in.position.y) % 1.0 < 0.003 || abs(in.position.y) % 1.0 > 0.997 {
    //     return vec4(0.04, 0.04, 0.04, 1.0);
    // }

    // if abs(in.position.x) % 0.5 < 0.002 || abs(in.position.x) % 0.5 > 0.998 || abs(in.position.y) % 0.5 < 0.002 || abs(in.position.y) % 0.5 > 0.998 {
    //     return vec4(0.04, 0.04, 0.04, 1.0);
    // }

    // if abs(in.position.x) % 0.25 < 0.001 || abs(in.position.x) % 0.25 > 0.999 || abs(in.position.y) % 0.25 < 0.001 || abs(in.position.y) % 0.25 > 0.999 {
    //     return vec4(0.04, 0.04, 0.04, 1.0);
    // }
    //done
    return vec4(0.0, 0.0, 0.0, 1.0);
}