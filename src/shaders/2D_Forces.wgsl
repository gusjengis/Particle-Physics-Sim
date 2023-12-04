struct Bond {
    index: i32,
    angle: f32,
    length: f32
};

struct Contact {
    a: i32,
    angle_a: f32,
    length_a: f32,
    b: i32,
    normal_force: f32,
    tangent_force: f32
};


struct Settings {
    hor_bound: f32,
    vert_bound: f32,
    gravity: i32,
    bonds: i32,
    collisions: i32,
    friction: i32,
    friction_coefficient: f32,
    rotation: i32,
    linear_contact_bonds: i32,
    gravity_acc: f32

}

@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(1) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> bonds: array<Bond>;
@group(3) @binding(1) var<storage, read_write> bond_info: array<vec2<i32>>;
@group(3) @binding(2) var<storage, read_write> contacts: array<Contact>;
@group(4) @binding(0) var<uniform> settings: Settings;
// @group(5) @binding(0) var<storage, read_write> col_sec: array<i32>;

const deltaTime: f32 = 0.0000390625;
const max_contacts = 8u;
const PI = 3.141592653589793238;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {

    let id: u32 = global_id.x;
    
    let stiffness: f32 = 10.0; // Arbitrarily chosen, adjust as per need
    let damping: f32 = 0.5; // Damping factor, can be adjusted

    //Contacts
    for(var i = id*max_contacts; i<(id+1u)*max_contacts; i++){
        if contacts[i].b == -1{
            continue;
        }
        let a = contacts[i].a;
        let b = contacts[i].b;
        let overlap = radii[a] + radii[b] - length(positions[b] - positions[a]);
        contacts[i].normal_force = overlap*stiffness;

        let delta = positions[b] - positions[a]; 
        let delta_norm = normalize(delta); 
        contacts[i].angle_a = atan2(delta_norm.x, delta_norm.y);
        contacts[i].length_a = radii[a] - overlap/2.0;
    }

    // //Bonds
    // if settings.bonds == 1 {
    //     let start = bond_info[id].x;
    //     let length = bond_info[id].y;
    //     let shear_lim = 0.11;
    //     let normal_lim = 1.00;
    //     if(start != -1){
    //         for(var i = u32(start); i<u32(start+length); i++){
    //             let bond_id: i32 = bonds[i].index;
    //             if(bond_id == -1){
    //                 continue;
    //             }

    //             // Linear Bonds, this is working
    //             if settings.linear_contact_bonds == 1 {
    //                 let dist: f32 = length(positions[bond_id] - positions[id]);
    //                 let ideal_length: f32 = bonds[i].length;//(radii[id] + radii[bond_id]);
    //                 let displacement: f32 = ideal_length - dist;
    //                 let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(positions[bond_id] - positions[id]);
    //                 let mass1: f32 = 3.14159265 * radii[id] * radii[id];
    //                 var force = (spring_force / mass1) * damping;
    //                 new_force -= force;
    //                 // if length(force) > normal_lim {
    //                 //     bonds[i].index = -1;
    //                 // }
    //             } else {
    //                 // Parallel Bonds, wip

    //                 let left_stiffness = 100.0;
    //                 let right_stiffness = 100.0;
    //                 let shear_stiffness = 100.0;
    //                 let mass = 3.14159265 * radii[id] * radii[id];
    //                 let rot_inertia = 0.5*mass*radii[id]*radii[id];
    //                 let R = sqrt(radii[id]*radii[bond_id]);
                    
    //                 // left spring

    //                 let pos_A = positions[id];
    //                 let pos_B = positions[bond_id];
    //                 var angle_A = (rot[id] + bonds[i].angle + PI/2.0);
    //                 var angle_B = (rot[bond_id] + bonds[i].angle + PI/2.0);
    //                 // angle_A = sign(angle_A) * (abs(angle_A) % 2.0*PI);
    //                 // angle_B = sign(angle_B) * (abs(angle_B) % 2.0*PI);
    //                 let left_spring_end_A = pos_A + R*vec2(cos(angle_A), sin(angle_A));
    //                 let left_spring_end_B = pos_B + R*vec2(cos(angle_B), sin(angle_B));
    //                 let left_spring_dir = normalize(left_spring_end_B - left_spring_end_A);
    //                 let left_spring_length = length(left_spring_end_A - left_spring_end_B);
    //                 let ideal_length = bonds[i].length;
    //                 let left_displacement = left_spring_length - ideal_length ;
    //                 let left_force_magnitude = left_displacement*left_stiffness;
    //                 let left_moment = R * left_force_magnitude;

    //                 // right spring 

    //                 let right_spring_end_A = pos_A + R*vec2(cos(angle_A + PI), sin(angle_A + PI));
    //                 let right_spring_end_B = pos_B + R*vec2(cos(angle_B + PI), sin(angle_B + PI));
    //                 let right_spring_dir = normalize(right_spring_end_B - right_spring_end_A);
    //                 let right_spring_length = length(right_spring_end_A - right_spring_end_B);
    //                 let right_displacement = right_spring_length - ideal_length;
    //                 let right_force_magnitude = right_displacement*right_stiffness;
    //                 let right_moment = -R * right_force_magnitude;

    //                 // shear spring
    //                 let bond_dir = vec2(-sin(rot[bond_id] + bonds[i].angle + PI), cos(rot[bond_id] + bonds[i].angle + PI));
    //                 let tangent_dir = vec2(-bond_dir.y, bond_dir.x);
    //                 let ideal_postition = pos_B + ideal_length*bond_dir;
    //                 let displacement = ideal_postition - pos_A;
    //                 let shear_force = dot(displacement, tangent_dir)*shear_stiffness;
    //                 //apply forces

    //                 rot_vel_buf[id] += (left_moment + right_moment);// / rot_inertia;
    //                 rot_vel_buf[id] += (-shear_force);// / rot_inertia;
    //                 new_force += (right_spring_dir * right_force_magnitude + left_spring_dir * left_force_magnitude + shear_force*tangent_dir);//


    //                     // let R = sqrt(radii[id]*radii[bond_id]);
    //                     // let rigidity = 5.0;

    //                     // // let diff = (positions[bond_id] - positions[id]);
    //                     // // let dist2 = length(diff);
    //                     // // let curr_angle = acos(diff.x/dist2);
    //                     // let bond_angle = bonds[i].angle;
    //                     // let other_bond_angle = (bond_angle + PI + rot[bond_id]) % (2.0*PI);
    //                     // let bond_dir = normalize(vec2(sin(other_bond_angle), cos(other_bond_angle)));
    //                     // // let bond_point = bond_dir*radii[bond_id] + positions[bond_id];
    //                     // // let bond_pos_diff = bond_point - positions[id];
    //                     // let shear_dir = normalize(vec2(-bond_dir.y, bond_dir.x));
    //                     // let ideal_pos = bond_dir*(bonds[i].length) + positions[bond_id];//radii[bond_id]+radii[id]
    //                     // let displacement2 = positions[id] - ideal_pos;
    //                     // let shear_force = dot(displacement2, shear_dir);
    //                     // let normal_force = dot(displacement2, bond_dir);

    //                     // new_force -= (shear_force*shear_dir + normal_force*bond_dir)*rigidity;
    //                 // velocities_buf[id] -= ;
    //                 // velocities_buf[id] -= displacement2;
    //                 // if length(spring_force) > shear_lim {//shear_force > shear_lim || normal_force > normal_lim {
    //                 //     bonds[i].index = -1;   
    //                 // }
    //                 // let ideal_length: f32 = 0.0;
    //                 // let displacement2: f32 = ideal_length - length(bond_point_b-bond_point_a);
    //                 // let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(bond_point_b-bond_point_a);
    //                 // let mass1: f32 = 3.14159265 * radii[id] * radii[id];
    //                 // let mass2: f32 = 3.14159265 * radii[bond_id] * radii[bond_id];
    //                 // let force = (spring_force / mass1) * damping;
    //                 // velocities_buf[id] -= force;
    //             }
                
                

                
    //         }
    //     }
    // }
}

