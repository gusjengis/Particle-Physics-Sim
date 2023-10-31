struct Bond {
    index: i32,
    angle: f32
};

@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(1) @binding(1) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(1) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(1) @binding(4) var<storage, read_write> rot_vel_buf: array<f32>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> bonds: array<Bond>;
@group(4) @binding(0) var<storage, read_write> bond_info: array<vec2<i32>>;
// @group(5) @binding(0) var<storage, read_write> col_sec: array<i32>;

const deltaTime: f32 = 0.0000390625;
const PI = 3.141592653589793238;
const vert_bound = 2.0;
const hor_bound = 3.0;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let gravity = 9.8 * deltaTime;
    let stiffness: f32 = 1000.0; // Arbitrarily chosen, adjust as per need
    let damping: f32 = 0.5; // Damping factor, can be adjusted

    velocities_buf[id] = vec2(velocities_buf[id].x, velocities_buf[id].y - gravity);

    //Section Based Collisions
    let corner1 = pointToSectionId(positions[id] + vec2(radii[id], radii[id]));
    let corner2 = pointToSectionId(positions[id] + vec2(-radii[id], radii[id]));
    let corner3 = pointToSectionId(positions[id] - vec2(radii[id], radii[id]));
    let corner4 = pointToSectionId(positions[id] - vec2(-radii[id], radii[id]));
    // collisionsInSection(id, corner1, stiffness, damping);
    // if(corner1 != corner2) {collisionsInSection(id, corner2, stiffness, damping);}
    // if(corner1 != corner3 && corner2 != corner3) {collisionsInSection(id, corner3, stiffness, damping);}
    // if(corner1 != corner4 && corner2 != corner4 && corner3 != corner4) {collisionsInSection(id, corner4, stiffness, damping);}

    //OG O(n^2) Collisions
    NSquaredCollisions(id, stiffness, damping);

    //Bonds
    let start = bond_info[id].x;
    let length = bond_info[id].y;
    let force_threshold = 10.0;
    if(start != -1){
        for(var i = u32(start); i<u32(start+length); i++){
            let bond_id: i32 = bonds[i].index;
            if(bond_id == -1){
                continue;
            }
            // let bond_angle = bonds[i].angle;
            // let surf_point_a = positions[id] + vec2(sin(bond_angle), cos(bond_angle))*radii[id];
            // let surf_point_b = positions[id] + vec2(sin(bond_angle+PI/2.0), cos(bond_angle+PI/2.0))*radii[bond_id];
            // let dist: f32 = length(surf_point_a - surf_point_b);
            let dist: f32 = length(positions[bond_id] - positions[id]);
            let ideal_length: f32 = (radii[id] + radii[bond_id]);//bonds[i].angle;
            let displacement: f32 = ideal_length - dist;
            // let displacement: f32 = clamp(ideal_length - dist,-100000000.0,0.0);
            // let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(surf_point_b - surf_point_a);
            let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(positions[bond_id] - positions[id]);
            let mass1: f32 = 3.14159265 * radii[id] * radii[id];
            let mass2: f32 = 3.14159265 * radii[bond_id] * radii[bond_id];
            let force = (spring_force / mass1) * damping;
            // if id > 100u {
            velocities_buf[id] -= force;
            // }
            // positions[id].x = bond_angle;
            // // Tear Bonds
            // if(length(force) > force_threshold){
            //     bonds[i].index = -1;
            // }
        }
    }

    // BS Walls
    let pos = positions[id];
    let rad = radii[id];
    let elasticity = 0.5;
    let anti_stick_coating = 0.01;
    let yH = vert_bound;
    let xW = hor_bound;
    if pos.x+rad > xW {
        velocities_buf[id] = vec2(-velocities_buf[id].x, velocities_buf[id].y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(xW-rad, pos.y);
    } else if pos.x-rad < -xW {
        velocities_buf[id] = vec2(-velocities_buf[id].x, velocities_buf[id].y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(-xW+rad, pos.y);
    }
    if pos.y+rad > yH {
        velocities_buf[id] = vec2(velocities_buf[id].x, -velocities_buf[id].y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(pos.x, yH-rad - anti_stick_coating);
    } else if pos.y-rad < -yH {
        velocities_buf[id] = vec2(velocities_buf[id].x, -velocities_buf[id].y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(pos.x, -yH+rad);
    }
}

fn collisionsInSection(id: u32, sec: u32, stiffness: f32, damping: f32) {
    // let sec_size = 30u;
    // // for(var i = sec*sec_size; i<(sec+1u)*sec_size; i++){
    // for(var i = 0u; i<arrayLength(&col_sec); i++){
    //     if(col_sec[i] == -1) {
    //         continue;
    //     }
    //     let j = u32(col_sec[i]);
    //     if j != id {
    //         //detect collisions
    //         if length(positions[j] - positions[id]) < (radii[j] + radii[id]){
    //             collide(id, j, stiffness, damping);
    //         }
    //     }
    // }
}

fn collide(a: u32, b: u32, stiffness: f32, damping: f32) {
    let overlap: f32 = (radii[b] + radii[a]) - length(positions[b] - positions[a]);
    let normal: vec2<f32> = normalize(positions[b] - positions[a]);
    let force: vec2<f32> = stiffness * overlap * normal;
    let tangent: vec2<f32> = normalize(vec2(-normal.y, normal.x));
    let relVel: vec2<f32> = velocities[a] - velocities[b];

    // Contact Bond Model, Excludes Rotation

    // let tangentialVelocity: f32 = dot(relVel, tangent);
    // let frictionForce: vec2<f32> = 0.2 * length(force) * tangentialVelocity * tangent;
    
    //Parallel Bond Model, Includes Rotation
    
    let tangentialVelocity_a: f32 = rot_vel[a] * radii[a];
    let tangentialVelocity_b: f32 = rot_vel[b] * radii[b];
    let relTangentialVelocity: f32 = dot(relVel, tangent) - (tangentialVelocity_a + tangentialVelocity_b);
    let frictionForce: vec2<f32> = 0.2 * length(force) * relTangentialVelocity * tangent;
    let r_a: vec2<f32> = positions[b] - positions[a];
    let torque_sign: f32 = sign(relTangentialVelocity);
    let torque_friction_a: f32 = torque_sign * length(r_a) * length(frictionForce);
    let I_a: f32 = 0.25 * 3.14159265 * radii[a] * radii[a] * radii[a] * radii[a];
    let delta_omega_friction_a: f32 = torque_friction_a / I_a;
    rot_vel_buf[a] += delta_omega_friction_a * deltaTime;

    let cappedFrictionForce: vec2<f32> = vec2(clamp(frictionForce.x, -10.0, 10.0), clamp(frictionForce.y, -10.0, 10.0));
    let mass1: f32 = 3.14159265 * radii[a] * radii[a];
    let mass2: f32 = 3.14159265 * radii[b] * radii[b];
    velocities_buf[a] = velocities_buf[a] - (2.0 * mass2 / (mass1 + mass2)) * damping * (force + cappedFrictionForce);


    
    
}

// fn is_bonded(id: u32, i: u32) -> bool {
//     let start = bond_info[id].x;
//     let length = bond_info[id].y;
//     let force_threshold = 10.0;
//     if(start != -1){
//         for(var i = u32(start); i<u32(start+length); i++){

//         }
//     }    
// }

fn pointToSectionId(point: vec2<f32>) -> u32 {
    let coll_grid_w = 30.0;
    let coll_grid_h = 30.0;
    let sec_x = u32((point.y + hor_bound)/(2.0*hor_bound) * coll_grid_w);
    let sec_y = u32((point.y + vert_bound)/(2.0*vert_bound) * coll_grid_h);
    return sec_y*u32(coll_grid_w) + sec_x;
}

fn NSquaredCollisions(id: u32, stiffness: f32, damping: f32){
    for(var i = 0u; i<arrayLength(&radii); i++){
        if i != id {
            //detect collisions
            if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
                collide(id, i, stiffness, damping);
            }
        }
    }
}