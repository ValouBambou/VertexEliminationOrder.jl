"""
    sample_iterative_dissections(graph, duration)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the iterative dissection and the flow cutter algorithm
several times and select the best_order and treewidth.


# Arguments
- `graph::SimpleGraph{Int64}`: the graph to analyse.
- `duration::Float64` : the maximum time to wait (in seconds) for running iterative_dissection multiple times.

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.
"""
function sample_iterative_dissections(
    graph::SimpleGraph{Int64}, 
    duration::Float64
    )::Pair{Vector{Int64},Int64}

    best_tw = typemax(Int64)
    best_order = []
    start = time()
    while time() - start < duration
        tmp1, tmp2 = iterative_dissection(graph, best_tw)
        if tmp2 < best_tw
            best_order, best_tw = tmp1, tmp2
        end
    end
    return best_order => best_tw
end