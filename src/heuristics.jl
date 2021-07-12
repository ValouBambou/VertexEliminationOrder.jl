"""
    count_added_edges_elim(g, v)
Computes the number of edges that will be added to the graph if we choose to
eliminate this vertex.

# Arguments
- `g::SimpleGraph{Int64}` the graph to consider.
- `v::Int64` the vertex to eliminate.

# Return
- `count::Int64` number of edges to add in the graph g if v is eliminated.
"""
function count_added_edges_elim(g::SimpleGraph{Int64}, v::Int64)::Int64
    count = 0
    ns = neighbors(g, v)
    len = length(ns)
    for i = 1:(len-1)
        for j = (i+1):len
            if !has_edge(g, ns[i], ns[j])
                count += 1
            end
        end
    end
    return count
end

"""
    connect_neighbors!(g, v)
Connect neighbors of v (in graph g) together if they are not already connected.

# Arguments
- `g::SimpleGraph{Int64}` the graph to consider.
- `v::Int64` the vertex to make simplicial.

# Return
- `change::Bool` true if edge is created false otherwise.
"""
function connect_neighbors!(g::SimpleGraph{Int64}, v::Int64)::Bool
    ns = neighbors(g, v)
    len = length(ns)
    change = false
    for i = 1:(len-1)
        for j = (i+1):len
            if !has_edge(g, ns[i], ns[j])
                add_edge!(g, ns[i], ns[j])
                change = true
            end
        end
    end
    return change
end


"""
    minfill!(g)
Computes an approximation of the upper bound of the treewidth of the graph G and
an order for elimination using the min-fill heuristic. Computation is done by
elimating vertices in g so the graph is empty after this function.

# Arguments
- `g::SimpleGraph{Int64}`: the graph to analyse.

# Return
- result::`Int64`  of the approximation.
- ordering::`Vector{Int64}` an array of vertices index.

# Examples
```jlrepl
julia> G = smallgraph("house")

julia> minfill!(G)
([5, 1, 4, 3, 2], 2)
```
"""
function minfill!(g::SimpleGraph{Int64})
    nvertices = nv(g)
    order = zeros(Int64, nvertices)
    labels = [i for i = 1:nvertices]
    treewidth = 0
    for i = 1:nvertices
        # find the vertex which add the less edges after elimination
        toremove = argmin(map(v -> count_added_edges_elim(g, v), vertices(g)))
        order[i] = labels[toremove]

        # keep track of index with the future remove
        max_index = nvertices + 1 - i
        if toremove < max_index
            labels[max_index] = toremove
            labels[toremove] = max_index
        end

        # compute the treewidth of the current decomposition
        treewidth = max(treewidth, degree(g, toremove))

        # remove the vertex by making it simplicial
        connect_neighbors!(g, toremove)
        rem_vertex!(g, toremove)
    end
    return (order, treewidth)
end

"""
    minwidth!(g)
Computes an approximation of the upper bound of the treewidth of the graph G and
an order for elimination using the min-width heuristic. Computation is done by
elimating vertices in g so the graph is empty after this function.

# Arguments
- `g::SimpleGraph{Int64}`: the graph to analyse.

# Return
- result::`Int64`  of the approximation.
- ordering::`Vector{Int64}` an array of vertices index.

# Examples
```jlrepl
julia> G = smallgraph("house")

julia> minwidth!(G)
([1, 5, 4, 3, 2], 2)
```
"""
function minwidth!(g::SimpleGraph{Int64})
    nvertices = nv(g)
    order = zeros(Int64, nvertices)
    labels = [i for i = 1:nvertices]
    treewidth = 0
    for i = 1:nvertices
        # find the vertex whith the minimum degree
        toremove = argmin(map(v -> degree(g, v), vertices(g)))
        order[i] = labels[toremove]

        # keep track of index with the future remove
        max_index = nvertices + 1 - i
        if toremove < max_index
            labels[max_index] = toremove
            labels[toremove] = max_index
        end

        # compute the treewidth of the current decomposition
        treewidth = max(treewidth, degree(g, toremove))

        # remove the vertex by making it simplicial
        connect_neighbors!(g, toremove)
        rem_vertex!(g, toremove)
    end
    return (order, treewidth)
end
