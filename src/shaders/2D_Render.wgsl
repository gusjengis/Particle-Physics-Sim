// Vertex shader

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

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) position: vec2<f32>,
    @location(1) color: vec3<f32>,
    @location(2) radius: f32,
    @location(3) rot: f32,
    @location(4) rot_vel: f32
};

@group(0) @binding(0)
var<uniform> dim: Dimensions;

@group(1) @binding(0)
var<storage, read_write> pos_buf: array<vec2<f32>>;

@group(2) @binding(0)
var<storage, read_write> radii_buf: array<f32>;

@group(3) @binding(0)
var<storage, read_write> color_buf: array<vec3<f32>>;

@group(4) @binding(2)
var<storage, read_write> rot_buf: array<f32>;

@group(4) @binding(3)
var<storage, read_write> rot_vel: array<f32>;

@vertex
fn vs_main(
    in: VertexIn,
    @builtin(instance_index) instance: u32,
) -> VertexOutput {
    var out: VertexOutput;
    let aspect = dim.width/dim.height;
    let scale= dim.scale;
    let xy = 2.0*scale*vec2(in.position.x / aspect, in.position.y);
    let center = scale*vec2(pos_buf[instance].x / aspect, pos_buf[instance].y);
    let off = vec2(dim.xOff / aspect, -dim.yOff)/1000.0;
    out.clip_position = vec4(xy*radii_buf[instance] + center + off, 0.0, 1.0);
    out.position = in.position;
    out.color = color_buf[instance % 16u];
    out.radius = radii_buf[instance];
    out.rot = rot_buf[instance];
    out.rot_vel = rot_vel[instance];
    return out;
}

const PI = 3.141592653589793238;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // cut out corners to make circle
    let len = length(in.position);
    if len > 0.5 {
        discard;
    }
    // add border/outline
    let rot_point = vec2(sin(in.rot), cos(in.rot));
    let rot_dimmer = 1.0;//(0.1+pow(clamp(dot(rot_point, normalize(in.position)),0.0,1.0),1.0));
    var color = vec4(in.color*rot_dimmer, 10.0);
    let border_width = 0.08;
    if len > 0.5-border_width && len < 0.5 {
        color = vec4(color.rgb*0.5, color.a);
        
    }
    // if in.rot_vel > 0.0 {
    //     color = vec4(0.0, color.g, color.ba);
    // } else if in.rot_vel < 0.0 {
    //     color = vec4(color.r, 0.0, color.ba);
    // }
    //done
    return color;
}
