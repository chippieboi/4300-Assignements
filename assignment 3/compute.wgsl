@group(0) @binding(0) var<uniform> res: vec2f;
@group(0) @binding(1) var<storage> statein: array<f32>;
@group(0) @binding(2) var<storage, read_write> stateout: array<f32>;
@group(0) @binding(3) var<uniform> Da: f32;
@group(0) @binding(4) var<uniform> Db: f32;
@group(0) @binding(5) var<uniform> F: f32;
@group(0) @binding(6) var<uniform> K: f32;

fn index( x:i32, y:i32 ) -> u32 {
  let _res = vec2i(res);
  return u32( (y % _res.y) * _res.x + ( x % _res.x ) );
}

fn laplaceA(x:i32, y:i32) -> f32 {
  return
    statein[index(x,y) * 2] * -1.0+
    statein[index(x+1,y) * 2] * 0.2 +
    statein[index(x-1,y) * 2] * 0.2 +
    statein[index(x,y+1) * 2] * 0.2 +
    statein[index(x,y-1) * 2] * 0.2 +
    statein[index(x+1,y+1) * 2] * 0.05 +
    statein[index(x-1,y+1) * 2] * 0.05 +
    statein[index(x+1,y-1) * 2] * 0.05 +
    statein[index(x-1,y-1) * 2] * 0.05 ;
}

fn laplaceB(x:i32, y:i32) -> f32 {
  return
    statein[index(x,y) * 2 + 1] * -1.0+
    statein[index(x+1,y) * 2 + 1] * 0.2 +
    statein[index(x-1,y) * 2 + 1] * 0.2 +
    statein[index(x,y+1) * 2 + 1] * 0.2 +
    statein[index(x,y-1) * 2 + 1] * 0.2 +
    statein[index(x+1,y+1) * 2 + 1] * 0.05 +
    statein[index(x-1,y+1) * 2 + 1] * 0.05 +
    statein[index(x+1,y-1) * 2 + 1] * 0.05 +
    statein[index(x-1,y-1) * 2 + 1] * 0.05 ;
}

fn flow(x:i32, y:i32) -> vec2f {
  let f = f32(x) * 0.01;
  let g = f32(y) * 0.05;

  return vec2f( (sin(g*2.0) + 1.0), cos(f * 2.0) / 1.0);
}

@compute
@workgroup_size(8,8)
fn cs( @builtin(global_invocation_id) _cell:vec3u ) {
  let cell = vec3i(_cell);

  let i = index(cell.x, cell.y);
  
  let a = statein[i * 2];
  let b = statein[i * 2 + 1];

  let flow = flow(cell.x, cell.y);
  let fx = i32(flow.x * 2.0);
  let fy = i32(flow.y * 2.0);

  let lapA = laplaceA(cell.x + fx, cell.y + fy);
  let lapB = laplaceB(cell.x + fx, cell.y + fy);

  let abb = a * b * b;

  let da = Da * lapA - abb + F * (1.0 - a);
  let db = Db * lapB + abb - (F + K) * b;

  stateout[i*2] = clamp(a + da, 0.0, 1.0);
  stateout[i*2+1] = clamp(b + db, 0.0, 1.0);
}
