struct VertexInput {
  @location(0) pos: vec2f,
  @builtin(instance_index) instance: u32,
};

struct VertexOutput {
  @builtin(position) position: vec4f,
  @location(0) color: vec3f,
};

struct Particle {
  pos: vec2f,
  speed: vec2f,
  droplet: f32,
  padding: f32
};

@group(0) @binding(0) var<uniform> frame: f32;
@group(0) @binding(1) var<uniform> res:   vec2f;
@group(0) @binding(2) var<storage> state: array<Particle>;
@group(0) @binding(3) var<uniform> angle: f32;

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

@vertex 
fn vs( input: VertexInput ) ->  VertexOutput {
  let aspect = res.y / res.x;
  let p = state[ input.instance ];
  let isDroplet = p.droplet > 0.5;
  let scale = select(0.015, 0.005, isDroplet);

  let size = input.pos * scale;
  

  var output: VertexOutput;
  var vertex = vec4f( p.pos.x - size.x * aspect, p.pos.y + size.y * 10, 0., 1.);
  
  vertex = rotate(vertex, angle);

  output.position = vertex;

  let rainColor = mix(vec3f(0.,0.,.4), vec3f(.2,0.,.7), (p.pos.y+1.0)/1.5);
  let splashColor = vec3f(0.3, 0.3, 1.0);
  output.color = select(rainColor, splashColor, p.droplet > 0.5);

  return output; 
}

@fragment 
fn fs( input: VertexOutput) -> @location(0) vec4f {;
  let color = input.color;
  return vec4f( color, .6 );
}
