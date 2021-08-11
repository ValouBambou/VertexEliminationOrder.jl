@with_kw struct Cut
    arcs::Vector{Pair{Int64,Int64}}
    imbalance::Float64
    expansion::Float64
    size::Int64 = length(arcs)
end


"""
    forward_grow!(set, g, flow_matrix, capacity_matrix, reverse)
Start a breadth first search in a graph g from nodes in set following only non
satured arcs. This function update the set and add to it every nodes that can be
reached from the nodes in set. In the context of undirected graphs this is the same
as backward growing.

# Arguments
- `set::BitVector` the set of nodes to consider.
- `g::SimpleGraph` the graph to explore.
- `capacity_matrix::SparseMatrixCSC{Int64, Int64}` capacities of arcs.
- `flow_matrix::Array{Int64, 2}` current flow of arcs.

# Return
- `nothing` (only set is modified)
"""
function forward_grow!(
    set::BitVector,
    g::SimpleGraph,
    flow_matrix::Array{Int64,2},
    capacity_matrix::SparseMatrixCSC{Int64,Int64},
)::Nothing
    # init the breadth first search algorithm
    q = Queue{Int64}()
    enqueue!.([q], findall(x -> x > 0, set))
    set .= false
    while !isempty(q)
        cur = dequeue!(q)
        set[cur] = true
        for nei in neighbors(g, cur)
            if !set[nei] &&
               abs(flow_matrix[cur, nei]) < capacity_matrix[cur, nei]
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
function augment_flow!(
    flow_matrix::Array{Int64,2},
    capacity_matrix::SparseMatrixCSC{Int64,Int64},
    g::SimpleGraph,
    source::Int64,
    target::Int64,
)::Int64
    # first find an augmented path from source to target with a DFS
    stack = Stack{Int64}()
    visited = falses(nv(g))
    push!(stack, source)
    visited[source] = true
    prevs = Array{Int64,1}(undef, nv(g))
    cur = source
    while (cur != target) && (!isempty(stack))
        cur = pop!(stack)
        for nei in neighbors(g, cur)
            if !visited[nei] &&
               abs(flow_matrix[cur, nei]) < capacity_matrix[cur, nei]
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
	piercing_node(cut, to_increase, to_avoid, increase_node, avoid_node, dist)
Compute which node will become a new source or target to balance the current cut.

# Arguments
-`cut::Vector{Pair{Int64, Int64}}` the current cut set of edges.
-`to_increase::BitVector` the side of the cut to increase.
-`to_avoid::BitVector` the side to the cut to not increase.
-`increase_node::Int64` the original source or target of to_increase.
-`avoid_node::Int64` the original source or target of to_avoid.
-`dist::Array{Int64, 2}` a matrix of distances (shortest path 1 per edge) between all nodes of the graph.

# Return
-`node::Int64` the new piercing node to balance the cut.
"""
function piercing_node(
    cut::Vector{Pair{Int64,Int64}},
    to_increase::BitVector,
    to_avoid::BitVector,
    increase_node::Int64,
    avoid_node::Int64,
    dist::Array{Int64,2},
)::Int64
    # first heuristic
    best_nodes = .~(to_increase .| to_avoid)
    nodes = map(arc -> to_increase[arc.first] ? arc.second : arc.first, cut)
    res = findfirst(p -> best_nodes[p], nodes)
    if isnothing(res)
        # second heuristic
        res = findmax(map(p -> dist[p, avoid_node] - dist[increase_node, p], nodes))[2]
    end
    return nodes[res]
end


"""
	flowcutter!(g, source, target, dist)
Computes multiple cuts more and more balanced in a graph g. Need super target and
sources created before.

# Arguments
-`g::SimpleGraph` the graph to consider.
-`source::Int64` index of the source node.
-`target::Int64` index of the target node.
-`dist::Matrix{Int64}` matrix of distance between all nodes in graph (weight=1).

# Return
-`cuts::Vector{Cut}` all the cuts computed by flowcutter.
"""
function flowcutter!(
    g::SimpleGraph,
    source::Int64,
    target::Int64,
    dist::Matrix{Int64},
)::Vector{Cut}

    n = nv(g)

    super_s = n - 1
    super_t = n

    add_edge!(g, super_s, source)
    add_edge!(g, target, super_t)


    flow_matrix = zeros(Int64, n, n)
    capacity_matrix = SparseMatrixCSC{Int64,Int64}(adjacency_matrix(g))
    capacity_matrix[super_s, source] = typemax(Int64)
    capacity_matrix[target, super_t] = typemax(Int64)

    S = falses(n)
    S[[super_s, source]] .= 1
    T = falses(n)
    T[[super_t, target]] .= 1

    S_reachable = copy(S)
    T_reachable = copy(T)

    cuts::Vector{Cut} = []

    forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
    forward_grow!(T_reachable, g, flow_matrix, capacity_matrix)

    while (!any(S .& T)) && (sum(S .| T) < n)
        if any(S_reachable .& T_reachable)
            augment_flow!(flow_matrix, capacity_matrix, g, super_s, super_t)
            S_reachable = copy(S)
            T_reachable = copy(T)
            forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
            forward_grow!(T_reachable, g, flow_matrix, capacity_matrix)
        else
            cut_arcs::Vector{Pair{Int64,Int64}} = []
            if sum(S_reachable) <= sum(T_reachable)
                forward_grow!(S, g, flow_matrix, capacity_matrix)
                # output source side cut edges
                for e in edges(g)
                    if S_reachable[e.src] ⊻ S_reachable[e.dst]
                        push!(cut_arcs, e.src => e.dst)
                    end
                end
                push!(
                    cuts,
                    Cut(
                        arcs = cut_arcs,
                        imbalance = 2 * (n - sum(S_reachable) - 1) / (n - 2) - 1,
                        expansion = length(cut_arcs) / (sum(S_reachable) - 1)
                    ),
                )

                x = piercing_node(
                    cut_arcs,
                    S_reachable,
                    T_reachable,
                    source,
                    target,
                    dist,
                )
                S[x] = 1
                S_reachable[x] = 1
                add_edge!(g, super_s, x)
                capacity_matrix[super_s, x] = typemax(Int64)

                forward_grow!(S_reachable, g, flow_matrix, capacity_matrix)
            else
                forward_grow!(T, g, flow_matrix, capacity_matrix)
                # output target side cut edges

                for e in edges(g)
                    if T_reachable[e.src] ⊻ T_reachable[e.dst]
                        push!(cut_arcs, e.src => e.dst)
                    end
                end
                push!(
                    cuts,
                    Cut(
                        arcs = cut_arcs,
                        imbalance =  2 * (n - sum(T_reachable) - 1) / (n - 2) - 1,
                        expansion = length(cut_arcs) / (sum(T_reachable) - 1)
                    )
                )

                x = piercing_node(
                    cut_arcs,
                    T_reachable,
                    S_reachable,
                    target,
                    source,
                    dist,
                )
                T[x] = 1
                T_reachable[x] = 1
                add_edge!(g, x, super_t)
                capacity_matrix[x, super_t] = typemax(Int64)

                forward_grow!(
                    T_reachable,
                    g,
                    flow_matrix,
                    capacity_matrix,
                )
            end
        end
    end
    return cuts
end
