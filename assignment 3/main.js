import { Pane } from 'https://cdn.jsdelivr.net/npm/tweakpane@4.0.5/dist/tweakpane.min.js'


function resetState(state, width, height) {
  for( let i = 0; i < width * height; i++ ) {
  state[ i * 2 ] = 1.0
  state[ i * 2 + 1 ] = 0.0

  const x = i % width
  const y = Math.floor( i / width )
  
    if (Math.abs(x - width / 2) < 150 && Math.abs(y - height / 2) < 100) {
      state[ i * 2 + 1] = 1.0
    }
  }
}


async function go() {

const sg      = await gulls.init(),
      frag    = await gulls.import( './frag.wgsl' ),
      compute = await gulls.import( './compute.wgsl' ),
      render  = gulls.constants.vertex + frag,
      size    = (window.innerWidth * window.innerHeight),
      state   = new Float32Array( size * 2 )

resetState(state, window.innerWidth, window.innerHeight)

// for (let i = 0; i < size; i++) {
//   state[i] = Math.round(Math.random())
// }

let statebuffer1 = sg.buffer( state )
let statebuffer2 = sg.buffer( state )
const res = sg.uniform([ window.innerWidth, window.innerHeight ])

//tweakpane stuff
const pane = new Pane()

const da = sg.uniform(1.0)
const db = sg.uniform(0.5)
const f = sg.uniform(0.02)
const k = sg.uniform(0.38)

pane.addBinding( da, 'value', { min: 0.0, max: 1.0, step: 0.01, label: 'Da' } )
pane.addBinding( db, 'value', { min: 0.0, max: 1.0, step: 0.01, label: 'Db' } )
pane.addBinding( f, 'value', { min: 0.0, max: 0.1, step: 0.001, label: 'F' } )
pane.addBinding( k, 'value', { min: 0.0, max: 1.0, step: 0.01, label: 'K' } )

pane.addButton({ title: 'Reset' }).on('click', () => {
  resetState(state, window.innerWidth, window.innerHeight)

  //statebuffer1.clear()
  //statebuffer2.clear()

  statebuffer1.write(state)
  statebuffer2.write(state)
})

const renderPass = await sg.render({
  shader: render,
  data: [
    res,
    sg.pingpong( statebuffer1, statebuffer2 )
  ]
})

const computePass = sg.compute({
  shader: compute,
  data: [ res, sg.pingpong( statebuffer1, statebuffer2 ), da, db, f, k ],
  dispatchCount:  [Math.round(gulls.width / 8), Math.round(gulls.height/8), 1],
  times: 1,
})

sg.run( computePass, renderPass )

}

window.onload=go