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
    @location(2) radius: f32
};

@group(0) @binding(0)
var<uniform> dim: Dimensions;

@group(1) @binding(0)
var<storage, read_write> pos_buf: array<vec2<f32>>;

@group(2) @binding(0)
var<storage, read_write> radii_buf: array<f32>;

@group(3) @binding(0)
var<storage, read_write> color_buf: array<vec3<f32>>;
// test
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
    out.color = color_buf[instance%100u];
    out.radius = radii_buf[instance];
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // cut out corners to make circle
    let len = length(in.position);
    if len > 0.5 {
        discard;
    }
    // add border/outline
    var color = vec4(in.color, 1.0);
    let border_width = 0.08;
    if len > 0.5-border_width && len < 0.5 {
        color = vec4(color.rgb*0.5, color.a);
    }
    //done
    return color;
}
