// Vertex shader

struct VertexIn {
    @location(0) position: vec2<f32>,
    @location(1) color: vec3<f32>,
    @location(2) radius: f32
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

@vertex
fn vs_main(
    in: VertexIn,
    @builtin(instance_index) instance: u32,
    @builtin(vertex_index) vertex: u32,
) -> VertexOutput {
    var out: VertexOutput;
    let aspect = dim.width/dim.height;
    
    
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // cut out corners to make circle
    let pixel = vec2(in.clip_position.x, in.clip_position.y);
    let center = vec2(in.position.x, in.position.y);
    let point = (pixel - center)/in.radius;
    let in_cirle = point.x*point.x + point.y+point.y
    if  in_cirle > 1.0 {
        discard;
    }
    // add border/outline
    var color = vec4(in.color, 1.0);
    let border_width = 0.05;
    let border_color = vec4(1.0, 1.0, 1.0, 1.0);
    if in_cirle > 1.0-border_width {
        color = border_color;
    }
    //done
    return color;
}
