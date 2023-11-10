use egui::*;

use crate::wgpu_structs::Uniform;

pub struct Settings {
    pub genPerFrame: i32,
    pub particles: usize,
    pub workgroups: usize,
    pub workgroup_size: usize,
    pub max_radius: f32,
    pub min_radius: f32,
    pub max_bonds: usize,
    pub max_h_velocity: f32,
    pub min_h_velocity: f32,
    pub max_v_velocity: f32,
    pub min_v_velocity: f32,
    pub structure: Structure,
    pub grid_width: f32,
    pub variable_rad: bool,
    pub settings_menu: bool,
    pub holeyness: f32,
    pub maintain_ar: bool,
    pub hor_bound: f32,
    pub vert_bound: f32,
    pub gravity: bool,
    pub bonds: bool,
    pub collisions: bool,
    pub friction: bool,
    pub friction_coefficient: f32,
    pub rotation: bool,
    pub linear_contact_bonds: bool,
    pub changed_collision_settings: bool,
    pub scale: f32,
    pub circular_particles: bool,
    pub render_rot: bool,
    pub color_code_rot: bool,
    pub colors: i32,
}

impl Settings {
    pub fn new() -> Self {
        let genPerFrame = 1;
        let workgroups = 4;
        let workgroup_size = 256;
        //particle settings
        let max_radius = 0.1/3.2;
        let variable_rad = true;
        let holeyness = 1.7;
        let min_radius = max_radius/holeyness;
        let max_bonds = 4;
        let max_h_velocity = 0.0;
        let min_h_velocity = 0.0;
        let max_v_velocity = 0.0;
        let min_v_velocity = 0.0;
        let particles = workgroup_size*workgroups;
        let structure = Structure::Grid;
        let grid_width = 32.0;
        let settings_menu = false;
        let maintain_ar = true;
        let hor_bound = 6.0;
        let vert_bound = 4.0;
        let gravity = true;
        let bonds = true;
        let collisions = true;
        let friction = true;
        let friction_coefficient = 0.2;
        let rotation = true;
        let linear_contact_bonds = true;
        let changed_collision_settings = false;
        let scale = 1.0/vert_bound;
        let circular_particles = true;
        let render_rot = true;
        let color_code_rot = true;
        let colors = 32;
        Self {
            genPerFrame,
            particles,
            workgroups,
            workgroup_size,
            max_radius,
            min_radius,
            max_bonds,
            max_h_velocity,
            min_h_velocity,
            max_v_velocity,
            min_v_velocity,
            structure,
            grid_width,
            variable_rad,
            settings_menu,
            holeyness,
            maintain_ar,
            hor_bound,
            vert_bound,
            gravity,
            bonds,
            collisions,
            friction,
            friction_coefficient,
            rotation,
            linear_contact_bonds,
            changed_collision_settings,
            scale,
            circular_particles,
            render_rot,
            color_code_rot,
            colors
        }
    }

