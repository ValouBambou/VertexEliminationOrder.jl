"""
    forward_growing!(set, g, flow_matrix, capacity_matrix, reverse)
Start a breadth first search in a graph g from nodes in set following only non
satured arcs. This function update the set and add to it every nodes that can be
reached from the nodes in set. Can be reverse to find the nodes which can reach
those in the set.

# Arguments
- `set::BitVector` the set of nodes to consider.
- `g::SimpleGraph` the graph to explore.
- `capacity_matrix::Array{Int64, 2}` capacities of arcs.
- `flow_matrix::Array{Int64, 2}` current flow of arcs.
- `reverse::Bool` if true it does backward growing.

# Return
- `nothing` (only set is modified)
"""
function forward_growing!(set, g, flow_matrix, capacity_matrix, reverse::Bool=false)
    # in case of backward growing we swap the flow
    if reverse
        flow_matrix .*= -1
    end
    # init the breadth first search algorithm
    q = Queue{Int64}()
    enqueue!.([q], findall(x -> x > 0, set))
    set .= false
    while !isempty(q)
        cur = dequeue!(q)
        set[cur] = true
        for nei in neighbors(g, cur)
            if !set[nei] && flow_matrix[cur, nei] < capacity_matrix[cur, nei]
                set[nei] = true
                enqueue!(q, nei)
            end
        end
    end
    nothing
end


function flowcutter(g::SimpleGraph, s::Int64, t::Int64)
	n = nv(g)
    flow_matrix = zeros(n, n)
	capacity_matrix = SparseMatrixCSC{AbstractFloat, Int64}(adjacency_matrix(g))
	S = falses(n); S[s] = 1
	T = falses(n); T[t] = 1

	S_reachable = copy(S)
	T_reachable = copy(T)

	while !any(S .& T)
		if any(S_reachable .& T_reachable)
			body
		else
			body2
		end
	end
end
