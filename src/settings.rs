pub struct Settings {
    pub genPerFrame: i32,
    pub particles: usize,
    pub max_radius: f32,
    pub min_radius: f32,
    pub max_init_velocity: f32
}

impl Settings {
    pub fn new() -> Self {
        let genPerFrame = 1;
        let workgroups = 1;
        //particle settings
        let max_radius = 0.1;
        let min_radius = 0.002;
        let max_init_velocity = 4.0;
        let particles = 256*workgroups;
        Self {
            genPerFrame,
            particles,
            max_radius,
            min_radius,
            max_init_velocity
        }
    }
}