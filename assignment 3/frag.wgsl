@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var<storage> state: array<f32>;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let idx : u32 = u32( pos.y * res.x + pos.x );
  var v = state[ idx * 2 + 1];
  let a = state[idx * 2];

  var weight: f32 = 0.0;

  for (var i: u32 = 0; i < 20; i += 2){
    weight += f32(state[(idx * 2 + 1) + i]);
  }

  if (weight > 0.5 && v < 0.3) {
    v = 0.5;
  }

  return vec4f( v,v,v, 1.);
}
