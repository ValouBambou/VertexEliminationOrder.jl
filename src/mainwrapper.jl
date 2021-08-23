"""
    order_tw_by_dissections_threads(graph, duration,nparallel=10, max_imbalances=[1.0, 0.8, 0.6], seed=4242)
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
function order_tw_by_dissections_threads(
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

"""
    order_tw_by_dissections_simple(graph, duration,)
Computes an approximation of the upper bound of the treewidth of the graph g and
an order for elimination using the iterative dissection (using flow cutter algorithm)
several times and select the best_order and treewidth.


# Arguments
- `graph::SimpleGraph{Int64}`: the graph to analyse.
- `duration::Int64` : the maximum time to wait (in seconds) for running iterative_dissection multiple times.
- `max_imbalance::Float64 = 0.6` criteria for selecting cuts that will build the separator.
- `seed::Int64 = 4242` the base seed for the RNG sampling the inputs of flowcutter and the choosen one cut for separator.
- `nsample::Int64 = 20` the number of calls to flowcutter with random inputs.

# Return
- `order::Vector{Int64}` an array of vertices index.
- `treewidth::Int64` the approximation of treewidth.

"""
function order_tw_by_dissections_simple(
    graph::SimpleGraph{Int64}, 
    duration::Int64;
    max_imbalances::Vector{Float64} = [1.0, 0.8, 0.6],
    seed::Int64 = 4242,
    nsample::Int64 = 20,
    sample_augment::Int64 = 8
    )::Pair{Vector{Int64},Int64}

    best_tw = typemax(Int64)
    best_order = Vector{Int64}()
    start = time()
    k = length(max_imbalances)
    i = 1
    
    while time() - start < duration
        @debug "time = $(round(time() - start; digits=2))"
        @debug "start new run with seed = $seed , current tw = $best_tw , max_imbalance = $(max_imbalances[i % k + 1]), nsample = $(20 + 20*(i÷8))"
        res = iterative_dissection(graph, best_tw, max_imbalances[i % k + 1] , nsample + nsample*(i ÷ sample_augment), seed)
        if res[2] < best_tw
            best_order, best_tw = res
        end
        seed += 1
        i += 1
    end
    @debug "finally best tw = $best_tw"
    return best_order => best_tw
end