// Vertex shader

struct VertexIn {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>
};

struct Dimensions {
    width: f32, time: f32,
    height: f32, temp: f32,
    xOff: f32, yOff: f32,
    scale: f32, dark: f32,
}

struct Camera {
    view_proj: mat4x4<f32>,
    eye: mat4x4<f32>,
    focus: mat4x4<f32>,
};

// struct Timestamp {
//     millis: f32, millis1: f32, millis2: f32, millis3: f32
// }

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) vertex_pos: vec3<f32>,
    // @location(3) pure_vertex_pos: vec3<f32>,

};

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0)@binding(1)
var s_diffuse: sampler;
@group(1) @binding(2)
var<uniform> dim: Dimensions;
// @group(2) @binding(3)
// var<uniform> time: Timestamp;
// @group(2) @binding(3)
// var t_diffuse2: texture_2d<f32>;//  texture_storage_2d<rgba8unorm, read_write>;//
// @group(2)@binding(4)
// var s_diffuse2: sampler;
@group(3) @binding(5)
var golTex: texture_2d<f32>;//  texture_storage_2d<rgba8unorm, read_write>;//
@group(3)@binding(6)
var golTexSamp: sampler;
@group(2) @binding(7)
var<uniform> cam: Camera;
// @group(3) @binding(5)
// var<storage, read_write> tex1: array<u32>;

@vertex
fn vs_main(
    in: VertexIn,
    @builtin(instance_index) instance: u32,
    @builtin(vertex_index) vertex: u32,
) -> VertexOutput {
    var out: VertexOutput;
    let aspect = dim.width/dim.height;
    // let t = f32(instance);
    // let c = time.millis;
    // let instances = 12499.0;
    // let spacing = 0.0004*20.0;
    // let xOff = spacing*sin((c/10000.0+1.0+t)*2.71828*sin(c/1100000.0))*t*(t/instances)/aspect;
    // let yOff = spacing*cos((c/10000.0+1.0+t)*2.71828*sin(c/1100000.0))*t*(t/instances);
    // let zoom = 2.0;
    // out.clip_position = vec4<f32>(
    //     (zoom)*(0.2*t/instances/aspect*(in.position.x)+xOff),
    //     (zoom)*(0.2*t/instances*in.position.y+yOff),
    //     in.position.z,
    //     1.0
    // );
    let WH = textureDimensions(golTex);//vec2(11584, 11584);
    let texAspect = f32(WH.x)/(f32(WH.y));

    let int_scaler = dim.scale;//floor(dim.height/f32(WH.y));
    // var atemp = int_scaler*f32(WH.y)/dim.height;
    // atemp = floor(atemp*f32(WH.y)*int_scaler)/(f32(WH.y)*int_scaler);
    // var x = texAspect*in.position.x/aspect*atemp;
    // var y = in.position.y*atemp;

    // x = floor((x*f32(WH.x))*int_scaler)/(f32(WH.x)*int_scaler) + 2.0*dim.xOff/dim.width;
    // y = floor((y*f32(WH.y))*int_scaler)/(f32(WH.y)*int_scaler) - 2.0*dim.yOff/dim.height;

    let detailLvl = sqrt(64000000.0);

    var position = in.position;
    var position2 = position;
    var position3 = position;

    
    position2.x += detailLvl/2.0;
    position2.x = position2.x/abs(position2.x) * 0.5;
    let tex2 = vec2(position2.x/abs(position2.x)*2.0, position2.z/abs(position2.z)*2.0);
    position2.x -= detailLvl/2.0;
    position3.z += detailLvl/2.0;
    position3.z = position3.z/abs(position3.z) * 0.5;
    let tex3 = vec2(position3.x/abs(position3.x)*2.0, position3.z/abs(position3.z)*2.0);
    position3.z -= detailLvl/2.0;

    
    let x = f32(instance) % 800.0;
    let z = floor(f32(instance) / 800.0);
    position.x += x;
    position.z += z;
    position2.x += x;
    position2.z += z;
    position3.x += x;
    position3.z += z;

    let tex_coords =  vec2((in.tex_coords.x/detailLvl)+x/detailLvl, (in.tex_coords.y/detailLvl)+z/detailLvl);
    let tex_coords2 = vec2((tex2.x/detailLvl)+x/detailLvl, (tex2.y/detailLvl)+z/detailLvl);
    let tex_coords3 = vec2((tex3.x/detailLvl)+x/detailLvl, (tex3.y/detailLvl)+z/detailLvl);
    let noise = vertNoise(tex_coords);
    let noise2 = vertNoise(tex_coords2);
    let noise3 = vertNoise(tex_coords3);
    position.y += noise.x * dim.temp;//perlInterpSamp(golTex, tex_coords).r * dim.temp;
    position2.y += noise2.x * dim.temp;//perlInterpSamp(golTex, tex_coords).r * dim.temp;
    position3.y += noise3.x * dim.temp;//perlInterpSamp(golTex, tex_coords).r * dim.temp;
    if(position.y < 0.0){ position.y = 0.0; position.y += noise.y * dim.temp;}
    if(position2.y < 0.0){ position2.y = 0.0; position2.y += noise2.y * dim.temp;}
    if(position3.y < 0.0){ position3.y = 0.0; position3.y += noise3.y * dim.temp;}
    // y = floor(y*f32(WH.y))/f32(WH.y); 
    out.normal = normalize(cross((position3 - position), (position2 - position)));
    // out.pure_vertex_pos = position;
    out.vertex_pos = position;
    // position.y = 1.0 - abs(position.x) - abs(position.z);
    // position.x = 400.0*sin(position.x*3.141592*2.0/800.0);
    // position.z = 400.0*sin(position.z*3.141592*2.0/800.0);

    out.clip_position =  cam.view_proj * vec4<f32>(position, 1.0);//vec4(x, y, in.position.z, 1.0);
    out.tex_coords = tex_coords;//detailLvl + vec2(x/detailLvl, z/detailLvl);
    // out.color = in.color;
    
    return out;
}

