@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(1) @binding(1) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(1) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(1) @binding(4) var<storage, read_write> rot_vel_buf: array<f32>;
// @group(2) @binding(0) var<storage, read_write> col_sec: array<i32>;

const PI = 3.141592653589793238;
// const vert_bound = 8.0;
// const hor_bound = 12.0;

@compute @workgroup_size(32)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let deltaTime: f32 = 0.0000390625;
    let sec_size = 30u;
    // let prev_sec_id = pointToSectionId(positions[id]);
    velocities[id] = velocities_buf[id];
    rot_vel[id] = rot_vel_buf[id];
    positions[id] += velocities_buf[id] * deltaTime;
    rot[id] = (rot[id] + rot_vel[id] * deltaTime)%(2.0*PI);
    // let sec_id = pointToSectionId(positions[id]);
    // if(prev_sec_id != sec_id) {
    //     for(var i=prev_sec_id*sec_size; i<(prev_sec_id+1u)*sec_size; i++) {
    //         if(col_sec[i] == i32(id)){
    //             col_sec[i] = -1;
    //             break;
    //         }
    //     }
    //     for(var i=sec_id*sec_size; i<(sec_id+1u)*sec_size; i++) {
    //         if(col_sec[i] == -1){
    //             col_sec[i] = i32(id);
    //             break;
    //         }
    //     }
    // }
}

// fn pointToSectionId(point: vec2<f32>) -> u32 {
//     let coll_grid_w = 30.0;
//     let coll_grid_h = 30.0;
//     let sec_x = u32((point.y + hor_bound)/(2.0*hor_bound) * coll_grid_w);
//     let sec_y = u32((point.y + vert_bound)/(2.0*vert_bound) * coll_grid_h);
//     return sec_y*u32(coll_grid_w) + sec_x;
// }