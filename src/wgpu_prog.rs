use std::fmt::DebugTuple;

use bytemuck::bytes_of;
use rand::Rng;
use crate::settings;
use crate::settings::Structure;
use crate::setup;
// use crate::
// use winit::*;
use crate::wgpu_structs::*;
use crate::wgpu_config::*;
use crate::setup::*;

use wgpu::util::DeviceExt;

const p_mult: usize = 1;//5;

pub const VERTICES: &[Vertex] = &[
    Vertex { position: [1.0, 1.0, 0.0] }, // 0 - Top Right
    Vertex { position: [1.0, -1.0, 0.0] }, // 1 - Bottom Right
    Vertex { position: [-1.0, -1.0, 0.0] }, // 2 - Bottom Left
    Vertex { position: [-1.0, 1.0, 0.0] }, // 3 - Top Left
];

// 1, 2, 0,
// 0, 2, 3,
pub const INDICES: &[u16] = &[
    0, 3, 2,
    0, 2, 1
];
pub struct WGPUProg {
    pub dim_uniform: Uniform,
    pub ren_set_uniform: Uniform,
    pub render_pipeline: wgpu::RenderPipeline,
    pub vertex_buffer: wgpu::Buffer,
    pub index_buffer: wgpu::Buffer,
    pub clear_color: wgpu::Color,
    pub shader_prog: WGPUComputeProg,
    pub depth_buffer: DepthBuffer,
    shader: wgpu::ShaderModule,
}

impl WGPUProg {
    pub fn new(config: &mut WGPUConfig) -> Self {
        let mut shader_prog = WGPUComputeProg::new(config);

        let clear_color = wgpu::Color {
            r: 0.0,
            g: 0.0,//0.266,
            b: 0.0,//1.0,
            a: 1.0,
        };
        let indices = &[
            0, 2, 1,
            2, 4, 1,
            4, 3, 1,
            4, 5, 3,
        ];
        let depth_buffer = DepthBuffer::new(&config.device, &config.config, "depth_texture");
        let shader = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("shaders/2D_Render.wgsl").into()),
        });
        let dim_contents = &[config.size.width as f32, config.size.height as f32, config.size.width as f32, config.size.height as f32, 0 as f32, 0 as f32, 1 as f32, 0 as f32];
        let dim_uniform = Uniform::new(&config.device, bytemuck::cast_slice(dim_contents), String::from("dimensions"), 0);
        let ren_set_uniform = Uniform::new(&config.device, bytemuck::cast_slice(&config.prog_settings.render_settings()), String::from("settings"), 0);

        let mut render_pipeline_layout =
        config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Render Pipeline Layout"),
            bind_group_layouts: &[
                &dim_uniform.bind_group_layout,
                &shader_prog.pos_buffer.bind_group_layout,
                &shader_prog.radii_buffer.bind_group_layout,
                &shader_prog.color_buffer.bind_group_layout,
                &shader_prog.mov_buffers.bind_group_layout,
                &shader_prog.contact_buffers.bind_group_layout,
                &ren_set_uniform.bind_group_layout,
            ],
            push_constant_ranges: &[],
        });
        
        let render_pipeline = config.device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Render Pipeline"),
            layout: Some(&render_pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: "vs_main", // 1.
                buffers: &[Vertex::desc()], // 2.
            },
            fragment: Some(wgpu::FragmentState { // 3.
                module: &shader,
                entry_point: "fs_main",
                targets: &[Some(wgpu::ColorTargetState { // 4.
                    format: config.config.format,
                    blend: Some(wgpu::BlendState::REPLACE),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
            }),
            primitive: wgpu::PrimitiveState {
                topology: wgpu::PrimitiveTopology::TriangleList, // 1.
                strip_index_format: None,
                front_face: wgpu::FrontFace::Ccw, // 2.
                cull_mode: Some(wgpu::Face::Back),
                // Setting this to anything other than Fill requires Features::NON_FILL_POLYGON_MODE
                polygon_mode: wgpu::PolygonMode::Fill,
                // Requires Features::DEPTH_CLIP_CONTROL
                unclipped_depth: false,
                // Requires Features::CONSERVATIVE_RASTERIZATION
                conservative: false,
            },
            depth_stencil: Some(wgpu::DepthStencilState {
                depth_write_enabled: true,
                depth_compare: wgpu::CompareFunction::Less,
                format: DepthBuffer::DEPTH_FORMAT,
                stencil: wgpu::StencilState::default(), // 2.
                bias: wgpu::DepthBiasState::default(),
              }), // 1.
            multisample: wgpu::MultisampleState {
                count: 1, // 2.
                mask: !0, // 3.
                alpha_to_coverage_enabled: false, // 4.
            },
            multiview: None, // 5.
        });

        let vertex_buffer = config.device.create_buffer_init(
            &wgpu::util::BufferInitDescriptor {
                label: Some("Vertex Buffer"),
                contents: bytemuck::cast_slice(VERTICES),
                usage: wgpu::BufferUsages::VERTEX,
            }
        );

        let index_buffer = config.device.create_buffer_init(
            &wgpu::util::BufferInitDescriptor {
                label: Some("Index Buffer"),
                contents: bytemuck::cast_slice(INDICES),
                usage: wgpu::BufferUsages::INDEX,
            }
        );

        
        
        Self{
            dim_uniform,
            ren_set_uniform,
            render_pipeline,
            vertex_buffer,
            index_buffer,
            clear_color,
            shader_prog,
            depth_buffer,
            shader
        }
    }

    // pub fn swap(&mut self, config: &WGPUConfig){
    //     let mut golTex = &mut self.shader_prog.tex2;

    //     if(self.shader_prog.use1){
    //         golTex = &mut self.shader_prog.tex1;
    //     }

    //     golTex.setBinding(config, 5, false);

    //     let clear_color = wgpu::Color {
    //         r: 0.0,
    //         g: 0.0,//0.266,
    //         b: 0.0,//1.0,
    //         a: 1.0,
    //     };
    // }
}

