import { default as seagulls } from './gulls.js'

const WORKGROUP_SIZE = 64,
      NUM_AGENTS = 256,
      DISPATCH_COUNT = [NUM_AGENTS/WORKGROUP_SIZE,1,1],
      GRID_SIZE = 3,
      STARTING_AREA = .3

const W = Math.round( window.innerWidth  / GRID_SIZE ),
      H = Math.round( window.innerHeight / GRID_SIZE )

const render_shader = seagulls.constants.vertex + `
@group(0) @binding(0) var<storage> pheromones: array<f32>;
@group(0) @binding(1) var<storage> render: array<f32>;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let grid_pos = floor( pos.xy / ${GRID_SIZE}.);
  
  let pidx = grid_pos.y  * ${W}. + grid_pos.x;
  let p = pheromones[ u32(pidx) ];
  let v = render[ u32(pidx) ];

  var out = vec3(0.);

  if (p == 1.) {
    out = vec3(.3,0.,0.);
  } else if (p == 2.) {
    out = vec3(0.,.3,0.);
  } else if (p == 3.) {
    out = vec3(0.,0.,.3);
  }

  if (v == 1.) {
    out = vec3(1.,0.,0.);
  } else if (v == 2.) {
    out = vec3(0.,1.,0.);
  } else if (v == 3.) {
    out = vec3(0.,0.,1.);
  }
  
  return vec4f( out, 1. );
}`

const compute_shader =`
struct Vant {
  pos: vec2f,
  dir: f32,
  flag: f32
}

@group(0) @binding(0) var<storage, read_write> vants: array<Vant>;
@group(0) @binding(1) var<storage, read_write> pheremones: array<f32>;
@group(0) @binding(2) var<storage, read_write> render: array<f32>;
@group(0) @binding(3) var<uniform> frame: f32;

fn pheromoneIndex( vant_pos: vec2f ) -> u32 {
  let width = ${W}.;
  return u32( abs( vant_pos.y % ${H}. ) * width + vant_pos.x );
}

fn mymod(x: f32, y: f32) -> f32 {
        return x - y * floor(x/y);
    }

@compute
@workgroup_size(${WORKGROUP_SIZE},1,1)

fn cs(@builtin(global_invocation_id) cell:vec3u)  {

  if(mymod(frame, 1) != 0){
    return;
  }

  let pi2   = ${Math.PI*2}; 
  var vant:Vant  = vants[ cell.x ];

  let pIndex    = pheromoneIndex( vant.pos );
  let pheromone = pheremones[ pIndex ];

  //pheromone: 0 - no pheromone
  //pheromone: 1 - red pheromone
  //pheromone: 2 - green pheromone
  //pheromone: 3 - blue pheromone

  // if pheromones were found
  //flag = 0 is red, set to 1
  if (vant.flag == 0.){
    //claim spot
    if(pheromone == 0.){
      vant.dir += -0.25;
      pheremones[pIndex] = 1.;
    } else if(pheromone == 1.){
      pheremones[pIndex] = 0.;
    } else if(pheromone == 2.){
      pheremones[pIndex] = 1.;
    } else if(pheromone == 3.){
      pheremones[pIndex] = 1.;
    }
  } 
  
  //flag = 1 is green, set to 2
  else if(vant.flag == 1.){
    //claim spot
    if(pheromone == 0.){
      vant.dir += -0.25;
      pheremones[pIndex] = 2.;
    } else if(pheromone == 1.){
      vant.dir += 0.25;
      pheremones[pIndex] = 2.;
    } else if(pheromone == 3.){
      vant.dir += -0.25;
      pheremones[pIndex] = 2.;
    }
  }
  
  //flag = 2 is blue, set to 3
  else if(vant.flag == 2.){
    //claim spot
    if(pheromone == 0.){
      pheremones[pIndex] = 3.;
    } else if(pheromone == 1.){
      pheremones[pIndex] = 0.;
    } else if(pheromone == 2.){
      pheremones[pIndex] = 0.;
    } else if(pheromone == 3.){
      vant.dir += 0.25;
      pheremones[pIndex] = 0.;
    }
  }

  // calculate direction based on vant heading
  let dir = vec2f( sin( vant.dir * pi2 ), cos( vant.dir * pi2 ) );
  
  vant.pos = round( vant.pos + dir ); 

  vants[ cell.x ] = vant;
  
  // we'll look at the render buffer in the fragment shader
  // if we see a value of one a vant is there and we can color
  // it accordingly. in our JavaScript we clear the buffer on every
  // frame.
  render[ pIndex ] = vant.flag + 1.;
}`
 
const NUM_PROPERTIES = 4 // must be evenly divisble by 4!
const pheromones   = new Float32Array( W*H ) // hold pheromone data
const vants_render = new Float32Array( W*H ) // hold info to help draw vants
const vants        = new Float32Array( NUM_AGENTS * NUM_PROPERTIES ) // hold vant info

const offset = .5 - STARTING_AREA / 2
for( let i = 0; i < NUM_AGENTS * NUM_PROPERTIES; i+= NUM_PROPERTIES ) {
  vants[ i ]   = Math.floor( (offset+Math.random()*STARTING_AREA) * W ) // x
  vants[ i+1 ] = Math.floor( (offset+Math.random()*STARTING_AREA) * H ) // y
  vants[ i+2 ] = 0 // direction 
  vants[ i+3 ] = Math.floor( Math.random() * 3. ) // vant behavior type 
}

const sg = await seagulls.init()
const pheromones_b = sg.buffer( pheromones )
const vants_b  = sg.buffer( vants )
const render_b = sg.buffer( vants_render )

let frame = 0;
const frame_u = sg.uniform(frame)

const render = await sg.render({
  shader: render_shader,
  data:[
    pheromones_b,
    render_b,
    frame_u
  ],
})

const compute = sg.compute({
  shader: compute_shader,
  data:[
    vants_b,
    pheromones_b,
    render_b,
    frame_u
  ],
  onframe() { render_b.clear(); frame_u.value++; },
  dispatchCount:DISPATCH_COUNT
})

sg.run( compute, render )