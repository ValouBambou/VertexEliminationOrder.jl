using LightGraphs
using Test
using Pkg

Pkg.activate(".")
using VertexEliminationOrder


# The file to read the graph from.
graph_file = "test/example_graphs/sycamore_53_20.gr"

ENV["JULIA_DEBUG"]=VertexEliminationOrder
g = smallgraph("house")
iterative_dissection(g)

g = graph_from_gr(graph_file)
times = Vector{Float64}()
for i in 1:10
    tic = time()
    @info "timing main algorithm iterative_dissection"
    iterative_dissection(g)
    push!(times, time() - tic)
end
@info "average time = $(round(sum(times) / 10; digits=2))"

@info "new wrapper"
order_tw_by_dissections(g, 30, 10, 1.0, 20, 4242)
