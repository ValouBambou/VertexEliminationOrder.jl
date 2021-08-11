using LightGraphs
using VertexEliminationOrder
using Test


# The file to read the graph from.
graph_file = "test/example_graphs/sycamore_53_20.gr"

ENV["JULIA_DEBUG"]=VertexEliminationOrder


g = graph_from_gr(graph_file)
res = iterative_dissection(g)
@test res[1] == unique(res[1])
@test res[2] == 57
