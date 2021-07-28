G = smallgraph("house")
ENV["JULIA_DEBUG"]=VertexEliminationOrder

@info "Testing nested_dissection with house graph"
nested_dissection(G)
