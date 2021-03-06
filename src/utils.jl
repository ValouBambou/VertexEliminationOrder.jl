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
    return order
end

"""
    graph_from_gr(filename::String)

Read a graph from the provided gr file.
"""
function graph_from_gr(filename::String)::SimpleGraph{Int64}
    lines = readlines(filename)

    # Create a Graph with the correct number of vertices.
    num_vertices, num_edges = parse.(Int, split(lines[1], ' ')[3:end])
    G = SimpleGraph(num_vertices)

    # Add an edge to the graph for every other line in the file.
    for line in lines[2:end]
        src, dst = parse.(Int, split(line, ' '))
        add_edge!(G, src, dst)
    end

    G
end

"""
    square_lattice_graph(n::Int64)
Return a square lattice graph of dimension n. The dimension means
a big square made of n x n squares so (n+1)?? nodes in total.

# Example

n = 2 give a graph like this:
    1 ---- 2 ---- 3
    |      |      |
    4 ---- 5 ---- 6
    |      |      |
    7 ---- 8 ---- 9

"""
function square_lattice_graph(n::Int64)::SimpleGraph{Int64}
    nrow = (n + 1)
    nvertices =  nrow * nrow
    g = SimpleGraph{Int64}(nvertices)
    for i in 1:nvertices
        if i % nrow != 0
            add_edge!(g, i, i + 1)
        end
        if trunc(i / nrow) < nrow - 1
            add_edge!(g, i, i + nrow)
        end
    end
    return g
end
