"""
    forward_grow!(set, g, flow_matrix, capacity_matrix, reverse)
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
function forward_grow!(
		set::BitVector,
		g::SimpleGraph,
		flow_matrix::Array{Int64, 2},
		capacity_matrix, reverse::Bool=false)
    # in case of backward growing we swap the flow
    if reverse
        flow_matrix = -1 .* flow_matrix
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

function augment_flow!(flow_matrix, capacity_matrix, g, source::Int64, target::Int64)
	# first find an augmented path from source to target with a DFS
	stack = Stack{Int64}()
	visited = falses(nv(g))
	push!(stack, source)
	visited[source] = true
	prevs = Array{Int64, 1}(undef, nv(g))
	cur = source
	while cur != target
		cur = pop!(stack)
		push!(path, cur)
		for nei in neighbors(g, cur)
			if !visited[nei] && flow_matrix[cur, nei] < capacity_matrix[cur, nei]
                visited[nei] = true
                push!(stack, nei)
				prevs[nei] = cur
            end
		end
	end
	path = [target]
	while cur != source
		cur = prevs[cur]
		push!(path, cur)
	end
	reverse!(path)
end


function flowcutter!(g::SimpleGraph, source::Int64, target::Int64)
	add_vertex!(g)
	add_vertex!(g)

	n = nv(g)

	super_s = nv(g) - 1
	super_t = nv(g)

    flow_matrix = zeros(n, n)
	capacity_matrix = SparseMatrixCSC{Int64, Int64}(adjacency_matrix(g))
	capacity_matrix[super_s, s] = Inf
	capacity_matrix[t, super_t] = Inf

	S = falses(n); S[[super_s, s]] .= 1
	T = falses(n); T[[super_t, t]] .= 1

	S_reachable = copy(S)
	T_reachable = copy(T)

	cuts::Vector{Vector{Pair{Int64, Int64}}} = []

	while (!any(S .& T)) || (sum(S .| T) >= n)
		if any(S_reachable .& T_reachable)
			augment_flow!(flow_matrix, capacity_matrix, g, super_s, super_t)
			S_reachable = copy(S)
			T_reachable = copy(T)
			forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
			forward_grow!(T_reachable, g, flow_matrix, capacity_matrix, reverse=true)
		else
			if sum(S_reachable) <= sum(T_reachable)
				forward_grow!(S, g, flow_matrix, capacity_matrix)
				# output source side cut edges
				cut = filter(
					e ->
						(S_reachable[e.src] && T_reachable[e.dest])
					 	||
						(S_reachable[e.dest] && T_reachable[e.src]),
					edges(g)
				)
				push!(cuts, cut)

				x = get_piercing_node()
				S[x] = 1
				add_edge!(g, super_s, x)
				capacity_matrix[super_s, x] = Inf
				S_reachable[x] = 1

				forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
			else
				forward_grow!(T, g, flow_matrix, capacity_matrix, reverse=true)
				# output source side cut edges
				cut = filter(
					e ->
						(S_reachable[e.src] && T_reachable[e.dest])
					 	||
						(S_reachable[e.dest] && T_reachable[e.src]),
					edges(g)
				)
				push!(cuts, cut)

				x = get_piercing_node()
				T[x] = 1
				add_edge!(g, x, super_t)
				capacity_matrix[x, super_t] = Inf
				T_reachable[x] = 1

				forward_grow!(T_reachable, g, flow_matrix, capacity_matrix, reverse=true)
			end
		end
	end
	return cuts
end
