@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(1) @binding(0) var<storage, read_write> velocities: array<vec2<f32>>;
@group(2) @binding(0) var<storage, read_write> radii: array<f32>;
@group(3) @binding(0) var<storage, read_write> velocities_buf: array<vec2<f32>>;
@group(4) @binding(0) var<storage, read_write> colors: array<vec2<f32>>;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let id: u32 = global_id.x;

    let deltaTime: f32 = 0.0000390625;
    let gravity = 9.8 * deltaTime;
    let stiffness: f32 = 1000.0; // Arbitrarily chosen, adjust as per need
    let damping: f32 = 0.5; // Damping factor, can be adjusted

    velocities_buf[id] = vec2(velocities_buf[id].x, velocities_buf[id].y - gravity);

    for(var i = 0u; i<arrayLength(&radii); i++){
        if i != id {
            //detect collisions
            if length(positions[i] - positions[id]) < (radii[i] + radii[id]){
                // Calculate the overlap or penetration depth
                let overlap: f32 = (radii[i] + radii[id]) - length(positions[i] - positions[id]);

                // Calculate the normal of collision
                let normal: vec2<f32> = normalize(positions[i] - positions[id]);

                // Calculate the force based on the overlap and the stiffness constant
                let force: vec2<f32> = stiffness * overlap * normal;

                // Apply the force to the velocities (assuming equal masses for simplicity)
                let mass1: f32 = 3.14159265 * radii[id] * radii[id];
                let mass2: f32 = 3.14159265 * radii[i] * radii[i];

            // Calculate adjusted velocities based on masses
                velocities_buf[id] = velocities_buf[id] - (2.0 * mass2 / (mass1 + mass2)) * damping * force;
                // velocities_buf[i] = velocities_buf[i] + (2.0 * mass1 / (mass1 + mass2)) * damping * force;
                // velocities_buf[i] = velocities_buf[i] + damping * force;
                // colors[id] = max(colors[id], colors[i]);
                // colors[i] = max(colors[id], colors[i]);
            }
        }
    }

    let pos = positions[id];
    let rad = radii[id];
    let elasticity = 0.5;
    let xW = 2.0*16.0/9.0;
    // if pos.x+rad > xW {
    //     let overlap: f32 = (pos.x + rad) - xW;
    //     let force: vec2<f32> = vec2(-stiffness * overlap, 0.0);
    //     velocities_buf[id] += damping * force;
    //     positions[id].x = xW - rad;
    // } else if pos.x-rad < -xW {
    //     let overlap: f32 = xW + (pos.x - rad);
    //     let force: vec2<f32> = vec2(stiffness * overlap, 0.0);
    //     velocities_buf[id] += damping * force;
    //     positions[id].x = -xW + rad;
    // }
    // if pos.y+rad > 2.0 {
    //     let overlap: f32 = (pos.y + rad) - 2.0;
    //     let force: vec2<f32> = vec2(0.0, -stiffness * overlap);
    //     velocities_buf[id] += damping * force;
    //     positions[id].y = 2.0 - rad;
    // } else if pos.y-rad < -2.0 {
    //     let overlap: f32 = (radii[id]) - length(vec2(positions[id].x, -2.0) - positions[id]);
    //     let next_pos = positions[id] + velocities[id] * deltaTime;
    //     let wall_int = (abs(positions[id].y - 2.0)/(positions[id].y - next_pos.y))*next_pos;
    //     let normal: vec2<f32> = normalize(cross(vec3(0.0, 0.0, 1.0), vec3(wall_int, 0.0)).xy);
    //     let force: vec2<f32> = stiffness * overlap * normal;
    //     velocities_buf[id] = velocities_buf[id] - damping * force;
    // }
    if pos.x+rad > xW {
        velocities_buf[id] = vec2(-velocities_buf[id].x, velocities_buf[id].y)*elasticity;
        positions[id] = vec2(xW-rad, pos.y);
    } else if pos.x-rad < -xW {
        velocities_buf[id] = vec2(-velocities_buf[id].x, velocities_buf[id].y)*elasticity;
        positions[id] = vec2(-xW+rad, pos.y);
    }
    if pos.y+rad > 2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x, -velocities_buf[id].y)*elasticity;
        positions[id] = vec2(pos.x, 2.0-rad);
    } else if pos.y-rad < -2.0 {
        velocities_buf[id] = vec2(velocities_buf[id].x, -velocities_buf[id].y)*elasticity;
        positions[id] = vec2(pos.x, -2.0+rad);
    }
}