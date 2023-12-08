struct Bond {
    index: i32,
    angle: f32,
    length: f32
};

struct Contact {
    a: i32,
    angle_a: f32,
    indent: f32,
    b: i32,
    angle_b: f32,
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
@group(1) @binding(1) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(1) @binding(3) var<storage, read_write> rot_vel: array<f32>;
@group(1) @binding(4) var<storage, read_write> rot_vel_buf: array<f32>;
@group(1) @binding(5) var<storage, read_write> forces: array<vec3<f32>>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> bonds: array<Bond>;
@group(3) @binding(1) var<storage, read_write> bond_info: array<vec2<i32>>;
@group(3) @binding(2) var<storage, read_write> contacts: array<Contact>;
@group(3) @binding(3) var<storage, read_write> contact_pointers: array<i32>;
@group(4) @binding(0) var<uniform> settings: Settings;
// @group(5) @binding(0) var<storage, read_write> col_sec: array<i32>;

const deltaTime: f32 = 0.0000390625;
const max_contacts = 8u;
const PI = 3.141592653589793238;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {

    let id: u32 = global_id.x;
    let stiffness: f32 = 10.0; // Arbitrarily chosen, adjust as per need
    let damping: f32 = 0.2; // Damping factor, can be adjusted

    var net_force = vec2(0.0, 0.0);
    var net_moment = 0.0;

    if settings.collisions == 1 {
        // higher ids
        for(var i = id*max_contacts; i<(id+1u)*max_contacts; i++){
            if contacts[i].b != -1 { 
                let a = contacts[i].a;
                let b = contacts[i].b;
                let normal = normalize(positions[a] - positions[b]); 
                let tangent = vec2(-normal.y, normal.x);
                net_force += damping * (normal*contacts[i].normal_force + tangent*contacts[i].tangent_force);
                net_moment -= (radii[a] - contacts[i].indent)*contacts[i].tangent_force;
            }
            // else if contact_pointers[i] != -1 {
            //     let contact = contacts[contact_pointers[i]];
            //     let a = contact.b;
            //     let b = contact.a;
            //     if a == -1 || b == -1 { continue; } 

            //     // positions[id] = vec2(f32(b), 0.0);
            //     let normal = normalize(positions[a] - positions[b]); 
            //     net_force += damping * (normal*contact.normal_force);
            // }
        }

        // lower ids
        for(var i = 0u; i<(id)*max_contacts; i++){
            if contacts[i].b != i32(id){
                continue;
            }
            let a = contacts[i].b;
            let b = contacts[i].a;
            let normal = normalize(positions[a] - positions[b]); 
            let tangent = vec2(-normal.y, normal.x);
            net_force += damping * (normal*contacts[i].normal_force + tangent*contacts[i].tangent_force);
            net_moment -= (radii[a] - contacts[i].indent)*contacts[i].tangent_force;
        }
    }

    
    
    //Bonds
    if settings.bonds == 1 {
        let start = bond_info[id].x;
        let length = bond_info[id].y;
        let shear_lim = 0.11;
        let normal_lim = 1.00;
        if(start != -1){
            for(var i = u32(start); i<u32(start+length); i++){
                let bond_id: i32 = bonds[i].index;
                if(bond_id == -1){
                    continue;
                }

                // Linear Bonds, this is working
                if settings.linear_contact_bonds == 1 {
                    let dist: f32 = length(positions[bond_id] - positions[id]);
                    let ideal_length: f32 = (radii[id] + radii[bond_id]);//bonds[i].length;////
                    let displacement: f32 = ideal_length - dist;
                    let spring_force: vec2<f32> = stiffness/100.0 * displacement * normalize(positions[bond_id] - positions[id]);
                    var force = (spring_force) * damping;
                    net_force -= force;
                    // if length(force) > normal_lim {
                    //     bonds[i].index = -1;
                    // }
                } else {
                    let ideal_position = positions[bond_id] + vec2(cos(bonds[i].angle + rot[bond_id]), sin(bonds[i].angle + rot[bond_id]))*bonds[i].length;
                    let displacement: f32 = length(ideal_position - positions[id]);
                    let spring_force: vec2<f32> = displacement * normalize(ideal_position - positions[id]);
                    var force = (spring_force) * damping;
                    net_force -= force;
                    // Parallel Bonds, wip

                    // let left_stiffness = 100.0;
                    // let right_stiffness = 100.0;
                    // let shear_stiffness = 100.0;
                    // let mass = 3.14159265 * radii[id] * radii[id];
                    // let rot_inertia = 0.5*mass*radii[id]*radii[id];
                    // let R = sqrt(radii[id]*radii[bond_id]);
                    
                    // // left spring

                    // let pos_A = positions[id];
                    // let pos_B = positions[bond_id];
                    // var angle_A = (rot[id] + bonds[i].angle + PI/2.0);
                    // var angle_B = (rot[bond_id] + bonds[i].angle + PI/2.0);
                    // // angle_A = sign(angle_A) * (abs(angle_A) % 2.0*PI);
                    // // angle_B = sign(angle_B) * (abs(angle_B) % 2.0*PI);
                    // let left_spring_end_A = pos_A + R*vec2(cos(angle_A), sin(angle_A));
                    // let left_spring_end_B = pos_B + R*vec2(cos(angle_B), sin(angle_B));
                    // let left_spring_dir = normalize(left_spring_end_B - left_spring_end_A);
                    // let left_spring_length = length(left_spring_end_A - left_spring_end_B);
                    // let ideal_length = bonds[i].length;
                    // let left_displacement = left_spring_length - ideal_length ;
                    // let left_force_magnitude = left_displacement*left_stiffness;
    
    
                    // let left_moment = R * left_force_magnitude;

                    // // right spring 

                    // let right_spring_end_A = pos_A + R*vec2(cos(angle_A + PI), sin(angle_A + PI));
                    // let right_spring_end_B = pos_B + R*vec2(cos(angle_B + PI), sin(angle_B + PI));
                    // let right_spring_dir = normalize(right_spring_end_B - right_spring_end_A);
                    // let right_spring_length = length(right_spring_end_A - right_spring_end_B);
                    // let right_displacement = right_spring_length - ideal_length;
                    // let right_force_magnitude = right_displacement*right_stiffness;
                    // let right_moment = -R * right_force_magnitude;

                    // // shear spring
                    // let bond_dir = vec2(-sin(rot[bond_id] + bonds[i].angle + PI), cos(rot[bond_id] + bonds[i].angle + PI));
                    // let tangent_dir = vec2(-bond_dir.y, bond_dir.x);
                    // let ideal_postition = pos_B + ideal_length*bond_dir;
                    // let displacement = ideal_postition - pos_A;
                    // let shear_force = dot(displacement, tangent_dir)*shear_stiffness;
                    // //apply forces

                    // rot_vel_buf[id] += (left_moment + right_moment);// / rot_inertia;
                    // rot_vel_buf[id] += (-shear_force);// / rot_inertia;
                    // net_force += (right_spring_dir * right_force_magnitude + left_spring_dir * left_force_magnitude + shear_force*tangent_dir);//


                        // let R = sqrt(radii[id]*radii[bond_id]);
                        // let rigidity = 5.0;
     
                        // // let diff = (positions[bond_id] - positions[id]);
                        // // let dist2 = length(diff);
                        // // let curr_angle = acos(diff.x/dist2);
                        // let bond_angle = bonds[i].angle;
                        // let other_bond_angle = (bond_angle + PI + rot[bond_id]) % (2.0*PI);
                        // let bond_dir = normalize(vec2(sin(other_bond_angle), cos(other_bond_angle)));
                        // // let bond_point = bond_dir*radii[bond_id] + positions[bond_id];
                        // // let bond_pos_diff = bond_point - positions[id];
                        // let shear_dir = normalize(vec2(-bond_dir.y, bond_dir.x));
                        // let ideal_pos = bond_dir*(bonds[i].length) + positions[bond_id];//radii[bond_id]+radii[id]
                        // let displacement2 = positions[id] - ideal_pos;
                        // let shear_force = dot(displacement2, shear_dir);
                        // let normal_force = dot(displacement2, bond_dir);
     
                        // net_force -= (shear_force*shear_dir + normal_force*bond_dir)*rigidity;
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
    }

    let mass1 = PI * radii[id] * radii[id];
    let rot_inertia = 0.5*mass1*radii[id]*radii[id];
    velocities_buf[id] = velocities[id] + net_force/mass1;
    rot_vel_buf[id] = rot_vel[id] + net_moment/rot_inertia;
    if settings.gravity == 1 {
        let gravity = settings.gravity_acc * deltaTime;
        velocities_buf[id] += vec2(0.0, -gravity);
    }
    // BS Walls
    let pos = positions[id];
    let rad = radii[id];
    let elasticity = 0.5;
    let anti_stick_coating = 0.01;
    let yH = settings.vert_bound;
    let xW = settings.hor_bound;
    
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