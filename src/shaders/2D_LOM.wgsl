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

@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(1) @binding(1) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(1) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(1) @binding(4) var<storage, read_write> rot_vel_buf: array<f32>;
@group(1) @binding(5) var<storage, read_write> acc: array<vec3<f32>>;
@group(1) @binding(6) var<storage, read_write> fixity: array<Particle_Settings>;
@group(1) @binding(7) var<storage, read_write> forces: array<Forces>;

// @group(2) @binding(0) var<storage, read_write> col_sec: array<i32>;

const PI = 3.141592653589793238;
// const vert_bound = 8.0;
// const hor_bound = 12.0;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let deltaTime: f32 = 0.0000390625;
    // let sec_size = 30u;
    // // let prev_sec_id = pointToSectionId(positions[id]);
    // acc[id] = velocities_buf[id] - velocities[id];
    // velocities[id] = velocities_buf[id];
    // positions[id] += velocities_buf[id] * deltaTime; // vel = unit/s

    if fixity[id].x_vel == 0 {
        acc[id] = vec3(vec2((velocities_buf[id] - velocities[id]).x, acc[id].y), acc[id].z);
        velocities[id] = vec2(velocities_buf[id].x, velocities[id].y);
    } else {
        acc[id] = vec3(vec2(0.0, acc[id].y), acc[id].z);
    }

    if fixity[id].y_vel == 0 {
        acc[id] = vec3(vec2(acc[id].x, (velocities_buf[id] - velocities[id]).y), acc[id].z);
        velocities[id] = vec2(velocities[id].x, velocities_buf[id].y);
    } else {
        acc[id] = vec3(vec2(acc[id].x, 0.0), acc[id].z);
    }

    // if id == 1u {
    //     velocities[id].x -= 0.5*deltaTime;
    // }

    velocities[id] += vec2(forces[id].x, forces[id].y)*deltaTime;

    positions[id] = positions[id] + velocities[id] * deltaTime;

    if fixity[id].rot_vel == 0 {
        acc[id] = vec3(acc[id].xy, rot_vel_buf[id] - rot_vel[id]/deltaTime);
        rot_vel[id] = rot_vel_buf[id];//clamp(rot_vel_buf[id],  -1000000.0, 1000000.0);//
    }

    rot_vel[id] += forces[id].rot*deltaTime;
    rot_vel_buf[id] = rot_vel[id];
    rot[id] = (rot[id] + rot_vel[id] * deltaTime)%(2.0*PI);

    forces[id].x += forces[id].delX*deltaTime;
    forces[id].y += forces[id].delY*deltaTime;
    forces[id].rot += forces[id].delRot*deltaTime;
    // acc[id] = velocities_buf[id] - velocities[id];
    // velocities[id] = velocities_buf[id];
    // positions[id] += velocities_buf[id] * deltaTime; // vel = unit/s
    // acc[id].z = rot_vel_buf[id] - rot_vel[id];
    // rot_vel[id] = rot_vel_buf[id];//clamp(rot_vel_buf[id],  -1000000.0, 1000000.0);
    // rot[id] = (rot[id] + rot_vel[id] * deltaTime)%(2.0*PI);

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