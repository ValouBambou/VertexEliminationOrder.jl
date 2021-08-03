# unit test order_tree!
G = SimpleGraph{Int64}()
for i in 1:9 add_vertex!(G) end
add_edge!(G, 1, 2)
add_edge!(G, 1, 3)
add_edge!(G, 1, 4)
add_edge!(G, 3, 7)
add_edge!(G, 2, 5)
add_edge!(G, 2, 6)
add_edge!(G, 5, 8)
add_edge!(G, 5, 9)
ENV["JULIA_DEBUG"]=VertexEliminationOrder
nodes = [j for j in 1:9]
@info "testing tree_order!"
@test tree_order!(G, nodes) == [9, 8, 7, 6, 4, 5, 3, 2, 1]


for i in 1:12 add_vertex!(G) end
# 1 to 5 is a clique
for i in 1:5
    for j in (i+1):5
        add_edge!(G, i, j)
    end
end
# 6 and 7 are midlle nodes
add_edge!(G, 5, 6)
add_edge!(G, 6, 7)
add_edge!(G, 6, 8)
# 8 to 12 is a tree
add_edge!(G, 8, 9)
add_edge!(G, 8, 10)
add_edge!(G, 9, 11)
add_edge!(G, 9, 12)

@info "Testing nested_dissection with custom graph"
res = nested_dissection(G)
@info res
# 6 should be separator
@test res[1][12] == 6
@test res[2] == 4
