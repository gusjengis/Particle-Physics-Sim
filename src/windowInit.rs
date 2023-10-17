//Followed this guide to get started https://sotrh.github.io/learn-wgpu/#what-is-wgpu
use rand::prelude::*;
use winit::{
    event::*,
    event_loop::{ControlFlow, EventLoop, EventLoopProxy},
    window::WindowBuilder, dpi::PhysicalSize,
};



#[cfg(target_arch="wasm32")]
use wasm_bindgen::prelude::*;

pub struct Canvas{
    pub window:  winit::window::Window,
    pub size: PhysicalSize<u32>
}

impl Canvas {
    pub fn new(window: winit::window::Window) -> Self {
        #[cfg(target_arch = "wasm32")]
        {  
            use winit::platform::web::WindowExtWebSys;
            web_sys::window()
                .and_then(|win| win.document())
                .and_then(|doc| {
                    let dst = doc.body()?;
                    let canvas = web_sys::Element::from(window.canvas());
                    canvas.set_id("winit");
                    dst.append_child(&canvas).ok()?;
                    Some(())
                })
                .expect("Couldn't append canvas to document body.");
        }

        // #[cfg(target_arch = "wasm32")] {
        //     use winit::dpi::PhysicalSize;
        //     let w = web_sys::window().unwrap().inner_width().unwrap().as_f64().unwrap();
        //     let h = web_sys::window().unwrap().inner_height().unwrap().as_f64().unwrap();
        //     self.window.set_inner_size(PhysicalSize::new(w, h));
        // }
    
        let size = window.inner_size();

        // // https://sotrh.github.io/learn-wgpu/showcase/imgui-demo/ <--  ImGui Tutorial vvv
        
        // let mut imgui = imgui::Context::create();
        // let mut platform = imgui_winit_support::WinitPlatform::init(&mut imgui);
        // platform.attach_window(
        //     imgui.io_mut(), 
        //     &display.window,
        //     imgui_winit_support::HiDpiMode::Default,
        // );
        // imgui.set_ini_filename(None);

        Self{
            window,
            size
        }
    }

    pub fn updateSize(&mut self, size: PhysicalSize<u32>){
        self.size = size;
        // self.window.set_inner_size(size);
        #[cfg(target_arch = "wasm32")] {
            use winit::dpi::PhysicalSize;
            let w = web_sys::window().unwrap().inner_width().unwrap().as_f64().unwrap();
            let h = web_sys::window().unwrap().inner_height().unwrap().as_f64().unwrap();
            self.window.set_inner_size(PhysicalSize::new(w, h));
        }
    }

}
// #[cfg_attr(target_arch="wasm32", wasm_bindgen(start))]
// pub async fn run() {
//     cfg_if::cfg_if! {
//         if #[cfg(target_arch = "wasm32")] {
//             std::panic::set_hook(Box::new(console_error_panic_hook::hook));
//             console_log::init_with_level(log::Level::Warn).expect("Couldn't initialize logger");
//         } else {
//             env_logger::init();
//         }
//     }
    
    
    

    // let mut state = State::new(window).await;


// }

use winit::window::Window;



