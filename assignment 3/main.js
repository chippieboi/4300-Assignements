async function go() {

const sg      = await gulls.init(),
      frag    = await gulls.import( './frag.wgsl' ),
      compute = await gulls.import( './compute.wgsl' ),
      render  = gulls.constants.vertex + frag,
      size    = (window.innerWidth * window.innerHeight),
      state   = new Float32Array( size )

for( let i = 0; i < size; i++ ) {
  state[ i ] = Math.round( Math.random() )
}

const statebuffer1 = sg.buffer( state )
const statebuffer2 = sg.buffer( state )
const res = sg.uniform([ window.innerWidth, window.innerHeight ])

const renderPass = await sg.render({
  shader: render,
  data: [
    res,
    sg.pingpong( statebuffer1, statebuffer2 )
  ]
})

const computePass = sg.compute({
  shader: compute,
  data: [ res, sg.pingpong( statebuffer1, statebuffer2 ) ],
  dispatchCount:  [Math.round(gulls.width / 8), Math.round(gulls.height/8), 1],
})

sg.run( computePass, renderPass )

}

window.onload=go