pub struct Settings {
    pub genPerFrame: i32,
    pub particles: usize,
    pub workgroups: usize,
    pub max_radius: f32,
    pub min_radius: f32,
    pub max_bonds: usize,
    pub max_init_velocity: f32,
    pub setup: Intial_Positions,
    pub tower_width: f32,
}

impl Settings {
    pub fn new() -> Self {
        let genPerFrame = 1;
        let workgroups = 2;
        let workgroup_size = 256;
        //particle settings
        let max_radius = 0.1/3.2;
        let min_radius = max_radius/1.7;
        let max_bonds = 4;
        let max_init_velocity = 4.0;
        let particles = workgroup_size*workgroups;
        let setup = Intial_Positions::Tower;
        let tower_width = 16.0;
        Self {
            genPerFrame,
            particles,
            workgroups,
            max_radius,
            min_radius,
            max_bonds,
            max_init_velocity,
            setup,
            tower_width
        }
    }
}

pub enum Intial_Positions {
    Tower,
    Random
}