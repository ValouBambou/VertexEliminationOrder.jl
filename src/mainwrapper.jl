"""
    order_tw_by_dissections(graph, duration,nparallel=10)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the iterative dissection (using flow cutter algorithm)
several times in parallel and select the best_order and treewidth.


# Arguments
- `graph::SimpleGraph{Int64}`: the graph to analyse.
- `duration::Int64` : the maximum time to wait (in seconds) for running iterative_dissection multiple times.
- `nparallel::Int64 = 10` the number of calls in parallel to iterative_dissection.
- `max_imbalance::Float64 = 0.6` criteria for selecting cuts that will build the separator.
- `max_nsample::Int64 = 20` the number of calls to flowcutter with random inputs.
- `seed::Int64 = 4242` the base seed for the RNG sampling the inputs of flowcutter and the choosen one cut for separator.

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.

"""
function order_tw_by_dissections(
    graph::SimpleGraph{Int64}, 
    duration::Int64,
    nparallel::Int64 = 2 * Threads.nthreads(),
    max_imbalances::Vector{Float64} = [1.0, 0.8, 0.6],
    seed::Int64 = 4242
    )::Pair{Vector{Int64},Int64}

    best_tw = typemax(Int64)
    best_order = Vector{Int64}()
    start = time()
    k = length(max_imbalances)
    
    while time() - start < duration
        @debug "start $nparallel run current tw = $best_tw , time = $(time() - start)"
        seed += Threads.nthreads()
        Threads.@threads for i = 1:nparallel
            res = iterative_dissection(graph, best_tw, max_imbalances[i % k + 1] , 20, seed + i)
            if res[2] < best_tw
                best_order, best_tw = res
            end
        end
    end
    @debug "finally best tw = $best_tw"
    return best_order => best_tw
end