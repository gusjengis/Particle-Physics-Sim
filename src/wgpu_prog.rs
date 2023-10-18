use rand::Rng;
// use crate::
// use winit::*;
use crate::wgpu_structs::*;
use crate::wgpu_config::*;

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
    pub render_pipeline: wgpu::RenderPipeline,
    pub vertex_buffer: wgpu::Buffer,
    pub index_buffer: wgpu::Buffer,
    pub clear_color: wgpu::Color,
    pub shader_prog: WGPUComputeProg,
    pub depth_buffer: DepthBuffer,
    shader: wgpu::ShaderModule,
}

impl WGPUProg {
    pub fn new(config: &WGPUConfig) -> Self {
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

        let mut render_pipeline_layout =
        config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Render Pipeline Layout"),
            bind_group_layouts: &[
                &dim_uniform.bind_group_layout,
                &shader_prog.pos_buffer.bind_group_layout,
                &shader_prog.radii_buffer.bind_group_layout,
                &shader_prog.color_buffer.bind_group_layout
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
    pub vel_buffer: BufferUniform,
    pub vel_buf_buffer: BufferUniform,
    pub radii_buffer: BufferUniform,
    pub color_buffer: BufferUniform,
    pub compute_pipeline: wgpu::ComputePipeline,
    pub compute_pipeline2: wgpu::ComputePipeline,
    // shader1: wgpu::ShaderModule,
    // pub use1: bool,
}


impl WGPUComputeProg {
    pub fn new(config: &WGPUConfig) -> Self {
        // Create empty arrays for particle data
        let mut pos = vec![0.0 as f32; config.prog_settings.particles*2];
        let mut vel = vec![0.0 as f32; config.prog_settings.particles*2];
        let mut radii = vec![0.0 as f32; config.prog_settings.particles];
        let mut color = vec![0.0 as f32; config.prog_settings.particles*3];
        
        // Setup initial state, Fill with random values
        let mut rng = rand::thread_rng();
        let max_rad = 0.1/p_mult as f32;
        let max_vel = 4.0;
        let max_pos = 2.0;
        for i in 0..pos.len() {
            pos[i] = rng.gen_range(-max_pos..max_pos);
            vel[i] = rng.gen_range(-max_vel..max_vel);
        }
        for i in 0..radii.len() as usize {
            radii[i] = rng.gen_range(max_rad/5.0..max_rad);
        }
        for i in 0..color.len() as usize {
            color[i] = rng.gen_range(0.1..1.0);
        }
        // Convert arrays to GPU buffers

        let pos_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&pos), "Position Buffer".to_string(), 0);
        let vel_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&vel), "Velocity Buffer".to_string(), 0);
        let vel_buf_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&vel), "Velocity Buffer".to_string(), 0);
        let radii_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&radii), "Radii Buffer".to_string(), 0);
        let color_buffer = BufferUniform::new(&config.device, bytemuck::cast_slice(&color), "Color Buffer".to_string(), 0);

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

        //create pipeline layout
        let compute_pipeline_layout = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("LOM compute"),
            bind_group_layouts: &[&pos_buffer.bind_group_layout, &vel_buffer.bind_group_layout, &vel_buf_buffer.bind_group_layout],
            push_constant_ranges: &[]
        });

        let compute_pipeline_layout2 = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Collision compute"),
            bind_group_layouts: &[&pos_buffer.bind_group_layout, &vel_buffer.bind_group_layout, &radii_buffer.bind_group_layout, &vel_buf_buffer.bind_group_layout, &color_buffer.bind_group_layout],
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

        Self {
            pos_buffer,
            vel_buffer,
            vel_buf_buffer,
            radii_buffer,
            color_buffer,
            // time_uniform,
            compute_pipeline,
            compute_pipeline2
        }
    }

    pub fn compute(&mut self, config: &WGPUConfig){
        //start compute
        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

        let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

        {
            let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

            // Set the compute pipeline
            compute_pass.set_pipeline(&self.compute_pipeline);

            // Bind resource bindings (if any)
            
            compute_pass.set_bind_group(0, &self.pos_buffer.bind_group, &[]);
            compute_pass.set_bind_group(1, &self.vel_buffer.bind_group, &[]);     
            compute_pass.set_bind_group(2, &self.vel_buf_buffer.bind_group, &[]);     

            // Dispatch the compute shader
            compute_pass.dispatch_workgroups(config.prog_settings.particles as u32/256, 1, 1);

            // You can also set other compute pass options, such as memory barriers and synchronization

        } // The compute pass ends here

        // Submit the command encoder
        config.queue.submit(Some(encoder.finish()));

        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

        let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

        {
            let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

            // Set the compute pipeline
            compute_pass.set_pipeline(&self.compute_pipeline2);

            // Bind resource bindings (if any)
            
            compute_pass.set_bind_group(0, &self.pos_buffer.bind_group, &[]);
            compute_pass.set_bind_group(1, &self.vel_buffer.bind_group, &[]);     
            compute_pass.set_bind_group(2, &self.radii_buffer.bind_group, &[]);   
            compute_pass.set_bind_group(3, &self.vel_buf_buffer.bind_group, &[]);     
            compute_pass.set_bind_group(4, &self.color_buffer.bind_group, &[]);     


            // Dispatch the compute shader
            compute_pass.dispatch_workgroups(p_mult as u32, 1, 1);

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