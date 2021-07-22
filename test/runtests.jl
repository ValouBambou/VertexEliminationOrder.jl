using VertexEliminationOrder
using Test
using LightGraphs
using SparseArrays



@testset "VertexEliminationOrder.jl" begin

    include("test_heurestics.jl")
    include("test_flowcutter.jl")
end
