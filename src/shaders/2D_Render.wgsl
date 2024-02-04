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
    @location(0) position: vec2<f32>,
    @location(1) color: vec3<f32>,
    @location(2) rot: f32,
    @location(3) rot_vel: f32,
    @location(4) id: u32,
    @location(5) selected: i32
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
    let xy = 2.0*scale*vec2(in.position.x / aspect, in.position.y);
    let center = scale*vec2(pos_buf[instance].x / aspect, pos_buf[instance].y);
    let off = vec2(dim.xOff / aspect, -dim.yOff)/1000.0;
    out.clip_position = vec4(xy*radii_buf[instance] + center + off, 0.0, 1.0);
    out.position = in.position;
    // out.color = color_buf[instance % u32(settings.colors)];
    if material_pointers[instance] != -1 { out.color = vec3(materials[(material_pointers[instance])].red, materials[(material_pointers[instance])].green, materials[(material_pointers[instance])].blue); }
    else { out.color = vec3(1.0, 1.0, 1.0); }
    if settings.random_colors == 1 {
        let seed1 = u32(rand(instance, 4294967296.0));
        let seed2 = u32(rand(seed1, 4294967296.0));
        let seed3 = u32(rand(seed2, 4294967296.0));
        out.color = vec3(
            rand(seed1, 1.0),
            rand(seed2, 1.0),
            rand(seed3, 1.0),
        );
    }
    out.rot = rot_buf[instance];
    out.rot_vel = rot_vel[instance];
    out.id = instance;
    out.selected = selections[instance];
    return out;
}

fn rand(seed: u32, max: f32) -> f32{
    //PCG Hash
    var res = seed;
    res = res * 747796405u + 2891336453u;
    res = ((res >> ((res >> 28u) + 4u)) ^ res) * 277803737u;
    res = (res >> 22u) ^ res;

    return max*f32(res)/4294967296.0;
}


const PI = 3.141592653589793238;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // discard corners to make circle
    let len = length(in.position);
    if settings.circular_particles == 1 {
        if len > 0.5 {
            discard;
        }
    }

    var color = vec4(in.color, 1.0);
    if settings.colors == 0 {
        color = vec4(0.05, 0.05, 0.05, 1.0);
    }
    
    // cut out wedge for rotation
    let rot_point = vec2(cos(in.rot), sin(in.rot));
    let rot_dot = dot(rot_point, normalize(in.position));
    if settings.render_rot == 1 {
        if rot_dot > 0.9 {
            color = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }

    // add border/outline
    if settings.circular_particles == 1 {
        let border_width = 0.08;
        if len > 0.5-border_width && len < 0.5 {
            if in.selected == 1 {
                color = vec4(1.0, 0.8, 0.0, 1.0);
            } else {
                if settings.colors == 0 { 
                    color = vec4(0.05, 0.05, 0.05, 1.0);
                } else {
                    color = vec4(in.color.rgb*0.5, color.a);
                }
            }
        }
    }
    
    // color code based on direction of rotation
    if settings.color_code_rot == 1 {
        if in.rot_vel > 0.0 {
            color = vec4(0.0, color.g, color.ba);
        } else if in.rot_vel < 0.0 {
            color = vec4(color.r, 0.0, color.ba);
        }
    }

    // bonds
    if settings.render_bonds == 1 && bond_info[in.id].x != -1 {
        for(var i = bond_info[in.id].x; i<bond_info[in.id].x+bond_info[in.id].y; i++){
            let displacement = ((radii_buf[in.id]+radii_buf[bonds[i].index]) - length(pos_buf[in.id] - pos_buf[abs(bonds[i].index)])) * 255.0;
            var dir = normalize(pos_buf[abs(bonds[i].index)] - pos_buf[in.id]);
            if dot(dir, normalize(in.position)) > 0.99 {
                color = vec4(1.0 - displacement, 1.0 + clamp(displacement*0.8, -0.8, 1.0) + 0.2*clamp(displacement, 0.0, 1.0), 1.0 - abs(displacement), 1.0);
                if bonds[i].index < 0 {
                    color = vec4(1.0, 0.0, 0.0, 1.0);
                }
            }
        }
    }
    
    //done
    return color;
}