pub struct WGPUComputeProg {
    pub pos_buffer: BufferUniform,
    pub mov_buffers: BufferGroup,
    pub radii_buffer: BufferUniform,
    pub color_buffer: BufferUniform,
    pub contact_buffers: BufferGroup,
    pub collision_settings: Uniform,
    // pub col_buffer: BufferUniform,
    pub compute_pipeline: wgpu::ComputePipeline,
    pub compute_pipeline2: wgpu::ComputePipeline,
    pub compute_pipeline3: wgpu::ComputePipeline,
    pub compute_pipeline4: wgpu::ComputePipeline,
    // shader1: wgpu::ShaderModule,
    // pub use1: bool,
}


impl WGPUComputeProg {
    pub fn new(config: &mut WGPUConfig) -> Self {
        // Create empty arrays for particle data
        let p_count = setup::p_count(&mut config.prog_settings);
        let mut pos = vec![0.0 as f32; p_count*2];
        let mut vel = vec![0.0 as f32; p_count*2];
        let mut acc = vec![0.0 as f32; p_count*3];
        let mut rot = vec![0.0 as f32; p_count];
        let mut rot_vel = vec![0.0 as f32; p_count];
        let mut forces = vec![0.0 as f32; p_count*6];
        let mut radii = vec![0.0 as f32; p_count];
        let mut color = vec![1.0 as f32; p_count*3];
        // let mut material = vec![1.0 as f32; p_count];
        let mut fixity = vec![0; p_count*3];
        let mut bonds = vec![-1; 1];
        let mut bond_info = vec![-1; 1];
        let mut contacts = vec![-1.0 as f32; 6*config.prog_settings.max_contacts*p_count];
        let mut contact_pointers = vec![-1; 8*p_count];

        // Setup initial state, Fill with random values
        match config.prog_settings.structure {
            Structure::Grid => {
                let bond_vecs = setup::grid(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp1 => {
                let bond_vecs = setup::exp1(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity, &mut forces);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp2 => {
                let bond_vecs = setup::exp2(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity, &mut forces);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp3 => {
                let bond_vecs = setup::exp3(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity, &mut forces);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp4 => {
                let bond_vecs = setup::exp4(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity, &mut forces);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp5 => {
                let bond_vecs = setup::exp5(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity, &mut forces);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp6 => {
                let bond_vecs = setup::exp6(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut color, &mut fixity, &mut forces);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Random => {},
        }
        // Print Bonds
        // for i in 0..p_count{
        //     if bond_info[i*2] != -1 {
        //         println!("\nStart: {}, Length: {}", bond_info[i*2], bond_info[i*2+1]);
        //         print!("Bonds: ");
        //         for j in bond_info[i*2]..bond_info[i*2]+bond_info[i*2+1] {
        //             print!("{}, ", bonds[j as usize]);
        //         }
        //         print!("\n");
        //     }
        // }

        // Convert arrays to GPU buffers
        let pos_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&pos), "Position Buffer".to_string(), 0);
        let mut mov_buffers = BufferGroup::new(&config.device, vec![
            bytemuck::cast_slice(&vel),
            bytemuck::cast_slice(&vel),
            bytemuck::cast_slice(&rot),
            bytemuck::cast_slice(&rot_vel),
            bytemuck::cast_slice(&rot_vel),
            bytemuck::cast_slice(&acc),
            bytemuck::cast_slice(&fixity),
            bytemuck::cast_slice(&forces),
            // bytemuck::cast_slice(&rot_forces),
            // bytemuck::cast_slice(&vel_forces),
        
        ], "Movement Buffer".to_string() );
        let radii_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&radii), "Radii Buffer".to_string(), 0);
        let color_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&color), "Color Buffer".to_string(), 0);
        let mut contact_buffers = BufferGroup::new(&config.device, vec![
            bytemuck::cast_slice(&bonds),
            bytemuck::cast_slice(&bond_info), 
            bytemuck::cast_slice(&contacts),
            bytemuck::cast_slice(&contact_pointers),
        ], "Contact Buffers".to_string() );
        // let contact_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&contacts), "Contact Buffer".to_string(), 0);
        // let bond_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&bonds), "Bond Buffer".to_string(), 0);
        let bond_info_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&bond_info), "Bond Info Buffer".to_string(), 0);
        let collision_settings = Uniform::new(&config.device, bytemuck::cast_slice(&config.prog_settings.collison_settings()), "Collision Settings".to_string(), 0);
        // let col_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&col_sec), "Collision Buffer".to_string(), 0);
        
        // let time_uniform = Uniform::new(&config.device, bytemuck::cast_slice(&[0.0 as f32, 0.0 as f32, 0.0 as f32, 0.0 as f32]), "Timestamp_Uniform".to_string(), 1);
        //create shaders
        let compute_shader = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: None,
            source: wgpu::ShaderSource::Wgsl(include_str!("./shaders/2D_LOM.wgsl").into()),
        });

        let compute_shader2 = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: None,
            source: wgpu::ShaderSource::Wgsl(include_str!("./shaders/2D_Collisions.wgsl").into()),
        });

        let compute_shader3 = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: None,
            source: wgpu::ShaderSource::Wgsl(include_str!("./shaders/2D_Forces.wgsl").into()),
        });

        let compute_shader4 = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: None,
            source: wgpu::ShaderSource::Wgsl(include_str!("./shaders/2D_Particle_Forces.wgsl").into()),
        });

        //create pipeline layout
        let compute_pipeline_layout = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("LOM compute"),
            bind_group_layouts: &[&pos_buffer.bind_group_layout, &mov_buffers.bind_group_layout],// &col_buffer.bind_group_layout],
            push_constant_ranges: &[]
        });

        let compute_pipeline_layout2 = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Collision compute"),
            bind_group_layouts: &[&pos_buffer.bind_group_layout, &mov_buffers.bind_group_layout, &radii_buffer.bind_group_layout, &contact_buffers.bind_group_layout, &collision_settings.bind_group_layout],// &col_buffer.bind_group_layout],
            push_constant_ranges: &[]
        });
        let compute_pipeline_layout3 = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Force compute"),
            bind_group_layouts: &[&pos_buffer.bind_group_layout, &mov_buffers.bind_group_layout, &radii_buffer.bind_group_layout, &contact_buffers.bind_group_layout, &collision_settings.bind_group_layout],// &col_buffer.bind_group_layout],    
            push_constant_ranges: &[]
        });
        let compute_pipeline_layout4 = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Particle Force compute"),
            bind_group_layouts: &[&pos_buffer.bind_group_layout, &mov_buffers.bind_group_layout, &radii_buffer.bind_group_layout, &contact_buffers.bind_group_layout, &collision_settings.bind_group_layout],// &col_buffer.bind_group_layout],
            push_constant_ranges: &[]
        });
        //create pipeline

        let compute_pipeline = config.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: None,
            layout: Some(&compute_pipeline_layout),
            module: &compute_shader,
            entry_point: "main",
        });

        let compute_pipeline2 = config.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: None,
            layout: Some(&compute_pipeline_layout2),
            module: &compute_shader2,
            entry_point: "main",
        });

        let compute_pipeline3 = config.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: None,
            layout: Some(&compute_pipeline_layout3),
            module: &compute_shader3,
            entry_point: "main",
        });

        let compute_pipeline4 = config.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: None,
            layout: Some(&compute_pipeline_layout4),
            module: &compute_shader4,
            entry_point: "main",
        });

        Self {
            pos_buffer,
            mov_buffers,
            radii_buffer,
            color_buffer,
            contact_buffers,
            collision_settings,
            // col_buffer,
            compute_pipeline,
            compute_pipeline2,
            compute_pipeline3,
            compute_pipeline4
        }
    }

    pub fn compute(&mut self, config: &mut WGPUConfig){
        //start compute
        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

        let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

        {
            let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

            // Set the compute pipeline
            compute_pass.set_pipeline(&self.compute_pipeline);

            // Bind resource bindings (if any)
            
            compute_pass.set_bind_group(0, &self.pos_buffer.bind_group, &[]);
            compute_pass.set_bind_group(1, &self.mov_buffers.bind_group, &[]);     
            // compute_pass.set_bind_group(2, &self.col_buffer.bind_group, &[]);     

            // Dispatch the compute shader
            compute_pass.dispatch_workgroups(config.prog_settings.workgroups as u32, 1, 1);

            // You can also set other compute pass options, such as memory barriers and synchronization

        } // The compute pass ends here

        // Submit the command encoder
        config.queue.submit(Some(encoder.finish()));



                let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

                let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

                if config.prog_settings.changed_collision_settings {
                    self.collision_settings.updateUniform(&config.device, bytemuck::cast_slice(&config.prog_settings.collison_settings()));
                }
                {
                    let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

                    // Set the compute pipeline
                    compute_pass.set_pipeline(&self.compute_pipeline2);

                    // Bind resource bindings (if any)
                    
                    compute_pass.set_bind_group(0, &self.pos_buffer.bind_group, &[]);
                    compute_pass.set_bind_group(1, &self.mov_buffers.bind_group, &[]);     
                    compute_pass.set_bind_group(2, &self.radii_buffer.bind_group, &[]);    
                    compute_pass.set_bind_group(3, &self.contact_buffers.bind_group, &[]);         
                    compute_pass.set_bind_group(4, &self.collision_settings.bind_group, &[]);     
                    // compute_pass.set_bind_group(5, &self.col_buffer.bind_group, &[]);     


                    // Dispatch the compute shader
                    compute_pass.dispatch_workgroups(config.prog_settings.workgroups as u32, 1, 1);

                    // You can also set other compute pass options, such as memory barriers and synchronization

                } // The compute pass ends here

                // Submit the command encoder
                config.queue.submit(Some(encoder.finish()));



                        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

                        let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

                        if config.prog_settings.changed_collision_settings {
                            self.collision_settings.updateUniform(&config.device, bytemuck::cast_slice(&config.prog_settings.collison_settings()));
                        }
                        {
                            let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

                            // Set the compute pipeline
                            compute_pass.set_pipeline(&self.compute_pipeline3);

                            // Bind resource bindings (if any)
                            
                            compute_pass.set_bind_group(0, &self.pos_buffer.bind_group, &[]);
                            compute_pass.set_bind_group(1, &self.mov_buffers.bind_group, &[]);     
                            compute_pass.set_bind_group(2, &self.radii_buffer.bind_group, &[]);    
                            compute_pass.set_bind_group(3, &self.contact_buffers.bind_group, &[]);      
                            compute_pass.set_bind_group(4, &self.collision_settings.bind_group, &[]);     
                            // compute_pass.set_bind_group(5, &self.col_buffer.bind_group, &[]);     


                            // Dispatch the compute shader
                            compute_pass.dispatch_workgroups(config.prog_settings.workgroups as u32, 1, 1);

                            // You can also set other compute pass options, such as memory barriers and synchronization

                        } // The compute pass ends here

                        // Submit the command encoder
                        config.queue.submit(Some(encoder.finish()));



                                let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

                                let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

                                if config.prog_settings.changed_collision_settings {
                                    self.collision_settings.updateUniform(&config.device, bytemuck::cast_slice(&config.prog_settings.collison_settings()));
                                }
                                {
                                    let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

                                    // Set the compute pipeline
                                    compute_pass.set_pipeline(&self.compute_pipeline4);

                                    // Bind resource bindings (if any)
                                    
                                    compute_pass.set_bind_group(0, &self.pos_buffer.bind_group, &[]);
                                    compute_pass.set_bind_group(1, &self.mov_buffers.bind_group, &[]);     
                                    compute_pass.set_bind_group(2, &self.radii_buffer.bind_group, &[]);    
                                    compute_pass.set_bind_group(3, &self.contact_buffers.bind_group, &[]);     
                                    compute_pass.set_bind_group(4, &self.collision_settings.bind_group, &[]);     
                                    // compute_pass.set_bind_group(5, &self.col_buffer.bind_group, &[]);     


                                    // Dispatch the compute shader
                                    compute_pass.dispatch_workgroups(config.prog_settings.workgroups as u32, 1, 1);

                                    // You can also set other compute pass options, such as memory barriers and synchronization

                                } // The compute pass ends here

                                // Submit the command encoder
                                config.queue.submit(Some(encoder.finish()));
    }
    
    fn print_particle(i: usize, pos: &[f32], vel: &[f32], radii: &[f32], color: &[f32]) {
        println!("\nParticle [\n
                        pos:   {}, {}\n
                        vel:   {}, {}\n    
                        rad:   {}\n    
                        color: {}, {}, {}\n
                    ]",
                        pos[i*2], pos[i*2+1], vel[i*2], vel[i*2+1], radii[i], 255.0*color[i*3], 255.0*color[i*3+1], 255.0*color[i*3+2]);
    }
}