fn vertNoise(tex_coords: vec2<f32>) -> vec2<f32> {

    let WH = textureDimensions(golTex);

    let coord = vec2(tex_coords.x*f32(WH.x), tex_coords.y*f32(WH.y));
    let coord2 = vec2(tex_coords.x*f32(WH.x), tex_coords.y*f32(WH.y))/5.0;
    let coord3 = vec2(tex_coords.x*f32(WH.x), tex_coords.y*f32(WH.y))/29.0;
    let coord4 = vec2(tex_coords.x*f32(WH.x), tex_coords.y*f32(WH.y))/101.0;
    let noise = perlinFilter(coord)/8.0 + perlinFilter(coord2)/2.0 + perlinFilter(coord3) + perlinFilter(coord4)*4.0;
    let noise2 = perlinFilter(coord)/32.0;// + perlinFilter(coord2)/2.0 + perlinFilter(coord3) + perlinFilter(coord4)*4.0;

    return vec2(noise, noise2);
}


@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // textureStore(t_diffuse2, in.tex_coords, textureSample(t_diffuse2, s_diffuse2, in.tex_coords)+vec4(0.01, 0.01, 0.01, 1.0));
    // let xOff = 0.0;//(sin(dim.time/10000.0 + in.tex_coords.x));
    // let yOff = 0.0;//(cos(dim.time/10000.0 + in.tex_coords.y));
    // let moddedCoords = vec2(sin(dim.time/10000.0)*sin(in.tex_coords.x*100.0)+xOff, sin(dim.time/10000.0)*sin(in.tex_coords.y*100.0)+yOff);
    // let tex = golTex;
    // let texSamp = golTexSamp;

    // GRAPHING PROG
    // var func_coords = in.tex_coords;
    // func_coords.x -= 0.5;
    // func_coords.y -= 0.5;
    // func_coords.y *= -1.0;
    // func_coords /= dim.scale * 0.01;
    // let y = 2.0*sin(func_coords.x/0.1) + 10.0*sin(func_coords.x/10.0);//pow(func_coords.x, 2.0);
    // // let x = pow(func_coords.y, 0.5);
    // let thresh = 0.08/dim.scale;
    //        if (y > func_coords.y - thresh && y < func_coords.y + thresh){
    //     return vec4(1.0, 0.0, 0.0, 1.0);
    // // } else if ((x > func_coords.x - thresh && x < func_coords.x + thresh) || (-x > func_coords.x - thresh && -x < func_coords.x + thresh)) {
    // //     return vec4(1.0, 0.0, 0.0, 1.0);
    // } else {
    //     return vec4(0.0, 0.0, 0.0, 1.0);
    // }


    let WH = textureDimensions(golTex);//vec2(11584, 11584);//
    
    // let WH = vec2(u32(32), u32(1));

    
    // let height = (3840.0/dim.height)*0.5*dim.temp*0.18662*vlines/240.0;//1.0/((dim.height/256.0) - 1.0);
    // let width = (3840.0/dim.height)*0.5*dim.temp*0.18662*(320.0/240.0)*vlines/320.0;//1.0/((dim.height/256.0) - 1.0);
    
    // let pixels = floor(dim.temp);
    let pixel_coord = vec2(i32(in.tex_coords.x*f32(WH.x)), i32(in.tex_coords.y*f32(WH.y)));
    // let tex2Color = textureLoad(golTex, pixel_coord, 0);//textureSample(t_diffuse2, s_diffuse2, vec2(in.tex_coords.x, (in.tex_coords.y*240.0)%1.0));//moddedCoords);//pixelate(in.tex_coords, pixels*2.0));//512.0));
    // var color = textureSample(golTex, golTexSamp, in.tex_coords);//pixelate(tex, in.tex_coords, pixels));// + tex2Color;//256.0));
    // let alive = getPixel(pixel_coord);
    // var pixColor = textureLoad(golTex, pixel_coord, 0);//textureSample(golTex, golTexSamp, in.tex_coords);//////textureSample(golTex, golTexSamp, pixelate(golTex, in.tex_coords, pixels));// + tex2Color;//256.0));
    
    //GOL Neighbor-based filtering
        // let neighbors_neighbors = count_neighbors_neighbors(pixel_coord);
        // let neighbors = count_neighbors(pixel_coord);
        // if(neighbors < 1 || neighbors_neighbors  1){
        //     pixColor = vec4(0.0, 0.0, 0.0, 0.0);
        // } else {
        //     pixColor = vec4(1.0, 1.0, 1.0, 1.0);
        // }

    // var pixColor = vec4(1.0, 1.0, 1.0 ,1.0);
    // if(alive == 1u){
    //     pixColor = vec4(0.0,0.0,0.0,1.0);
    // } else if(alive == 2u){
    //     pixColor = vec4(1.0,0.0,0.0,1.0);
    // }
    // var vPixColor = textureSample(golTex, golTexSamp, vec2(in.tex_coords.x, pixelateVertically(golTex, in.tex_coords, pixels)));// + tex2Color;//256.0));
    // if((vlines*in.tex_coords.y)%1.0 > height){
    //     discard;
    // }
    // if((hlines*in.tex_coords.x)%1.0 > width){
    //     discard;
    // }

    //SCANLINE/GRID CODE

        let int_scaler = dim.scale;//floor(dim.height/f32(WH.y));
        let vlines = f32(WH.y);
        let hlines = f32(WH.x);
        
        // if((floor(vlines*int_scaler*in.tex_coords.y))%int_scaler >= int_scaler - dim.temp){
        //     discard;
        // }
        // if((floor(hlines*int_scaler*in.tex_coords.x))%int_scaler >= int_scaler - dim.temp && dim.time == 0.0){
        //     discard;
        // }

    // // if(tex2Color.r == 0.0 && tex2Color.g==0.0 && tex2Color.b == 0.0){
    //     discard;
    // }
    // if(pixColor.r == 0.0){
    //     pixColor = vec4(1.0, 1.0, 1.0, 1.0);
    // } else {
    //     pixColor = vec4(0.0, 0.0, 0.0, 1.0);
    // }
    // var avg = vec4((vPixColor.r + 2.0*pixColor.r)/3.0, (vPixColor.g + 2.0*pixColor.g)/3.0, (vPixColor.b + 2.0*pixColor.b)/3.0, 1.0);
    // if((lines*in.tex_coords.y)%1.0 > height){
        //pixColor = vec4(avg.rgb*0.01, avg.a);
    // }
    // var dimmer = 1.0;
    // let pixCoord = vec2(in.tex_coords.x*f32(WH.x), in.tex_coords.y*f32(WH.y));
    // var rand = randFromCoord(((in.tex_coords.x + in.tex_coords.y)/2.0));

    // rand = randFromCoord((rand));
    // rand = randFromCoord((rand));
    // rand = randFromCoord((rand));
    // rand = randFromCoord((rand));
    // rand = randFromCoord((rand));
    // let pixColor1 = textureLoad(golTex, pixel_coord, 0);//textureSample(golTex, golTexSamp, in.tex_coords);//////textureSample(golTex, golTexSamp, pixelate(golTex, in.tex_coords, pixels));// + tex2Color;//256.0));
    let coord = vec2(in.tex_coords.x*f32(WH.x), in.tex_coords.y*f32(WH.y));
    let coord2 = vec2(in.tex_coords.x*f32(WH.x), in.tex_coords.y*f32(WH.y))/5.0;
    let coord3 = vec2(in.tex_coords.x*f32(WH.x), in.tex_coords.y*f32(WH.y))/29.0;
    let coord4 = vec2(in.tex_coords.x*f32(WH.x), in.tex_coords.y*f32(WH.y))/101.0;
    let noise = perlinFilter(coord)/8.0 + perlinFilter(coord2)/2.5 + perlinFilter(coord3) + perlinFilter(coord4)*4.0;
    var rivers = (pow(abs(noise), 0.2));
    if(rivers < 0.1) { rivers = 0.0; } else { rivers = 1.0;}
    var water = 0.0;
    var snow = 0.0;
    var grass = 0.0;
    var sand = 0.0;
    let snowThresh = 1.1 + perlinFilter(coord)/8.0;
    let sandThresh = 0.1 + perlinFilter(coord)/8.0;
    let lightPos = (vec3(dim.xOff, dim.temp*2.6, dim.yOff));
    let lightDir = normalize(lightPos - in.vertex_pos);
    let brightness = max(dot3D(in.normal, lightDir), 0.0);
    let eye = vec3(cam.eye[0][0], cam.eye[0][1], cam.eye[0][2]);
    let focus = in.vertex_pos;//vec3(cam.focus[0][0], cam.focus[0][1], cam.focus[0][2]);
    let camDir =  normalize(focus - eye);
    var refDir = normalize(reflect(lightDir, in.normal));
    // refDir.x *= -1.0;
    var specular = 0.0;//pow(clamp(dot3D(refDir, camDir), 0.0, 1.0), 1024.0);


    let ambient = 0.01;
    if(noise > snowThresh) { snow = 1.0; }
    if(noise > 0.0 && noise < sandThresh ) { sand = 1.0; }
    if(noise < snowThresh && noise > sandThresh) { grass = 1.0; }
    // if(water > 0.0) { water = 0.0;}
    if(noise < 0.0) { water = 1.0;}
    // if(specular < 0.8) {specular = 0.0;} //vec4(in.normal.x, in.normal.y, in.normal.z, 1.0);//vec4(in.vertex_pos.xyz, 1.0)/800.0;//
    var out = (brightness + specular + ambient) * vec4((snow + 0.72156862745*sand), (0.64705882352*sand + snow + grass*0.6) + 0.1*water, (sand*0.3294117647 + snow)* noise + water, 1.0);////50.0*vec4(brightness, 0.0, 0.0, 1.0);//(abs(brightness) + ambient) * vec4((snow + 0.72156862745*sand), (0.64705882352*sand + snow + grass*0.6) + 0.1*water, (sand*0.3294117647 + snow)* noise + water, 1.0);// vec4(0.0, noise, 1.0 - rivers - noise, 1.0) ;//* (pow(abs(noise), 0.2));// * (noise);//perlinFilter(coord);// pow(abs(interpDots), 0.2);//* f32(neighbors)/8.0;// * f32(alive);
    if(length(abs(in.vertex_pos.xz - vec2(dim.xOff, dim.yOff))) < 3.0){
        out = vec4(0.8, 0.0, 1.0, 1.0);
    }
    // out = textureLoad(golTex, pixel_coord, 0).r * vec4(.0, 1.0, 1.0, 1.0);
    // var out = vec4(1.0, 1.0, 1.0, 1.0) * ((rand));
    // Fractal!!!
        // var coords = in.tex_coords;
        // coords.x = coords.x - 0.8;
        // coords.y = coords.y - 0.5;
        // coords = coords * 2.0;
        // let output = iterateMandelbrot(coords);
        // var out = vec4(output, output, output, 1.0);



    // Color Mapper
        // out.r = sin(out.r*2.0*3.14159);
        // out.g = -cos(out.g*2.0*3.14159);
        // out.b = -sin(out.b*2.0*3.14159);

    // Color Mapper 2
        // out.r = cos((out.r + 3.0/4.0)*1.0*3.14159/3.0);
        // out.g = cos((out.g + 1.5/4.0)*1.0*3.14159/1.5);
        // out.b = cos((out.b +  1.0/4.0)*1.0*3.14159/1.0);

    // if(output == 0.0){
    //     out = vec4(0.0, 0.0, 0.0, 1.0);
    // }
        
    var color = perlInterpSamp(golTex, in.tex_coords);//perlInterpSamp(golTex, in.tex_coords);
    
    // Dark Mode/ Invert Colors
        if(dim.dark == 1.0){
            color = invert(color);
            out = invert(out);
        }
    
    //SRGB Mapping
        color = SRGB(color);
        out = SRGB(out);

    return out;//color;//out;//* pixColor.r;//vec4(out.r, out.g, out.b, 1.0);
}