    pub fn ui(&mut self, ctx: &Context) -> bool {
        let mut reset = false;
        if self.settings_menu {
            egui::Window::new("Settings").collapsible(false).show(ctx, |ui| {
                // ui.add(egui::Hyperlink::from_label_and_url("This Repo!", "https://github.com/gusjengis/DEM"));
                // ui.heading("Settings");
                egui::CollapsingHeader::new("Setup").show(ui, |ui| {
                    if ui.add(egui::Slider::new(&mut self.particles, self.workgroup_size..=self.workgroup_size*100).
                    text("Particles").
                    step_by(self.workgroup_size as f64)).changed() {
                        self.workgroups = self.particles/self.workgroup_size;
                        reset = true;
                    };
                    
                    egui::ComboBox::from_label("Structures")
                        .selected_text(format!("{:?}", self.structure))
                        .show_ui(ui, |ui| {
                            reset = ui.selectable_value(&mut self.structure, Structure::Random, "Random").changed();
                            reset = ui.selectable_value(&mut self.structure, Structure::Grid, "Grid").changed();
                        });
                    if self.structure == Structure::Grid {
                        if ui.add(egui::Slider::new(&mut self.grid_width, 1.0..=self.particles as f32).
                        text("Grid Width")
                        .logarithmic(true)).changed() {
                            reset = true;
                        };
                    }
                    if ui.checkbox(&mut self.variable_rad, "Random Radius").changed() {
                        reset = true;
                    }
                    if self.variable_rad {
                        match self.structure {
                            Structure::Grid => {
                                if ui.add(egui::Slider::new(&mut self.holeyness, 1.0..=10.0).
                                text("Holeyness")).changed() {
                                    self.min_radius = self.max_radius/self.holeyness;
                                    reset = true;
                                };
                            },
                            _ => {
                                if ui.add(egui::Slider::new(&mut self.max_radius, 0.0001..=0.5).
                                text("Max Radius")).changed() {
                                    reset = true;
                                };
                                if ui.add(egui::Slider::new(&mut self.min_radius, 0.0001..=0.5).
                                text("Min Radius")).changed() {
                                    reset = true;
                                };
                            }
                        }
                    }
                    egui::CollapsingHeader::new("Initial Velocities").show(ui, |ui| {
                        if ui.add(egui::Slider::new(&mut self.max_h_velocity, -10.0..=10.0).
                        text("Max xV")).changed() {
                            if self.max_h_velocity < self.min_h_velocity {
                                self.min_h_velocity = self.max_h_velocity;
                            }
                            reset = true;
                        };
                        if ui.add(egui::Slider::new(&mut self.min_h_velocity, -10.0..=10.0).
                        text("Min xV")).changed() {
                            if self.max_h_velocity < self.min_h_velocity {
                                self.max_h_velocity = self.min_h_velocity;
                            }
                            reset = true;
                        };
                        if ui.add(egui::Slider::new(&mut self.max_v_velocity, -10.0..=10.0).
                        text("Max yV")).changed() {
                            if self.max_v_velocity < self.min_v_velocity {
                                self.min_v_velocity = self.max_v_velocity;
                            }
                            reset = true;
                        };
                        if ui.add(egui::Slider::new(&mut self.min_v_velocity, -10.0..=10.0).
                        text("Min yV")).changed() {
                            if self.max_v_velocity < self.min_v_velocity {
                                self.max_v_velocity = self.min_v_velocity;
                            }
                            reset = true;
                        };
                    });
                });
                
                egui::CollapsingHeader::new("Runtime").default_open(true).show(ui, |ui| {
                    if ui.add(egui::Slider::new(&mut self.genPerFrame, 1..=214).
                        logarithmic(true).
                        text("Gen/Frame")).changed() {
                            self.workgroups = self.particles/self.workgroup_size;
                        };
                    egui::CollapsingHeader::new("Physics").default_open(false).show(ui, |ui| {
                        if ui.checkbox(&mut self.gravity, "Gravity").changed() {
                            self.changed_collision_settings = true;
                        }
                        if ui.checkbox(&mut self.bonds, "Bonds").changed() {
                            self.changed_collision_settings = true;
                        }
                        if self.bonds {
                            if ui.checkbox(&mut self.linear_contact_bonds, "Linear Bonds").changed() {
                                self.changed_collision_settings = true;
                            }
                        }
                        if ui.checkbox(&mut self.collisions, "Collisions").changed() {
                            self.changed_collision_settings = true;
                        }
                        if self.collisions {
                            if ui.checkbox(&mut self.friction, "Friction").changed() {
                                self.changed_collision_settings = true;
                            }
                            if self.friction {
                                if ui.add(egui::Slider::new(&mut self.friction_coefficient, 0.0..=1.0).
                                    text("Friction Coefficent")).changed() {
                                        self.changed_collision_settings = true;
                                    };
                                if ui.checkbox(&mut self.rotation, "Rotation").changed() {
                                    self.changed_collision_settings = true;
                                }
                            }
                        }
                        
                        
                    });

                    egui::CollapsingHeader::new("Walls").default_open(false).show(ui, |ui| {
                        ui.checkbox(&mut self.maintain_ar, "Maintain Aspect Ratio");
                        let ar = self.hor_bound/self.vert_bound;
                        if ui.add(egui::Slider::new(&mut self.hor_bound, 0.0..=16.0).
                            text("Width")).changed() {
                                self.changed_collision_settings = true;
                                if self.maintain_ar {
                                    self.vert_bound = self.hor_bound*1.0/ar;
                                }
                            };
                        if ui.add(egui::Slider::new(&mut self.vert_bound, 0.0..=16.0).
                            text("Height")).changed() {
                                self.changed_collision_settings = true;
                                if self.maintain_ar {
                                    self.hor_bound = self.vert_bound*ar;
                                }
                            };
                    });

                });
                ui.horizontal(|ui| {
                    if ui.button("Reset Settings").clicked() {
                        self.reset();
                    }
                });
            });
        }
        return reset;
    }

    pub fn collison_settings(&mut self) -> Vec<f32> {
        self.changed_collision_settings = false;
        return vec![
            self.hor_bound,
            self.vert_bound,
            bytemuck::cast(1 as i32 * self.gravity as i32),
            bytemuck::cast(1 as i32 * self.bonds as i32),
            bytemuck::cast(1 as i32 * self.collisions as i32),
            bytemuck::cast(1 as i32 * self.friction as i32),
            self.friction_coefficient,
            bytemuck::cast(1 as i32 * self.rotation as i32),
            bytemuck::cast(1 as i32 * self.linear_contact_bonds as i32),
        ];
    }

    pub fn render_settings(&mut self) -> Vec<i32> {
        self.changed_collision_settings = false;
        return vec![
            self.circular_particles as i32,
            self.render_rot as i32,
            self.color_code_rot as i32,
            self.colors
        ];
    }

    fn reset(&mut self){
        self.genPerFrame = 1;
        self.workgroups = 4;
        self.workgroup_size = 256;
        self.max_radius = 0.1/3.2;
        self.variable_rad = true;
        self.holeyness = 1.7;
        self.min_radius = self.max_radius/self.holeyness;
        self.max_bonds = 4;
        self.max_h_velocity = 0.0;
        self.min_h_velocity = 0.0;
        self.max_v_velocity = 0.0;
        self.min_v_velocity = 0.0;
        self.particles = self.workgroup_size*self.workgroups;
        self.structure = Structure::Grid;
        self.grid_width = 32.0;
        self.settings_menu = true;
        self.maintain_ar = true;
        self.hor_bound = 6.0;
        self.vert_bound = 4.0;
        self.gravity = true;
        self.bonds = true;
        self.collisions = true;
        self.friction = true;
        self.rotation = true;
        self.linear_contact_bonds = true;
        self.changed_collision_settings = false;
    }
}

#[derive(Debug, PartialEq)]
pub enum Structure {
    Grid,
    Random
}