// fn collide(a: u32, b: u32, stiffness: f32, damping: f32) -> vec2<f32> {
//     let overlap = (radii[b] + radii[a]) - length(positions[b] - positions[a]);
//     let normal = normalize(positions[b] - positions[a]);
//     let normal_force = stiffness * overlap * normal;
//     let tangent = normalize(vec2(-normal.y, normal.x));
//     let mass1 = 3.14159265 * radii[a] * radii[a];
//     let mass2 = 3.14159265 * radii[b] * radii[b];
//     let relVel = velocities[a] - velocities[b];

//     if settings.friction == 1 {
//         if settings.rotation == 0 {  // Without Rotation
//             // let tangentialVelocity_a: f32 = rot_vel[a] * radii[a];
//             // let tangentialVelocity_b: f32 = rot_vel[b] * radii[b];
//             // let relTangentialVelocity: f32 = dot(relVel, tangent) - (tangentialVelocity_a + tangentialVelocity_b);
            
//             // let lin_acc = forces[a].xy;
//             // // let friction_magnitude = length(lin_acc)*dot(normalize(lin_acc), tangent)*mass1 + rot_acc*rot_inertia;
//             // let friction_magnitude = length(lin_acc)*dot(normalize(lin_acc), tangent)*mass1;
//             // let friction_limit = length(normal_force)*settings.friction_coefficient;
//             // let friction_force = tangent*sign(friction_magnitude)*min(abs(friction_magnitude), friction_limit);
            
