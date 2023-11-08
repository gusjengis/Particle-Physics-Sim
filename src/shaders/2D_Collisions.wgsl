struct Bond {
    index: i32,
    angle: f32
};

struct Settings {
    hor_bound: f32,
    vert_bound: f32,
    gravity: i32,
    bonds: i32,
    collisions: i32,
    friction: i32,
    rotation: i32,
    linear_contact_bonds: i32,
}

@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(1) @binding(1) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(1) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(1) @binding(4) var<storage, read_write> rot_vel_buf: array<f32>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> bonds: array<Bond>;
@group(4) @binding(0) var<storage, read_write> bond_info: array<vec2<i32>>;
@group(5) @binding(0) var<uniform> settings: Settings;
// @group(5) @binding(0) var<storage, read_write> col_sec: array<i32>;

const deltaTime: f32 = 0.0000390625;
const PI = 3.141592653589793238;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {

    let id: u32 = global_id.x;
    
    let stiffness: f32 = 1000.0; // Arbitrarily chosen, adjust as per need
    let damping: f32 = 0.5; // Damping factor, can be adjusted
    
    var new_velocity = velocities[id];

    if settings.gravity == 1 {
        let gravity = 9.8 * deltaTime;
        new_velocity = vec2(velocities[id].x, velocities[id].y - gravity);
    }
    

    //OG O(n^2) Collisions
    if settings.collisions == 1 {
        new_velocity -= NSquaredCollisions(id, stiffness, damping);
    }

    //Bonds
    if settings.bonds == 1 {
        let start = bond_info[id].x;
        let length = bond_info[id].y;
        let shear_lim = 0.11;
        let normal_lim = 0.11;
        if(start != -1){
            for(var i = u32(start); i<u32(start+length); i++){
                let bond_id: i32 = bonds[i].index;
                if(bond_id == -1){
                    continue;
                }

                // Linear Bonds, this is working
                if settings.linear_contact_bonds == 1 {
                    let dist: f32 = length(positions[bond_id] - positions[id]);
                    let ideal_length: f32 = (radii[id] + radii[bond_id]);
                    let displacement: f32 = ideal_length - dist;
                    let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(positions[bond_id] - positions[id]);
                    let mass1: f32 = 3.14159265 * radii[id] * radii[id];
                    var force = (spring_force / mass1) * damping;
                    new_velocity -= force;
                }
                
                // Parallel Bonds, wip

                // let R = sqrt(radii[id]*radii[bond_id]);
                // let rigidity = 5.0;

                // // let diff = (positions[bond_id] - positions[id]);
                // // let dist2 = length(diff);
                // // let curr_angle = acos(diff.x/dist2);
                // let bond_angle = bonds[i].angle + rot[id];
                // let other_bond_angle = (bond_angle + PI) % (2.0*PI);
                // let bond_dir = normalize(vec2(sin(other_bond_angle), cos(other_bond_angle)));
                // let bond_point = bond_dir*radii[bond_id] + positions[bond_id];
                // // let bond_pos_diff = bond_point - positions[id];
                // let shear_dir = normalize(vec2(-bond_dir.y, bond_dir.x));
                // let ideal_pos = bond_dir*radii[bond_id]*radii[id] + positions[bond_id];//bond_point + bond_dir*radii[id];
                // let displacement2 = positions[id] - ideal_pos;
                // let shear_force = dot(displacement2, shear_dir);
                // let normal_force = dot(displacement2, bond_dir);

                // velocities_buf[id] -= (shear_force*shear_dir + normal_force*bond_dir)*rigidity;
                // velocities_buf[id] -= ;
                // velocities_buf[id] -= displacement2;
                // if length(spring_force) > shear_lim {//shear_force > shear_lim || normal_force > normal_lim {
                //     bonds[i].index = -1;   
                // }
                // let ideal_length: f32 = 0.0;
                // let displacement2: f32 = ideal_length - length(bond_point_b-bond_point_a);
                // let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(bond_point_b-bond_point_a);
                // let mass1: f32 = 3.14159265 * radii[id] * radii[id];
                // let mass2: f32 = 3.14159265 * radii[bond_id] * radii[bond_id];
                // let force = (spring_force / mass1) * damping;
                // velocities_buf[id] -= force;
                

                
            }
        }
    }

    // BS Walls
    let pos = positions[id];
    let rad = radii[id];
    let elasticity = 0.5;
    let anti_stick_coating = 0.01;
    let yH = settings.vert_bound;
    let xW = settings.hor_bound;
    if pos.x+rad > xW {
        new_velocity = vec2(-new_velocity.x, new_velocity.y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(xW-rad, pos.y);
    } else if pos.x-rad < -xW {
        new_velocity = vec2(-new_velocity.x, new_velocity.y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(-xW+rad, pos.y);
    }
    if pos.y+rad > yH {
        new_velocity = vec2(new_velocity.x, -new_velocity.y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(pos.x, yH-rad - anti_stick_coating);
    } else if pos.y-rad < -yH {
        new_velocity = vec2(new_velocity.x, -new_velocity.y)*elasticity;
        rot_vel_buf[id] = rot_vel_buf[id]*0.9;
        positions[id] = vec2(pos.x, -yH+rad);
    }

    velocities_buf[id] = new_velocity;
}

fn collide(a: u32, b: u32, stiffness: f32, damping: f32) -> vec2<f32> {
    let overlap: f32 = (radii[b] + radii[a]) - length(positions[b] - positions[a]);
    let normal: vec2<f32> = normalize(positions[b] - positions[a]);
    let force: vec2<f32> = stiffness * overlap * normal;
    let tangent: vec2<f32> = normalize(vec2(-normal.y, normal.x));
    let relVel: vec2<f32> = velocities[a] - velocities[b];
    let mass1: f32 = 3.14159265 * radii[a] * radii[a];
    let mass2: f32 = 3.14159265 * radii[b] * radii[b];

    if settings.friction == 1 {
        if settings.rotation == 1 {  // With Rotation
            let tangentialVelocity: f32 = dot(relVel, tangent);
            let frictionForce: vec2<f32> = 0.2 * length(force) * tangentialVelocity * tangent;
            let cappedFrictionForce = vec2(clamp(frictionForce.x, -10.0, 10.0), clamp(frictionForce.y, -10.0, 10.0));
            return (2.0 * mass2 / (mass1 + mass2)) * damping * (force + cappedFrictionForce);  
        } else { // Without Rotation
            let tangentialVelocity_a: f32 = rot_vel[a] * radii[a];
            let tangentialVelocity_b: f32 = rot_vel[b] * radii[b];
            let relTangentialVelocity: f32 = dot(relVel, tangent) - (tangentialVelocity_a + tangentialVelocity_b);
            let frictionForce: vec2<f32> = 0.2 * length(force) * tangent * relTangentialVelocity;
            let r_a: vec2<f32> = positions[b] - positions[a];
            let torque_sign: f32 = sign(relTangentialVelocity);
            let torque_friction_a: f32 = torque_sign * length(r_a) * length(frictionForce);
            let I_a: f32 = 0.25 * 3.14159265 * radii[a] * radii[a] * radii[a] * radii[a];
            let delta_omega_friction_a: f32 = torque_friction_a / I_a;
            rot_vel_buf[a] += delta_omega_friction_a * deltaTime;
            let cappedFrictionForce = vec2(clamp(frictionForce.x, -10.0, 10.0), clamp(frictionForce.y, -10.0, 10.0));
            return (2.0 * mass2 / (mass1 + mass2)) * damping * (force + cappedFrictionForce);  
        }
    } else {
        return (2.0 * mass2 / (mass1 + mass2)) * damping * (force);
    }
    

      
    
}

fn NSquaredCollisions(id: u32, stiffness: f32, damping: f32) -> vec2<f32> {
    var collision_force = vec2(0.0, 0.0);
    for(var i = 0u; i<arrayLength(&radii); i++){
        if i != id {
            //detect collisions
            if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
                collision_force += collide(id, i, stiffness, damping);
            }
        }
    }
    return collision_force;
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


fn pointToSectionId(point: vec2<f32>) -> u32 {
    let coll_grid_w = 30.0;
    let coll_grid_h = 30.0;
    let sec_x = u32((point.y + settings.hor_bound)/(2.0*settings.hor_bound) * coll_grid_w);
    let sec_y = u32((point.y + settings.vert_bound)/(2.0*settings.vert_bound) * coll_grid_h);
    return sec_y*u32(coll_grid_w) + sec_x;
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
    // //Section Based Collisions
    // let corner1 = pointToSectionId(positions[id] + vec2(radii[id], radii[id]));
    // let corner2 = pointToSectionId(positions[id] + vec2(-radii[id], radii[id]));
    // let corner3 = pointToSectionId(positions[id] - vec2(radii[id], radii[id]));
    // let corner4 = pointToSectionId(positions[id] - vec2(-radii[id], radii[id]));
    // // collisionsInSection(id, corner1, stiffness, damping);
    // // if(corner1 != corner2) {collisionsInSection(id, corner2, stiffness, damping);}
    // // if(corner1 != corner3 && corner2 != corner3) {collisionsInSection(id, corner3, stiffness, damping);}
    // // if(corner1 != corner4 && corner2 != corner4 && corner3 != corner4) {collisionsInSection(id, corner4, stiffness, damping);}