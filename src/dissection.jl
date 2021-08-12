@with_kw struct Cell
    boundary::BitVector
    interior::BitVector
    size::Int64 = sum(boundary .| interior)
end

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
)::Tuple{Vector{Int64},Vector{Vector{Int}}}

    # run flowcutter many times and collect all of these cuts
    cuts::Vector{Cut} = []
    n = nv(g) + 2

    for i in 1:max_nsample
        add_vertex!(g)
        add_vertex!(g)
        s, t = sample(1:length(subgraph_nodes), 2, replace=false)
        dist = [dijkstra_shortest_paths(g, s).dists dijkstra_shortest_paths(g, t).dists]
        append!(cuts, filter(c -> c.imbalance < max_imbalance, flowcutter!(g, s, t, dist)))
        rem_vertex!(g, n)
        rem_vertex!(g, n - 1)
    end

    # remove dominated cuts
    candidates = Dict{Int64, Cut}()
    for c in cuts
        size = c.size
        # update candidates if they are not previous candidates with its size
        # or in case the candidate is better than its predecessor i.e same this but lower imbalance
        if !(size in keys(candidates)) || c.imbalance < candidates[size].imbalance
            candidates[size] = c
        end
    end

    # select cut with min expansion
    cut = findmin(c -> c.expansion, values(candidates))[2]
    @debug "selected cut = $cut"
    sep = unique(map(a -> sample([a.first, a.second]), cut.arcs))
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
    iterative_dissection(g)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the iterative dissection and the flow cutter algorithm.


# Arguments
- `g::SimpleGraph{Int64}`: the graph to analyse.

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.
"""
function iterative_dissection(
        g::SimpleGraph{Int64}, 
        best_tw::Int64 = typemax(Int64)
    )::Pair{Vector{Int64}, Int64}
    n = nv(g)
    order = zeros(Int64, n)
    treewidth = 0
    q = PriorityQueue{Cell, Int64}(Base.Order.Reverse)
    enqueue!(q, Cell(boundary = falses(n), interior = trues(n)), n)
    i = n
    while (!isempty(q)) && (treewidth < best_tw)
        cell = dequeue!(q)
        subgraph_nodes = findall(it -> it > 0, cell.interior)
        graph = induced_subgraph(g, subgraph_nodes)[1]
        # if graph is a tree or complete we can stop
        n = nv(graph)
        nedges = ne(graph)
        if nedges == n * (n - 1) / 2
            @debug "graph is complete"
            order[(i - n + 1):i] .= subgraph_nodes
            i -= n
            treewidth = max(cell.size, treewidth)
            continue
        elseif nedges == n - 1
            @debug "graph is a tree"
            order[(i - n + 1):i] .= tree_order!(graph, subgraph_nodes)
            i -= n
            treewidth = max(cell.size, treewidth)
            continue
        end
        
        # compute separator and cut graph in several parts (graph and indices)
        sep, toqueue = separator!(graph, subgraph_nodes)

        # update order and treewidth
        k = length(sep) + sum(cell.boundary)
        order[(i - k + 1):i] = sep
        i -= k
        treewidth = max(k, treewidth)
        n = nv(g)
        # add next subgraphs to the queue
        for new_interiors in toqueue
            Ic = falses(n)
            Ic[new_interiors] .= true
            Bc = falses(n)
            tmp_Bc = findall(cell.boundary)
            tmp_Bc = findall(
                node -> any(
                    bound -> has_edge(g, node, bound), 
                    tmp_Bc
                    ), 
                sep
            )
            Bc[tmp_Bc] .= true
            new_cell = Cell(boundary = Bc, interior = Ic)
            enqueue!(q, new_cell, new_cell.size)
        end
    end
    return order => treewidth
end