fn invert(color: vec4<f32>) -> vec4<f32> {
    var clone = color;
    clone.r = 1.0 - clone.r;
    clone.g = 1.0 - clone.g;
    clone.b = 1.0 - clone.b;
    
    return clone;

}
fn SRGB(color: vec4<f32>) -> vec4<f32> {
    var clone = color;
    clone.r = pow(clone.r, (2.2));
    clone.g = pow(clone.g, (2.2));
    clone.b = pow(clone.b, (2.2));  

    return color;
}

fn perlInterpSamp(tex: texture_2d<f32>, tex_coords: vec2<f32>) -> vec4<f32> {
    let WH = textureDimensions(tex);
    let coord = vec2(tex_coords.x*f32(WH.x) - 0.5, tex_coords.y*f32(WH.y) - 0.5);

    let coord1 = vec2(i32(floor(coord.x)), i32(floor(coord.y)));
    let coord2 = vec2(i32(ceil(coord.x)), i32(floor(coord.y)));
    let coord3 = vec2(i32(floor(coord.x)), i32(ceil(coord.y)));
    let coord4 = vec2(i32(ceil(coord.x)), i32(ceil(coord.y)));
    
    let color1 = textureLoad(tex, coord1, 0);
    let color2 = textureLoad(tex, coord2, 0);
    let color3 = textureLoad(tex, coord3, 0);
    let color4 = textureLoad(tex, coord4, 0);

    let u = (coord.x-floor(coord.x));
    let v = (coord.y-floor(coord.y));

    return Lerp2(u, Lerp2(v, color1, color3), Lerp2(v, color2, color4));
}

