using LightGraphs

"""
    eliminate!(g::SimpleGraph{Int64}, v::Int64, labels)::Nothing
Connect neighbors of v (in graph g) together if they are not already connected, delete v
and update the labels array. Labels is pop and element v updated.

# Arguments
- `g::SimpleGraph{Int64}` the graph to consider.
- `v::Int64` the vertex to eliminate.
- `labels::Vector{Int64}` labels to keep track of nodes id in original graph before elimination.

# Return
- Nothing.
"""
function eliminate!(g::SimpleGraph{Int64}, v::Int64, labels::Vector{Int64})::Nothing
    ns = neighbors(g, v)
    len = length(ns)
    for i = 1:(len-1)
        for j = (i+1):len
            add_edge!(g, ns[i], ns[j])
        end
    end
    rem_vertex!(g, v)
    labels[v] = labels[end]
    pop!(labels)
    nothing
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
    labels = collect(1:n)
    for rm_origin_id in order
        toremove = findfirst(id -> id == rm_origin_id, labels)
        treewidth = max(treewidth, degree(g, toremove))
        eliminate!(g, toremove, labels)
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
    order = zeros(Int64, n)
    leafs = filter(node -> length(neighbors(graph, node)) == 1, 1:n)

    # trick to get the last node
    lastnode = sum(nodes)
    while eliminated < n
        parents = unique(map(it -> neighbors(graph, it)[1], leafs))
        for rm in leafs
            order[eliminated] = nodes[rm]
            lastnode -= nodes[rm]
            if ne(graph) != 0
                rem_edge!(graph, rm, neighbors(graph, rm)[1])
            end
            eliminated += 1
        end
        # new leafs are parents with 1 neighbors
        leafs = filter(
            node -> length(neighbors(graph, node)) == 1,
            parents
        )
    end
    # fix last node have no neighbor because all edges are deleted
    if order[n] == 0
        order[n] = lastnode
    end
    @debug "tree_order! return : $order"
    return order
end
