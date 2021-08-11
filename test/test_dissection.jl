using VertexEliminationOrder
using Test
using LightGraphs

ENV["JULIA_DEBUG"]=VertexEliminationOrder

using LightGraphs
using Test
using VertexEliminationOrder

G = SimpleGraph{Int64}(12)
# 1 to 5 is a clique
for i in 1:5
    for j in (i+1):5
        add_edge!(G, i, j)
    end
end
# 6 and 7 are midle nodes
add_edge!(G, 5, 6)
add_edge!(G, 6, 7)
add_edge!(G, 6, 8)
# 8 to 12 is a tree
add_edge!(G, 8, 9)
add_edge!(G, 8, 10)
add_edge!(G, 9, 11)
add_edge!(G, 9, 12)

@info "Testing iterative_dissection with custom graph"
res = iterative_dissection(G)
@info res
# 6 should be separator but t seems that it depends on the random s and t
@test res[2] >= 4 # 4 is the tw but it returns an upper bound
