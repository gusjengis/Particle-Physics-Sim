@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(2) @binding(0) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(3) @binding(0) var<storage, read_write> col_sec: array<i32>;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let deltaTime: f32 = 0.0000390625;
    let sec_size = 50u;
    let prev_sec_id = pointToSectionId(positions[id]);
    velocities[id] = velocities_buf[id];
    positions[id] = positions[id] + velocities[id] * deltaTime;
    let sec_id = pointToSectionId(positions[id]);
    if(prev_sec_id != sec_id) {
        for(var i=prev_sec_id*sec_size; i<(prev_sec_id+1u)*sec_size; i++) {
            if(col_sec[i] == i32(id)){
                col_sec[i] = -1;
                break;
            }
        }
        for(var i=sec_id*sec_size; i<(sec_id+1u)*sec_size; i++) {
            if(col_sec[i] == -1){
                col_sec[i] = i32(id);
                break;
            }
        }
    }
}

fn pointToSectionId(point: vec2<f32>) -> u32 {
    let vert_bound = 2.0;
    let hor_bound = vert_bound*16.0/11.0;
    let coll_grid_w = 30.0;
    let coll_grid_h = 30.0;
    let sec_x = u32((point.y + hor_bound)/(2.0*hor_bound) * coll_grid_w);
    let sec_y = u32((point.y + vert_bound)/(2.0*vert_bound) * coll_grid_h);
    return sec_y*u32(coll_grid_w) + sec_x;
}