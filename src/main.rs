pub mod windowInit;
pub mod client;
pub mod wgpu_config;
pub mod wgpu_structs;
pub mod wgpu_prog;


// use std::Timer;


pub  fn main(){
    env_logger::init();
    let mut client = async_std::task::block_on(client::Client::new());

    client.resize(client.canvas.size);

    // while(true){
        
        
        
    // }
}