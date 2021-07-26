using VertexEliminationOrder
using Test
using LightGraphs
using SparseArrays


ENV["JULIA_DEBUG"]=VertexEliminationOrder

@testset "VertexEliminationOrder.jl" begin

    include("test_heuristics.jl")
    include("test_flowcutter.jl")
end
