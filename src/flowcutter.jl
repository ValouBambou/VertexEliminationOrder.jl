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
- result::`Int64`  of the approximation.
- ordering::`Vector{Int64}` an array of vertices index.

# Examples
```jlrepl
julia> G = smallgraph("house")

julia> nested_dissection(G)
([1, 5, 4, 3, 2], 2)
```
"""
function nested_dissection(g::SimpleGraph{Int64})
    open_cells = PriorityQueue{Cell, Int64}(Base.Order.Reverse)
    enqueue!(open_cells, Cell(boundary = Set([]), interior = vertices(g)), 0)
    finals_cells::Set{Cell} = Set()
    max_bag_size_finals = 0

    c = peek(open_cells).first
    while c.bag_size > max_bag_size_finals
        c = dequeue!(open_cells)
        # split the current cell (using a separator from flow cutter) gives a set of cells
        cf = split_cell(c)

        # need to catch the final cell cf to add in the final cells set

        # updating finals cells set and its max bag size
        push!(open_cells, cf)
        max_bag_size_finals = max(max_bag_size_finals, cf.bag_size)

        # the next cell is the max_bag_size
        c = peek(open_cells).first
    end
end
