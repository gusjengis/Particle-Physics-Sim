use std::fmt::DebugTuple;
use std::mem;
use std::fs::File;
use std::io::prelude::*;
use std::path::PathBuf;

use bytemuck::{bytes_of, cast_slice};
use rand::Rng;
use crate::settings;
use crate::settings::Structure;
use crate::setup;
// use crate::
// use winit::*;
use crate::wgpu_structs::*;
use crate::wgpu_config::*;
use crate::wgpu_prog::*;
use crate::setup::*;

use wgpu::util::DeviceExt;

// import the flatbuffers runtime library
extern crate flatbuffers;

// import the generated code
#[allow(dead_code, unused_imports)]
#[path = "../schema_generated.rs"]
mod schema_generated;
pub use schema_generated::*;

pub struct State {
    pub p_count: usize,
    pub pos: Vec<f32>,
    pub vel: Vec<f32>,
    pub acc: Vec<f32>,
    pub rot: Vec<f32>,
    pub rot_vel: Vec<f32>,
    pub forces: Vec<f32>,
    pub radii: Vec<f32>,
    pub fixity: Vec<i32>,
    pub bonds: Vec<i32>,
    pub bond_info: Vec<i32>,
    pub material_pointers: Vec<i32>,
    pub flatbuffer: Vec<u8>,
}

impl State {
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
        let mut fixity = vec![0; p_count*3];
        let mut bonds = vec![-1; 1];
        let mut bond_info = vec![-1; 1];
        let mut material_pointers = vec![0; p_count];
        let flatbuffer = vec![0 as u8; 1];

