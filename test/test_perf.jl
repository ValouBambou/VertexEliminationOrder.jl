using LightGraphs
using VertexEliminationOrder
using Test


"""
    graph_from_gr(filename::String)

Read a graph from the provided gr file.
"""
function graph_from_gr(filename::String)
    lines = readlines(filename)

    # Create a Graph with the correct number of vertices.
    num_vertices, num_edges = parse.(Int, split(lines[1], ' ')[3:end])
    G = SimpleGraph(num_vertices)

    # Add an edge to the graph for every other line in the file.
    for line in lines[2:end]
        src, dst = parse.(Int, split(line, ' '))
        add_edge!(G, src, dst)
    end

    G
end

# The file to read the graph from.
graph_file = "test/example_graphs/sycamore_53_20.gr"

ENV["JULIA_DEBUG"]=VertexEliminationOrder


g = graph_from_gr(graph_file)
res = iterative_dissection!(g)
@test res[1] == unique(res[1])
@test res[2] == 57
