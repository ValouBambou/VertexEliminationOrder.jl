using VertexEliminationOrder
using LightGraphs
using Test
using Random

G =  smallgraph("house")
@info "test treewidth of house"
@test treewidth_by_elimination!(G, collect(1:5)) == 2
@test nv(G) == 0

# tree
G = SimpleGraph{Int64}(5)
add_edge!(G, 1, 2)
add_edge!(G, 1, 3)
add_edge!(G, 3, 4)
add_edge!(G, 3, 5)
@info "test treewidth of tree"
@test treewidth_by_elimination!(G, [5, 4, 3, 2, 1]) == 1
@test nv(G) == 0

# complete graph
G = SimpleGraph{Int64}(100)
for i in 1:99
    for j in (i + 1):100
        add_edge!(G, i, j)
    end
end
@info "test treewidth of complete graph"
@test treewidth_by_elimination!(G, shuffle(collect(1:100))) == 99
@test nv(G) == 0

# unit test order_tree!
G = SimpleGraph{Int64}(10)
add_edge!(G, 1, 2)
add_edge!(G, 1, 3)
add_edge!(G, 3, 4)
add_edge!(G, 3, 5)
add_edge!(G, 4, 6)
add_edge!(G, 4, 7)
add_edge!(G, 7, 8)
add_edge!(G, 8, 9)
add_edge!(G, 8, 10)
nodes = [6, 7, 8, 9, 10, 11, 12, 23, 34, 45]
@info "testing tree_order!"
# we expect 7, 10, 11, 12, 34, 45 first (leafs) then 6, 9 then 8 (order in each block don't matter)
res = tree_order!(G, nodes)
print("lol $res")
@test  res == [7, 10, 11, 34, 45, 6, 23, 9, 12, 8]
# after this function G is empty
@test nv(G) == 0
