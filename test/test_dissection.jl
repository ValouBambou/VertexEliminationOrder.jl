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


G = smallgraph("house")

@info "Testing nested_dissection with house graph"
@info nested_dissection(G)
