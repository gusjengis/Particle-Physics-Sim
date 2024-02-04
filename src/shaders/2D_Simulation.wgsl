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

struct Contact {
    a: i32,
    b: i32,
    tangent_force: f32,
    bonded: i32
};

struct Bond {
    index: i32,
    angle: f32,
    length: f32
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
    gravity_acc: f32,
    stiffness: f32,
    bonds_tear: i32,
    bond_force_limit: f32
}

struct Material {
    red: f32,
    green: f32,
    blue: f32,
    density: f32,
    normal_stiffness: f32,
    shear_stiffness: f32,
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
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> bonds: array<Bond>;
@group(3) @binding(1) var<storage, read_write> bond_info: array<vec2<i32>>;
@group(3) @binding(2) var<storage, read_write> contacts: array<Contact>;
@group(3) @binding(3) var<storage, read_write> contact_pointers: array<i32>;
@group(3) @binding(4) var<storage, read_write> material_pointers: array<i32>;
@group(4) @binding(0) var<uniform> settings: Settings;
@group(5) @binding(0) var<storage, read_write> materials: array<Material>;


const deltaTime: f32 = 0.0000390625;
const PI = 3.141592653589793238;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {

    let id: u32 = global_id.x;
    let mat_id = material_pointers[id];

    let damping: f32 = 0.2; // Damping factor, can be adjusted

    var net_force = vec2(0.0, 0.0);
    var net_moment = 0.0;

    //Bonds
    let bond_shear_lim = 0.5;
    var bonded_particles = array<i32, 6u>(-1,-1,-1,-1,-1,-1);
    if settings.bonds != 0 {
        let start = bond_info[id].x;
        let length = bond_info[id].y;
        if(start != -1){
            for(var i = u32(start); i<u32(start+length); i++){
                let bond_id: i32 = bonds[i].index;
                if(bond_id < 0){
                    continue;
                }
                if settings.bonds == 2 || settings.bonds == 3 {
                    bonded_particles[i-u32(start)] = bond_id;
                }
                if settings.bonds == 1 || settings.bonds == 2 || settings.bonds == 3 {
                    let displacement: f32 = -distance(i32(id), bond_id);
                    let spring_force: vec2<f32> = settings.stiffness * displacement * normalize(positions[bond_id] - positions[id]);
                    var force = (spring_force) * damping;
                    net_force -= force;
                    if settings.bonds_tear == 1 && displacement > settings.bond_force_limit {
                        bonds[i].index = -bonds[i].index;
                    }
                    if settings.bonds == 3 {
                        let ideal_rot = rot[bond_id];
                        let rot_disp = rot[id] - rot[bond_id];
                        net_moment -= (radii[id])*rot_disp/10000.0;

                    }
                } else {
                    // Linear Bonds, w/ shear resistance 

                    // let bond_angle = bonds[i].angle;
                    // let other_bond_angle = (bond_angle + PI + rot[bond_id] ) % (2.0*PI);
                    // let bond_dir = vec2(sin(other_bond_angle), cos(other_bond_angle));
                    // let ideal_pos = bond_dir*(bonds[i].length) + positions[bond_id];
                    // let rot_displacement = rot[bond_id] - rot[id];
                    // let displacement =  ideal_pos - positions[id];
                    // let force = displacement*settings.stiffness;

                    // let moment = rot_displacement;//*materials[(material_pointers[id])].shear_stiffness;
                    // net_moment += moment*deltaTime;
                    // net_force += force;
                    // if settings.bonds_tear == 1 && length(force) > settings.bond_force_limit {
                    //     bonds[i].index = -bonds[i].index;
                    // }
                }
            }
        }
    }

    //OG O(n^2) Collisions
    if settings.collisions == 1 {
        let max_contacts = 8u;
        var collisions = array<i32, 8u>();
        var count = 0u;
        //make a list of particles that we're colliding with
        for(var i = 0u; i<arrayLength(&radii); i++){
            if i != id {
                if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
                    collisions[count] = i32(i);
                    count += 1u;
                    if count == max_contacts {
                        break;
                    }
                } 
            }
        }
        //delete contacts that don't exist
        for(var j = id*max_contacts; j<(id+1u)*max_contacts; j++){
            if contacts[j].b == -1 {
                continue;
            }
            var found_contact = false;
            var other_particle = -1;
            for(var i = 0u; i<count; i++){
                if contacts[j].b == collisions[i] {
                    found_contact = true;
                    other_particle = (contacts[j].b);
                }
            }
            if !found_contact && contacts[j].bonded == -1 {
                //delete
                contacts[j].a = -1;
                contacts[j].b = -1;
                for(var k = u32(other_particle)*max_contacts; k<(u32(other_particle)+1u)*max_contacts; k++) {
                    if contact_pointers[k] == i32(j) {
                        contact_pointers[k] = -1;
                        break;
                    }
                }
            }
        }   

        //create new contacts
        for(var i = 0u; i<count; i++){
            var existing_index = -1;
            var empty_index = -1;
            for(var j = id*max_contacts; j<(id+1u)*max_contacts; j++){
                if contacts[j].b == collisions[i] {
                    existing_index = i32(j);
                    break;
                } else if contacts[j].b == -1 {
                    empty_index = i32(j);
                }
                
            }
            
            if existing_index == -1 && empty_index == -1 {
                continue;
            } else if existing_index == -1 { // initialize completely new contact
                let b = collisions[i];
                for(var j = 0u; j<6u; j++){
                    if bonded_particles[j] == contacts[i].b {
                        contacts[empty_index].bonded = 1;
                        break;
                    }
                }
                contacts[empty_index].a = i32(id);
                contacts[empty_index].b = b;
                contacts[empty_index].tangent_force = 0.0;
            }

        }

        for(var i = id*max_contacts; i<(id+1u)*max_contacts; i++){
            if contacts[i].b == -1{
                continue;
            }
            var bonded = false;
            for(var j = 0u; j<6u; j++){
                if bonded_particles[j] == contacts[i].b {
                    bonded = true;
                    break;
                }
            }
            if bonded == false {
                contacts[i].bonded = -1;
            }
            let a = contacts[i].a;
            let b = contacts[i].b;
            let overlap = max(-distance(a, b), 0.0);
            
            var normal_stiffness = 10.0;
            var shear_stiffness = 0.25;
            if mat_id != -1 {
                normal_stiffness = (materials[(material_pointers[b])].normal_stiffness);
                shear_stiffness = (materials[(material_pointers[b])].shear_stiffness);
            }
            var normal_force = overlap*normal_stiffness;
            let normal = normalize(positions[a] - positions[b]); 
            let tangent = vec2(-normal.y, normal.x);

            let del_pos_a = velocities[a]*deltaTime;
            let del_pos_b = velocities[b]*deltaTime;
            let del_rot_a = rot_vel[a]*deltaTime*(radii[a]);//-overlap/2.0);
            let del_rot_b = rot_vel[b]*deltaTime*(radii[b]);//-overlap/2.0);
            
            let rel_trans = del_pos_b - del_pos_a;
            let rel_rot = del_rot_b + del_rot_a;
            
            let rel_tangent = dot(rel_trans, tangent) + rel_rot;
            
            var friction_limit = abs(normal_force)*settings.friction_coefficient;
            var moment = true;
            if bonded && settings.bonds == 2 || settings.bonds == 3 {
                normal_force = 0.0;
                friction_limit = bond_shear_lim;
                moment = false;
            }
            contacts[i].tangent_force = contacts[i].tangent_force + rel_tangent*shear_stiffness;//clamp(contacts[i].tangent_force + rel_tangent*shear_stiffness, -friction_limit, friction_limit);
            net_force += damping * (normal*normal_force + tangent*contacts[i].tangent_force);
            // if moment {
            net_moment -= (radii[a])*contacts[i].tangent_force;// - overlap/2.0
            // }
        }
    }
    
    // Apply sum of forces and gravity to velocities
    var density = 1.0;
    if mat_id != -1 {
        density = materials[mat_id].density;
    }
    let mass1 = density * PI * radii[id] * radii[id];
    let rot_inertia = 0.5*mass1*radii[id]*radii[id];
    velocities_buf[id] = velocities[id] + net_force/mass1;
    rot_vel_buf[id] = rot_vel[id] + net_moment/rot_inertia;
    if settings.gravity == 1 {
        let gravity = 9.81 * settings.gravity_acc * deltaTime;
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

fn distance(a: i32, b: i32) -> f32 {
    return  length(positions[a] - positions[b]) - (radii[a] + radii[b]);
}