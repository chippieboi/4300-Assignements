// because gulls uses the await keyword, we have to wrap our
// code in an async function and call it. when we use js modules we
// don't have to do this, which is nice... but wrapping isn't that
// big of a deal.
async function run() {
  const sg = await gulls.init()

  // a simple vertex shader to make a quad
  const quadVertexShader = gulls.constants.vertex

  // our fragment shader, just returns blue
  const fragmentShader = `
  @fragment
  fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
    return vec4(0., 0., 1., 1. );
  }
  `

  // our vertex + fragment shader together
  const shader = quadVertexShader + fragmentShader

  // create a render pass
  const renderPass = await sg.render({ shader })

  // run our render pass
  sg.run( renderPass )
}

run()