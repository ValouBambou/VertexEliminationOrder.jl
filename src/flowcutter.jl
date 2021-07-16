@with_kw struct Cell
    boundary::Set{Int64}
    interior::Set{Int64}
    bag_size::Int64 = length(boundary) + length(interior)
end


function split_cell(c::Cell)
    # get a separator to split the cell using flow cutter algorithm
    nothing
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
    enqueue!(open_cells, Cell(boundary = Set([]), interior = vertices(g)), nv(g))
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

    return (,
end