//             // return (2.0 * mass2 / (mass1 + mass2)) * damping * (normal_force + friction_force);    
                    


//             // OLD Friction, GPT'd
//             let tangentialVelocity: f32 = dot(relVel, tangent);
//             let frictionForce: vec2<f32> = settings.friction_coefficient * length(normal_force) * tangentialVelocity * tangent;
//             let cappedFrictionForce = vec2(clamp(frictionForce.x, -10.0, 10.0), clamp(frictionForce.y, -10.0, 10.0));
//             return (2.0 * mass2 / (mass1 + mass2)) * damping * (normal_force + cappedFrictionForce); //Acceleration


//         } else { // With Rotation linear acceleration*mass + angular acceleration*rotational inertia == mag, normal_force*friction_coefficient == limit
//             let tangentialVelocity_a: f32 = rot_vel[a] * radii[a];
//             let tangentialVelocity_b: f32 = rot_vel[b] * radii[b];
//             let relTangentialVelocity: f32 = (dot(relVel, tangent) - (tangentialVelocity_a + tangentialVelocity_b)); // meters/time - angular? meters/time
            
//             let lin_acc = forces[a].xy;
//             let rot_acc = forces[a].z; // (current rot_vel - prev rot_vel)/delTime, change in rot_vel
//             let rot_inertia = 0.5*mass1*radii[a]*radii[a]; // Disc, Units kg*meters^2 
//             // let friction_magnitude = length(lin_acc)*dot(normalize(lin_acc), tangent)*mass1 + rot_acc*rot_inertia;
//             let friction_magnitude = length(lin_acc)*dot(lin_acc, tangent)*mass1 + relTangentialVelocity*rot_inertia;//deltaTime/radii[a]; // mass*d/s^2 + mass*d/s^2  
//             let friction_limit = length(normal_force)*settings.friction_coefficient;
//             let friction_force = tangent*sign(friction_magnitude)*min(abs(friction_magnitude), friction_limit);
            
//             let torque_sign: f32 = sign(relTangentialVelocity);
//             let torque_friction_a: f32 = torque_sign * length(radii[a]) * 0.5*length(friction_force);
//             let delta_omega_friction_a: f32 = torque_friction_a / rot_inertia;
//             rot_vel_buf[a] += delta_omega_friction_a;
//             return (2.0 * mass2 / (mass1 + mass2)) * damping * (normal_force + friction_force);    


//             // OLD Friction, GPT'd
//             // let tangentialVelocity_a: f32 = rot_vel[a] * radii[a];
//             // let tangentialVelocity_b: f32 = rot_vel[b] * radii[b];
//             // let relTangentialVelocity: f32 = dot(relVel, tangent) - (tangentialVelocity_a + tangentialVelocity_b);
//             // let frictionForce: vec2<f32> = settings.friction_coefficient * length(normal_force) * tangent * relTangentialVelocity;
//             // let r_a: vec2<f32> = positions[b] - positions[a];
//             // let torque_sign: f32 = sign(relTangentialVelocity);
//             // let torque_friction_a: f32 = torque_sign * length(r_a) * length(frictionForce);
//             // let I_a: f32 = 0.25 * 3.14159265 * radii[a] * radii[a] * radii[a] * radii[a];
//             // let delta_omega_friction_a: f32 = torque_friction_a / I_a;
//             // rot_vel_buf[a] += delta_omega_friction_a * deltaTime;
//             // let cappedFrictionForce = vec2(clamp(frictionForce.x, -10.0, 10.0), clamp(frictionForce.y, -10.0, 10.0));
//             // return (2.0 * mass2 / (mass1 + mass2)) * damping * (normal_force + cappedFrictionForce);   //Acceleration
//         }
//     } else {
//         return (2.0 * mass2 / (mass1 + mass2)) * damping * (normal_force); //Acceleration
//     }
// }