# test augment_flow!
G = smallgraph("house")
n = nv(G)
cap = SparseMatrixCSC{Int64, Int64}(adjacency_matrix(G))
flow = zeros(Int64, n, n)
expected_flow = zeros(Int64, n, n)
expected_flow[5, 4] = 1
expected_flow[4, 5] = -1
expected_flow[4, 2] = 1
expected_flow[2, 4] = -1
expected_flow[2, 1] = 1
expected_flow[1, 2] = -1
@info "Testing augment_flow! with house graph"
@test augment_flow!(flow, cap, G, 5, 1) == 1
@test flow == expected_flow
expected_flow[5, 3] = 1
expected_flow[3, 5] = -1
expected_flow[3, 1] = 1
expected_flow[1, 3] = -1
@test augment_flow!(flow, cap, G, 5, 1) == 1
@test flow == expected_flow
# no more augmenting path available
@test augment_flow!(flow, cap, G, 5, 1) == 0

# undo the last flow augmentation
flow[5, 3] = 0
flow[3, 5] = 0
flow[3, 1] = 0
flow[1, 3] = 0

# test forward growing
SR = falses(5); SR[5] = true
expected_SR = falses(5); expected_SR[[1, 3, 4, 5]] .= true
forward_grow!(SR, G, flow, cap)
@test SR == expected_SR

# test backward growing
TR = falses(5); TR[1] = true
expected_TR = falses(5); expected_TR[[1, 3, 4, 5]] .= true
@info "Testing forward_grow! (backward) with house graph"
forward_grow!(TR, G, flow, cap)
@test TR == expected_TR

# test piercing_node
dist = floyd_warshall_shortest_paths(G).dists
cut = [4=>2, 4=>3, 5=>3]
SR=falses(5); SR[[4, 5]] .= true
TR=falses(5); SR[[1, 3]] .= true
@info "Testing piercing_node with house graph"
@test piercing_node(cut, SR, TR, 5, 1, dist) == 2

#test flowcutter
@info flowcutter!(G, 5, 1, dist)
