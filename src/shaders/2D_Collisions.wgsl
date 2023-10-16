@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> velocities_buf: array<vec2<f32>>;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let deltaTime: f32 = 0.0000390625; // assuming 60 FPS
    let elasticity = 0.5; 

    velocities_buf[id] = velocities[id];

    let pos = positions[id];
    let rad = radii[id];
    
    let gravity = 9.8 * deltaTime;

    velocities_buf[id] = vec2(velocities_buf[id].x, velocities_buf[id].y - gravity);

    if pos.x+rad > 2.0 {
        velocities_buf[id] = vec2(-velocities_buf[id].x*elasticity, velocities_buf[id].y*elasticity);
        positions[id] = vec2(2.0-rad, pos.y);
    } else if pos.x-rad < -2.0 {
        velocities_buf[id] = vec2(-velocities_buf[id].x*elasticity, velocities_buf[id].y*elasticity);
        positions[id] = vec2(-2.0+rad, pos.y);
    }
    if pos.y+rad > 2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x*elasticity, -velocities_buf[id].y*elasticity);
        positions[id] = vec2(pos.x, 2.0-rad);
    } else if pos.y-rad < -2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x*elasticity, -velocities_buf[id].y*elasticity);
        positions[id] = vec2(pos.x, -2.0+rad);
    }

    for(var i = 0u; i<arrayLength(&radii); i++){
        if i != id {
            // if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
            //     velocities_buf[id] = elasticity*(velocities[i] - velocities[id]);
            // }
            let delta = positions[i] - positions[id];
            let distance = length(delta);
            let minDistance = radii[i] + rad;

            // Check for collision
            if distance < minDistance {
                // Calculate the collision response
                let normal = normalize(delta);
                let relativeVelocity = velocities[i] - velocities[id];
                let impulse = (2.0 * elasticity * dot(relativeVelocity, normal)) / (1.0 + 1.0);

                // Update velocities for both particles
                velocities_buf[id] = velocities[id] + impulse * normal;
                velocities_buf[i] = velocities[i] - impulse * normal;

                // Separate particles to avoid overlap
                let separation = (minDistance - distance) * 0.5;
                positions[id] -= separation * normal;
                positions[i] += separation * normal;
            }
        }
    }

    if pos.x+rad > 2.0 {
        velocities_buf[id] = vec2(-velocities_buf[id].x*elasticity, velocities_buf[id].y*elasticity);
        positions[id] = vec2(2.0-rad, pos.y);
    } else if pos.x-rad < -2.0 {
        velocities_buf[id] = vec2(-velocities_buf[id].x*elasticity, velocities_buf[id].y*elasticity);
        positions[id] = vec2(-2.0+rad, pos.y);
    }
    if pos.y+rad > 2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x*elasticity, -velocities_buf[id].y*elasticity);
        positions[id] = vec2(pos.x, 2.0-rad);
    } else if pos.y-rad < -2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x*elasticity, -velocities_buf[id].y*elasticity);
        positions[id] = vec2(pos.x, -2.0+rad);
    }
}