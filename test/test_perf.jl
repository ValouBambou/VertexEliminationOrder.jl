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
n = 20
times = Vector{Float64}()
@info "timing main algorithm iterative_dissection with $(Threads.nthreads()) threads"
for i in 1:n
    tic = time()
    iterative_dissection(g)
    push!(times, time() - tic)
end
avg_time = sum(times) / n
@info "average time = $(avg_time)"

using DelimitedFiles

open("dissection_time_threads.txt", "w") do io
    writedlm(io, [Threads.nthreads(), avg_time])
end