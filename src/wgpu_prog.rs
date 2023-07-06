
// use crate::
// use winit::*;
use crate::wgpu_structs::*;
use crate::wgpu_config::*;

use wgpu::util::DeviceExt;

pub const VERTICES: &[Vertex] = &[
    Vertex { position: [-1.0, 1.0, 0.0], tex_coords: [0.0, 0.0,] },
    Vertex { position: [-1.0, -1.0, 0.0], tex_coords: [0.0, 1.0,] },
    Vertex { position: [1.0, -1.0, 0.0], tex_coords: [1.0, 1.0,] },
    Vertex { position: [1.0, 1.0, 0.0], tex_coords: [1.0, 0.0,] }
];

pub const INDICES: &[u16] = &[
    1, 2, 0,
    0, 2, 3,
    // 0, 2, 1,
    // 2, 4, 1,
    // 4, 3, 1,
    // 4, 5, 3,
];
pub struct WGPUProg {
    pub dim_uniform: Uniform,
    pub tex1: Texture,
    pub tex2: Texture,
    // pub time_uniform: Uniform,
    pub render_pipeline: wgpu::RenderPipeline,
    pub vertex_buffer: wgpu::Buffer,
    pub index_buffer: wgpu::Buffer,
    pub clear_color: wgpu::Color,
    pub shader_prog: WGPUComputeProg,
    shader: wgpu::ShaderModule
    // pub diffuse_bind_group: wgpu::BindGroup,
}