        // Setup initial state, Fill with random values
        match config.prog_settings.structure {
            Structure::Grid => {
                let bond_vecs = setup::grid(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp1 => {
                let bond_vecs = setup::exp1(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp2 => {
                let bond_vecs = setup::exp2(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp3 => {
                let bond_vecs = setup::exp3(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp4 => {
                let bond_vecs = setup::exp4(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp5 => {
                let bond_vecs = setup::exp5(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Exp6 => {
                let bond_vecs = setup::exp6(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Mats => {
                let bond_vecs = setup::mats(&mut config.prog_settings, &mut pos, &mut vel, &mut rot, &mut rot_vel, &mut radii, &mut fixity, &mut forces, &mut material_pointers);
                bonds = bond_vecs.0;
                bond_info = bond_vecs.1;
            },
            Structure::Random => {},
        }

        let mut state = State {
            p_count,
            pos,
            vel,
            acc,
            rot,
            rot_vel,
            forces,
            radii,
            fixity,
            bonds,
            bond_info,
            material_pointers,
            flatbuffer,
        };

        state.save(config);

        return state;
    }

    pub fn print_state(&self) {
        print!("Positions:");
        for i in 0..self.pos.len() {
            if i % 2 == 0 {
                print!("\n    ");
            }
            print!("{}, ", self.pos[i]);
        }

        print!("\nRadii:\n");
        for i in 0..self.radii.len() {
            print!("    {}, \n", self.radii[i]);
        }
        
        print!("Velocities:");
        for i in 0..self.vel.len() {
            if i % 2 == 0 {
                print!("\n    ");
            }
            print!("{}, ", self.vel[i]);
        }

        print!("\nRotations:");
        for i in 0..self.rot.len() {
            print!("    {}, \n", self.rot[i]);
        }

        print!("Rotational Velocities: \n");
        for i in 0..self.rot_vel.len() {
            print!("    {}, \n", self.rot_vel[i]);
        }

        print!("Forces:");
        for i in 0..self.forces.len() {
            if i % 6 == 0 {
                print!("\n    ");
            }
            print!("{}, ", self.forces[i]);
        }
        
        print!("\nFixity:");
        for i in 0..self.forces.len() {
            if i % 3 == 0 {
                print!("\n    ");
            }
            print!("{}, ", self.forces[i]);
        } 
    }

    pub fn save(&mut self, config: &mut WGPUConfig) {

        let mut builder = flatbuffers::FlatBufferBuilder::new();

        let pos = builder.create_vector(&self.pos);
        let vel = builder.create_vector(&self.vel);
        let acc = builder.create_vector(&self.acc);
        let rot = builder.create_vector(&self.rot);
        let rot_vel = builder.create_vector(&self.rot_vel);
        let forces = builder.create_vector(&self.forces);
        let radii = builder.create_vector(&self.radii);
        let fixity = builder.create_vector(&self.fixity);
        let bonds = builder.create_vector(&self.bonds);
        let bond_info = builder.create_vector(&self.bond_info);
        let material_pointers = builder.create_vector(&self.material_pointers);

        let state = schema_generated::State::create(&mut builder, &schema_generated::StateArgs{
            particles: self.p_count as i32,
            pos: Some(pos),
            vel: Some(vel),
            acc: Some(acc),
            rot: Some(rot),
            rot_vel: Some(rot_vel),
            forces: Some(forces),
            radii: Some(radii),
            fixity: Some(fixity),
            bonds: Some(bonds),
            bond_info: Some(bond_info),
            material_pointers: Some(material_pointers),
        });

        builder.finish(state, None);

        self.flatbuffer = builder.finished_data().to_vec();

    }

    pub fn save_to_file(&self, path: std::path::PathBuf) -> std::io::Result<()> {
        let mut file = File::create(path)?;
        file.write_all(&self.flatbuffer)?;
        Ok(())
    }

    pub fn load_from_file(&mut self, path: PathBuf) -> std::io::Result<()> {
        let mut file = File::open(path)?;
        let mut buffer = Vec::new();
        file.read_to_end(&mut buffer)?;
        self.flatbuffer = buffer;
        Ok(())
    }

    pub fn load(&mut self) {
        let state = schema_generated::root_as_state(self.flatbuffer.as_slice()).unwrap();
        self.p_count = state.particles() as usize;
        self.pos = State::f32_vec_from_vector(state.pos());
        self.vel = State::f32_vec_from_vector(state.vel());
        self.acc = State::f32_vec_from_vector(state.acc());
        self.rot = State::f32_vec_from_vector(state.rot());
        self.rot_vel = State::f32_vec_from_vector(state.rot_vel());
        self.forces = State::f32_vec_from_vector(state.forces());
        self.radii = State::f32_vec_from_vector(state.radii());
        self.fixity = State::i32_vec_from_vector(state.fixity());
        self.bonds = State::i32_vec_from_vector(state.bonds());
        self.bond_info = State::i32_vec_from_vector(state.bond_info());
        self.material_pointers = State::i32_vec_from_vector(state.material_pointers());
    }

    fn f32_vec_from_vector(vector: Option<flatbuffers::Vector<f32>>) -> Vec<f32> {
        let bytes = vector.unwrap().bytes();
        let f32_slice: &[f32] = unsafe {
            std::slice::from_raw_parts(
                bytes.as_ptr() as *const f32,
                bytes.len() / 4,
            )
        };
        return f32_slice.to_vec();
    }

    fn i32_vec_from_vector(vector: Option<flatbuffers::Vector<i32>>) -> Vec<i32> {
        let bytes = vector.unwrap().bytes();
        let i32_slice: &[i32] = unsafe {
            std::slice::from_raw_parts(
                bytes.as_ptr() as *const i32,
                bytes.len() / 4,
            )
        };
        return i32_slice.to_vec();
    }

    pub fn update_state(&mut self, config: &mut WGPUConfig, buffers: &mut BufferContainer) {

        self.p_count = config.prog_settings.particles;
        State::update_f32(config, &mut self.pos, &mut buffers.pos_buffer.buffer);
        State::update_f32(config, &mut self.radii, &mut buffers.radii_buffer.buffer);
        State::update_f32(config, &mut self.vel, &mut buffers.mov_buffers.buffers[0]);
        State::update_f32(config, &mut self.rot, &mut buffers.mov_buffers.buffers[2]);
        State::update_f32(config, &mut self.rot_vel, &mut buffers.mov_buffers.buffers[3]);
        State::update_f32(config, &mut self.acc, &mut buffers.mov_buffers.buffers[5]);
        State::update_i32(config, &mut self.fixity, &mut buffers.mov_buffers.buffers[6]);
        State::update_f32(config, &mut self.forces, &mut buffers.mov_buffers.buffers[7]);
        State::update_i32(config, &mut self.bonds, &mut buffers.contact_buffers.buffers[0]);
        State::update_i32(config, &mut self.bond_info, &mut buffers.contact_buffers.buffers[1]);
        State::update_i32(config, &mut self.material_pointers, &mut buffers.contact_buffers.buffers[4]);

    }

    pub fn update_i32(config: &mut WGPUConfig, vector: &mut Vec<i32>, buffer: &mut wgpu::Buffer) {
        
        let buffer_size = (vector.len() * mem::size_of::<i32>()) as u64;

        let staging_buffer = config.device.create_buffer(&wgpu::BufferDescriptor {
            size: buffer_size,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            label: None,
            mapped_at_creation: false,
        });
        
        // Create a command encoder
        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });
        
        // Copy from the GPU buffer to the staging buffer
        encoder.copy_buffer_to_buffer(&buffer, 0, &staging_buffer, 0, buffer_size);
        
        // Submit the commands to the queue
        config.queue.submit(Some(encoder.finish()));
        
        // Requesting to map the buffer for reading
        let buffer_slice = staging_buffer.slice(..); // Get a slice of the buffer

        // Request to map the buffer for reading
        buffer_slice.map_async(wgpu::MapMode::Read, |result| {
            match result {
                Ok(()) => {
                    // Mapping succeeded, handle the data
                }
                Err(e) => {
                    // Handle the error
                    eprintln!("Buffer map failed: {:?}", e);
                }
            }
        }); // buffer_size is the size of the buffer
        
        // Poll the device in a loop or in an event-driven manner
        config.device.poll(wgpu::Maintain::Wait);
        
        // Once the buffer is mapped, get the mapped range
        {
        let mapped_range = buffer_slice.get_mapped_range();

        // Access the data
        // For example, if your buffer contains byte data, you might convert it to a byte slice
        let data: &[u8] = mapped_range.as_ref();
        // You can now read from `data` as needed
        
        *vector = bytemuck::cast_slice(&data).to_vec();
        }
        // After you're done with the data, unmap the buffer
        staging_buffer.unmap();

    }

    pub fn update_f32(config: &mut WGPUConfig, vector: &mut Vec<f32>, buffer: &mut wgpu::Buffer) {
        
        let buffer_size = (vector.len() * mem::size_of::<f32>()) as u64;

        let staging_buffer = config.device.create_buffer(&wgpu::BufferDescriptor {
            size: buffer_size,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            label: None,
            mapped_at_creation: false,
        });
        
        // Create a command encoder
        let mut encoder = config.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });
        
        // Copy from the GPU buffer to the staging buffer
        encoder.copy_buffer_to_buffer(&buffer, 0, &staging_buffer, 0, buffer_size);
        
        // Submit the commands to the queue
        config.queue.submit(Some(encoder.finish()));
        
        // Requesting to map the buffer for reading
        let buffer_slice = staging_buffer.slice(..); // Get a slice of the buffer

        // Request to map the buffer for reading
        buffer_slice.map_async(wgpu::MapMode::Read, |result| {
            match result {
                Ok(()) => {
                    // Mapping succeeded, handle the data
                }
                Err(e) => {
                    // Handle the error
                    eprintln!("Buffer map failed: {:?}", e);
                }
            }
        }); // buffer_size is the size of the buffer
        
        // Poll the device in a loop or in an event-driven manner
        config.device.poll(wgpu::Maintain::Wait);
        
        // Once the buffer is mapped, get the mapped range
        {
        let mapped_range = buffer_slice.get_mapped_range();

        // Access the data
        // For example, if your buffer contains byte data, you might convert it to a byte slice
        let data: &[u8] = mapped_range.as_ref();
        // You can now read from `data` as needed
        
        *vector = bytemuck::cast_slice(&data).to_vec();
        }
        // After you're done with the data, unmap the buffer
        staging_buffer.unmap();

    }
}

