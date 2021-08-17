"""
    sample_iterative_dissections(graph, duration)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the iterative dissection and the flow cutter algorithm
several times and select the best_order and treewidth.


# Arguments
- `graph::SimpleGraph{Int64}`: the graph to analyse.
- `duration::Int64` : the maximum time to wait (in seconds) for running iterative_dissection multiple times.
- `nparallel::Int64 = 10` the number of calls in parallel to iterative_dissection

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.

"""
function sample_iterative_dissections(
    graph::SimpleGraph{Int64}, 
    duration::Int64,
    nparallel::Int64 = 10,
    )::Pair{Vector{Int64},Int64}

    best_tw = typemax(Int64)
    best_order = Vector{Int64}()
    start = time()
    while time() - start < duration
        @debug "start 10 run current tw = $best_tw , time = $(time() - start)"
        Threads.@threads for i = 1:nparallel
            res = iterative_dissection(graph, best_tw)
            if res[2] < best_tw
                best_order, best_tw = res
            end
        end
    end
    return best_order => best_tw
end