impl WGPUProg {
    pub fn new(config: &WGPUConfig) -> Self {
        let mut shader_prog = WGPUComputeProg::new(config);
        let mut golTex = &mut shader_prog.tex2;

        if(shader_prog.use1){
            golTex = &mut shader_prog.tex1;
        }

        golTex.setBinding(config, 5, false);

        let clear_color = wgpu::Color {
            r: 0.0,
            g: 0.0,//0.266,
            b: 0.0,//1.0,
            a: 1.0,
        };
        let vertices = &[
            Vertex { position: [0.0, 0.5, 0.0], tex_coords: [1.0, 0.0] },
            Vertex { position: [0.433, 0.25, 0.0], tex_coords: [0.5, 0.0] },
            Vertex { position: [-0.433, 0.25, 0.0], tex_coords: [0.5, 0.5] },
            Vertex { position: [0.433, -0.25, 0.0], tex_coords: [0.0, 0.0] },
            Vertex { position: [-0.433, -0.25, 0.0], tex_coords: [0.0, 1.0] },
            Vertex { position: [0.0, -0.5, 0.0], tex_coords: [0.0, 0.5] },
            // Vertex { position: [0.0, 0.5, 0.0], color: [1.0, 0.0, 0.0] },
            // Vertex { position: [0.433, 0.25, 0.0], color: [0.5, 0.0, 0.5] },
            // Vertex { position: [-0.433, 0.25, 0.0], color: [0.5, 0.5, 0.0] },
            // Vertex { position: [0.433, -0.25, 0.0], color: [0.0, 0.0, 1.0] },
            // Vertex { position: [-0.433, -0.25, 0.0], color: [0.0, 1.0, 0.0] },
            // Vertex { position: [0.0, -0.5, 0.0], color: [0.0, 0.5, 0.5] },
        ];
        let indices = &[
            0, 2, 1,
            2, 4, 1,
            4, 3, 1,
            4, 5, 3,
        ];
        let shader = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("shaders/shader.wgsl").into()),
        });
        let dim_contents = &[config.size.width as f32, config.size.height as f32, config.size.width as f32, config.size.height as f32, 0 as f32, 0 as f32, 1 as f32, 0 as f32];
        // let cursor_contents = &[0.0, 0.0, 0.0, 0.0];
        let time_contents = &[0.0, 0.0, 0.0, 0.0];
        let dim_uniform = Uniform::new(&config.device, bytemuck::cast_slice(dim_contents), String::from("dimensions"), 2);
        // let cursor_uniform = Uniform::new(&config.device, bytemuck::cast_slice(cursor_contents), String::from("cursor"), 1);
        // let time_uniform = Uniform::new(&config.device, bytemuck::cast_slice(time_contents), String::from("time"), 3);
        
        let tex1 = Texture::new(&config, include_bytes!("../golBase.png"), 0);

        // let tex2 = Texture::new(&config, image, 4);
        let tex2 = Texture::new(&config, include_bytes!("../golBase.png"), 3);

       
        // let buffer2 = Uniform::new(&config.device, golBase, String::from("dimensions"), 6);

        let mut render_pipeline_layout =
        config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Render Pipeline Layout"),
            bind_group_layouts: &[&tex1.bind_group_layout, &dim_uniform.bind_group_layout, &tex2.bind_group_layout, &golTex.bind_group_layout],
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
            depth_stencil: None, // 1.
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
            tex1,
            tex2,
            // time_uniform,
            render_pipeline,
            vertex_buffer,
            index_buffer,
            clear_color,
            shader_prog,
            shader
        }
    }

    pub fn swap(&mut self, config: &WGPUConfig){
        let mut golTex = &mut self.shader_prog.tex2;

        if(self.shader_prog.use1){
            golTex = &mut self.shader_prog.tex1;
        }

        golTex.setBinding(config, 5, false);

        let clear_color = wgpu::Color {
            r: 0.0,
            g: 0.0,//0.266,
            b: 0.0,//1.0,
            a: 1.0,
        };

        // let dim_contents = &[config.size.width as f32, config.size.height as f32, config.size.width as f32, config.size.height as f32,];
        // let cursor_contents = &[0.0, 0.0, 0.0, 0.0];
        // let time_contents = &[0.0, 0.0, 0.0, 0.0];
        // let dim_uniform = Uniform::new(&config.device, bytemuck::cast_slice(dim_contents), String::from("dimensions"), 2);
        // let cursor_uniform = Uniform::new(&config.device, bytemuck::cast_slice(cursor_contents), String::from("cursor"), 1);
        // let time_uniform = Uniform::new(&config.device, bytemuck::cast_slice(time_contents), String::from("time"), 3);
        


       
        // let buffer2 = Uniform::new(&config.device, golBase, String::from("dimensions"), 6);

        // let mut render_pipeline_layout =
        // config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        //     label: Some("Render Pipeline Layout"),
        //     bind_group_layouts: &[&self.tex1.bind_group_layout, &dim_uniform.bind_group_layout, &self.tex2.bind_group_layout, &golTex.bind_group_layout],
        //     push_constant_ranges: &[],
        // });
        
        // self.render_pipeline = config.device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        //     label: Some("Render Pipeline"),
        //     layout: Some(&render_pipeline_layout),
        //     vertex: wgpu::VertexState {
        //         module: &self.shader,
        //         entry_point: "vs_main", // 1.
        //         buffers: &[Vertex::desc()], // 2.
        //     },
        //     fragment: Some(wgpu::FragmentState { // 3.
        //         module: &self.shader,
        //         entry_point: "fs_main",
        //         targets: &[Some(wgpu::ColorTargetState { // 4.
        //             format: config.config.format,
        //             blend: Some(wgpu::BlendState::REPLACE),
        //             write_mask: wgpu::ColorWrites::ALL,
        //         })],
        //     }),
        //     primitive: wgpu::PrimitiveState {
        //         topology: wgpu::PrimitiveTopology::TriangleList, // 1.
        //         strip_index_format: None,
        //         front_face: wgpu::FrontFace::Ccw, // 2.
        //         cull_mode: Some(wgpu::Face::Back),
        //         // Setting this to anything other than Fill requires Features::NON_FILL_POLYGON_MODE
        //         polygon_mode: wgpu::PolygonMode::Fill,
        //         // Requires Features::DEPTH_CLIP_CONTROL
        //         unclipped_depth: false,
        //         // Requires Features::CONSERVATIVE_RASTERIZATION
        //         conservative: false,
        //     },
        //     depth_stencil: None, // 1.
        //     multisample: wgpu::MultisampleState {
        //         count: 1, // 2.
        //         mask: !0, // 3.
        //         alpha_to_coverage_enabled: false, // 4.
        //     },
        //     multiview: None, // 5.
        // });
    }
}

pub struct WGPUComputeProg {
    pub tex1: Texture,
    pub tex2: Texture,
    pub compute_pipeline: wgpu::ComputePipeline,
    shader1: wgpu::ShaderModule,
    // shader2: wgpu::ShaderModule,
    pub use1: bool,
}


