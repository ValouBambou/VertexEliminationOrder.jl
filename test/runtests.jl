using VertexEliminationOrder
using Test
using LightGraphs
using SparseArrays



@testset "VertexEliminationOrder.jl" begin

    include("test_heuristics.jl")
    include("test_flowcutter.jl")
end
