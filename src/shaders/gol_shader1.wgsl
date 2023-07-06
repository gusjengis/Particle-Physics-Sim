@group(0) @binding(0)
var tex1: texture_storage_2d<rgba8unorm, write>;
@group(1) @binding(1)
var tex2: texture_2d<f32>;
@group(1) @binding(2)
var tex2_sampler: sampler;

@compute @workgroup_size(16, 16, 1)
fn main(
  @builtin(global_invocation_id) pixel : vec3<u32>
) {
    let pixel_coord = vec2(i32(pixel.x), i32(pixel.y) );
    let neighbors = count_neighbors(pixel_coord);

    var color = vec4(0.0, 0.0, 0.0, 0.0);

    if(neighbors == 3 || neighbors == 6){
      color = vec4(1.0, 1.0, 1.0, 1.0);
    } else if (neighbors == 2){
      color = textureLoad(tex2, pixel_coord, 0);
    }
    textureStore(tex1, pixel_coord, vec4(color.r, color.gba));
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
  if(color.r == 1.0 && color.g==1.0 && color.b == 1.0){
    return 1;
  } else {
    return 0;
  }
}