impl WGPUComputeProg {
    pub fn new(config: &WGPUConfig) -> Self {
        //create resources
        // let golBase = &[0 as u8; 256*256 as usize];

        let mut tex1 = Texture::new(&config, include_bytes!("../golBase.png"), 0);
        let mut tex2 = Texture::new(&config, include_bytes!("../golBase.png"), 1);

        // let buffer1 = BufferUniform::new(&config.device, golBase, String::from("dimensions"), 5);

        // let buffer2 = Uniform::new(&config.device, golBase, String::from("dimensions"), 6);

        //create bind group layouts
        //create bind groups

        tex1.setBinding(config, 0, true);
        tex2.setBinding(config, 1, false);

        //create shaders
        let compute_shader1 = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: None,
            source: wgpu::ShaderSource::Wgsl(include_str!("./shaders/gol_shader1.wgsl").into()),
        });

        // let compute_shader2 = config.device.create_shader_module(wgpu::ShaderModuleDescriptor {
        //     label: None,
        //     source: wgpu::ShaderSource::Wgsl(include_str!("./shaders/gol_shader2.wgsl").into()),
        // });
        //create pipeline layout
        let compute_pipeline_layout = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("gol compute"),
            bind_group_layouts: &[&tex1.bind_group_layout, &tex2.bind_group_layout],
            push_constant_ranges: &[]
        });
        //create pipeline

        let compute_pipeline = config.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: None,
            layout: Some(&compute_pipeline_layout),
            module: &compute_shader1,
            entry_point: "main",
        });
        
        let use1 = true;
        Self{
            tex1,
            tex2,
            compute_pipeline,
            shader1: compute_shader1,
            // shader2: compute_shader2,
            use1
        }
    }

    pub fn clearTextures(&mut self, config: &WGPUConfig){
        self.tex1 = Texture::new(&config, include_bytes!("../golClear.png"), 0);
        self.tex2 = Texture::new(&config, include_bytes!("../golClear.png"), 1);
        self.swap(config);
    }

    fn swap(&mut self, config: &WGPUConfig){
        self.tex1.setBinding(config, 0, true);
        self.tex2.setBinding(config, 1, false);
        if(!self.use1){
            self.tex2.setBinding(config, 0, true);
            self.tex1.setBinding(config, 1, false);
        }
        let mut compute_pipeline_layout = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("gol compute"),
            bind_group_layouts: &[&self.tex1.bind_group_layout, &self.tex2.bind_group_layout],
            push_constant_ranges: &[]
        });
        if(!self.use1){
            compute_pipeline_layout = config.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("gol compute"),
                bind_group_layouts: &[&self.tex2.bind_group_layout, &self.tex1.bind_group_layout],
                push_constant_ranges: &[]
            });
        }
        //create pipeline

        self.compute_pipeline = config.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: None,
            layout: Some(&compute_pipeline_layout),
            module: &self.shader1,
            entry_point: "main",
        });
    }

    pub fn compute(&mut self, config: &WGPUConfig){
        self.use1 = !self.use1;
        self.swap(config);
        //start compute
        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

        let mut compute_pass_descriptor = wgpu::ComputePassDescriptor::default();

        {
            let mut compute_pass = encoder.begin_compute_pass(&compute_pass_descriptor);

            // Set the compute pipeline
            compute_pass.set_pipeline(&self.compute_pipeline);

            // Bind resource bindings (if any)
            
            
            if(!self.use1){
                compute_pass.set_bind_group(0, &self.tex2.diffuse_bind_group, &[]);
                compute_pass.set_bind_group(1, &self.tex1.diffuse_bind_group, &[]);     
            } else {
                compute_pass.set_bind_group(0, &self.tex1.diffuse_bind_group, &[]);
                compute_pass.set_bind_group(1, &self.tex2.diffuse_bind_group, &[]);
            }
            // Dispatch the compute shader
            compute_pass.dispatch_workgroups(self.tex1.dimensions.0/16, self.tex1.dimensions.1/16, 1);

            // You can also set other compute pass options, such as memory barriers and synchronization

        } // The compute pass ends here

        // Submit the command encoder
        config.queue.submit(Some(encoder.finish()));
        
        // self.swap(config);        
    }
}