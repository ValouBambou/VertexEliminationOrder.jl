module VertexEliminationOrder

using LightGraphs
using Parameters
using DataStructures
using StatsBase
using SparseArrays

include("heuristics.jl")
include("flowcutter.jl")
include("dissection.jl")

export minfill!, minwidth!, augment_flow!, forward_grow!, piercing_node, flowcutter, nested_dissection


end
