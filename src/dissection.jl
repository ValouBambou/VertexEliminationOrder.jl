"""
    separator!(g, subgraph_nodes)
Call flowcutter (with s and t random) on g and pick nodes at random in the cut matching the 60% imbalance
heuristic to form a separator. Then split the graph g with respect to the separator.

# Arguments
- `g::SimpleGraph{Int64}`: the subgraph to run flowcutter.
- `subgraph_nodes::Vector{Int64}`: a table where element at index i is corresponding label in the original root graph.

# Return
- `sep::Vector{Int64}`: the set of indices of the nodes in separator.
- `split_parts::Array{Array{Int64,1},1}` several parts of the graph resulted from separation.
"""
function separator!(
    g::SimpleGraph{Int64},
    subgraph_nodes::Vector{Int64},
)::Tuple{Vector{Int64},Array{Array{Int64,1},1}}

    s, t = sample(subgraph_nodes, 2, replace = false)
    dist = floyd_warshall_shortest_paths(g).dists
    # 60% imbalance is like index = 40% of length(cuts) (as last cuts are close to 0% imbalance)
    # TODO: improve this, probably not what we want
    cuts = flowcutter(g, s, t, dist)
    cut = cuts[trunc(Int64, 0.4 * length(cuts) + 1)]
    sep = unique(map(a -> sample([a.first, a.second]), cut))
    n = length(sep)
    # split the subgraph in several parts
    # be careful with index while removing vertices from sep
    indices = Array(1:n)
    for i = 1:n
        max_i = n + 1 - i
        toremove = sep[i]
        if toremove < max_i
            indices[toremove] = max_i
        end
        rem_vertex!(g, toremove)
    end
    # catch the multiple parts created from the split
    split_parts = connected_components(g)
    # be careful to return indices which make sense in the original root graph
    return (
        map(node -> subgraph_nodes[node], sep),
        map(
            vector -> map(node -> subgraph_nodes[indices[node]], vector),
            split_parts,
        ),
    )
end



"""
    nested_dissection(g)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the nested dissection and the flow cutter algorithm.


# Arguments
- `g::SimpleGraph{Int64}`: the graph to analyse.

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.
"""
function nested_dissection(g::SimpleGraph{Int64})
    n = nv(g)
    order = zeros(Int64, n)
    treewidth = 0
    q = Queue{Vector{Int64}}()
    enqueue!(q, Vector(1:n))
    i = n
    while !isempty(q)
        subgraph_nodes = dequeue!(q)
        graph = induced_subgraph(g, subgraph_nodes)[1]
        # if graph is a tree or complete we can stop
        n = nv(graph)
        nedges = ne(graph)
        if nedges == n * (n - 1) / 2
            treewidth = max(treewidth, n - 1)
            order[(i-n+1):i] .= subgraph_nodes
            i -= n
            continue
        elseif nedges == n - 1
            treewidth = max(treewidth, 1)
            # TODO: change this order to a bottom to top order for tree real tw
            order[(i-n+1):i] .= subgraph_nodes
            i -= n
            continue
        end

        # compute separator and cut graph in several parts (graph and indices)
        sep, toqueue = separator!(graph, subgraph_nodes)

        # update order and treewidth
        k = length(sep)
        order[(i-k+1):i] = sep
        i -= k
        treewidth = max(treewidth, k)

        # add next subgraphs to the queue
        enqueue!.([q], toqueue)
    end
    return (order, treewidth)
end
