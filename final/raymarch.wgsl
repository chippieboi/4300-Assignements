const MAX_DIST : f32 = 10.; 
const MIN_DIST : f32 = .01;
const MAX_STEPS: u32 = 20u;

@group(0) @binding(0) var<uniform> frame: f32;
@group(0) @binding(1) var<uniform> res:   vec2f;

fn scene( p:vec3f ) -> f32 {
  var pz = p;
  pz.z += frame / 200.f;
  pz.x += .25;
  var d = sub(sphere( repeat(pz, vec3f(.5)), .2), sphere(p,2.));
  d = min( d, plane( p, vec3f(0.,-1.,0.),1. ) );

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

fn calcNormal( p:vec3f ) -> vec3f {
    const h:f32 = 0.0001; // replace by an appropriate value
    const k:vec2f = vec2(1.,-1.);
    return normalize( k.xyy*scene( p + k.xyy*h ) + 
                      k.yyx*scene( p + k.yyx*h ) + 
                      k.yxy*scene( p + k.yxy*h ) + 
                      k.xxx*scene( p + k.xxx*h ) );
}

fn raymarch(rayorigin : vec3f, raydirection: vec3f ) -> f32 {
  var totaldistance = 0.0;
  var color = vec3(0.0);

  for(var i:u32 = 0; i < MAX_STEPS; i++) {
    var p = rayorigin + raydirection * totaldistance;
    let nextdistance = scene(p);

    totaldistance += nextdistance;

    if(totaldistance > MAX_DIST || nextdistance < MIN_DIST ) {
      break;
    }
  }
  return totaldistance;
}


@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  var uv = pos.xy/res.xy;

	// make 0,0 the origin instead of .5,.5
  uv -= 0.5;
  // correct aspect ratio
  uv.x *= res.x / res.y;

  // ray origin aka camera position
  let ro = vec3f(0.0, 0.0, 5.0);
  // ray direction through the window into the scene
  let rd = normalize(vec3(uv, -.5));
  // get distance to surface intersection with ray
  let dst = raymarch( ro, rd );
  
  // location of intersection = 
  // camera position + ray direction * distance
  let p = ro + rd * dst;

	// default color / bg
  var bgcolor = vec3f(.0,0.,0.);
  var color = vec3f(0.,0.,0.);

  // color pixel if intersection is within tolerance
  if( dst < MAX_DIST ) {
    let nor = calcNormal(p);
    let lightposition = vec3f(2,-2,2);
		let dir = normalize( lightposition - p );
		let lightStrength = clamp( dot(nor,dir),0.,1.);
    color = vec3f( lightStrength );
    let fogAmount = .2;
    let fog = 1. - exp( -dst * fogAmount );
    let fogcolor = bgcolor * fog;
    color = mix( color, fogcolor, fog );
  }else{
    color = bgcolor;
  }

  return vec4f( color, 1. );
}