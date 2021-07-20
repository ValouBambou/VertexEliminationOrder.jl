@with_kw struct Cell
    nodes::BitVector
    size::Int64 = sum(nodes)
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
"""
function nested_dissection(g::SimpleGraph{Int64})
    # init cells sets
    open_cells = PriorityQueue{Cell, Int64}(Base.Order.Reverse)
    enqueue!(open_cells, Cell(nodes = vertices(g)), nv(g))
    finals_cells::Vector{Cell} = []
    max_bag_size_finals = 0

    c = peek(open_cells).first
    while c.size > max_bag_size_finals
        c = dequeue!(open_cells)
        # TODO write the split related code and correct this one
        # split the current cell (using a separator from flow cutter)
        cf, co = split_cell(c)

        # updating finals cells set and its max bag size
        push!(finals_cells, cf)
        max_bag_size_finals = max(max_bag_size_finals, cf.size)

        # update the open cells set
        for c in co
            enqueue!(open_cells, c, c.size)
        end
        # the next cell is the max_bag_size
        c = peek(open_cells).first
    end
    treewidth = max(map(v -> v.size, finals_cells), map(v -> v.size, open_cells))
    # flat a vector of Cells to a vector of indices
    order = vcat(
        map(
            cell -> findall(node -> node > 0, cell.nodes),
            vcat(
                collect(keys(open_cells)),
                reverse(finals_cells)
                )
            )
        )...
    return (order, treewidth)
end
