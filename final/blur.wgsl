@group(0) @binding(0) var <uniform> res  : vec2f;
@group(0) @binding(1) var <uniform> dir  : vec2f;
@group(0) @binding(2) var tex: texture_2d<f32>;
@group(0) @binding(3) var smp: sampler;
@group(0) @binding(4) var rain: texture_2d<f32>;
@group(0) @binding(5) var raymarch: texture_2d<f32>;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
    var sum:vec4f = vec4f(0.);
    let tc = pos.xy / res;

    let rain_depth = textureSample(rain, smp, tc);
    let ray_depth = textureSample(raymarch, smp, tc);

    var depth_distance = max(abs(rain_depth.w), abs(ray_depth.w));
    if(depth_distance < .9) {
        //depth_distance = 0.;
        depth_distance = depth_distance;
    }

    depth_distance -= 1.3;
    let blur = (dir * depth_distance)/res;

    sum += textureSample( tex, smp, tc - 4. * blur ) * 0.0162162162;
	sum += textureSample( tex, smp, tc - 3. * blur ) * 0.0540540541;
	sum += textureSample( tex, smp, tc - 2. * blur ) * 0.1216216216;
	sum += textureSample( tex, smp, tc - 1. * blur ) * 0.1945945946;
	
	sum += textureSample( tex, smp, tc ) * 0.2270270270;
	
	sum += textureSample( tex, smp, tc + 4. * blur ) * 0.0162162162;
	sum += textureSample( tex, smp, tc + 3. * blur ) * 0.0540540541;
	sum += textureSample( tex, smp, tc + 2. * blur ) * 0.1216216216;
	sum += textureSample( tex, smp, tc + 1. * blur ) * 0.1945945946;

    return vec4f( sum.rgb, 1.);
}