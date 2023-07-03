# Conway's Game of Life
Conway's Game of Life implemented using WebGPU compute shaders. 
Can be compiled and run natively using ```cargo run --release```, or compiled to WASM and run in the web.

WASM version can be demoed at https://portfolio.agreenweb.com. Because this uses compute shaders, it requires a browser that supports WebGPU to run (https://caniuse.com/webgpu).

If you want to test this in the web yourself, build using ```wasm-pack build --target web```, then use a server to serve index.html, index.js, and the pkg folder. Compiling to WASM requires that the RUSTFLAGS environment variable is set to ```RUSTFLAGS=--cfg=web_sys_unstable_apis cargo run```.

This was created for my own learning, wanted to learn WebGPU/GPU Programming/GPU Compute. Also wanted to test an idea I've had about updating each cell in Conway's Game of Life in parallel. Was hoping it would be fast and I wasn't disappointed, 
on my machine(RTX 3090Ti) it seems to run many times faster than the other web-based Game of Life implementations I've found, and it's completely unoptimized. 
It's currently a very straightforward implementation, in the compute shader I just count the number of neighbors and write a new color for each cell, there are way fancier, way faster algorithms for Game of Life.
