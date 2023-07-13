@group(0) @binding(0)
var tex1: texture_storage_2d<rgba8unorm, write>;
@group(1) @binding(1)
var tex2: texture_2d<f32>;
@group(1) @binding(2)
var tex2_sampler: sampler;
@group(2) @binding(3)
var<uniform> input: Input;

struct Input {
    time: f32, temp1: f32,
    temp2: f32, temp3: f32,
}

@compute @workgroup_size(16, 16, 1)
fn main(
  @builtin(global_invocation_id) pixel : vec3<u32>
) {
    let pixel_coord = vec2(i32(pixel.x), i32(pixel.y) );
    // let neighbors = count_neighbors(pixel_coord);

    // var color = vec4(0.0, 0.0, 0.0, 0.0);

    // if(neighbors == 3 || neighbors == 6){
    //   color = vec4(1.0, 1.0, 1.0, 1.0);
    // } else if (neighbors == 2){
    //   color = textureLoad(tex2, pixel_coord, 0);
    // }
    // var output = textureLoad(tex2, pixel_coord, 0);
    // output.r += pow(cos(output.r * 3.141593), 257.0)*0.1 + (randFromCoord(vec2(pixel.x + u32(input.time), pixel.y), 0.02) - 0.01);// + (randFromCoord(pixel.xy, 0.02) - 0.01);
    // output.g += pow(cos(output.g * 3.141593), 257.0)*0.1 + (randFromCoord(vec2(pixel.x + u32(input.time), pixel.y)*2u, 0.02) - 0.01);// + (randFromCoord(pixel.xy*2u, 0.02) - 0.01);
    // output.r = output.r%1.0;
    // output.g = output.g%1.0;
    // let isBlk = textureLoad(tex2, pixel_coord, 0).rgb == vec3(0.0, 0.0, 0.0);
    // if(isBlk.x && isBlk.y && isBlk.z){
      var rand1 = randFromCoord(vec2(pixel.x + u32(input.time), pixel.y), 1.0);
      var rand2 = randFromCoord(vec2(pixel.x + u32(input.time), pixel.y)*2u, 1.0);
      var rand3 = randFromCoord(vec2(pixel.x + u32(input.time), pixel.y)*3u, 1.0);
      let output = vec4(normalize(vec2(rand1, rand2)), rand3, 1.0);
    // }
    

    textureStore(tex1, pixel_coord, output);
    
}


//https://www.reedbeta.com/blog/quick-and-easy-gpu-random-numbers-in-d3d11/
fn randFromCoord(coord: vec2<u32>, max: f32) -> f32{
    let seedGenInput = u32((f32(coord.x) + 2048.0*f32(coord.y)));
    //PCG Hash
      var seed = seedGenInput;
      // for(var i = 0; i<1; i+=1){
        seed = seed * 747796405u + 2891336453u;
        seed = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
        seed = (seed >> 22u) ^ seed;
      // }

    //xorshift
      // var rand = seed;
      // rand = rand ^ (rand << 13u);
      // rand = rand ^ (rand >> 17u);
      // rand = rand ^ (rand << 5u);

    return max*f32(seed)/4294967296.0;
}

fn wang_hash(seed: u32) -> u32
{
    var seed = (seed ^ 61u) ^ (seed >> 16u);
    seed *= 9u;
    seed = seed ^ (seed >> 4u);
    seed *= 0x27d4eb2du;
    seed = seed ^ (seed >> 15u);
    return seed;
}

fn count_neighbors(pix_coord: vec2<i32> ) -> i32 {
  var sum = 0;
  sum += is_black(getPixel(vec2(pix_coord.x + 1, pix_coord.y + 1)));
  sum += is_black(getPixel(vec2(pix_coord.x + 0, pix_coord.y + 1)));
  sum += is_black(getPixel(vec2(pix_coord.x - 1, pix_coord.y + 1)));
  sum += is_black(getPixel(vec2(pix_coord.x - 1, pix_coord.y + 0)));
  sum += is_black(getPixel(vec2(pix_coord.x + 1, pix_coord.y + 0)));
  sum += is_black(getPixel(vec2(pix_coord.x - 1, pix_coord.y - 1)));
  sum += is_black(getPixel(vec2(pix_coord.x + 0, pix_coord.y - 1)));
  sum += is_black(getPixel(vec2(pix_coord.x + 1, pix_coord.y - 1)));
  
  return sum;
}

fn getPixel(pix_coord: vec2<i32>) -> vec4<f32> {
  let WH = textureDimensions(tex2);
  if(pix_coord.x < 0 || pix_coord.x > (i32(WH.x) - 1) || pix_coord.y < 0 || pix_coord.y > (i32(WH.y) - 1)){
    return vec4(0.0, 0.0, 0.0, 0.0);
  } else {
    return textureLoad(tex2, vec2(pix_coord.x, pix_coord.y), 0);
  }
}

fn is_black(color: vec4<f32> ) -> i32{
  if(color.r == 1.0){
    return 1;
  } else {
    return 0;
  }
}