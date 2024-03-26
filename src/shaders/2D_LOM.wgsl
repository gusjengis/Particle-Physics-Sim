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

const deltaTime: f32 = 0.0000390625; // We need to calculate this based on the model parameters
const PI = 3.141592653589793238;

// This calculation comes before the forece-displacement calculation
@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    // I think we want to use the equations of motion to update the position and the half step velocity
    // I'm using velocities_buf to store the half step velocity

    // Note: below, grav must be vec2<f32> with a default value of (0.0, -9.8) m/s/s
    // If we made rot the third component of positions, we could use a vec3<f32> for positions and velocities
    // and we could use a vec3<f32> for forces. This would allow us to use a single array for all of the data.
    // mass and gravity would also need to be vec3<f32> with the third component of mass being the moment of inertia.
    velocities_buf[id] = velocities[id] + (forces[id].xy/mass[id] + grav)*deltaTime/2.0;
    rot_vel_buf[id] = rot_vel[id] + forces[id].rot*deltaTime/moment_of_inertia[id]/2.0;

    if fixity[id].x_vel == 0 {
        // I don't think the acceleration should be updated here.
        velocities_buf[id].x = velocities[id].x;
    }

    if fixity[id].y_vel == 0 {
        velocities_buf[id].y = velocities[id].y;
    } 
    
    if fixity[id].rot_vel == 0 {
        rot_vel_buf[id] = rot_vel[id];
    }

    velocities[id] += vec2(forces[id].x, forces[id].y)*deltaTime;

    positions[id] = positions[id] + velocities_buf[id] * deltaTime;
    rot[id] = rot[id] + rot_vel_buf[id] * deltaTime;

    // I don't think we need to update the forces here.
    // Maybe this is intened to be updating externally applied forces?
    forces[id].x += forces[id].delX*deltaTime;
    forces[id].y += forces[id].delY*deltaTime;
    forces[id].rot += forces[id].delRot*deltaTime;
}