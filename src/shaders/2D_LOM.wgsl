[[group(0), binding(0)]] var<storage, read_write> particles: array<Particle>;
[[group(0), binding(1)]] var<storage, read_write> velocities: array<Velocity>;

struct Particle {
    pos: vec2<f32>;
};

struct Velocity {
    vel: vec2<f32>;
};

[[stage(compute), workgroup_size(64)]]
fn main([[builtin(global_invocation_id)]] global_id: vec3<u32>) {
    let id: u32 = global_id.x;
    var p: Particle = particles[id];
    var v: Velocity = velocities[id];

    let deltaTime: f32 = 0.016; // assuming 60 FPS
    
    // Update the particle's position considering the velocity.
    p.pos = p.pos + v.vel * deltaTime;

    // Update the particle data in the buffer.
    particles[id] = p;
}