G = smallgraph("house")
n = nv(G)
cap = SparseMatrixCSC{Int64, Int64}(adjacency_matrix(G))
flow = zeros(Int64, n, n)
@info "Testing augment_flow! with house graph"
@test augment_flow!(flow, cap, G, 5, 1) == 1
expected_flow = zeros(Int64, n, n)
expected_flow[5, 4] = 1
expected_flow[4, 5] = -1
expected_flow[4, 2] = 1
expected_flow[2, 4] = -1
expected_flow[2, 1] = 1
expected_flow[1, 2] = -1
@test flow == expected_flow
@test augment_flow!(flow, cap, G, 5, 1) == 1
expected_flow[5, 3] = 1
expected_flow[3, 5] = -1
expected_flow[3, 1] = 1
expected_flow[1, 3] = -1
@test flow == expected_flow
@test augment_flow!(flow, cap, G, 5, 1) == 0
