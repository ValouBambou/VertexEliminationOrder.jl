using VertexEliminationOrder
using Test


@testset "VertexEliminationOrder.jl" begin
    include("test_utils.jl")
    include("test_heuristics.jl")
    include("test_flowcutter.jl")
    include("test_dissection.jl")

end