fn perlinFilter(coord: vec2<f32>) -> f32 {
    // let coordf = vec2(i32(floor(coord.x)), i32(floor(coord.y)));
    let coord1 = vec2(i32(floor(coord.x)), i32(floor(coord.y))); // top left
    let coord2 = vec2(i32(ceil(coord.x)), i32(floor(coord.y))); // top right
    let coord3 = vec2(i32(floor(coord.x)), i32(ceil(coord.y))); // bottom left
    let coord4 = vec2(i32(ceil(coord.x)), i32(ceil(coord.y))); // bottom right
    let dist1 = coord - vec2(f32(coord1.x), f32(coord1.y));
    let dist2 = coord - vec2(f32(coord2.x), f32(coord2.y));
    let dist3 = coord - vec2(f32(coord3.x), f32(coord3.y));
    let dist4 = coord - vec2(f32(coord4.x), f32(coord4.y));
    let color1 = textureLoad(golTex, coord1, 0);
    let color2 = textureLoad(golTex, coord2, 0);
    let color3 = textureLoad(golTex, coord3, 0);
    let color4 = textureLoad(golTex, coord4, 0);
    let vect1 = vec2(color1.r - 0.5, color1.g - 0.5) * 2.0;
    let vect2 = vec2(color2.r - 0.5, color2.g - 0.5) * 2.0;
    let vect3 = vec2(color3.r - 0.5, color3.g - 0.5) * 2.0;
    let vect4 = vec2(color4.r - 0.5, color4.g - 0.5) * 2.0;
    let dot1 = dot(dist1, vect1);
    let dot2 = dot(dist2, vect2);
    let dot3 = dot(dist3, vect3);
    let dot4 = dot(dist4, vect4);
    let u = (coord.x-floor(coord.x));
    let v = (coord.y-floor(coord.y));
    return Lerp(v, Lerp(u, dot1, dot2), Lerp(u, dot3, dot4));
    // if((length(dist1) < 0.3 && dot(dist1, vect1) <= 1.0 && dot(dist1, vect1) > 0.0) || 
    //    (length(dist2) < 0.3 && dot(dist2, vect2) <= 1.0 && dot(dist2, vect2) > 0.0) || 
    //    (length(dist3) < 0.3 && dot(dist3, vect3) <= 1.0 && dot(dist3, vect3) > 0.0) || 
    //    (length(dist4) < 0.3 && dot(dist4, vect4) <= 1.0 && dot(dist4, vect4) > 0.0)){
    //     return 1.0;
    // }
    // return -1.0;
}


