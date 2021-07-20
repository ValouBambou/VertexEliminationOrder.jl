@with_kw struct Cell
    boundary::Vector{Int64}
    interior::Vector{Int64}
    bag_size::Int64 = length(boundary) + length(interior)
end

function bfs_non_satured_path(
        g::SimpleGraph,
        root::Int64,
        objective::Set{Int64},
        capacity_matrix::Array{Int64, 2},
        flow_matrix::Array{Int64, 2})

    visited = fill(false, nv(g))
    queue = Queue{Int64}()
    visited[root] = true
    enqueue!(queue, root)
    while !isempty(queue)
        v = dequeue!(queue)
        if v in objective
            return v
        end
        for n in neighbors(g, v)
            if (flow_matrix[v, n] != capacity_matrix[v, n]) && (!visited[n])
                visited[v] = true
                enqueue!(queue, v)
            end
        end
    end
end

function forward_grow!(
        set::Set{Int64},
        g::SimpleGraph,
        capacity_matrix::Array{Int64, 2},
        flow_matrix::Array{Int64, 2})

    to_explore = setdiff(vertices(g), set)
    for node in to_explore
        for x in set
            queue = Queue{Int64}()
        end
    end
end

function flowcutter(g::SimpleGraph, s::Int64, t::Int64)
    S, T = [s], [t]
    reachable_S, reachable_T = [s], [t]

end

"""
    split_cell(cell, g)
Computes a separator using flow cutter algorithm and return one final cell and
multiple open cells for nested recursion.

# Arguments
- `cell::Cell` the cell to split
- `g::SimpleGraph` the graph which contains the cell

# Return
- `cf::Cell` the final cell from separator
- `co::Vector{Cell}` the rest of open cells from the separation
"""
function split_cell(cell::Cell, g::SimpleGraph)
    # be careful with subgraph they are new graph with their own indices
    # use vmap to map the i index of the subgraph to vmap[i] its original index
    gc, vmap = induced_subgraph(g, cell.interior)
    # choose randomly 2 distinct nodes to became source and target for flowcutter
    s, t = sample(cell.interior, 2, replace = false)
    sep = flowcutter(gc, s, t)
    # TODO fix cells co for return values, and try to implement this without Cell
    return (
        Cell(boundary = cell.boundary, interior = sep),
        setdiff(vertices(gc), sep)
    )
end

"""
    nested_dissection(g)
Computes an approximation of the upper bound of the treewidth of the graph G and
an order for elimination using the nested dissection and the flow cutter algorithm.


# Arguments
- `g::SimpleGraph{Int64}`: the graph to analyse.

# Return
- ordering::`Vector{Int64}` an array of vertices index.
- result::`Int64`  of the approximation.

# Examples
```jlrepl
julia> G = smallgraph("house")

julia> nested_dissection(G)
([1, 5, 4, 3, 2], 2)
```
"""
function nested_dissection(g::SimpleGraph{Int64})
    # init cells sets
    open_cells = PriorityQueue{Cell, Int64}(Base.Order.Reverse)
    enqueue!(open_cells, Cell(boundary = [], interior = vertices(g)), nv(g))
    finals_cells::Vector{Cell} = []
    max_bag_size_finals = 0

    c = peek(open_cells).first
    while c.bag_size > max_bag_size_finals
        c = dequeue!(open_cells)
        # split the current cell (using a separator from flow cutter)
        cf, co = split_cell(c)

        # updating finals cells set and its max bag size
        push!(finals_cells, cf)
        max_bag_size_finals = max(max_bag_size_finals, cf.bag_size)

        # update the open cells set
        for c in co
            enqueue!(open_cells, c, c.bag_size)
        end
        # the next cell is the max_bag_size
        c = peek(open_cells).first
    end
    treewidth = max(map(v -> v.bag_size, finals_cells), map(v -> v.bag_size, open_cells))
    order = vcat(
        map(
            cell -> vcat(cell.interior, cell.boundary),
            vcat(collect(keys(open_cells)), reverse(finals_cells))
            )...
    )

    return (order, treewidth)
end
