@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var currentSampler: sampler;
@group(0) @binding(2) var rainBuffer: texture_2d<f32>;
@group(0) @binding(3) var marchBuffer: texture_2d<f32>;


@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {;
  let uv = pos.xy / res;
  let rain = textureSample(rainBuffer, currentSampler, uv);
  let march = textureSample(marchBuffer, currentSampler, uv);
  let out = rain + march;
  return vec4f(out);
}