fn Lerp2(t: f32, a1: vec4<f32>, a2: vec4<f32>) -> vec4<f32> {
	// let smoother = t * t * (3.0f - 2.0f * t);
    return a1 + smoothstep(0.0, 1.0, t)*(a2-a1);
}

//https://rtouti.github.io/graphics/perlin-noise-algorithm {
fn Lerp(t: f32, a1: f32, a2: f32) -> f32 {
	// let smoother = t * t * (3.0f - 2.0f * t);
    return a1 + smoothstep(0.0, 1.0, t)*(a2-a1);
}

// fn Fade(t: f32) -> f32 {
// 	return ((6.0*t - 15.0)*t + 10.0)*t*t*t;
// }
//}

fn dot(v1: vec2<f32>, v2: vec2<f32>) -> f32 {
    return v1.x*v2.x + v1.y*v2.y;
}

fn dot3D(v1: vec3<f32>, v2: vec3<f32>) -> f32 {
    return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
}

fn cross3D(v1: vec3<f32>, v2: vec3<f32>) -> vec3<f32> {
    return vec3(
            v1.y*v2.z - v1.z*v2.y,
            v1.z*v2.x - v1.x*v2.z,
            v1.x*v2.y - v1.y*v2.x
           );
}

fn squareImaginary(number: vec2<f32> ) -> vec2<f32> {
	return vec2(
		pow(number.x,2.0)-pow(number.y,2.0),
		2.0*number.x*number.y
	);
}

