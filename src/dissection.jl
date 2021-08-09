"""
    separator!(g, subgraph_nodes, max_imbalance=0.6, max_nsample=20)
Call flowcutter (with s and t random) on g and pick nodes at random in the cut matching the 60% imbalance
heuristic to form a separator. Then split the graph g with respect to the separator.
Parameter max_imbalance define the heurestic to choose a cut amoung all generated by
flowcutter. Parameter max_nsample define the number of call to flowcutter.

# Arguments
- `g::SimpleGraph{Int64}`: the subgraph to run flowcutter.
- `subgraph_nodes::Vector{Int64}`: a table where element at index i is corresponding label in the original root graph.
- `max_imbalance::Float64 = 0.6` max imbalance to select cut from flowcutter result.
- `max_nsample::Int64 = 20` max number of try to get a separator.
# Return
- `sep::Vector{Int64}`: the set of indices of the nodes in separator.
- `split_parts::Array{Array{Int64,1},1}` several parts of the graph resulted from separation.
"""
function separator!(
    g::SimpleGraph{Int64},
    subgraph_nodes::Vector{Int64},
    max_imbalance::Float64=0.6,
    max_nsample::Int64=20,
)::Tuple{Vector{Int64},Array{Array{Int64,1},1}}
    @debug "------ separator! --------"

    # run flowcutter many times and collect all of these cuts
    cuts::Vector{Cut} = []
    n = nv(g) + 2

    dist = floyd_warshall_shortest_paths(g).dists
    for i in 1:max_nsample
        add_vertex!(g)
        add_vertex!(g)
        s, t = sample(1:length(subgraph_nodes), 2, replace=false)
        append!(cuts, flowcutter!(g, s, t, dist))
        rem_vertex!(g, n)
        rem_vertex!(g, n - 1)
    end


    # find best size imbalance for cuts
    minsize = typemax(Int64)
    minimbalance = typemax(Int64)
    for c in cuts
        size = c.size
        imbalance = c.imbalance
        expansion = c.expansion
        if size < minsize
            minsize = size
        end
        if imbalance < minimbalance
            minimbalance = imbalance
        end
    end
    # remove dominated cuts and cuts with more than max_imbalance (=0.6)
    filter!(
        c -> ((c.size == minsize) || (c.imbalance == minimbalance)) && (c.imbalance < max_imbalance),
        cuts
    )

    # select cut with min expansion
    cut = findmin(c -> c.expansion, cuts)[2]
    sep = unique(map(a -> sample([a.first, a.second]), cut.arcs))
    @debug "cut=$cut"
    @debug "sep=$sep"
    n -= 2
    # split the subgraph in several parts
    # be careful with index while removing vertices from sep
    labels = collect(1:n)
    for rm_origin_id in sep
        rm = findfirst(id -> id == rm_origin_id, labels)
        rem_vertex!(g, rm)
        labels[rm] = labels[end]
        pop!(labels)
    end
    # catch the multiple parts created from the split
    split_parts = connected_components(g)

    @debug "subgraph_nodes=$subgraph_nodes"
    @debug "labels=$labels"
    @debug "split_parts=$split_parts"
    # be careful to return indices which make sense in the original root graph
    return (
        map(node -> subgraph_nodes[node], sep),
        map(
            vector -> map(node -> subgraph_nodes[labels[node]], vector),
            split_parts,
        ),
    )
end



"""
    nested_dissection!(g)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the nested dissection and the flow cutter algorithm.


# Arguments
- `g::SimpleGraph{Int64}`: the graph to analyse.

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.
"""
function nested_dissection!(g::SimpleGraph{Int64})
    n = nv(g)
    order = zeros(Int64, n)
    q = Queue{Vector{Int64}}()
    sep::Vector{Int64} = []
    enqueue!(q, collect(1:n))
    i = n
    while !isempty(q)
        @debug "order is $order"
        subgraph_nodes = dequeue!(q)
        graph = induced_subgraph(g, subgraph_nodes)[1]
        # if graph is a tree or complete we can stop
        n = nv(graph)
        nedges = ne(graph)
        if nedges == n * (n - 1) / 2
            @debug "graph is complete"
            order[(i - n + 1):i] .= subgraph_nodes
            i -= n
            continue
        elseif nedges == n - 1
            @debug "graph is a tree"
            order[(i - n + 1):i] .= tree_order!(graph, subgraph_nodes)
            i -= n
            continue
        end

        # compute separator and cut graph in several parts (graph and indices)
        sep, toqueue = separator!(graph, subgraph_nodes)
        @debug "separator! returns $sep $toqueue"


        # update order and treewidth
        k = length(sep)
        order[(i - k + 1):i] = sep
        i -= k

        # add next subgraphs to the queue
        enqueue!.([q], toqueue)
    end
    treewidth = treewidth_by_elimination!(g, order)
    return (order, treewidth)
end
