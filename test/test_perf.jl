using LightGraphs
using VertexEliminationOrder
using Test
using ProfileView


# The file to read the graph from.
graph_file = "test/example_graphs/sycamore_53_20.gr"

ENV["JULIA_DEBUG"]=VertexEliminationOrder
g = smallgraph("house")
iterative_dissection(g)
g = graph_from_gr(graph_file)

@info "running wrapper function for 30s"
ProfileView.@profview sample_iterative_dissections(g, 30)