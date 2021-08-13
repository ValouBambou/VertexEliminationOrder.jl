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
res = iterative_dissection(g)
@info res[2]
res_expected = treewidth_by_elimination!(g, res[1])
@info res_expected
@test res[2] >= res_expected
