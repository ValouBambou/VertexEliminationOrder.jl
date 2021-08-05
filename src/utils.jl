using LightGraphs

"""
    connect_neighbors!(g, v)
Connect neighbors of v (in graph g) together if they are not already connected.

# Arguments
- `g::SimpleGraph{Int64}` the graph to consider.
- `v::Int64` the vertex to make simplicial.

# Return
- `change::Bool` true if edge is created false otherwise.
"""
function connect_neighbors!(g::SimpleGraph{Int64}, v::Int64)::Bool
    ns = neighbors(g, v)
    len = length(ns)
    change = false
    for i = 1:(len-1)
        for j = (i+1):len
            if !has_edge(g, ns[i], ns[j])
                add_edge!(g, ns[i], ns[j])
                change = true
            end
        end
    end
    return change
end

"""
    treewidth_by_elimination!(g::SimpleGraph{Int64}, order::Vector{Int64})
Computes the treewidth by eliminating in order vertices of the graph and keep track of the max degree.

# Arguments
- `g::SimpleGraph{Int64}` the graph to consider.
- `order::Vector{Int64}` the vertex elimination order to perform.

# Return
- `treewidth::Int64` the max degree of vertices during elimination.
"""
function treewidth_by_elimination!(g::SimpleGraph{Int64}, order::Vector{Int64})::Int64
    treewidth = 0
    n = nv(g)
    indices = collect(1:n)
    for i in 1:n
        max_index = n + 1 - i
        toremove = order[i]
        index_rm = indices[toremove]
        indices[max_index] = index_rm

        
        treewidth = max(treewidth, degree(g, index_rm))

        connect_neighbors!(g, index_rm)
        rem_vertex!(g, index_rm)
    end
    return treewidth
end


"""
    tree_order!(graph, nodes)
Computes the optimal elimination order for nodes in a tree. Graph is modified, all its edges are deleted.

# Arguments
- `graph::SimpleGraph{Int64}` the subtree to consider.
- `nodes::Vector{Int64}` indices of nodes in the root greaph.

# Return
- `order::Vector{Int64}` vertex elimination order (indices in the root graph) to get treewidth of 1 in the subtree.
"""
function tree_order!(graph::SimpleGraph{Int64}, nodes::Vector{Int64})::Vector{Int64}
    @debug "tree_order! args : graph = $graph, nodes = $nodes"
    n = length(nodes)
    eliminated = 1
    original_to_cur_indices = collect(1:n) # convert old index to current index in graph
    order = zeros(Int64, n)
    leafs = filter(node -> length(neighbors(graph, node)) == 1, 1:n) # always contains numbers in 1:n
    max_index = n

    while nv(graph) > 1
        parents = unique(map(it -> neighbors(graph, original_to_cur_indices[it])[1], leafs))
        nnodes = nv(graph)
        nleafs = length(leafs)
        for rm in leafs # rm is always in 1:n
            order[eliminated] = nodes[rm] # fill order with root graph nodes id
            # index badness to keep track of correct nodes
            index_rm = original_to_cur_indices[rm]
            original_to_cur_indices[max_index] = index_rm

            rem_vertex!(graph, index_rm)
            eliminated += 1
            max_index -= 1
        end
        # new leafs are parents with 1 neighbors
        leafs = filter(
            node -> length(neighbors(graph, original_to_cur_indices[node])) == 1,
            parents
        )
    end
    println("mdr")
    if nv(graph) == 1
        # rem last vertex (which has no neighbors)
        order[n] = nodes[old_indices[1]]
        rem_vertex!(graph, 1)
    end
    @debug "tree_order! return : $order"
    return order
end
