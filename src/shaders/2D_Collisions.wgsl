struct Contact {
    a: i32,
    angle_a: f32,
    indent: f32,
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
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(2) var<storage, read_write> contacts: array<Contact>;
@group(3) @binding(3) var<storage, read_write> contact_pointers: array<i32>;
@group(4) @binding(0) var<uniform> settings: Settings;
// @group(5) @binding(0) var<storage, read_write> col_sec: array<i32>;

const deltaTime: f32 = 0.0000390625;
const PI = 3.141592653589793238;

@compute @workgroup_size(1)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    
    
    let id: u32 = global_id.x;    
    let max_contacts = 8u;
    var collisions = array<i32, 8u>();//settings.max_contacts
    var count = 0u;
    //OG O(n^2) Collisions
    if settings.collisions == 1 {
        var collision_force = vec2(0.0, 0.0);
        for(var i = id+1u; i<arrayLength(&radii); i++){
            // if i == id {
            //     continue;
            // }
            //detect collisions
            if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
                // collision_force += collide(id, i, stiffness, damping);
                collisions[count] = i32(i);
                count += 1u;
                if count == max_contacts {
                    break;
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
            if !found_contact {
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
            // if u32(collisions[i]) < id {
            //     var existing_index = -1;
            //     var empty_index = -1;
            //     for(var j = id*max_contacts; j<(id+1u)*max_contacts; j++){
            //         if contact_pointers[j] >= collisions[i]*i32(max_contacts) && contact_pointers[j] < (collisions[i]+1)*i32(max_contacts){
            //             existing_index = i32(j);
            //             break;
            //         } else if contact_pointers[j] == -1 {
            //             empty_index = i32(j);
            //         }
            //     }
            //     if existing_index == -1 && empty_index == -1 {
            //         continue;
            //     } else if existing_index == -1 { // initialize new contact pointer
            //         let b = collisions[i];
                    
            //         for(var j = u32(b)*max_contacts; j<(u32(b)+1u)*max_contacts; j++) {

            //             if contacts[j].b == i32(id) {
            //                 // positions[id] = vec2(f32(contacts[j].b), f32(id));
            //                 contact_pointers[empty_index] = i32(j);
            //                 // positions[id] = vec2(0.0, f32(j));

            //                 break;
            //             }
            //         }
            //     }
            // } else {
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
                    let delta = positions[b] - positions[id]; 
                    let delta_norm = normalize(delta); 
                    let overlap = (radii[id] + radii[b]) - length(delta);
                    contacts[empty_index].a = i32(id);
                    contacts[empty_index].angle_a = atan2(delta_norm.x, delta_norm.y);
                    contacts[empty_index].indent = overlap/2.0;
                    contacts[empty_index].b = b;
                    contacts[empty_index].normal_force = 0.0;
                    contacts[empty_index].tangent_force = 0.0;

                    // for(var j = u32(b)*max_contacts; j<(u32(b)+1u)*max_contacts; j++) {
                    //     if contact_pointers[j] == -1 {
                    //         contact_pointers[j] = empty_index;
                    //         break;
                    //     }
                    // }
                }
            // }
        }
    }

}























// fn collisionsInSection(id: u32, sec: u32, stiffness: f32, damping: f32) {
//     // let sec_size = 30u;
//     // // for(var i = sec*sec_size; i<(sec+1u)*sec_size; i++){
//     // for(var i = 0u; i<arrayLength(&col_sec); i++){
//     //     if(col_sec[i] == -1) {
//     //         continue;
//     //     }
//     //     let j = u32(col_sec[i]);
//     //     if j != id {
//     //         //detect collisions
//     //         if length(positions[j] - positions[id]) < (radii[j] + radii[id]){
//     //             collide(id, j, stiffness, damping);
//     //         }
//     //     }
//     // }
// }


// fn pointToSectionId(point: vec2<f32>) -> u32 {
//     let coll_grid_w = 30.0;
//     let coll_grid_h = 30.0;
//     let sec_x = u32((point.y + settings.hor_bound)/(2.0*settings.hor_bound) * coll_grid_w);
//     let sec_y = u32((point.y + settings.vert_bound)/(2.0*settings.vert_bound) * coll_grid_h);
//     return sec_y*u32(coll_grid_w) + sec_x;
// }

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