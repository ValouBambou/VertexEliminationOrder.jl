G = smallgraph("house")
  @info "Testing minwidth with house graph"
  @test minwidth!(G) == ([1, 5, 4, 3, 2], 2)

  G = smallgraph("house")
  @info "Testing minwidth with house graph"
  @test minfill!(G) == ([5, 1, 4, 3, 2], 2)
