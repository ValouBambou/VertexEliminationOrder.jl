"""
    separator(g, indices)
Call flowcutter (with s and t random) and pick nodes at random in the cut matching the 60% imbalance
heuristic to form a separator. Then split the graph with respect to the separator.

# Arguments
- `g::SimpleGraph{Int64}`: the graph to run flowcutter.

# Return
- `sep::Vector{Int64}`: the set of indices of the nodes in separator.
"""
function separator(g::SimpleGraph{Int64},
                   indices::Vector{Int64}
                   )::Vector{Int64}
    n = nv(g)
    s, t = sample(1:n, 2, replace = false)
    # 60% imbalance is like index = 40% of length(cuts) (as last cuts are close to 0% imbalance)
    # TODO: improve this, probably not what we want
    cuts = flowcutter(g, s, t)
    k = length(cuts)
    cut = cuts[trunc(Int64, 0.4 * k + 1)]
    sep = unique(map(a -> indices[sample([a.first, a.second])], cut))
    return sep
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
    q = Queue{Pair{SimpleGraph{Int64}, Vector{Int64}}}()
    enqueue!(q, g=>Vector(1:n))
    i = n
    while !isempty(q)
        graph, indices = dequeue!(q)
        # if graph is a tree or complete we can stop
        n = nv(graph)
        nedges = ne(graph)
        if nedges == n * (n - 1) / 2
            treewidth = max(treewidth, n - 1)
            order[(i-n+1):i] = indices[1:n]
            i -= n
            continue
        elseif nedges == n - 1
            treewidth = max(treewidth, 1)
            # TODO: change this order to a bottom to top order for tree real tw
            order[(i-n+1):i] = indices[1:n]
            i -= n
            continue
        end
        # compute separator and cut graph in several parts (graph and indices)
        sep = separator(graph, indices)
        toqueue = separate(graph, sep)
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