fn iterateMandelbrot(coord: vec2<f32>) -> f32 {
	var z = vec2(0.0,0.0);
    let maxIters = 100*i32(dim.time);//i32(10.0*dim.scale);
	for(var i=0;i<maxIters;i+=1){
		z = squareImaginary(z) + coord;
		if(length(z)>2.0) {return 1.0 * pow((f32(i)/f32(maxIters)), 0.1);}
	}
	return 0.0;//f32(maxIters);
}

fn count_neighbors_neighbors(pix_coord: vec2<i32> ) -> i32 {
    var min = 8;
    min = min(min, count_neighbors(vec2(pix_coord.x + 1, pix_coord.y + 1)));
    min = min(min, count_neighbors(vec2(pix_coord.x + 0, pix_coord.y + 1)));
    min = min(min, count_neighbors(vec2(pix_coord.x - 1, pix_coord.y + 1)));
    min = min(min, count_neighbors(vec2(pix_coord.x - 1, pix_coord.y + 0)));
    min = min(min, count_neighbors(vec2(pix_coord.x + 1, pix_coord.y + 0)));
    min = min(min, count_neighbors(vec2(pix_coord.x - 1, pix_coord.y - 1)));
    min = min(min, count_neighbors(vec2(pix_coord.x + 0, pix_coord.y - 1)));
    min = min(min, count_neighbors(vec2(pix_coord.x + 1, pix_coord.y - 1)));

    return min;
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
    let WH = textureDimensions(golTex);
    if(pix_coord.x < 0 || pix_coord.x > (i32(WH.x) - 1) || pix_coord.y < 0 || pix_coord.y > (i32(WH.y) - 1)){
    return vec4(0.0, 0.0, 0.0, 0.0);
    } else {
    return textureLoad(golTex, vec2(pix_coord.x, pix_coord.y), 0);
    }
}

fn is_black(color: vec4<f32> ) -> i32{
    if(color.r == 1.0 && color.g==1.0 && color.b == 1.0){
    return 1;
    } else {
    return 0;
    }
}




fn pixelate(texture: texture_2d<f32>, texCoord: vec2<f32> , pixels: f32) -> vec2<f32> {
    let WH = textureDimensions(texture);
    // let WH = vec2(64u, 64u);
    var x: f32 = (floor(texCoord.x*f32(WH.x))+0.5);
    var y: f32 = (floor(texCoord.y*f32(WH.y))+0.5);
    if(x > f32(WH.x)){ x -= 1.0; }
    if(y > f32(WH.y)){ y -= 1.0; }
    x /= f32(WH.x);
    y /= f32(WH.y);
    return vec2(x, y);
}

fn pixelateVertically(texture: texture_2d<f32>, texCoord: vec2<f32> , pixels: f32) -> f32 {
    let WH = textureDimensions(texture);
    var y: f32 = (floor(texCoord.y*f32(WH.y))+0.5);
    if(y > f32(WH.y)){ y -= 1.0; }
    y /= f32(WH.y);
    return y;
}