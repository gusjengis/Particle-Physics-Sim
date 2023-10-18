pub struct Settings {
    pub genPerFrame: i32,
    pub particles: usize
}

impl Settings {
    pub fn new() -> Self {
        let genPerFrame = 1;
        let workgroups = 1;
        let particles = 256*workgroups;
        Self {
            genPerFrame,
            particles
        }
    }
}