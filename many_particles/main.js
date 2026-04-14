import { default as gulls } from './gulls.js'

//VIDEO: https://www.bing.com/videos/riverview/relatedvideo?q=minecraft+rain&&mid=1F6383C405E0454EF2D91F6383C405E0454EF2D9&churl=https%3a%2f%2fwww.youtube.com%2fchannel%2fUCL1dpFs5mBGAH0NcYtaOTXw&mcid=E778BA273D704BEAB6B279C694952050&FORM=VRDGAR

const sg = await gulls.init(),
      render_shader  = await gulls.import( './render.wgsl' ),
      compute_shader = await gulls.import( './compute.wgsl' )

const NUM_PARTICLES = 1024, 
      NUM_PROPERTIES = 4, 
      state = new Float32Array( NUM_PARTICLES * NUM_PROPERTIES )

for( let i = 0; i < NUM_PARTICLES * NUM_PROPERTIES; i+= NUM_PROPERTIES ) {
  state[ i ] = -2 + Math.random() * 4
  state[ i + 1 ] = -1 + Math.random() * 2
  state[ i + 2 ] = 0
  state[ i + 3 ] = Math.random() * -10
}

const state_b = sg.buffer( state ),
      frame_u = sg.uniform( 0 ),
      res_u   = sg.uniform([ sg.width, sg.height ]) 

const slider = document.querySelector('#slider')
let slider_u = sg.uniform(slider.value)

const render = await sg.render({
  shader: render_shader,
  data: [
    frame_u,
    res_u,
    state_b,
    slider_u
  ],
  onframe() { frame_u.value++ },
  count: NUM_PARTICLES,
  blend: true
})



const dc = Math.ceil( NUM_PARTICLES / 64 )

const compute = sg.compute({
  shader: compute_shader,
  data:[
    res_u,
    state_b,
    slider_u
  ],
  dispatchCount: [ dc, dc, 1 ] 

})

slider.oninput = ()=> slider_u.value = slider.value

sg.run( compute, render )
