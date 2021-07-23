"""
    forward_grow!(set, g, flow_matrix, capacity_matrix, reverse)
Start a breadth first search in a graph g from nodes in set following only non
satured arcs. This function update the set and add to it every nodes that can be
reached from the nodes in set. Can be reverse to find the nodes which can reach
those in the set.

# Arguments
- `set::BitVector` the set of nodes to consider.
- `g::SimpleGraph` the graph to explore.
- `capacity_matrix::SparseMatrixCSC{Int64, Int64}` capacities of arcs.
- `flow_matrix::Array{Int64, 2}` current flow of arcs.
- `reverse::Bool` if true it does backward growing.

# Return
- `nothing` (only set is modified)
"""
function forward_grow!(set::BitVector,
					   g::SimpleGraph,
					   flow_matrix::Array{Int64, 2},
					   capacity_matrix::SparseMatrixCSC{Int64, Int64},
					   reverse::Bool=false)::Nothing
    # in case of backward growing we swap the flow
    if reverse
        flow_matrix = -1 .* flow_matrix
    end
    # init the breadth first search algorithm
    q = Queue{Int64}()
    enqueue!.([q], findall(x -> x > 0, set))
    set .= false
    while !isempty(q)
		@debug q
        cur = dequeue!(q)
        set[cur] = true
        for nei in neighbors(g, cur)
            if !set[nei] && flow_matrix[cur, nei] == 0 && capacity_matrix[cur, nei] == 1
                set[nei] = true
                enqueue!(q, nei)
            end
        end
    end
    nothing
end

"""
	augment_flow!(flow_matrix, capacity_matrix, g, source, target)
Find an augmenting path and augment the flow of 1 unit along it. The flow_matrix
is modified for every arc (u,v) in the path it does flow_matrix[u, v] += 1 and
flow_matrix[v,u] += -1.

# Arguments
-`flow_matrix::Array{Int64, 2}` the value of the current flow which may be modified.
-`capacity_matrix::SparseMatrixCSC{Int64, Int64}` the value of the arcs capacities.
-`g::SimpleGraph` the graph to consider.
-`source::Int64` index of the source node.
-`target::Int64` index of the target node.

# Return
- `augment::Int64` the augmentation of the flow so 1 if path is found, 0 otherwise.
"""
function augment_flow!(flow_matrix::Array{Int64, 2},
					   capacity_matrix::SparseMatrixCSC{Int64, Int64},
					   g::SimpleGraph,
					   source::Int64,
					   target::Int64)::Int64
	# first find an augmented path from source to target with a DFS
	stack = Stack{Int64}()
	visited = falses(nv(g))
	push!(stack, source)
	visited[source] = true
	prevs = Array{Int64, 1}(undef, nv(g))
	cur = source
	while (cur != target) && (!isempty(stack))
		cur = pop!(stack)
		for nei in neighbors(g, cur)
			if !visited[nei] && flow_matrix[cur, nei] < capacity_matrix[cur, nei]
                visited[nei] = true
                push!(stack, nei)
				prevs[nei] = cur
            end
		end
	end

	return if cur == target
		# augmenting path exists so augment flow along it
		while cur != source
			next = cur
			cur = prevs[cur]
			flow_matrix[cur, next] += 1
			flow_matrix[next, cur] += -1
		end
		1
	else
		0
	end
end


"""
	piercing_node(g, sources, targets, SR, TR)
Compute which node will become a new source or target to balance the current cut.
"""
function piercing_node(cut::Vector{Pair{Int64, Int64}},
					   to_increase::BitVector,
					   to_avoid::BitVector,
					   increase_node::Int64,
					   avoid_node::Int64,
					   dist::Array{Int64, 2})::Int64
	# first heuristic
	best_nodes = findall(.~(to_increase .| to_avoid))
	nodes = map(arc -> to_increase[arc.first] ? arc.second : arc.first, cut)
	res = findfirst(p -> best_nodes[p], nodes)
	return if isnothing(res)
		# second heuristic
		nodes[findmax(
			map(
				p -> dist[p, avoid_node] - dist[increase_node, p],
				nodes
			)
		)[2]]
		else
			res
		end
end


"""
	flowcutter!(g, source, target)
Computes multiple cuts more and more balanced in a graph g. The graph g is modified
to limit the allocations (add super source and target for implementation purpose) so be aware and prepare a copy
or remove those extra vertices after using this function.

# Arguments
-`g::SimpleGraph` the graph to consider.
-`source::Int64` index of the source node.
-`target::Int64` index of the target node.

# Return
-`cuts::Vector{Vector{Pair{Int64, Int64}}}` all the cuts computed by flowcutter.
"""
function flowcutter!(g::SimpleGraph, source::Int64, target::Int64)
	add_vertex!(g)
	add_vertex!(g)

	n = nv(g)

	dist = floyd_warshall_shortest_paths(g).dists

	super_s = nv(g) - 1
	super_t = nv(g)

    flow_matrix = zeros(Int64, n, n)
	capacity_matrix = SparseMatrixCSC{Int64, Int64}(adjacency_matrix(g))
	capacity_matrix[super_s, source] = typemax(Int64)
	capacity_matrix[target, super_t] = typemax(Int64)

	S = falses(n); S[[super_s, source]] .= 1
	T = falses(n); T[[super_t, target]] .= 1

	S_reachable = copy(S)
	T_reachable = copy(T)

	cuts::Vector{Vector{Pair{Int64, Int64}}} = []

	while (!any(S .& T)) || (sum(S .| T) >= n)
		if any(S_reachable .& T_reachable)
			augment_flow!(flow_matrix, capacity_matrix, g, super_s, super_t)
			S_reachable = copy(S)
			T_reachable = copy(T)
			forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
			forward_grow!(T_reachable, g, flow_matrix, capacity_matrix, true)
		else
			cut::Vector{Pair{Int64, Int64}} = []
			if sum(S_reachable) <= sum(T_reachable)
				forward_grow!(S, g, flow_matrix, capacity_matrix)
				# output source side cut edges
				for e in edges(g)
					if S_reachable[e.src] ⊻ S_reachable[e.dst]
						push!(cut, e.src=>e.dst)
					end
				end
				push!(cuts, cut)

				x = piercing_node()
				S[x] = 1
				add_edge!(g, super_s, x)
				capacity_matrix[super_s, x] = Inf
				S_reachable[x] = 1

				forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
			else
				forward_grow!(T, g, flow_matrix, capacity_matrix, true)
				# output target side cut edges

				for e in edges(g)
					if T_reachable[e.src] ⊻ T_reachable[e.dst]
						push!(cut, e.src=>e.dst)
					end
				end
				push!(cuts, cut)

				x = piercing_node()
				T[x] = 1
				add_edge!(g, x, super_t)
				capacity_matrix[x, super_t] = Inf
				T_reachable[x] = 1

				forward_grow!(T_reachable, g, flow_matrix, capacity_matrix, true)
			end
		end
	end
	return cuts
end
