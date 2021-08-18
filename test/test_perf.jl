using LightGraphs
using Test
using Pkg

Pkg.activate(".")
using VertexEliminationOrder


# The file to read the graph from.
graph_file = "test/example_graphs/sycamore_53_20.gr"

ENV["JULIA_DEBUG"]=VertexEliminationOrder
g = smallgraph("house")
iterative_dissection(g)

g = graph_from_gr(graph_file)
@time iterative_dissection(g)
