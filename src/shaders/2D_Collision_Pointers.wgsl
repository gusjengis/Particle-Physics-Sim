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
@group(1) @binding(2) var<storage, read_write> rot: array<f32>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(2) var<storage, read_write> contacts: array<Contact>;
@group(3) @binding(3) var<storage, read_write> contact_pointers: array<i32>;
@group(4) @binding(0) var<uniform> settings: Settings;
// @group(5) @binding(0) var<storage, read_write> col_sec: array<i32>;

const deltaTime: f32 = 0.0000390625;
const PI = 3.141592653589793238;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    
    
    // let id = i32(global_id.x);    
    // let max_contacts = 8;
    // var collisions = array<i32, 8u>();
    // var count = 0;
    // //OG O(n^2) Collisions
    // if settings.collisions == 1 {
    //     var collision_force = vec2(0.0, 0.0);
    //     for(var i = 0; i<id; i++){
    //         if contacts[i].b == id {
    //             collisions[count] = i;
    //         }
    //         count += 1;
    //         if count == max_contacts {
    //             break;
    //         }
    //     }
    // }

    // for(var i = id*max_contacts; i<(id+1)*max_contacts; i++){
    //     if contact_pointers[i] == -1 {
    //         continue;
    //     }
    //     var found = false;
    //     var location = -1;
    //     for(var j = 0; j<count; j++){
    //         if contact_pointers[i] == collisions[j] {
    //             found = true;
    //             location = j;
    //             break;
    //         }
    //     }
    //     if found {
    //         collisions[location] = collisions[count - 1];
    //         count -= 1;
    //         break;
    //     } else {
    //         contact_pointers[i] = -1;
    //     }
    // }

    // for(var i = 0; i<count; i++){
    //     for(var j = id*max_contacts; j<(id+1)*max_contacts; j++){
    //         if contact_pointers[j] == -1 {
    //             contact_pointers[j] = collisions[i];
    //             break;
    //         }
    //     }
    // }
}