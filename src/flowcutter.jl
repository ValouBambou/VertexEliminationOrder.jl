struct Cell
    boundary::Set{Int64}
    interior::Set{Int64}
    size::Int64 = length(boundary) + length(interior)
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
    cell = Cell(boundary = Set([]), interior = vertices(g))
    while true
        # get a separator to split the cell using flow cutter algorithm

        # split the cell
    end

end
