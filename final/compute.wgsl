struct Particle {
  pos: vec3f,
  vel: vec3f,
  droplet: f32,
  padding: f32,
  padding2: f32
};

@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var<storage, read_write> state: array<Particle>;
@group(0) @binding(2) var<uniform> angle: f32;
@group(0) @binding(3) var<uniform> frame: f32;

fn cellindex( cell:vec3u ) -> u32 {
  let size = 8u;
  return cell.x + (cell.y * size) + (cell.z * size * size);
}

fn rotate(v: vec4f, angle: f32) -> vec4f{
  let PI = 3.14159265358979;
  var radians = angle * PI / 180;

  let c = cos(radians);
  let s = sin(radians);

  let rotation_matrix = mat4x4<f32>(
    vec4f(c, s, 0.0, 0.0),
    vec4f(-s, c, 0.0, 0.0),
    vec4f(0.0, 0.0, 1.0, 0.0),
    vec4f(0.0, 0.0, 0.0, 1.0)
  );

  return rotation_matrix * v;
}

//========================================================================================================
//raymarch contact points
fn scene( p2:vec3f ) -> f32 {
  var p = p2;
  p.z = -p.z;
  p = p + vec3f(0., 0., 2.5);
  var pz = p;
  pz.z += frame / 200.f;
  pz.x += .25;
  var d = sphere(p, 2.);
  //d = sub(sphere( repeat(pz, vec3f(.5)), .2), sphere(p,2.));
  d = min( d, plane( p, vec3f(0.,1.,0.),1.5 ) );

  var s = plane( p, vec3f(0.,1.,0.),1.5 );

  return d;
}

fn sub( a:f32, b:f32 ) -> f32 {
  return max(-a,b);
}

fn repeat( p:vec3f, d:vec3f ) -> vec3f {
  return p - d*round(p/d);
}

fn sphere( point:vec3f, radius:f32 ) -> f32 {
  return length(point) - radius;
}

fn plane( point:vec3f, normal:vec3f, distance:f32 ) -> f32 {
  // the normal must be normalized
  return dot(point,normal) + distance;
}
//========================================================================================================




@compute
@workgroup_size(64,1)

fn cs(@builtin(global_invocation_id) cell:vec3u)  {
  let i = cell.x;
  if (i > arrayLength(&state)){
    return;
  }
  let p = state[ i ];
  var pos = p.pos;
  var vel = p.vel;
  var droplet = p.droplet;

  let floor = -1.5;
  let gravity = -0.001;

  if (droplet < 0.5) {

    //pos += (2.0 / res) * vel + vec2f(0.0, -abs(angle) / 2000.0);
    vel.y += gravity;
    pos += vel;

    if (scene(pos) <= 0.) {
      pos.y -= scene(pos);

      droplet = 1.0;

      let r1 = fract(sin(f32(i) * 83.72836) * 63592.4515);
      let r2 = fract(sin(f32(i) * 27.4197) * 63592.4515);

      vel.x = (r1 - 0.5) * 0.005;
      vel.y = 0.02 + r2 * 0.02;
      vel.z = 0.0;
    }

  } else {

    vel.y += gravity;
    pos += vel;


    //it hit the ground after bounce, go back into sky
    if (scene(pos) <= 0.) {
      pos.y = 7.0 + fract(sin(f32(i)*31.872) * 4852.4515);
      pos.x = -7.0 + fract(sin(f32(i)*50.872) * 63592.4515) * 15.0;
      pos.z = 1.5 + (fract(sin(f32(i)*836.7)*3050.0)-0.5)*6.0;

      droplet = 0.0;
      vel = vec3f(0.0, -0.02, 0.0);
    }
  }

  state[i].pos = pos;
  state[i].vel = vel;
  state[i].droplet = droplet;
}
