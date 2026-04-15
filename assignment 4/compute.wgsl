struct Particle {
  pos: vec2f,
  vel: vec2f,
  droplet: f32,
  padding: f32
};

@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var<storage, read_write> state: array<Particle>;
@group(0) @binding(2) var<uniform> angle: f32;

fn cellindex( cell:vec3u ) -> u32 {
  let size = 8u;
  return cell.x + (cell.y * size) + (cell.z * size * size);
}

@compute
@workgroup_size(8,8)

fn cs(@builtin(global_invocation_id) cell:vec3u)  {
  let i = cellindex( cell );
  let p = state[ i ];
  var pos = p.pos;
  var vel = p.vel;
  var droplet = p.droplet;

  let floor = -1.5;
  let gravity = -0.001;

  if (droplet < 0.5) {

    pos += (2.0 / res) * vel + vec2f(0.0, -abs(angle) / 2000.0);

    if (pos.y <= floor) {
      pos.y = floor;

      droplet = 1.0;

      let r1 = fract(sin(f32(i) * 83.72836) * 63592.4515);
      let r2 = fract(sin(f32(i) * 27.4197) * 63592.4515);

      vel.x = (r1 - 0.5) * 0.005;
      vel.y = 0.02 + r2 * 0.02;
    }

  } else {

    vel.y += gravity;
    pos += vel;

    if (pos.y <= -2.0) {
      pos.y = 1.5;
      pos.x = -2.0 + fract(sin(f32(i)*50.872) * 63592.4515) * 4.0;

      droplet = 0.0;
      let r = fract(sin(f32(i) * 73.5256) * 63592.4515);
      vel = vec2f(0.0, -10.0 * r);
    }
  }

  state[i].pos = pos;
  state[i].vel = vel;
  state[i].droplet = droplet;
}
